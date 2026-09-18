# frozen_string_literal: true

class Croissant::Style::Type::Keyword < Croissant::Style::Type
  def self.value_class
    Croissant::Style::Value::Keyword
  end

  PATTERN = /\A-{0,2}[a-z_\u{80}-\u{10FFFF}][a-z0-9_\-\u{80}-\u{10FFFF}]*\z/i

  def initialize(matcher = nil)
    super(expand(matcher))
  end

  private

  def expand(matcher)
    return value_class.new(matcher) if matcher.is_a?(Symbol) || matcher.is_a?(String)

    matcher
  end

  def parse_value(input)
    value_class.new(input.to_s) if PATTERN.match?(input)
  end
end
