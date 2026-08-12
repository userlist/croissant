# frozen_string_literal: true

class Croissant::Selector::Combinator::Descendant < Croissant::Selector::Combinator
  def matches?(element)
    return false unless super

    element.ancestors.any? { |ancestor| ancestor.element? && left.matches?(ancestor) }
  end

  def to_s
    "#{left} #{right}"
  end
end
