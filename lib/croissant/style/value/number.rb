# frozen_string_literal: true

class Croissant::Style::Value::Number < Croissant::Style::Value::Numeric
  def scalar?
    true
  end

  def to_html
    round.to_s
  end

  def to_percentage
    Percentage.new(value * 100)
  end

  def to_number
    self
  end
end
