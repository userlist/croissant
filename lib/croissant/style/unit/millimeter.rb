# frozen_string_literal: true

class Croissant::Style::Unit::Millimeter < Croissant::Style::Unit
  def initialize
    super('mm')
  end

  def absolutize(value, **)
    value * 96.0 / 25.4
  end
end
