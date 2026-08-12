# frozen_string_literal: true

class Croissant::Selector::PseudoClass::Structural::NthOfType < Croissant::Selector::PseudoClass::Structural::NthChild
  def matches?(element)
    index = 1
    sibling = element.previous_element

    while sibling
      index += 1 if sibling.name == element.name
      sibling = sibling.previous_element
    end

    matches_formula?(index)
  end

  private

  def keyword
    'nth-of-type'
  end
end
