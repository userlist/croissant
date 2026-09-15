# frozen_string_literal: true

class Croissant::Style::DeclarationSet
  include Enumerable

  def initialize(*collections)
    @declarations = {}

    collections.each do |declarations|
      declarations.each { |declaration| add(declaration) }
    end
  end

  # Adds a declaration, replacing an existing one of the same property and
  # moving it to the end. A normal declaration never replaces an important
  # one. Returns whether the declaration was added.
  def add(declaration) # rubocop:disable Naming/PredicateMethod
    name = declaration.property.name
    existing = @declarations[name]

    return false if existing&.important? && !declaration.important?

    @declarations.delete(name) if existing
    @declarations[name] = declaration
    true
  end

  def <<(declaration)
    add(declaration)
    self
  end

  # Deletes the declaration of a property. Deleting a shorthand also deletes
  # its longhands, so it works on expanded sets as well.
  def delete(property)
    property = Croissant::Style::Property.lookup(property)

    @declarations.delete(property.name)

    if property.is_a?(Croissant::Style::Property::Shorthand)
      property.longhands.each { |longhand| @declarations.delete(longhand) }
    end

    self
  end

  def freeze
    @declarations.freeze
    super
  end

  def [](name)
    @declarations[name]
  end

  def each(&)
    @declarations.each_value(&)
  end

  def size
    @declarations.size
  end

  def empty?
    @declarations.empty?
  end

  def merge(declarations)
    spawn(self, declarations)
  end

  def expand
    spawn(flat_map { |declaration| declaration.property.expand(declaration) })
  end

  def collapse
    reduce(self) { |collapsed, declaration| declaration.property.collapse(collapsed) }
  end

  def replace(names, declaration)
    replaced = @declarations.each_with_object({}) do |(name, existing), result|
      if names.include?(name)
        result[declaration.property.name] ||= declaration
      else
        result[name] = existing
      end
    end

    spawn(replaced.values)
  end

  def to_s
    @declarations.values.join(';')
  end

  def ==(other)
    other.is_a?(self.class) && to_a == other.to_a
  end
  alias eql? ==

  def hash
    [self.class, to_a].hash
  end

  private

  def spawn(*collections)
    set = self.class.new(*collections)
    set.freeze if frozen?
    set
  end
end
