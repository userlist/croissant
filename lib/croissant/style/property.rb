# frozen_string_literal: true

class Croissant::Style::Property
  attr_reader :name, :initial, :shorthand, :type

  def self.lookup(property)
    return property if property.is_a?(self)

    registry.lookup(property)
  end

  def self.registry
    @registry ||= Croissant::Registry.new(
      BUILT_IN,
      fallback: ->(name) { Croissant::Style::Property.new(name) }
    )
  end

  def initialize(name, initial: nil, inherited: false, shorthand: nil, type: nil)
    @name = name
    @inherited = inherited
    @shorthand = shorthand
    @type = type || Croissant::Style::Value.default_type
    @initial = parse_value(initial)

    freeze
  end

  def inherited?
    @inherited
  end

  def parse_value(value)
    Croissant::Style::Value.parse(value, type)
  end

  def expand(declaration)
    [declaration]
  end

  def collapse(declarations)
    shorthand ? shorthand.collapse(declarations) : declarations
  end

  def to_s
    name
  end

  def ==(other)
    other.is_a?(self.class) &&
      name == other.name &&
      initial == other.initial &&
      inherited? == other.inherited? &&
      shorthand == other.shorthand &&
      type == other.type
  end
  alias eql? ==

  def hash
    [self.class, name, initial, inherited?, shorthand, type].hash
  end
end

require_relative 'property/shorthand'
require_relative 'property/built_in'
