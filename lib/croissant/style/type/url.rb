# frozen_string_literal: true

class Croissant::Style::Type::Url < Croissant::Style::Type
  def self.value_class
    Croissant::Style::Value::Url
  end

  PATTERN = /\Aurl\(\s*(?:"([^"]*)"|'([^']*)'|([^)]*?))\s*\)\z/i

  private

  def parse_value(input)
    return unless match = PATTERN.match(input)

    source = match[1] || match[2] || match[3]

    value_class.new(source) unless source.empty?
  end
end
