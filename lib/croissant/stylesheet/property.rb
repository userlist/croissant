# frozen_string_literal: true

class Croissant::Stylesheet::Property < String
  def initialize(property)
    super(property.to_s.strip.downcase)

    freeze
  end
end
