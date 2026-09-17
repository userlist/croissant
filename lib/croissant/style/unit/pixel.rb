# frozen_string_literal: true

class Croissant::Style::Unit::Pixel < Croissant::Style::Unit
  def initialize
    super('px')
  end

  def absolutize(value, **)
    value
  end
end
