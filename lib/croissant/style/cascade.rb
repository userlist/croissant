# frozen_string_literal: true

module Croissant::Style::Cascade
  class << self
    def resolve(*rules)
      declarations = rules
        .sort_by!
        .with_index { |rule, index| [rule.specificity, index] }
        .flat_map(&:declarations)
        .map { |declaration| build_declaration(declaration) }

      Croissant::Style::DeclarationSet.new(declarations).expand
    end

    private

    def build_declaration(declaration)
      return declaration if declaration.is_a?(Croissant::Style::Declaration)

      Croissant::Style::Declaration.new(declaration.property, declaration.value, important: declaration.important?)
    end
  end
end
