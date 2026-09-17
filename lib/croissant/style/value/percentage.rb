# frozen_string_literal: true

class Croissant::Style::Value::Percentage < Croissant::Style::Value::Numeric
  PATTERN = /\A(#{NUMBER})%\z/

  def self.parse(input)
    match = PATTERN.match(input)

    new(Float(match[1])) if match
  end

  def scalar?
    true
  end

  def to_f
    value / 100.0
  end

  def absolutize(base: nil, **)
    base ? Length.new(base * to_f) : self
  end

  def to_i
    to_f.to_i
  end

  def to_s
    "#{super}%"
  end

  def to_number
    Number.new(to_f)
  end

  def to_percentage
    self
  end
end
