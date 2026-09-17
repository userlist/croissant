# frozen_string_literal: true

class Croissant::Style::Value::Unparsed < Croissant::Style::Value
  def self.parse(input)
    new(input)
  end

  def initialize(value)
    super(value.to_s)
  end
end
