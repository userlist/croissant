# frozen_string_literal: true

# Base class for document transformations. Instances are built once with their
# options, frozen, and called with a Croissant::Document per run.
class Croissant::Transformation
  def initialize
    freeze
  end

  def call(_document)
    raise NotImplementedError, "subclass must implement #{self.class}##{__method__}"
  end
end

require_relative 'transformation/element'
require_relative 'transformation/elements'
