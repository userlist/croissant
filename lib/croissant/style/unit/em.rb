# frozen_string_literal: true

class Croissant::Style::Unit::Em < Croissant::Style::Unit
  def initialize
    super('em')
  end

  def absolutize(value, font_size: nil, **)
    return unless font_size

    font_size * value
  end
end
