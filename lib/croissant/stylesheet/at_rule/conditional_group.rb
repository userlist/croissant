# frozen_string_literal: true

class Croissant::Stylesheet::AtRule::ConditionalGroup < Croissant::Stylesheet::AtRule
  attr_reader :rules

  def initialize(name:, prelude:, rules:)
    @rules = rules

    super(name:, prelude:)
  end

  def to_s
    prefix = prelude.empty? ? "@#{name}" : "@#{name} #{prelude}"

    "#{prefix}{#{rules.join("\n")}}"
  end

  def ==(other)
    super && rules == other.rules
  end
  alias eql? ==

  def hash
    [self.class, name, prelude, rules].hash
  end
end
