# frozen_string_literal: true

# Writes the computed style of an element to its style attribute. The
# element's own style attribute keeps precedence over the stylesheet rules,
# and important declarations win regardless.
class Croissant::Transformation::InlineStyles < Croissant::Transformation::Element
  selector '*'

  def call(element)
    element.style = element.computed_style
  end
end
