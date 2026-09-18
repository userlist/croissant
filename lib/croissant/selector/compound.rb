# frozen_string_literal: true

class Croissant::Selector::Compound < Croissant::Selector
  attr_reader :selectors

  def initialize(selectors = [])
    @selectors = selectors

    super()
  end

  def matches?(element)
    return false unless element.element?

    selectors.all? { |selector| selector.matches?(element) }
  end

  def inlinable?
    selectors.all?(&:inlinable?)
  end

  def specificity
    value = 0

    selectors.each { |selector| value += selector.specificity.to_i }

    Croissant::Selector::Specificity.new(value)
  end

  def append_to(buffer)
    return buffer << '*' if selectors.empty?

    selectors.each { |selector| selector.append_to(buffer) }

    buffer
  end

  def index_key
    selectors.grep(Croissant::Selector::Simple::Id).first ||
      selectors.grep(Croissant::Selector::Simple::ClassName).first ||
      selectors.grep(Croissant::Selector::Simple::Type).first
  end
end
