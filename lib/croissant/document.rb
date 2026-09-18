# frozen_string_literal: true

require 'nokogiri'

class Croissant::Document
  DOCUMENT_PATTERN = /<!doctype\s|<html[\s>]/i
  NO_RULES = [].freeze

  private_constant :NO_RULES

  def self.parse(html)
    if html.match?(DOCUMENT_PATTERN)
      new(Nokogiri::HTML::Document.parse(html))
    else
      new(Nokogiri::HTML::DocumentFragment.parse(html))
    end
  end

  attr_reader :stylesheets

  def initialize(document)
    @document = document
    @parser = Croissant::Stylesheet::Parser.new
    @nodes = {}.compare_by_identity

    reload
  end

  def to_html
    document.to_html
  end

  def fragment?
    document.is_a?(Nokogiri::XML::DocumentFragment)
  end

  def each_element(&)
    xpath('.//*').each(&)
  end

  def root
    node = document.root
    node && element_for(node)
  end

  def children
    document.children.map { |child| element_for(child) }
  end

  def add_child(node)
    node = node.send(:node) if node.is_a?(Croissant::Document::Node)
    document.add_child(node)
  end

  def xpath(path)
    return enum_for(__method__, path) unless block_given?

    document.xpath(path).each { |node| yield element_for(node) }
  end

  def at_xpath(path)
    node = document.at_xpath(path)
    node && element_for(node)
  end

  def node_for(node)
    @nodes[node] ||= (node.element? ? Croissant::Document::Element : Croissant::Document::Node).new(self, node)
  end

  def element_for(node)
    raise ArgumentError, "expected an element node, got #{node.class}" unless node.element?

    node_for(node)
  end

  def style_for(element)
    Croissant::Style::ElementStyle.new(cascade.resolve(*inline_rules_for(element)))
  end

  def computed_style_for(element)
    Croissant::Style::ElementStyle.new(cascade.resolve(*rules_for(element), *inline_rules_for(element)))
  end

  def create_node(name)
    node = Nokogiri::XML::Node.new(name, document)

    node_for(node)
  end

  def head
    return nil if fragment?

    at_xpath('/html/head') || create_head
  end

  def body
    return nil if fragment?

    at_xpath('/html/body') || create_body
  end

  def reload
    @stylesheets = xpath('.//style').map { |element| parser.parse(element.content) }
    @rules = Croissant::Selector::Index.new { |index| inlinable_rules.each { |rule| index.add(rule.selector, rule) } }
    @cascade = Croissant::Style::Cascade.new(inlinable_rules)
  end

  private

  attr_reader :document, :parser, :cascade

  def inlinable_rules
    stylesheets.flat_map(&:rules).select(&:inlinable?)
  end

  def rules_for(element)
    @rules[element]
  end

  def inline_rules_for(element)
    value = element['style']
    return NO_RULES if value.nil? || value.strip.empty?

    [parser.parse_attribute(value)]
  end

  def html
    document.root || document.add_child(Nokogiri::XML::Node.new('html', document))
  end

  def create_head
    head = Nokogiri::XML::Node.new('head', document)

    (first = html.children.first) ? first.add_previous_sibling(head) : html.add_child(head)
  end

  def create_body
    html.add_child(Nokogiri::XML::Node.new('body', document))
  end
end

require_relative 'document/node'
require_relative 'document/element'
