# frozen_string_literal: true

class Croissant::Selector::Simple::Id < Croissant::Selector::Simple
  def matches?(element)
    element['id'] == name
  end

  def specificity
    Croissant::Selector::Specificity.new(0, 1, 0, 0)
  end

  def to_s
    "##{name}"
  end
end
