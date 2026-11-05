# frozen_string_literal: true

class Croissant::Selector::PseudoElement < Croissant::Selector
  attr_reader :name, :argument

  def initialize(name, argument: nil)
    @name = name.downcase
    @argument = argument

    super()
  end

  def matches?(_)
    false
  end

  def inlinable?
    false
  end

  def specificity
    Croissant::Selector::Specificity.element
  end

  def append_to(buffer)
    append_identifier(buffer << '::', name)
    buffer << '(' << argument.to_s << ')' if argument

    buffer
  end
end
