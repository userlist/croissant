# frozen_string_literal: true

class Croissant::Selector::Simple::ClassName < Croissant::Selector::Simple
  def matches?(element)
    element.classes.include?(name)
  end

  def specificity
    Croissant::Selector::Specificity.new(0, 0, 1, 0)
  end

  def to_s
    ".#{name}"
  end
end
