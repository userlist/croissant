# frozen_string_literal: true

class Croissant::Selector::PseudoClass::Functional < Croissant::Selector::PseudoClass
  attr_reader :selectors

  def initialize(selectors)
    @selectors = selectors

    super()
  end

  def matches?(element)
    selectors.any? { |selector| selector.matches?(element) }
  end

  def inlinable?
    selectors.all?(&:inlinable?)
  end

  def to_s
    ":#{keyword}(#{selectors.join(', ')})"
  end

  private

  def keyword
    raise NotImplementedError, "subclass must implement #{self.class}##{__method__}"
  end
end

require_relative 'functional/not'
require_relative 'functional/is'
require_relative 'functional/where'
require_relative 'functional/has'
