# frozen_string_literal: true

class Croissant::Selector::Relative::NextSibling < Croissant::Selector::Relative
  def matches?(anchor)
    return false unless sibling = anchor.next_element

    selector.matches?(sibling)
  end

  private

  def prefix
    '+'
  end
end
