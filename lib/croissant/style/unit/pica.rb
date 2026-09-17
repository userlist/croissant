# frozen_string_literal: true

class Croissant::Style::Unit::Pica < Croissant::Style::Unit
  def initialize
    super('pc')
  end

  def absolutize(value, **)
    value * 16.0
  end
end
