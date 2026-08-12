# frozen_string_literal: true

class Croissant::Selector::PseudoClass::Functional::Where < Croissant::Selector::PseudoClass::Functional::Is
  def specificity
    Croissant::Selector::Specificity.zero
  end

  private

  def keyword
    'where'
  end
end
