# frozen_string_literal: true

# The style of a single element as an immutable mapping from property name to
# value, backed by an expanded DeclarationSet. Every change returns a new
# style; assign it back to the element to write it to the style attribute.
#
# Setting a property follows the rules of the backing set: a normal
# declaration never replaces an important one, so +set+ with +important:+ is
# the way to override one.
class Croissant::Style::ElementStyle
  include Enumerable

  attr_reader :declarations

  def initialize(declarations = Croissant::Style::DeclarationSet.new)
    @declarations = declarations.freeze

    freeze
  end

  def [](property)
    declaration_for(property)&.value
  end

  def important?(property)
    declaration_for(property)&.important? || false
  end

  # Returns a style with the property set; a shorthand sets all of its
  # longhands. Returns the style itself when nothing changed, which is the
  # case when a normal value is set on a property that is important.
  def set(property, value, important: false)
    declaration = Croissant::Style::Declaration.new(property, value, important:)
    copy = Croissant::Style::DeclarationSet.new(declarations)
    added = declaration.property.expand(declaration).map { |expanded| copy.add(expanded) }

    added.any? ? self.class.new(copy) : self
  end

  # Returns a style without the property; deleting a shorthand deletes all of
  # its longhands. Returns the style itself when nothing changed.
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
