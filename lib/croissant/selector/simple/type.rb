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

  # Overrides Serializable#to_s: a name that needs no escaping is already the whole serialisation.
  def to_s
    safe_identifier?(name) ? name : super
  end

  def append_to(buffer)
    append_identifier(buffer, name)
  end
end
