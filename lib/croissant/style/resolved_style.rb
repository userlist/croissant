# frozen_string_literal: true

class Croissant::Style::ResolvedStyle
  attr_reader :properties

  def initialize(rules)
    @properties = {}

    important, declarations = resolve_declarations(rules)

    declarations.each do |declaration|
      properties[declaration.property] = declaration
    end

    important.each do |declaration|
      properties[declaration.property] = declaration
    end

    freeze
  end

  def [](property)
    declaration = properties[property] || properties[Croissant::Stylesheet::Property.new(property)]
    declaration&.value
  end

  def to_s
    properties.values.sort_by(&:property).join(';')
  end

  def freeze
    properties.freeze

    super
  end

  def ==(other)
    other.is_a?(self.class) && properties == other.properties
  end
  alias eql? ==

  def hash
    [self.class, properties].hash
  end

  private

  def resolve_declarations(rules)
    rules
      .sort_by
      .with_index { |rule, index| [rule.specificity, index] }
      .flat_map(&:declarations)
      .partition(&:important?)
  end
end
