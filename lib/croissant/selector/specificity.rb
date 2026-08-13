# frozen_string_literal: true

class Croissant::Selector::Specificity
  include Comparable

  attr_reader :style, :ids, :classes, :elements

  def self.inline
    @inline ||= new(1, 0, 0, 0)
  end

  def self.zero
    @zero ||= new(0, 0, 0, 0)
  end

  def self.id
    @id ||= new(0, 1, 0, 0)
  end

  def self.class_name
    @class_name ||= new(0, 0, 1, 0)
  end

  def self.element
    @element ||= new(0, 0, 0, 1)
  end

  def initialize(style, ids, classes, elements)
    @style = style
    @ids = ids
    @classes = classes
    @elements = elements

    freeze
  end

  def <=>(other)
    return unless other.is_a?(self.class)

    compare(:style, other) || compare(:ids, other) || compare(:classes, other) || (elements <=> other.elements)
  end

  def +(other)
    self.class.new(
      style + other.style,
      ids + other.ids,
      classes + other.classes,
      elements + other.elements
    )
  end

  def eql?(other)
    other.is_a?(self.class) &&
      style == other.style &&
      ids == other.ids &&
      classes == other.classes &&
      elements == other.elements
  end

  def hash
    [self.class, style, ids, classes, elements].hash
  end

  def inspect
    "<#{self.class} [#{style}, #{ids}, #{classes}, #{elements}]>"
  end

  private

  def compare(field, other)
    result = public_send(field) <=> other.public_send(field)
    result unless result.zero?
  end
end
