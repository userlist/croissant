# frozen_string_literal: true

class Croissant::Selector::PseudoClass::Structural::Root < Croissant::Selector::PseudoClass::Structural
  def matches?(element)
    parent = element.parent
    parent.nil? || !parent.element?
  end

  private

  def keyword
    'root'
  end
end
