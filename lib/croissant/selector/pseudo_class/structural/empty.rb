# frozen_string_literal: true

class Croissant::Selector::PseudoClass::Structural::Empty < Croissant::Selector::PseudoClass::Structural
  def matches?(element)
    element.children.none? { |child| child.element? || (child.text? && !child.content.empty?) }
  end

  private

  def keyword
    'empty'
  end
end
