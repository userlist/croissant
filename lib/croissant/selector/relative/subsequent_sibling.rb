# frozen_string_literal: true

class Croissant::Selector::Relative::SubsequentSibling < Croissant::Selector::Relative
  def matches?(anchor)
    sibling = anchor.next_element

    while sibling
      return true if selector.matches?(sibling)

      sibling = sibling.next_element
    end

    false
  end

  private

  def prefix
    '~'
  end
end
