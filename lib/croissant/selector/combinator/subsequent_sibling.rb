# frozen_string_literal: true

class Croissant::Selector::Combinator::SubsequentSibling < Croissant::Selector::Combinator
  def matches?(element)
    return false unless super

    sibling = element.previous_element

    while sibling
      return true if left.matches?(sibling)

      sibling = sibling.previous_element
    end

    false
  end

  private

  def combinator
    '~'
  end
end
