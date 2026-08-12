# frozen_string_literal: true

class Croissant::Selector::PseudoClass::Structural::LastChild < Croissant::Selector::PseudoClass::Structural
  def matches?(element)
    element.next_element.nil?
  end

  private

  def keyword
    'last-child'
  end
end
