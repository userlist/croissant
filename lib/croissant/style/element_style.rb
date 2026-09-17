# frozen_string_literal: true

class Croissant::Style::ElementStyle
  include Enumerable

  attr_reader :declarations

  def initialize(declarations = Croissant::Style::DeclarationSet.new)
    @declarations = declarations.freeze

    freeze
  end

  def [](property)
    declaration_for(property)&.parsed_value
  end

  def important?(property)
    declaration_for(property)&.important? || false
  end

  def set(property, value, important: false)
    declaration = Croissant::Style::Declaration.new(property, value, important:)
    copy = Croissant::Style::DeclarationSet.new(declarations)
    added = declaration.property.expand(declaration).map { |expanded| copy.add(expanded) }

    added.any? ? self.class.new(copy) : self
  end

  def delete(property)
    copy = Croissant::Style::DeclarationSet.new(declarations).delete(property)

    copy.size == declarations.size ? self : self.class.new(copy)
  end

  def each(&)
    declarations.each(&)
  end

  def empty?
    declarations.empty?
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

  def declaration_for(property)
    name = property.is_a?(Croissant::Style::Property) ? property.name : property

    declarations[name]
  end
end
