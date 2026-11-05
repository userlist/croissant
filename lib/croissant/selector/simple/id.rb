# frozen_string_literal: true

class Croissant::Selector::Simple::Id < Croissant::Selector::Simple
  def matches?(element)
    element.id == name
  end

  def specificity
    Croissant::Selector::Specificity.id
  end

  def append_to(buffer)
    append_identifier(buffer << '#', name)
  end
end
