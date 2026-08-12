# frozen_string_literal: true

class Croissant::Selector::PseudoClass::Structural::LastOfType < Croissant::Selector::PseudoClass::Structural
  def matches?(element)
    sibling = element.next_element

    while sibling
      return false if sibling.name == element.name

      sibling = sibling.next_element
    end

    true
  end

  private

  def keyword
    'last-of-type'
  end
end
