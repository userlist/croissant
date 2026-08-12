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
    style = ids = classes = elements = 0

    selectors.each do |selector|
      specificity = selector.specificity
      style += specificity.style
      ids += specificity.ids
      classes += specificity.classes
      elements += specificity.elements
    end

    Croissant::Selector::Specificity.new(style, ids, classes, elements)
  end

  def to_s
    selectors.empty? ? '*' : selectors.join
  end

  def index_key
    selectors.grep(Croissant::Selector::Simple::Id).first ||
      selectors.grep(Croissant::Selector::Simple::ClassName).first ||
      selectors.grep(Croissant::Selector::Simple::Type).first
  end
end
