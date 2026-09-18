# frozen_string_literal: true

class Croissant::Selector::Combinator::Descendant < Croissant::Selector::Combinator
  def matches?(element)
    return false unless super

    ancestor = element.parent

    while ancestor&.element?
      return true if left.matches?(ancestor)

      ancestor = ancestor.parent
    end

    false
  end

  def append_to(buffer)
    left.append_to(buffer) << ' '

    right.append_to(buffer)
  end
end
