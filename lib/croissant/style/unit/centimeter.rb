# frozen_string_literal: true

class Croissant::Style::Unit::Centimeter < Croissant::Style::Unit
  def initialize
    super('cm')
  end

  def absolutize(value, **)
    value * 96.0 / 2.54
  end
end
