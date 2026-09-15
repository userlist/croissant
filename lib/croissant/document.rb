# frozen_string_literal: true

require 'nokogiri'

class Croissant::Document
  DOCUMENT_PATTERN = /<!doctype\s|<html[\s>]/i

  def self.parse(html)
    if html.match?(DOCUMENT_PATTERN)
      new(Nokogiri::HTML::Document.parse(html))
    else
      new(Nokogiri::HTML::DocumentFragment.parse(html))
    end
  end

  attr_reader :document

  def initialize(document)
    @document = document
  end

  def to_html
    document.to_html
  end

  def fragment?
    document.is_a?(Nokogiri::XML::DocumentFragment)
  end

  # One stylesheet per <style> element, in document order. The document is
  # mutable, so this is parsed afresh on every call.
  def stylesheets
    document.xpath('.//style').map { |element| parser.parse(element.content) }
  end

  # Yields a Document::Element for every element node, in document order.
  def each_element
    return enum_for(:each_element) unless block_given?

    document.xpath('.//*').each { |node| yield Croissant::Document::Element.new(self, node) }
  end

  # Compiles the style attribute of an element into an ElementStyle.
  def style_for(element)
    declarations = Croissant::Style::Cascade.resolve(inline_rules_for(element))

    Croissant::Style::ElementStyle.new(declarations)
  end

  # Cascades the inlinable stylesheet rules matching an element and its style
  # attribute into an ElementStyle.
  def computed_style_for(element)
    declarations = Croissant::Style::Cascade.resolve(rules_for(element), inline_rules_for(element))

    Croissant::Style::ElementStyle.new(declarations)
  end

  def head
    return nil if fragment?

    document.at_xpath('/html/head') || create_head
  end

  def body
    return nil if fragment?

    document.at_xpath('/html/body') || create_body
  end

  private

  def parser
    @parser ||= Croissant::Stylesheet::Parser.new
  end

  # Indexes the inlinable rules of all stylesheets. Built afresh on every
  # call.
  def rule_set
    Croissant::Style::RuleSet.new(stylesheets.flat_map(&:rules).select(&:inlinable?))
  end

  # The inlinable stylesheet rules matching an element, in source order.
  def rules_for(element)
    rule_set[element.node]
  end

  # The style attribute of an element parsed into a rule with inline
  # specificity, or no rules without one.
  def inline_rules_for(element)
    value = element['style']
    return [] if value.nil? || value.strip.empty?

    [parser.parse_attribute(value)]
  end

  def html
    document.root || document.add_child(Nokogiri::XML::Node.new('html', document))
  end

  # The head goes before any other child of <html>.
  def create_head
    head = Nokogiri::XML::Node.new('head', document)

    (first = html.children.first) ? first.add_previous_sibling(head) : html.add_child(head)
  end

  # The body goes after any other child of <html>.
  def create_body
    html.add_child(Nokogiri::XML::Node.new('body', document))
  end
end

require_relative 'document/element'
