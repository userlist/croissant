# frozen_string_literal: true

class Croissant::Style::Value::Integer < Croissant::Style::Value::Number
  PATTERN = /\A[-+]?\d+\z/

  def self.parse(input)
    new(input) if PATTERN.match?(input)
  end

  def initialize(value)
    super(value.to_i)
  end
end
