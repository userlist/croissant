# frozen_string_literal: true

class Croissant::Style::Unit::Point < Croissant::Style::Unit
  def initialize
    super('pt')
  end

  def absolutize(value, **)
    value * 96.0 / 72
  end
end
