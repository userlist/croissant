# frozen_string_literal: true

class Croissant::Style::Property::Shorthand < Croissant::Style::Property
  attr_reader :longhands

  def initialize(name, longhands, initial: nil, inherited: false)
    @longhands = longhands.freeze

    super(name, initial:, inherited:)
  end

  def expand(declaration)
    sides = expand_sides(Croissant::Style::Value::List.split(declaration.value))
    return [] unless sides

    longhands.zip(sides).map do |longhand, value|
      Croissant::Style::Declaration.new(longhand, value, important: declaration.important?)
    end
  end

  def collapse(declarations)
    parts = longhands.map { |longhand| declarations[longhand] }
    return declarations unless collapsible?(parts)

    value = collapse_sides(parts.map { |part| part.value.to_s }).join(' ')

    declarations.replace(longhands, Croissant::Style::Declaration.new(self, value, important: parts.first.important?))
  end

  def ==(other)
    super && longhands == other.longhands
  end
  alias eql? ==

  def hash
    [super, longhands].hash
  end

  private

  def expand_sides(values)
    case values.length
    when 1 then values * 4
    when 2 then values * 2
    when 3 then [values[0], values[1], values[2], values[1]]
    when 4 then values
    end
  end

  def collapsible?(parts)
    parts.none?(&:nil?) && parts.map(&:important?).uniq.size == 1
  end

  def collapse_sides(sides)
    sides = sides[0..2] if sides[3] == sides[1]
    sides = sides[0..1] if sides.length == 3 && sides[2] == sides[0]
    sides = sides[0..0] if sides.length == 2 && sides[1] == sides[0]
    sides
  end
end
