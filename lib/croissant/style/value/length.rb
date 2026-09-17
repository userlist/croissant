# frozen_string_literal: true

class Croissant::Style::Value::Length < Croissant::Style::Value::Numeric
  attr_reader :unit

  PATTERN = /\A(#{NUMBER})([a-z]+)?\z/i

  def self.parse(input)
    match = PATTERN.match(input)
    return unless match

    number = Float(match[1])
    unit = match[2]
    return new(number, unit) if unit

    new(number) if number.zero?
  end

  def initialize(value, unit = 'px')
    @unit = Croissant::Style::Unit.lookup(unit)

    super(value)
  end

  def absolutize(**)
    pixels = unit.absolutize(value, **)

    pixels ? self.class.new(pixels) : self
  end

  def to_s
    "#{super}#{unit}"
  end

  def ==(other)
    return super unless other.instance_of?(self.class)

    super && unit == other.unit
  end

  def eql?(other)
    super && unit.eql?(other.unit)
  end

  def hash
    [super, unit].hash
  end

  def inspect
    "#<#{self.class} #{value.inspect} #{unit.inspect}>"
  end

  private

  def spawn(value)
    self.class.new(value, unit)
  end

  def compatible?(other)
    super && other.unit == unit
  end
end
