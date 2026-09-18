# frozen_string_literal: true

class Croissant::Style::DeclarationSet
  include Croissant::Serializable
  include Enumerable

  def initialize(*collections)
    @declarations = {}
    @important = false

    collections.each { |declarations| declarations.each { |declaration| add(declaration) } }
  end

  def add(declaration) # rubocop:disable Naming/PredicateMethod
    name = declaration.property.name
    existing = @declarations[name]

    return false if existing&.important? && !declaration.important?

    @declarations.delete(name) if existing
    @declarations[name] = declaration
    @important ||= declaration.important?
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

  # Important declarations sort last, which only needs a second pass when the set holds any.
  def each(&block)
    return enum_for(__method__) unless block
    return @declarations.each_value(&block) unless @important

    @declarations.each_value { |declaration| yield declaration unless declaration.important? }
    # rubocop:disable-next Style/CombinableLoops
    @declarations.each_value { |declaration| yield declaration if declaration.important? }
  end

  def size
    @declarations.size
  end

  def empty?
    @declarations.empty?
  end

  def merge(declarations)
    spawn { |copy| copy.merge!(declarations) }
  end

  def merge!(declarations)
    declarations.each { |declaration| add(declaration) }

    self
  end

  def expand
    spawn(&:expand!)
  end

  def expand!
    expanded = flat_map { |declaration| declaration.property.expand(declaration) }

    @declarations = {}
    @important = false
    expanded.each { |declaration| add(declaration) }

    self
  end

  def collapse
    reduce(self) { |collapsed, declaration| declaration.property.collapse(collapsed) }
  end

  def replace(names, declaration)
    spawn { |copy| copy.replace!(names, declaration) }
  end

  def replace!(names, declaration)
    @declarations = replaced_declarations(names, declaration)
    @important ||= declaration.important?

    self
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

  # A copy owns its declarations, so the block can mutate it without touching this set.
  def initialize_copy(other)
    super

    @declarations = @declarations.dup
  end

  def spawn
    copy = dup
    yield copy
    copy.freeze if frozen?
    copy
  end

  # Rebuilt rather than mutated so the replacement keeps the slot of the first name it replaces.
  def replaced_declarations(names, declaration)
    target = declaration.property.name
    replaced = {}

    @declarations.each_key do |name|
      if names.include?(name)
        replaced[target] ||= declaration
      else
        replaced[name] = @declarations[name]
      end
    end

    replaced
  end
end
