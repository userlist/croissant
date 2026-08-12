# frozen_string_literal: true

class Croissant::Selector::PseudoClass::Unknown < Croissant::Selector::PseudoClass
  attr_reader :name, :argument

  def initialize(name, argument: nil)
    @name = name
    @argument = argument

    super()
  end

  def to_s
    argument ? ":#{name}(#{argument})" : ":#{name}"
  end

  def matches?(_)
    false
  end

  def inlinable?
    false
  end

  def specificity
    Croissant::Selector::Specificity.new(0, 0, 1, 0)
  end
end
