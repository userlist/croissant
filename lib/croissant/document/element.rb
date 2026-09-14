# frozen_string_literal: true

class Croissant::Document::Element
  attr_reader :document, :node

  def initialize(document, node)
    @document = document
    @node = node

    yield(self) if block_given?
  end

  def name
    node.name
  end

  def [](attribute)
    node[attribute]
  end

  def []=(attribute, value)
    node[attribute] = value
  end

  def remove_attribute(attribute)
    node.remove_attribute(attribute)
  end
end
