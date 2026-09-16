# frozen_string_literal: true

class Croissant::Selector::Specificity
  include Comparable

  BUCKET_BITS = 8
  BUCKET_SIZE = 1 << BUCKET_BITS
  BUCKET_MASK = BUCKET_SIZE - 1

  ELEMENT_SHIFT = 0
  CLASS_SHIFT = BUCKET_BITS
  ID_SHIFT = BUCKET_BITS * 2
  STYLE_SHIFT = BUCKET_BITS * 3

  class << self
    def build(style, ids, classes, elements)
      new(
        (style << STYLE_SHIFT) +
          (ids << ID_SHIFT) +
          (classes << CLASS_SHIFT) +
          (elements << ELEMENT_SHIFT)
      )
    end

    def inline
      @inline ||= build(1, 0, 0, 0)
    end

    def zero
      @zero ||= build(0, 0, 0, 0)
    end

    def id
      @id ||= build(0, 1, 0, 0)
    end

    def class_name
      @class_name ||= build(0, 0, 1, 0)
    end

    def element
      @element ||= build(0, 0, 0, 1)
    end
  end

  def initialize(value)
    @value = value

    freeze
  end

  def style
    @value >> STYLE_SHIFT
  end

  def ids
    (@value >> ID_SHIFT) & BUCKET_MASK
  end

  def classes
    (@value >> CLASS_SHIFT) & BUCKET_MASK
  end

  def elements
    (@value >> ELEMENT_SHIFT) & BUCKET_MASK
  end

  def <=>(other)
    @value <=> other.to_i if other.is_a?(self.class)
  end

  def +(other)
    self.class.new(@value + other.to_i)
  end

  def eql?(other)
    other.is_a?(self.class) && @value == other.to_i
  end

  def hash
    [self.class, @value].hash
  end

  def to_i
    @value
  end

  def inspect
    "<#{self.class} [#{style}, #{ids}, #{classes}, #{elements}]>"
  end
end
