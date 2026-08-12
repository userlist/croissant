# frozen_string_literal: true

class Croissant::Selector::PseudoClass::Structural::NthLastChild < Croissant::Selector::PseudoClass::Structural::NthChild
  def matches?(element)
    index = 1
    sibling = element.next_element

    while sibling
      index += 1
      sibling = sibling.next_element
    end

    matches_formula?(index)
  end

  private

  def keyword
    'nth-last-child'
  end
end
