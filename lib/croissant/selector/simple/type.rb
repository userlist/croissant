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

  # Overrides Serializable#to_s: the name is already the whole serialisation.
  def to_s
    name
  end

  def append_to(buffer)
    buffer << name
  end
end
