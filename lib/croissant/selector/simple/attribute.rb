# frozen_string_literal: true

class Croissant::Selector::Simple::Attribute < Croissant::Selector::Simple
  OPERATOR_TOKENS = {
    equals: '=',
    includes: '~=',
    hyphenated: '|=',
    starts_with: '^=',
    ends_with: '$=',
    contains: '*='
  }.freeze

  attr_reader :operator, :value

  def initialize(name, operator: :exists, value: nil, case_insensitive: false)
    @operator = operator
    @value = value
    @case_insensitive = case_insensitive

    super(name.downcase)
  end

  def case_insensitive?
    @case_insensitive
  end

  def matches?(element)
    actual = element[name]
    return !actual.nil? if operator == :exists
    return false if actual.nil?

    compare(actual, value)
  end

  def specificity
    Croissant::Selector::Specificity.class_name
  end

  def to_s
    return "[#{name}]" if operator == :exists

    flag = case_insensitive? ? ' i' : ''
    operator = OPERATOR_TOKENS.fetch(self.operator)

    "[#{name}#{operator}\"#{value}\"#{flag}]"
  end

  private

  def compare(actual, expected) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength
    if case_insensitive?
      actual = actual.downcase
      expected = expected.downcase
    end

    case operator
    when :equals then actual == expected
    when :includes then actual.split(/\s+/).include?(expected)
    when :hyphenated then actual == expected || actual.start_with?("#{expected}-")
    when :starts_with then actual.start_with?(expected)
    when :ends_with then actual.end_with?(expected)
    when :contains then actual.include?(expected)
    end
  end
end
