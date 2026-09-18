# frozen_string_literal: true

class Croissant::Style::Cascade
  def self.resolve(*rules)
    new.resolve(*rules)
  end

  def initialize(rules = [])
    @declarations = rules.to_h { |rule| [rule, prepare(rule).freeze] }.compare_by_identity.freeze

    freeze
  end

  def resolve(*rules)
    set = Croissant::Style::DeclarationSet.new

    sort(rules).each do |rule|
      declarations_for(rule).each { |declaration| set.add(declaration) }
    end

    set
  end

  def declarations_for(rule)
    @declarations[rule] || prepare(rule)
  end

  private

  def prepare(rule)
    rule.declarations.flat_map do |declaration|
      declaration = build_declaration(declaration)
      declaration.property.expand(declaration)
    end
  end

  def build_declaration(declaration)
    return declaration if declaration.is_a?(Croissant::Style::Declaration)

    Croissant::Style::Declaration.new(declaration.property, declaration.value, important: declaration.important?)
  end

  def sort(rules)
    1.upto(rules.size - 1) do |index|
      rule = rules[index]

      while index.positive? && (rules[index - 1].specificity <=> rule.specificity).positive?
        rules[index] = rules[index - 1]
        index -= 1
      end

      rules[index] = rule
    end

    rules
  end
end
