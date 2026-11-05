# frozen_string_literal: true

require 'strscan'

class Croissant::Selector::Parser
  LEGACY_PSEUDO_ELEMENTS = %w[
    before
    after
    first-line
    first-letter
  ].freeze

  FUNCTIONAL_PSEUDO_NAMES = %w[is not has where].freeze
  OPENING_PAREN = '('
  CLOSING_PAREN = ')'

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
  BACKSLASH = '\\'.ord
  UPPERCASE = (('A'.ord)..('Z'.ord))
  LOWERCASE = (('a'.ord)..('z'.ord))
  DIGITS = (('0'.ord)..('9'.ord))
  WHITESPACE_BYTES = [SPACE, TAB, NEWLINE, CARRIAGE_RETURN, FORM_FEED].freeze
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
  CASE_FLAG_BYTES = (CASE_INSENSITIVE_FLAG_BYTES + CASE_SENSITIVE_FLAG_BYTES).freeze
  # Any non-ASCII code point may appear in a name, and every byte of its UTF-8 encoding is at least
  # NON_ASCII, so a name is scanned byte by byte without ever splitting a character.
  NON_ASCII = 0x80
  # https://www.w3.org/TR/css-syntax-3/#ident-start-code-point
  NAME_START_BYTES = Array.new(256) do |byte|
    UPPERCASE.cover?(byte) || LOWERCASE.cover?(byte) || byte == UNDERSCORE || byte >= NON_ASCII
  end.freeze
  # The bytes besides a name start that may begin an ident: a hyphen, or the backslash of an escape.
  IDENT_PREFIX_BYTES = [HYPHEN, BACKSLASH].freeze
  # https://www.w3.org/TR/css-syntax-3/#ident-code-point
  WORD_BYTES = Array.new(256) do |byte|
    NAME_START_BYTES[byte] || DIGITS.cover?(byte) || byte == HYPHEN
  end.freeze
  # A backslash and the character after it, or up to six hex digits naming a code point and one
  # optional whitespace character ending them. https://developer.mozilla.org/en-US/docs/Web/CSS/ident
  ESCAPE = /\\(?:(\h{1,6})(?:\r\n|[ \t\r\n\f])?|([^\r\n\f]))/
  SURROGATES = (0xD800..0xDFFF)
  MAXIMUM_CODE_POINT = 0x10FFFF
  REPLACEMENT_CHARACTER = 0xFFFD.chr(Encoding::UTF_8).freeze
  NTH_KEYWORDS = { 'odd' => [2, 1], 'even' => [2, 0] }.freeze
  NTH_INTEGER = /\A[+-]?\d+\z/
  NTH_FORMULA = /\A([+-]?\d*)n\s*([+-]\s*\d+)?\z/
  # Thrown, not raised, on input that is not a selector Croissant can parse: the input is
  # untrusted, so failing must stay as cheap as succeeding. Every #parse catches it, so a failure
  # inside :is() or :where() only loses that argument, as their forgiving selector lists require.
  INVALID = :invalid_selector

  class CompoundBuilder
    attr_reader :selectors, :compounds, :combinators

    def initialize
      @compounds = []
      @combinators = []
      reset
    end

    def clear!
      compounds.clear
      combinators.clear
      reset
    end

    def start!
      @started = true
    end

    def add(selector)
      selectors << selector
    end

    def combinator!(symbol)
      if symbol == :descendant
        @pending_combinator ||= symbol
      else
        # A combinator needs a compound on its left, and only one combinator fits between two.
        throw INVALID unless @started && [nil, :descendant].include?(@pending_combinator)

        @pending_combinator = symbol
      end
    end

    def flush!
      return unless @started && @pending_combinator

      push_compound
      combinators << @pending_combinator
      reset
    end

    def finish!
      # And it needs a compound on its right.
      throw INVALID unless [nil, :descendant].include?(@pending_combinator)

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

  def initialize
    @builders = []
    @depth = 0
    @position = 0
  end

  # Answers nil when the selector is empty or cannot be parsed.
  def parse(selector)
    position = @position

    catch(INVALID) do
      selector = strip_padding(selector.to_s)
      builder = scan_compounds(selector, selector.bytesize)
      return if builder.compounds.empty?

      build_root(builder.compounds, builder.combinators)
    end
  ensure
    @position = position
  end

  private

  def strip_padding(text)
    return text if text.empty?

    padded = WHITESPACE_BYTES.include?(text.getbyte(0)) ||
             WHITESPACE_BYTES.include?(text.getbyte(text.bytesize - 1))

    padded ? text.strip : text
  end

  def scan_compounds(text, stop) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
    builder = (@builders[@depth] ||= CompoundBuilder.new)
    builder.clear!
    @depth += 1
    position = 0

    while position < stop
      byte = text.getbyte(position)

      if NAME_START_BYTES[byte] || (IDENT_PREFIX_BYTES.include?(byte) && ident_start?(text, position, stop))
        name = scan_ident(text, position, stop)
        builder.flush!
        builder.start!
        builder.add(Croissant::Selector::Simple::Type.new(name))
        position = @position
        next
      elsif (combinator = COMBINATOR_SYMBOLS[byte])
        builder.combinator!(combinator)
        position += 1
        next
      end

      case byte
      when HASH
        name = scan_ident(text, position + 1, stop) || throw(INVALID)
        builder.flush!
        builder.start!
        builder.add(Croissant::Selector::Simple::Id.new(name))
        position = @position
      when DOT
        name = scan_ident(text, position + 1, stop) || throw(INVALID)
        builder.flush!
        builder.start!
        builder.add(Croissant::Selector::Simple::ClassName.new(name))
        position = @position
      when COLON
        @position = position
        pseudo = parse_pseudo(text, stop) || throw(INVALID)
        position = @position
        builder.flush!
        builder.start!
        builder.add(pseudo)
      when LEFT_BRACKET
        @position = position + 1
        attribute = parse_attribute(text, stop)
        position = @position
        builder.flush!
        builder.start!
        builder.add(attribute)
      when ASTERISK
        builder.flush!
        builder.start!
        position += 1
      else
        throw INVALID
      end
    end

    builder.finish!

    builder
  ensure
    @depth -= 1
  end

  def build_root(compounds, combinators)
    root = compounds.first
    index = 1

    while index < compounds.length
      root = COMBINATOR_CLASSES.fetch(combinators[index - 1]).new(root, compounds[index])
      index += 1
    end

    root
  end

  def parse_pseudo(text, stop) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity
    return parse_pseudo_element(text, stop) if text.getbyte(@position + 1) == COLON

    name = scan_ident(text, @position + 1, stop)
    return unless name

    name.downcase!(:ascii)

    return Croissant::Selector::PseudoElement.new(name) if legacy_pseudo_element?(name)

    argument = nil

    if text.getbyte(@position) == LEFT_PAREN
      return parse_functional_pseudo(text, stop, name) if FUNCTIONAL_PSEUDO_NAMES.include?(name)
      return parse_nth_pseudo(text, stop, name) if NTH_PSEUDO_CLASSES.key?(name)

      argument = parse_argument(text, stop)
    elsif STRUCTURAL_PSEUDO_CLASSES.key?(name)
      return STRUCTURAL_PSEUDO_CLASSES.fetch(name).new
    end

    Croissant::Selector::PseudoClass::Unknown.new(name, argument:)
  end

  def parse_pseudo_element(text, stop)
    name = scan_ident(text, @position + 2, stop)
    return unless name

    argument = parse_argument(text, stop) if text.getbyte(@position) == LEFT_PAREN

    Croissant::Selector::PseudoElement.new(name, argument:)
  end

  def parse_functional_pseudo(text, stop, name)
    parts = split_selector_list(parse_argument(text, stop))

    case name
    when 'has'
      Croissant::Selector::PseudoClass::Functional::Has.new(parse_strict_list(parts) { parse_relative_selector(_1) })
    when 'not'
      Croissant::Selector::PseudoClass::Functional::Not.new(parse_strict_list(parts) { parse(_1) })
    else
      FUNCTIONAL_PSEUDO_CLASSES.fetch(name).new(parts.filter_map { |part| parse(part) })
    end
  end

  # :not() and :has() take an unforgiving selector list: one invalid or missing selector, or none
  # at all, invalidates the whole pseudo-class.
  def parse_strict_list(parts)
    throw INVALID if parts.empty?

    parts.map { |part| yield(part) || throw(INVALID) }
  end

  def parse_relative_selector(part)
    symbol = RELATIVE_COMBINATOR_SYMBOLS[part.getbyte(0)]
    remainder = symbol ? part[1..].strip : part
    selector = parse(remainder)

    selector && RELATIVE_CLASSES.fetch(symbol || :descendant).new(selector)
  end

  def parse_nth_pseudo(text, stop, name)
    argument = parse_argument(text, stop)
    step, offset = parse_nth(argument)

    if step
      NTH_PSEUDO_CLASSES.fetch(name).new(step, offset)
    else
      Croissant::Selector::PseudoClass::Unknown.new(name, argument:)
    end
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
    unless text.include?(',')
      part = text.strip
      return part.empty? ? [] : [part]
    end

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
        when BACKSLASH then position += 1 if position + 1 < stop
        when LEFT_PAREN, LEFT_BRACKET then depth += 1
        when RIGHT_PAREN, RIGHT_BRACKET then depth -= 1
        end
      end

      position += 1
    end

    parts
  end

  def parse_attribute(text, stop) # rubocop:disable Metrics/MethodLength
    @position = skip_whitespace(text, @position, stop)
    name = scan_ident(text, @position, stop) || throw(INVALID)
    @position = skip_whitespace(text, @position, stop)

    operator = parse_attribute_operator(text, stop)
    value = nil

    if operator
      @position = skip_whitespace(text, @position, stop)
      value = parse_attribute_value(text, stop)
      @position = skip_whitespace(text, @position, stop)
    end

    case_insensitive = parse_case_insensitive_flag?(text)
    skip_closing_bracket(text, stop)

    Croissant::Selector::Simple::Attribute.new(
      name, operator: operator || :exists, value:, case_insensitive:
    )
  end

  def skip_closing_bracket(text, stop)
    @position = skip_whitespace(text, @position, stop)
    throw INVALID unless text.getbyte(@position) == RIGHT_BRACKET

    @position += 1
  end

  def parse_attribute_operator(text, stop)
    return if @position >= stop

    operator = text.byteslice(@position, 2)
    operator = text.byteslice(@position, 1) unless ATTRIBUTE_OPERATORS.key?(operator)
    return unless ATTRIBUTE_OPERATORS.key?(operator)

    @position += operator.bytesize
    ATTRIBUTE_OPERATORS[operator]
  end

  def parse_attribute_value(text, stop)
    byte = text.getbyte(@position)
    return parse_quoted_attribute_value(text, byte, stop) if QUOTE_BYTES.include?(byte)

    start = @position
    while @position < stop && !attribute_value_boundary?(byte = text.getbyte(@position))
      # An escaped `]` or the whitespace ending a hex escape is part of the value.
      @position += (byte == BACKSLASH && escape_length(text, @position)) || 1
    end
    # An empty value has to be quoted.
    throw INVALID if @position == start

    unescape(text.byteslice(start, @position - start))
  end

  def parse_quoted_attribute_value(text, quote, stop)
    start = @position + 1
    closing = closing_quote_index(text, quote, start, stop)
    throw INVALID if closing >= stop

    value = text.byteslice(start, closing - start)
    @position = closing + 1

    unescape(value)
  end

  def closing_quote_index(text, quote, position, stop)
    closing = text.byteindex(quote.chr, position) || stop
    backslash = text.byteindex('\\', position)
    return closing if backslash.nil? || backslash > closing

    while position < stop
      byte = text.getbyte(position)
      return position if byte == quote

      # An escaped quote, or escaped backslash, does not close the string.
      position += byte == BACKSLASH ? 2 : 1
    end

    stop
  end

  def attribute_value_boundary?(byte)
    byte == RIGHT_BRACKET || WHITESPACE_BYTES.include?(byte)
  end

  def parse_case_insensitive_flag?(text)
    byte = text.getbyte(@position)
    return false unless byte && CASE_FLAG_BYTES.include?(byte)

    next_byte = text.getbyte(@position + 1)
    return false if next_byte && next_byte != RIGHT_BRACKET && !WHITESPACE_BYTES.include?(next_byte)

    @position += 1
    CASE_INSENSITIVE_FLAG_BYTES.include?(byte)
  end

  def skip_whitespace(text, position, stop)
    position += 1 while position < stop && WHITESPACE_BYTES.include?(text.getbyte(position))
    position
  end

  def parse_argument(text, stop)
    closing = matching_paren_index(text, @position + 1, stop)
    throw INVALID if closing >= stop

    argument = text.byteslice(@position + 1, closing - @position - 1)
    @position = closing + 1

    argument
  end

  def matching_paren_index(text, position, stop)
    closing = text.byteindex(CLOSING_PAREN, position)
    return stop unless closing

    opening = text.byteindex(OPENING_PAREN, position)
    backslash = text.byteindex('\\', position)
    return closing if (opening.nil? || opening > closing) && (backslash.nil? || backslash > closing)

    scan_matching_paren(text, position, stop)
  end

  def scan_matching_paren(text, position, stop) # rubocop:disable Metrics/MethodLength
    depth = 1

    while position < stop
      case text.getbyte(position)
      when BACKSLASH then position += 1
      when LEFT_PAREN then depth += 1
      when RIGHT_PAREN
        depth -= 1
        return position if depth.zero?
      end

      position += 1
    end

    stop
  end

  # The ident sequence at position, unescaped, leaving @position after it. Answers nil when there is
  # none. Without escapes, which is nearly always, it is a single slice of text.
  def scan_ident(text, position, stop)
    return if position >= stop

    # A plain name start is by far the most common, so it skips the method call.
    return unless NAME_START_BYTES[text.getbyte(position)] || ident_start?(text, position, stop)

    @position = position + word_length(text, position, stop)
    return scan_escaped_ident(text, position, stop) if text.getbyte(@position) == BACKSLASH

    text.byteslice(position, @position - position) if @position > position
  end

  # Whether an ident sequence starts at position: a name-start code point, a valid escape, or a
  # hyphen followed by either or by a second hyphen, but never a digit.
  # https://www.w3.org/TR/css-syntax-3/#would-start-an-identifier
  def ident_start?(text, position, stop)
    return false if position >= stop

    byte = text.getbyte(position)

    if byte == HYPHEN
      position += 1
      return false if position >= stop

      byte = text.getbyte(position)
      return true if byte == HYPHEN
    end

    byte == BACKSLASH ? !escape_length(text, position).nil? : NAME_START_BYTES[byte]
  end

  def scan_escaped_ident(text, position, stop)
    while text.getbyte(@position) == BACKSLASH && (length = escape_length(text, @position))
      @position += length
      @position += word_length(text, @position, stop)
    end

    unescape(text.byteslice(position, @position - position)) if @position > position
  end

  def escape_length(text, position)
    scanner = (@escape_scanner ||= StringScanner.new(''))
    scanner.string = text
    scanner.pos = position
    scanner.skip(ESCAPE)
  end

  def unescape(text)
    return text unless text.include?('\\')

    text.gsub(ESCAPE) do
      hex = Regexp.last_match(1)
      next Regexp.last_match(2) unless hex

      code = hex.to_i(16)
      invalid = code.zero? || code > MAXIMUM_CODE_POINT || SURROGATES.cover?(code)
      invalid ? REPLACEMENT_CHARACTER : code.chr(Encoding::UTF_8)
    end
  end

  def word_length(text, position, stop)
    start = position
    position += 1 while position < stop && WORD_BYTES[text.getbyte(position)]

    position - start
  end

  def legacy_pseudo_element?(name)
    LEGACY_PSEUDO_ELEMENTS.include?(name)
  end
end
