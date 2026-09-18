# frozen_string_literal: true

class Croissant::Document::Element < Croissant::Document::Node
  NO_CLASSES = [].freeze
  private_constant :NO_CLASSES

  def element?
    true
  end

  def id
    return @id if defined?(@id)

    @id = node['id']
  end

  def classes
    @classes ||= (value = node['class']) ? value.split : NO_CLASSES
  end

  def [](attribute)
    node[attribute]
  end

  def []=(attribute, value)
    node[attribute] = value
    forget(attribute)
  end

  def remove_attribute(attribute)
    node.remove_attribute(attribute)
    forget(attribute)
  end

  def style
    @style ||= document.style_for(self)
  end

  def computed_style
    document.computed_style_for(self)
  end

  def style=(style)
    @style = style

    if style.empty?
      node.remove_attribute('style')
    else
      serialized = style.to_s
      node['style'] = serialized unless node['style'] == serialized
    end
  end

  private

  def forget(attribute)
    case attribute
    when 'class' then @classes = nil
    when 'id' then remove_instance_variable(:@id) if defined?(@id)
    end
  end
end
