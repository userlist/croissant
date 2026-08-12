# frozen_string_literal: true

class Croissant::Selector::PseudoClass::Structural::NthLastOfType < Croissant::Selector::PseudoClass::Structural::NthChild
  def matches?(element)
    index = 1
    sibling = element.next_element

    while sibling
      index += 1 if sibling.name == element.name
      sibling = sibling.next_element
    end

    matches_formula?(index)
  end

  private

  def keyword
    'nth-last-of-type'
  end
end
