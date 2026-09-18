# frozen_string_literal: true

require_relative '../refinements'

module Croissant::Refinements::Symbol
  refine ::Symbol do
    def |(other)
      Croissant::Style::Type::Union.new(self, other)
    end
  end
end
