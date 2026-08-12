# frozen_string_literal: true

class Croissant::Selector::Combinator::NextSibling < Croissant::Selector::Combinator
  def matches?(element)
    return false unless super
    return false unless sibling = element.previous_element

    left.matches?(sibling)
  end

  private

  def combinator
    '+'
  end
end
