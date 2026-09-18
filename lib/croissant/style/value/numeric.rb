# frozen_string_literal: true

class Croissant::Style::Value::Numeric < Croissant::Style::Value
  def initialize(value)
    value = value.to_f unless value.is_a?(::Numeric)
    value = value.to_i if (value % 1).zero?

    super
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
    spawn(value.fdiv(factor(other)))
  end

  def %(other)
    spawn(value % operand(other))
  end

  def round(...)
    spawn(value.round(...))
  end

  def <=>(other)
    other = spawn(other) if other.is_a?(::Numeric)
    return unless compatible?(other)

    value <=> other.value
  end

  def coerce(other)
    [spawn(other), self]
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
