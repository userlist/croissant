# frozen_string_literal: true

class Croissant::Style::RuleSet
  def initialize(rules)
    @index = Croissant::Selector::Index.new do |index|
      rules.each { |rule| index.add(rule.selector, rule) if rule.selector }
    end

    freeze
  end

  def [](element)
    @index[element]
  end

  def size
    @index.size
  end

  def empty?
    @index.empty?
  end
end
