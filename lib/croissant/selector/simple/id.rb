# frozen_string_literal: true

class Croissant::Selector::Simple::Id < Croissant::Selector::Simple
  def matches?(element)
    element['id'] == name
  end

  def specificity
    Croissant::Selector::Specificity.id
  end

  def to_s
    "##{name}"
  end
end
