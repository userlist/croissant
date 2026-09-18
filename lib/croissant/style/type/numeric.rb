# frozen_string_literal: true

class Croissant::Style::Type::Numeric < Croissant::Style::Type
  NUMBER = /[-+]?(?:\d+(?:\.\d+)?|\.\d+)/

  def self.value_class
    Croissant::Style::Value::Numeric
  end

  def self.types
    @types ||= [Croissant::Style::Type::Number.new,
                Croissant::Style::Type::Percentage.new,
                Croissant::Style::Type::Length.new].freeze
  end

  private

  def parse_value(input)
    self.class.types.each do |type|
      value = type.parse(input)
      return value if value
    end

    nil
  end
end
