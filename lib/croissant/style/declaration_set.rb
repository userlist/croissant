# frozen_string_literal: true

class Croissant::Style::DeclarationSet
  include Enumerable

  def initialize(*collections)
    @declarations = {}

    collections.each do |declarations|
      declarations.each do |declaration|
        @declarations.delete(declaration.property.name)
        @declarations[declaration.property.name] = declaration
      end
    end

    @declarations.freeze
    freeze
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
    self.class.new(self, declarations)
  end

  def expand
    self.class.new(flat_map { |declaration| declaration.property.expand(declaration) })
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

    self.class.new(replaced.values)
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
end
