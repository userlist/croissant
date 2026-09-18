# frozen_string_literal: true

class Croissant::Stylesheet::AtRule::Statement < Croissant::Stylesheet::AtRule
  def append_to(buffer)
    append_prelude(buffer) << ';'
  end
end
