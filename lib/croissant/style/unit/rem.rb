# frozen_string_literal: true

class Croissant::Style::Unit::Rem < Croissant::Style::Unit
  def initialize
    super('rem')
  end

  def absolutize(value, root_font_size: nil, **)
    return unless root_font_size

    root_font_size * value
  end
end
