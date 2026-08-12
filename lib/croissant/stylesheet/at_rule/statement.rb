# frozen_string_literal: true

class Croissant::Stylesheet::AtRule::Statement < Croissant::Stylesheet::AtRule
  def to_s
    prelude.empty? ? "@#{name};" : "@#{name} #{prelude};"
  end
end
