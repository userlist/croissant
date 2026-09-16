# frozen_string_literal: true

class Croissant::Transformation::InlineStyles < Croissant::Transformation::Element
  selector '*'

  def call(element)
    element.style = element.computed_style
  end
end
