# frozen_string_literal: true

class Croissant::Style::Value::Numeric < Croissant::Style::Value
  NUMBER = /[-+]?(?:\d+(?:\.\d+)?|\.\d+)/

  def self.parse(input)
    Number.parse(input) || Percentage.parse(input) || Length.parse(input)
  end

  def initialize(value)
    super(value.to_f)
  end

  def +(other)
    spawn(value + operand(other))
  end

  def -(other)
    spawn(value - operand(other))
  end

  def *(other)
    spawn(value * factor(other))
  end

  def /(other)
    spawn(value / factor(other))
  end

  def round(...)
    spawn(value.round(...))
  end

  def to_s
    return value.to_i.to_s if (value % 1).zero?

    super
  end

  def to_i
    value.to_i
  end

  def to_f
    value.to_f
  end

  def positive?
    value.positive?
  end

  def negative?
    value.negative?
  end

  def zero?
    value.zero?
  end

  def scalar?
    false
  end

  private

  def operand(other)
    return other if other.is_a?(::Numeric)
    return other.value if other.instance_of?(Number)

    raise ArgumentError, "can't combine #{inspect} and #{other.inspect}" unless compatible?(other)

    other.value
  end

  def compatible?(other)
    other.instance_of?(self.class)
  end

  def factor(other)
    return other if other.is_a?(::Numeric)
    return other.to_f if other.is_a?(Croissant::Style::Value::Numeric) && other.scalar?

    raise ArgumentError, "can't scale #{inspect} by #{other.inspect}"
  end
end
