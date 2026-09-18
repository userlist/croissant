# frozen_string_literal: true

class Croissant::Style::Type::Union < Croissant::Style::Type
  attr_reader :types

  def initialize(*types)
    @types = types.flat_map { |type| expand(type) }.freeze

    super()
  end

  def ==(other)
    super && types == other.types
  end
  alias eql? ==

  def hash
    [self.class, types].hash
  end

  def inspect
    "#<#{self.class} #{types.inspect}>"
  end

  private

  def matches?(value)
    types.any? { |type| type.match(value) }
  end

  def parse_value(input)
    types.each do |type|
      value = type.parse(input)
      return value if value
    end

    nil
  end

  def expand(type)
    return type.types if type.instance_of?(self.class)
    return Croissant::Style::Type::Keyword.new(type) if type.is_a?(Symbol) || type.is_a?(String)

    type
  end
end
