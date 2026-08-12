# frozen_string_literal: true

class Croissant::Selector::PseudoClass::Functional::Not < Croissant::Selector::PseudoClass::Functional
  def matches?(element)
    selectors.none? { |selector| selector.matches?(element) }
  end

  def specificity
    selectors.map(&:specificity).max || Croissant::Selector::Specificity.zero
  end

  private

  def keyword
    'not'
  end
end
