# frozen_string_literal: true

class Croissant::Selector::Simple::Type < Croissant::Selector::Simple
  def initialize(name)
    super(name.downcase)
  end

  def matches?(element)
    element.name == name
  end

  def specificity
    Croissant::Selector::Specificity.element
  end

  def to_s
    name
  end
end
