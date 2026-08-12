# frozen_string_literal: true

class Croissant::Selector::PseudoClass::Functional::Is < Croissant::Selector::PseudoClass::Functional
  def specificity
    selectors.map(&:specificity).max || Croissant::Selector::Specificity.zero
  end

  private

  def keyword
    'is'
  end
end
