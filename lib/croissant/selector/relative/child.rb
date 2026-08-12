# frozen_string_literal: true

class Croissant::Selector::Relative::Child < Croissant::Selector::Relative
  def matches?(anchor)
    anchor.element_children.any? { |child| selector.matches?(child) }
  end

  private

  def prefix
    '>'
  end
end
