# frozen_string_literal: true

class Croissant::Style::Value::Keyword < Croissant::Style::Value
  PATTERN = /\A-{0,2}[a-z_\u{80}-\u{10FFFF}][a-z0-9_\-\u{80}-\u{10FFFF}]*\z/i

  def self.[](input)
    return new(input) if input.is_a?(Symbol)

    super
  end

  def self.parse(input)
    new(input) if PATTERN.match?(input)
  end

  def initialize(value)
    super(value.to_sym)
  end

  def parse(input)
    self if self == input
  end

  def |(other)
    Union.new(self, other)
  end

  def to_sym
    value
  end

  def ==(other)
    return value == other if other.is_a?(Symbol)

    super
  end
end
