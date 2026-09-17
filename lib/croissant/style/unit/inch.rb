# frozen_string_literal: true

class Croissant::Style::Unit::Inch < Croissant::Style::Unit
  def initialize
    super('in')
  end

  def absolutize(value, **)
    value * 96.0
  end
end
