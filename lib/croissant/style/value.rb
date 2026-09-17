# frozen_string_literal: true

class Croissant::Style::Value
  def self.parse(input, type = default_type)
    return input if input.is_a?(Croissant::Style::Value)

    input = input.to_s.strip
    return if input.empty?

    type.parse(input) || List.parse(input, type) || Unparsed.parse(input)
  end

  def self.[](...)
    parse(...)
  end

  def self.|(other)
    Union.new(self, other)
  end

  def self.default_type
    @default_type ||= Numeric | Keyword | Color
  end

  def initialize(value)
    @value = value

    freeze
  end

  def absolutize(**)
    self
  end

  def to_s
    value.to_s
  end

  def to_str
    to_s
  end

  def ==(other)
    return to_s == other if other.is_a?(String)

    other.instance_of?(self.class) && value == other.value
  end

  def eql?(other)
    other.instance_of?(self.class) && value.eql?(other.value)
  end

  def hash
    [self.class, value].hash
  end

  def freeze
    @value.freeze

    super
  end

  def inspect
    "#<#{self.class} #{value.inspect}>"
  end

  protected

  attr_reader :value

  private

  def spawn(value)
    self.class.new(value)
  end
end

require_relative 'value/numeric'
require_relative 'value/number'
require_relative 'value/percentage'
require_relative 'value/length'
require_relative 'value/keyword'
require_relative 'value/unparsed'
require_relative 'value/color'
require_relative 'value/list'
require_relative 'value/union'
