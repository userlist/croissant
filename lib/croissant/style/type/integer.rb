# frozen_string_literal: true

class Croissant::Style::Type::Integer < Croissant::Style::Type::Number
  PATTERN = /\A[-+]?\d+\z/

  private

  def matches?(value)
    super && whole?(value)
  end

  def whole?(value)
    value.is_a?(value_class) && (value % 1).zero?
  end

  def parse_value(input)
    value_class.new(input.to_s) if PATTERN.match?(input)
  end
end
