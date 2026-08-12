# frozen_string_literal: true

class Croissant::Selector::Simple::ClassName < Croissant::Selector::Simple
  def matches?(element)
    element.classes.include?(name)
  end

  def specificity
    Croissant::Selector::Specificity.class_name
  end

  def to_s
    ".#{name}"
  end
end
