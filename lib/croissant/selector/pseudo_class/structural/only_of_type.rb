# frozen_string_literal: true

class Croissant::Selector::PseudoClass::Structural::OnlyOfType < Croissant::Selector::PseudoClass::Structural
  def matches?(element) # rubocop:disable Metrics/MethodLength
    sibling = element.previous_element

    while sibling
      return false if sibling.name == element.name

      sibling = sibling.previous_element
    end

    sibling = element.next_element

    while sibling
      return false if sibling.name == element.name

      sibling = sibling.next_element
    end

    true
  end

  private

  def keyword
    'only-of-type'
  end
end
