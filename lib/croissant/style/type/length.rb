# frozen_string_literal: true

class Croissant::Style::Type::Length < Croissant::Style::Type::Numeric
  def self.value_class
    Croissant::Style::Value::Length
  end

  PATTERN = /\A(#{NUMBER})([a-z]+)?\z/i

  attr_reader :unit

  def initialize(matcher = nil, unit = nil)
    @unit = unit.is_a?(String) || unit.is_a?(Symbol) ? Croissant::Style::Unit.lookup(unit) : unit

    super(matcher)
  end

  def ==(other)
    super && unit == other.unit
  end
  alias eql? ==

  def hash
    [super, unit].hash
  end

  def inspect
    return super if unit.nil?

    "#<#{self.class} #{[*matcher&.inspect, unit.inspect].join(' ')}>"
  end

  private

  def matches?(value)
    super && unit?(value)
  end

  def unit?(value)
    return true if unit.nil?

    value.is_a?(value_class) && unit === value.unit # rubocop:disable Style/CaseEquality
  end

  def parse_value(input)
    match = PATTERN.match(input)
    return unless match

    number = Float(match[1])
    written = match[2]
    return value_class.new(number, written) if written

    value_class.new(number) if number.zero?
  end
end
