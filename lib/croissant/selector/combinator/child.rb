# frozen_string_literal: true

class Croissant::Selector::Combinator::Child < Croissant::Selector::Combinator
  def matches?(element)
    return false unless super
    return false unless parent = element.parent

    parent.element? && left.matches?(parent)
  end

  private

  def combinator
    '>'
  end
end
