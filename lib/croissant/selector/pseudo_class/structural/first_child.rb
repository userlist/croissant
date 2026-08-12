# frozen_string_literal: true

class Croissant::Selector::PseudoClass::Structural::FirstChild < Croissant::Selector::PseudoClass::Structural
  def matches?(element)
    element.previous_element.nil?
  end

  private

  def keyword
    'first-child'
  end
end
