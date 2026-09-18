# frozen_string_literal: true

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
require_relative 'transformation/inline_styles'
require_relative 'transformation/presentational_attributes'
require_relative 'transformation/remove_styles'
require_relative 'transformation/preserve_styles'
