# frozen_string_literal: true

class Croissant::Selector::PseudoClass::Structural::OnlyChild < Croissant::Selector::PseudoClass::Structural
  def matches?(element)
    element.previous_element.nil? && element.next_element.nil?
  end

  private

  def keyword
    'only-child'
  end
end
