# frozen_string_literal: true

class Croissant::Selector::PseudoClass::Structural::NthChild < Croissant::Selector::PseudoClass::Structural
  attr_reader :step, :offset

  def initialize(step, offset)
    @step = step
    @offset = offset

    super()
  end

  def matches?(element)
    index = 1
    sibling = element.previous_element

    while sibling
      index += 1
      sibling = sibling.previous_element
    end

    matches_formula?(index)
  end

  def to_s
    super + "(#{formula})"
  end

  private

  def keyword
    'nth-child'
  end

  def matches_formula?(index)
    return index == offset if step.zero?

    diff = index - offset
    (diff % step).zero? && (diff / step) >= 0
  end

  def formula
    return offset.to_s if step.zero?

    step_text = { 1 => 'n', -1 => '-n' }.fetch(step, "#{step}n")
    return step_text if offset.zero?

    "#{step_text}#{offset.positive? ? '+' : '-'}#{offset.abs}"
  end
end
