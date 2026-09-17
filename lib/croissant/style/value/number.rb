# frozen_string_literal: true

class Croissant::Style::Value::Number < Croissant::Style::Value::Numeric
  PATTERN = /\A(#{NUMBER})\z/

  def self.parse(input)
    match = PATTERN.match(input)

    new(Float(match[1])) if match
  end

  def scalar?
    true
  end

  def to_percentage
    Percentage.new(value * 100)
  end

  def to_number
    self
  end
end
