# frozen_string_literal: true

class Croissant::Selector::Combinator < Croissant::Selector
  attr_reader :left, :right

  def initialize(left, right)
    @left = left
    @right = right

    super()
  end

  def matches?(element)
    right.matches?(element)
  end

  def inlinable?
    left.inlinable? && right.inlinable?
  end

  def specificity
    left.specificity + right.specificity
  end

  def index_key
    right.index_key
  end

  def append_to(buffer)
    left.append_to(buffer) << ' ' << combinator << ' '

    right.append_to(buffer)
  end
end

require_relative 'combinator/child'
require_relative 'combinator/descendant'
require_relative 'combinator/next_sibling'
require_relative 'combinator/subsequent_sibling'
