# frozen_string_literal: true

class Croissant::Selector::Relative < Croissant::Selector
  attr_reader :selector

  def initialize(selector)
    @selector = selector

    super()
  end

  def inlinable?
    selector.inlinable?
  end

  def specificity
    selector.specificity
  end

  def append_to(buffer)
    buffer << prefix << ' ' if prefix

    selector.append_to(buffer)
  end

  private

  def prefix
    nil
  end
end

require_relative 'relative/descendant'
require_relative 'relative/child'
require_relative 'relative/next_sibling'
require_relative 'relative/subsequent_sibling'
