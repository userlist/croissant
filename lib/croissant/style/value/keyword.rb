# frozen_string_literal: true

class Croissant::Style::Value::Keyword < Croissant::Style::Value
  def initialize(value)
    super(value.to_sym)
  end

  def to_sym
    value
  end

  def ==(other)
    return value == other if other.is_a?(Symbol)

    super
  end
end
