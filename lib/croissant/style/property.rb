# frozen_string_literal: true

class Croissant::Style::Property
  attr_reader :name, :initial, :shorthand

  def self.lookup(property)
    return property if property.is_a?(self)

    Croissant::Style::Properties[property]
  end

  def initialize(name, initial: nil, inherited: false, shorthand: nil)
    @name = name
    @initial = initial
    @inherited = inherited
    @shorthand = shorthand

    freeze
  end

  def inherited?
    @inherited
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
      shorthand == other.shorthand
  end
  alias eql? ==

  def hash
    [self.class, name, initial, inherited?, shorthand].hash
  end
end
