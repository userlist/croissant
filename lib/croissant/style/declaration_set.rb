# frozen_string_literal: true

class Croissant::Style::DeclarationSet
  include Croissant::Serializable
  include Enumerable

  def initialize(*collections)
    @declarations = {}

    collections.each do |declarations|
      declarations.each { |declaration| add(declaration) }
    end
  end

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

  def each
    return enum_for(__method__) unless block_given?

    @declarations.each_value { |declaration| yield declaration unless declaration.important? }
    @declarations.each_value { |declaration| yield declaration if declaration.important? } # rubocop:disable Style/CombinableLoops
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

  def append_to(buffer)
    append_each(buffer, self, ';')
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
