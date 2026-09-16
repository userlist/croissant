# frozen_string_literal: true

class Croissant::Document::Node
  attr_reader :document, :name

  def initialize(document, node)
    @document = document
    @node = node

    @name = node.name
  end

  def element?
    node.element?
  end

  def text?
    node.text?
  end

  def content
    node.content
  end

  def content=(value)
    node.content = value
  end

  def parent
    return @parent if defined?(@parent)

    parent = node.parent
    @parent = parent&.element? ? wrap(parent) : nil
  end

  def at_xpath(path)
    result = node.at_xpath(path)
    wrap(result)
  end

  def xpath(path)
    return enum_for(__method__, path) unless block_given?

    document.xpath(path).each { |node| yield wrap(node) }
  end

  def previous_element
    wrap(node.previous_element)
  end

  def next_element
    wrap(node.next_element)
  end

  def children
    node.children.map { |child| wrap(child) }
  end

  def element_children
    node.element_children.map { |child| wrap(child) }
  end

  def add_child(node)
    node = node.node if node.is_a?(Croissant::Document::Node)
    self.node.add_child(node)
  end

  def add_previous_sibling(node)
    node = node.node if node.is_a?(Croissant::Document::Node)
    self.node.add_previous_sibling(node)
  end

  def key?(...)
    node.key?(...)
  end

  def matches?(...)
    node.matches?(...)
  end

  def text
    node.text
  end

  def remove
    node.remove
  end

  def to_html
    node.to_html
  end

  protected

  attr_reader :node

  private

  def wrap(node)
    node && document.node_for(node)
  end
end
