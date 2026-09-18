# frozen_string_literal: true

class Croissant::Style::Type::Unparsed < Croissant::Style::Type
  def self.value_class
    Croissant::Style::Value::Unparsed
  end

  private

  def parse_value(input)
    value_class.new(input)
  end
end
