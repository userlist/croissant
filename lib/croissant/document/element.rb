# frozen_string_literal: true

# A thin view of a Nokogiri element for element transformations. It exposes
# the attributes, the style, and the computed style. Anything else is
# reachable through +node+.
#
# Mirroring the DOM, +style+ is the element's own style attribute and
# +computed_style+ is the cascade of the matching stylesheet rules and that
# attribute. Styles are immutable, so a transformation derives a new one and
# assigns it back, which writes it to the attribute right away.
class Croissant::Document::Element
  attr_reader :document, :node

  def initialize(document, node)
    @document = document
    @node = node
  end

  def name
    node.name
  end

  def [](attribute)
    node[attribute]
  end

  def []=(attribute, value)
    node[attribute] = value
  end

  def remove_attribute(attribute)
    node.remove_attribute(attribute)
  end

  # The style parsed from the element's own style attribute.
  def style
    @style ||= document.style_for(self)
  end

  # The cascade of the matching stylesheet rules and the style attribute.
  # Computed afresh on every call.
  def computed_style
    document.computed_style_for(self)
  end

  # Replaces the style and writes it to the style attribute, removing the
  # attribute when the style is empty. The attribute is left alone when it
  # already holds the serialized style.
  def style=(style)
    @style = style

    if style.empty?
      node.remove_attribute('style')
    else
      serialized = style.to_s
      node['style'] = serialized unless node['style'] == serialized
    end
  end
end
