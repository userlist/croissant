# frozen_string_literal: true

# A selector list Croissant could not parse, kept as written. It may be invalid, or valid syntax
# Croissant does not support; either way it is never inlined and the email client gets the final
# say, the way it does for an unknown pseudo-class.
class Croissant::Selector::Unknown < Croissant::Selector
  attr_reader :text

  def initialize(text)
    @text = text

    super()
  end

  def append_to(buffer)
    buffer << text
  end

  def matches?(_element)
    false
  end

  def specificity
    Croissant::Selector::Specificity.zero
  end

  def inlinable?
    false
  end
end
