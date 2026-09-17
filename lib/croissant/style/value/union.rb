# frozen_string_literal: true

# One of several types — the `|` of a CSS value definition, as in
# `<length> | <percentage> | auto`. It answers #parse the way a single type
# does, so a property's type can be one class or a dozen without anything
# downstream knowing which.
class Croissant::Style::Value::Union
  attr_reader :types

  # Unions among the arguments are absorbed rather than nested, so `a | (b | c)`
  # and `(a | b) | c` are the same union. Alternation is associative; the
  # bracketing is an artefact of how it was written.
  #
  # A Symbol is read as the keyword literal it names, so a grammar can be
  # written the way CSS writes it: `length | :auto` rather than
  # `length | Keyword[:auto]`.
  def initialize(*types)
    @types = types.flat_map { |type| expand(type) }.freeze

    freeze
  end

  def |(other)
    self.class.new(self, other)
  end

  def parse(input)
    types.each do |type|
      value = type.parse(input)
      return value if value
    end

    nil
  end

  def ==(other)
    other.instance_of?(self.class) && types == other.types
  end
  alias eql? ==

  def hash
    [self.class, types].hash
  end

  def inspect
    "#<#{self.class} #{types.inspect}>"
  end

  private

  def expand(type)
    return type.types if type.is_a?(self.class)
    return Croissant::Style::Value::Keyword[type] if type.is_a?(Symbol) || type.is_a?(String)

    type
  end
end
