# frozen_string_literal: true

class Croissant::Style::ResolvedStyle
  attr_reader :declarations

  def initialize(rules)
    important, normal = resolve_declarations(rules)

    @declarations = Croissant::Style::DeclarationSet.new(normal, important).expand

    freeze
  end

  def [](property)
    declarations[property]&.value
  end

  def to_s
    declarations.collapse.to_s
  end

  def ==(other)
    other.is_a?(self.class) && declarations == other.declarations
  end
  alias eql? ==

  def hash
    [self.class, declarations].hash
  end

  private

  def resolve_declarations(rules)
    rules
      .sort_by
      .with_index { |rule, index| [rule.specificity, index] }
      .flat_map(&:declarations)
      .map { |declaration| build_declaration(declaration) }
      .partition(&:important?)
  end

  def build_declaration(declaration)
    Croissant::Style::Declaration.new(declaration.property, declaration.value, important: declaration.important?)
  end
end
