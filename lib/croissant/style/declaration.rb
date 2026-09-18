# frozen_string_literal: true

class Croissant::Style::Declaration
  include Croissant::Serializable

  attr_reader :property, :value

  def initialize(property, value, important: false)
    @property = Croissant::Style::Property.lookup(property)
    @value = value
    @important = important

    freeze
  end

  def important?
    @important
  end

  def parsed_value
    property.parse_value(value)
  end

  def append_to(buffer)
    buffer << property.to_s << ':' << value.to_s
    buffer << ' !important' if important?

    buffer
  end

  def ==(other)
    other.is_a?(self.class) &&
      property == other.property &&
      value == other.value &&
      important? == other.important?
  end
  alias eql? ==

  def hash
    [self.class, property, value, important?].hash
  end
end
