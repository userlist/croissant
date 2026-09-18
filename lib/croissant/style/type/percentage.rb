# frozen_string_literal: true

class Croissant::Style::Type::Percentage < Croissant::Style::Type::Numeric
  def self.value_class
    Croissant::Style::Value::Percentage
  end

  PATTERN = /\A(#{NUMBER})%\z/

  private

  def parse_value(input)
    match = PATTERN.match(input)

    value_class.new(Float(match[1])) if match
  end
end
