# frozen_string_literal: true

class Croissant::Selector::Parser # rubocop:disable Metrics/ClassLength
  LEGACY_PSEUDO_ELEMENTS = %w[
    before
    after
    first-line
    first-letter
  ].freeze

  FUNCTIONAL_PSEUDO_NAMES = %w[is not has where].freeze
  CLOSING_BRACKET = ']'

  ATTRIBUTE_OPERATORS = {
    '~=' => :includes,
    '|=' => :hyphenated,
    '^=' => :starts_with,
    '$=' => :ends_with,
    '*=' => :contains,
    '=' => :equals
  }.freeze

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
  TAB = "\t".ord
  NEWLINE = "\n".ord
  CARRIAGE_RETURN = "\r".ord
  FORM_FEED = "\f".ord
  GREATER_THAN = '>'.ord
  PLUS = '+'.ord
  TILDE = '~'.ord
  ASTERISK = '*'.ord
  DOUBLE_QUOTE = '"'.ord
  SINGLE_QUOTE = "'".ord
  UPPERCASE = (('A'.ord)..('Z'.ord))
  LOWERCASE = (('a'.ord)..('z'.ord))
  DIGITS = (('0'.ord)..('9'.ord))
  WHITESPACE_BYTES = [SPACE, TAB, NEWLINE, CARRIAGE_RETURN, FORM_FEED].freeze
  COMBINATORS = (WHITESPACE_BYTES + [GREATER_THAN, PLUS, TILDE]).freeze
  QUOTE_BYTES = [DOUBLE_QUOTE, SINGLE_QUOTE].freeze
  CASE_INSENSITIVE_FLAG_BYTES = ['i'.ord, 'I'.ord].freeze
  CASE_SENSITIVE_FLAG_BYTES = ['s'.ord, 'S'.ord].freeze
  COMBINATOR_SYMBOLS = WHITESPACE_BYTES.to_h { |byte| [byte, :descendant] }.merge(
    GREATER_THAN => :child,
    PLUS => :next_sibling,
    TILDE => :subsequent_sibling
  ).freeze
  COMBINATOR_CLASSES = {
    child: Croissant::Selector::Combinator::Child,
    descendant: Croissant::Selector::Combinator::Descendant,
    next_sibling: Croissant::Selector::Combinator::NextSibling,
    subsequent_sibling: Croissant::Selector::Combinator::SubsequentSibling
  }.freeze
  RELATIVE_CLASSES = {
    child: Croissant::Selector::Relative::Child,
    descendant: Croissant::Selector::Relative::Descendant,
    next_sibling: Croissant::Selector::Relative::NextSibling,
    subsequent_sibling: Croissant::Selector::Relative::SubsequentSibling
  }.freeze
  RELATIVE_COMBINATOR_SYMBOLS = {
    GREATER_THAN => :child,
    PLUS => :next_sibling,
    TILDE => :subsequent_sibling
  }.freeze
  FUNCTIONAL_PSEUDO_CLASSES = {
    'not' => Croissant::Selector::PseudoClass::Functional::Not,
    'is' => Croissant::Selector::PseudoClass::Functional::Is,
    'where' => Croissant::Selector::PseudoClass::Functional::Where
  }.freeze
  STRUCTURAL_PSEUDO_CLASSES = {
    'first-child' => Croissant::Selector::PseudoClass::Structural::FirstChild,
    'last-child' => Croissant::Selector::PseudoClass::Structural::LastChild,
    'only-child' => Croissant::Selector::PseudoClass::Structural::OnlyChild,
    'first-of-type' => Croissant::Selector::PseudoClass::Structural::FirstOfType,
    'last-of-type' => Croissant::Selector::PseudoClass::Structural::LastOfType,
    'only-of-type' => Croissant::Selector::PseudoClass::Structural::OnlyOfType,
    'empty' => Croissant::Selector::PseudoClass::Structural::Empty,
    'root' => Croissant::Selector::PseudoClass::Structural::Root
  }.freeze
  NTH_PSEUDO_CLASSES = {
    'nth-child' => Croissant::Selector::PseudoClass::Structural::NthChild,
    'nth-of-type' => Croissant::Selector::PseudoClass::Structural::NthOfType,
    'nth-last-child' => Croissant::Selector::PseudoClass::Structural::NthLastChild,
    'nth-last-of-type' => Croissant::Selector::PseudoClass::Structural::NthLastOfType
  }.freeze
  NTH_KEYWORDS = { 'odd' => [2, 1], 'even' => [2, 0] }.freeze
  NTH_INTEGER = /\A[+-]?\d+\z/
  NTH_FORMULA = /\A([+-]?\d*)n\s*([+-]\s*\d+)?\z/

  class CompoundBuilder
    attr_reader :selectors, :compounds, :combinators

    def initialize
      @compounds = []
      @combinators = []
      reset
    end

    def start!
      @started = true
    end

    def add(selector)
      selectors << selector
    end

    def combinator!(symbol)
      @pending_combinator = symbol if symbol != :descendant || @pending_combinator.nil?
    end

    def flush!
      return unless @started && @pending_combinator

      push_compound
      combinators << @pending_combinator
      reset
    end

    def finish!
      push_compound if @started
    end

    private

    def push_compound
      compounds << Croissant::Selector::Compound.new(selectors)
    end

    def reset
      @selectors = []
      @started = false
      @pending_combinator = nil
    end
  end
  private_constant :CompoundBuilder

  def self.parse(selector)
    new.parse(selector)
  end

  def parse(selector)
    selector = selector.to_s.strip
    stop = selector.bytesize
    compounds, combinators = analyze_compounds(selector, stop)
    return if compounds.empty?

    build_root(compounds, combinators)
  end

  private

  def analyze_compounds(text, stop) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength
    builder = CompoundBuilder.new
    position = 0

    while position < stop
      case text.getbyte(position)
      when HASH
        length = word_length(text, position + 1, stop)
        if length.positive?
          builder.flush!
          builder.start!
          builder.add(Croissant::Selector::Simple::Id.new(text.byteslice(position + 1, length)))
        end
        position += 1 + length
      when DOT
        length = word_length(text, position + 1, stop)
        if length.positive?
          builder.flush!
          builder.start!
          builder.add(Croissant::Selector::Simple::ClassName.new(text.byteslice(position + 1, length)))
        end
        position += 1 + length
      when COLON
        position, pseudo = parse_pseudo(text, position, stop)

        if pseudo
          builder.flush!
          builder.start!
          builder.add(pseudo)
        end
      when LEFT_BRACKET
        attribute, position = parse_attribute(text, position + 1, stop)
        builder.flush!
        builder.start!
        builder.add(attribute)
      when LEFT_PAREN
        position = matching_paren_index(text, position + 1, stop) + 1
      when ASTERISK
        builder.flush!
        builder.start!
        position += 1
      when UPPERCASE, LOWERCASE
        length = word_length(text, position + 1, stop)
        builder.flush!
        builder.start!
        builder.add(Croissant::Selector::Simple::Type.new(text.byteslice(position, 1 + length)))
        position += 1 + length
      when *COMBINATORS
        builder.combinator!(COMBINATOR_SYMBOLS.fetch(text.getbyte(position)))
        position += 1
      else
        position += 1
      end
    end

    builder.finish!

    [builder.compounds, builder.combinators]
  end

  def build_root(compounds, combinators)
    compounds[1..].each_with_index.reduce(compounds.first) do |left, (right, i)|
      COMBINATOR_CLASSES.fetch(combinators[i]).new(left, right)
    end
  end

  def parse_pseudo(text, position, stop) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
    return parse_pseudo_element(text, position, stop) if text.getbyte(position + 1) == COLON

    length = word_length(text, position + 1, stop)
    return [position + 1, nil] if length.zero?

    name = text.byteslice(position + 1, length).downcase
    position += 1 + length

    return [position, Croissant::Selector::PseudoElement.new(name)] if legacy_pseudo_element?(name)

    argument = nil

    if text.getbyte(position) == LEFT_PAREN
      return parse_functional_pseudo(text, position, stop, name) if FUNCTIONAL_PSEUDO_NAMES.include?(name)
      return parse_nth_pseudo(text, position, stop, name) if NTH_PSEUDO_CLASSES.key?(name)

      argument, position = parse_argument(text, position, stop)
    elsif STRUCTURAL_PSEUDO_CLASSES.key?(name)
      return [position, STRUCTURAL_PSEUDO_CLASSES.fetch(name).new]
    end

    [position, Croissant::Selector::PseudoClass::Unknown.new(name, argument:)]
  end

  def parse_pseudo_element(text, position, stop)
    length = word_length(text, position + 2, stop)
    return [position + 2, nil] if length.zero?

    name = text.byteslice(position + 2, length).downcase
    position += 2 + length
    argument = nil
    argument, position = parse_argument(text, position, stop) if text.getbyte(position) == LEFT_PAREN

    [position, Croissant::Selector::PseudoElement.new(name, argument:)]
  end

  def parse_functional_pseudo(text, position, stop, name)
    argument, position = parse_argument(text, position, stop)

    selector =
      if name == 'has'
        arguments = split_selector_list(argument).filter_map { |part| parse_relative_selector(part) }
        Croissant::Selector::PseudoClass::Functional::Has.new(arguments)
      else
        selectors = split_selector_list(argument).filter_map { |part| parse(part) }
        FUNCTIONAL_PSEUDO_CLASSES.fetch(name).new(selectors)
      end

    [position, selector]
  end

  def parse_relative_selector(part)
    symbol = RELATIVE_COMBINATOR_SYMBOLS[part.getbyte(0)]
    remainder = symbol ? part[1..].strip : part
    selector = parse(remainder)

    selector && RELATIVE_CLASSES.fetch(symbol || :descendant).new(selector)
  end

  def parse_nth_pseudo(text, position, stop, name)
    argument, position = parse_argument(text, position, stop)
    step, offset = parse_nth(argument)

    selector =
      if step
        NTH_PSEUDO_CLASSES.fetch(name).new(step, offset)
      else
        Croissant::Selector::PseudoClass::Unknown.new(name, argument:)
      end

    [position, selector]
  end

  def parse_nth(argument)
    normalized = argument.strip.downcase
    return NTH_KEYWORDS[normalized] if NTH_KEYWORDS.key?(normalized)
    return [0, normalized.to_i] if NTH_INTEGER.match?(normalized)

    match = NTH_FORMULA.match(normalized)
    return unless match

    [parse_nth_step(match[1]), parse_nth_offset(match[2])]
  end

  def parse_nth_step(text)
    case text
    when '', '+' then 1
    when '-' then -1
    else text.to_i
    end
  end

  def parse_nth_offset(text)
    text ? text.delete(' ').to_i : 0
  end

  def split_selector_list(text) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
    parts = []
    start = 0
    depth = 0
    position = 0
    stop = text.bytesize

    while position <= stop
      byte = text.getbyte(position) if position < stop

      if position == stop || (depth.zero? && byte == COMMA)
        parts << text.byteslice(start, position - start).strip
        start = position + 1
      else
        case byte
        when LEFT_PAREN, LEFT_BRACKET then depth += 1
        when RIGHT_PAREN, RIGHT_BRACKET then depth -= 1
        end
      end

      position += 1
    end

    parts.reject(&:empty?)
  end

  def parse_attribute(text, position, stop) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    position = skip_whitespace(text, position, stop)
    length = word_length(text, position, stop)
    name = text.byteslice(position, length)
    position = skip_whitespace(text, position + length, stop)

    operator, position = parse_attribute_operator(text, position, stop)
    value = nil

    if operator
      position = skip_whitespace(text, position, stop)
      value, position = parse_attribute_value(text, position, stop)
      position = skip_whitespace(text, position, stop)
    end

    case_insensitive, position = parse_attribute_flag(text, position, stop)

    closing = text.byteindex(CLOSING_BRACKET, position)
    attribute = Croissant::Selector::Simple::Attribute.new(
      name, operator: operator || :exists, value:, case_insensitive:
    )

    [attribute, closing ? closing + 1 : stop]
  end

  def parse_attribute_operator(text, position, stop)
    return [nil, position] if position >= stop

    pair = text.byteslice(position, 2)
    return [ATTRIBUTE_OPERATORS[pair], position + 2] if pair && ATTRIBUTE_OPERATORS.key?(pair)

    single = text.byteslice(position, 1)
    return [ATTRIBUTE_OPERATORS[single], position + 1] if single && ATTRIBUTE_OPERATORS.key?(single)

    [nil, position]
  end

  def parse_attribute_value(text, position, stop) # rubocop:disable Metrics/AbcSize
    byte = text.getbyte(position)

    if QUOTE_BYTES.include?(byte)
      closing = text.byteindex(byte.chr, position + 1) || stop
      [text.byteslice(position + 1, closing - position - 1), closing + 1]
    else
      length = 0
      length += 1 while position + length < stop && !attribute_value_boundary?(text.getbyte(position + length))
      [text.byteslice(position, length), position + length]
    end
  end

  def attribute_value_boundary?(byte)
    byte == RIGHT_BRACKET || WHITESPACE_BYTES.include?(byte)
  end

  def parse_attribute_flag(text, position, _stop)
    byte = text.getbyte(position)
    return [false, position] unless byte && (CASE_INSENSITIVE_FLAG_BYTES + CASE_SENSITIVE_FLAG_BYTES).include?(byte)

    next_byte = text.getbyte(position + 1)
    return [false, position] if next_byte && next_byte != RIGHT_BRACKET && !WHITESPACE_BYTES.include?(next_byte)

    [CASE_INSENSITIVE_FLAG_BYTES.include?(byte), position + 1]
  end

  def skip_whitespace(text, position, stop)
    position += 1 while position < stop && WHITESPACE_BYTES.include?(text.getbyte(position))
    position
  end

  def parse_argument(text, position, stop)
    closing = matching_paren_index(text, position + 1, stop)

    [text.byteslice(position + 1, closing - position - 1), closing + 1]
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
end
