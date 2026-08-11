# frozen_string_literal: true

class Croissant::Stylesheet::Parser::Selector # rubocop:disable Metrics/ClassLength
  LEGACY_PSEUDO_ELEMENTS = %w[
    before
    after
    first-line
    first-letter
  ].freeze

  NON_INLINABLE_PSEUDO_CLASSES = %w[
    hover
    focus
    focus-visible
    focus-within
    active
    visited
    link
    target
    target-within
  ].freeze

  FUNCTIONAL_PSEUDO_CLASSES = %w[is not has where].freeze
  ZERO_SPECIFICITY = 'where'
  CLOSING_BRACKET = ']'

  HASH = '#'.ord
  DOT = '.'.ord
  COLON = ':'.ord
  COMMA = ','.ord
  HYPHEN = '-'.ord
  UNDERSCORE = '_'.ord
  LEFT_PAREN = '('.ord
  RIGHT_PAREN = ')'.ord
  LEFT_BRACKET = '['.ord
  RIGHT_BRACKET = ']'.ord
  SPACE = ' '.ord
  GREATER_THAN = '>'.ord
  PLUS = '+'.ord
  TILDE = '~'.ord
  UPPERCASE = (('A'.ord)..('Z'.ord))
  LOWERCASE = (('a'.ord)..('z'.ord))
  DIGITS = (('0'.ord)..('9'.ord))
  COMBINATORS = [SPACE, GREATER_THAN, PLUS, TILDE].freeze

  def self.parse(selector)
    new.parse(selector)
  end

  def parse(selector) # rubocop:disable Metrics/MethodLength
    selector = selector.to_s.strip
    ids, classes, elements, pseudo_element, dynamic, key_ids, key_classes, key_tag =
      analyze(selector, 0, selector.bytesize)

    Croissant::Stylesheet::Selector.new(
      selector: selector,
      specificity: Croissant::Stylesheet::Specificity.new(0, ids, classes, elements),
      inlinable: !pseudo_element && !dynamic,
      ids: key_ids,
      classes: key_classes,
      tag: key_tag
    )
  end

  private

  def analyze(text, position, stop) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
    ids = classes = elements = 0
    pseudo_element = false
    dynamic = false
    key_ids = []
    key_classes = []
    key_tag = nil

    while position < stop
      case text.getbyte(position)
      when HASH
        length = word_length(text, position + 1, stop)
        if length.positive?
          ids += 1
          key_ids << text.byteslice(position + 1, length)
        end
        position += 1 + length
      when DOT
        length = word_length(text, position + 1, stop)
        if length.positive?
          classes += 1
          key_classes << text.byteslice(position + 1, length)
        end
        position += 1 + length
      when COLON
        position, p_ids, p_classes, p_elements, p_pseudo_element, p_dynamic = analyze_pseudo(text, position, stop)
        ids += p_ids
        classes += p_classes
        elements += p_elements
        pseudo_element ||= p_pseudo_element
        dynamic ||= p_dynamic
      when LEFT_BRACKET
        classes += 1
        closing = text.byteindex(CLOSING_BRACKET, position + 1)
        position = closing && closing < stop ? closing + 1 : stop
      when LEFT_PAREN
        position = matching_paren_index(text, position + 1, stop) + 1
      when UPPERCASE, LOWERCASE
        elements += 1
        length = word_length(text, position + 1, stop)
        key_tag = text.byteslice(position, 1 + length)
        position += 1 + length
      when *COMBINATORS
        key_ids = []
        key_classes = []
        key_tag = nil
        position += 1
      else
        position += 1
      end
    end

    [ids, classes, elements, pseudo_element, dynamic, key_ids, key_classes, key_tag]
  end

  def analyze_pseudo(text, position, stop) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    return analyze_pseudo_element(text, position, stop) if text.getbyte(position + 1) == COLON

    length = word_length(text, position + 1, stop)
    return [position + 1, 0, 0, 0, false, false] if length.zero?

    name = text.byteslice(position + 1, length).downcase
    position += 1 + length

    if text.getbyte(position) == LEFT_PAREN
      closing = matching_paren_index(text, position + 1, stop)

      if FUNCTIONAL_PSEUDO_CLASSES.include?(name)
        ids, classes, elements, inlinable = analyze_arguments(text, position + 1, closing)
        ids = classes = elements = 0 if name == ZERO_SPECIFICITY

        return [closing + 1, ids, classes, elements, false, !inlinable]
      end

      return [closing + 1, 0, 1, 0, legacy_pseudo_element?(name), dynamic_pseudo_class?(name)]
    end

    [position, 0, 1, 0, legacy_pseudo_element?(name), dynamic_pseudo_class?(name)]
  end

  def analyze_pseudo_element(text, position, stop)
    length = word_length(text, position + 2, stop)
    return [position + 2, 0, 0, 0, false, false] if length.zero?

    [position + 2 + length, 0, 0, 1, true, false]
  end

  def analyze_arguments(text, from, to) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
    best_ids = best_classes = best_elements = 0
    inlinable = true
    start = from
    position = from
    depth = 0

    while position <= to
      byte = text.getbyte(position) if position < to

      if position == to || (depth.zero? && byte == COMMA)
        ids, classes, elements, pseudo_element, dynamic = analyze(text, start, position)
        inlinable &&= !pseudo_element && !dynamic

        if more_specific?(ids, classes, elements, best_ids, best_classes, best_elements)
          best_ids = ids
          best_classes = classes
          best_elements = elements
        end

        start = position + 1
      else
        case byte
        when LEFT_PAREN, LEFT_BRACKET then depth += 1
        when RIGHT_PAREN, RIGHT_BRACKET then depth -= 1
        end
      end

      position += 1
    end

    [best_ids, best_classes, best_elements, inlinable]
  end

  def more_specific?(ids, classes, elements, best_ids, best_classes, best_elements) # rubocop:disable Metrics/ParameterLists
    return ids > best_ids if ids != best_ids
    return classes > best_classes if classes != best_classes

    elements > best_elements
  end

  def matching_paren_index(text, position, stop) # rubocop:disable Metrics/MethodLength
    depth = 1

    while position < stop
      case text.getbyte(position)
      when LEFT_PAREN then depth += 1
      when RIGHT_PAREN
        depth -= 1
        return position if depth.zero?
      end

      position += 1
    end

    stop
  end

  def word_length(text, position, stop)
    start = position
    position += 1 while position < stop && word_byte?(text.getbyte(position))

    position - start
  end

  def word_byte?(byte)
    LOWERCASE.cover?(byte) || UPPERCASE.cover?(byte) || DIGITS.cover?(byte) ||
      byte == HYPHEN || byte == UNDERSCORE
  end

  def legacy_pseudo_element?(name)
    LEGACY_PSEUDO_ELEMENTS.include?(name)
  end

  def dynamic_pseudo_class?(name)
    NON_INLINABLE_PSEUDO_CLASSES.include?(name)
  end
end
