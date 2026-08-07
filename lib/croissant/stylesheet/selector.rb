# frozen_string_literal: true

class Croissant::Stylesheet::Selector
  attr_reader :selector, :specificity

  def initialize(selector:, specificity:, inlinable:)
    @selector = selector
    @specificity = specificity
    @inlinable = inlinable

    freeze
  end

  alias to_s selector
  alias to_str selector

  def inlinable?
    @inlinable
  end

  def ==(other)
    other.is_a?(self.class) &&
      selector == other.selector &&
      specificity == other.specificity &&
      inlinable? == other.inlinable?
  end
  alias eql? ==

  def hash
    [self.class, selector, specificity, inlinable?].hash
  end
end
