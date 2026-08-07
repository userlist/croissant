# frozen_string_literal: true

class Croissant::Stylesheet::Declaration
  attr_reader :property, :value, :important

  def initialize(property:, value:, important: false)
    @property = Croissant::Stylesheet::Property.new(property)
    @value = value
    @important = important

    freeze
  end

  def important?
    important
  end

  def to_s
    important? ? "#{property}:#{value} !important" : "#{property}:#{value}"
  end

  def ==(other)
    other.is_a?(self.class) &&
      property == other.property &&
      value == other.value &&
      important == other.important
  end
  alias eql? ==

  def hash
    [self.class, property, value, important].hash
  end
end
