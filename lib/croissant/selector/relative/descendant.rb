# frozen_string_literal: true

class Croissant::Selector::Relative::Descendant < Croissant::Selector::Relative
  def matches?(anchor)
    anchor.element_children.any? { |child| selector.matches?(child) || matches?(child) }
  end
end
