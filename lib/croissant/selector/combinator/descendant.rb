# frozen_string_literal: true

class Croissant::Selector::Combinator::Descendant < Croissant::Selector::Combinator
  def matches?(element)
    return false unless super

    ancestor = element.parent

    # The walk ends at the document or fragment holding the tree.
    while ancestor&.element?
      return true if left.matches?(ancestor)

      ancestor = ancestor.parent
    end

    false
  end

  def to_s
    "#{left} #{right}"
  end
end
