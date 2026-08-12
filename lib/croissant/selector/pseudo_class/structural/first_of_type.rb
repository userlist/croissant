# frozen_string_literal: true

class Croissant::Selector::PseudoClass::Structural::FirstOfType < Croissant::Selector::PseudoClass::Structural
  def matches?(element)
    sibling = element.previous_element

    while sibling
      return false if sibling.name == element.name

      sibling = sibling.previous_element
    end

    true
  end

  private

  def keyword
    'first-of-type'
  end
end
