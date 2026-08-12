# frozen_string_literal: true

class Croissant::Selector::Simple < Croissant::Selector
  attr_reader :name

  def initialize(name)
    @name = name

    super()
  end

  def inlinable?
    true
  end
end

require_relative 'simple/type'
require_relative 'simple/id'
require_relative 'simple/class_name'
require_relative 'simple/attribute'
