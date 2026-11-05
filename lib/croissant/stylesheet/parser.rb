# frozen_string_literal: true

require 'strscan'

class Croissant::Stylesheet::Parser
  HTML_COMMENT = /<!--|-->/
  IMPORTANT = /!\s*important\s*\z/i

  AT_RULE_NAME = /[\w-]*/
  CONDITIONAL_GROUP_NAMES = %w[media supports].freeze
  DECLARATION_BLOCK_NAMES = %w[font-face].freeze
  WHITESPACE = /\s+/
  COMMENT_OPEN = %r{/\*}
  COMMENT_CLOSE = %r{\*/}

  QUOTED_DOUBLE = /(?:\\.|[^\\"])*"/m
  QUOTED_SINGLE = /(?:\\.|[^\\'])*'/m
  # Every boundary also stops at a backslash, so the escaped character after it (`.sm\:hidden`,
  # `.a\,b`, `.w-\[50\%\]`) is skipped rather than read as structure.
  PAREN_SPECIALS = /['"()\\]/
  BRACKET_SPECIALS = /['"\[\]\\]/

  PRELUDE_BOUNDARY = %r{[\{;\}'"(\[/\\]}
  BLOCK_BOUNDARY = %r{[\}'"(\[/\\]}
  RULE_BOUNDARY = %r{[\{\}'"(\[/\\]}
  DECLARATION_BOUNDARY = %r{[;'"(\[/\\]}
  SELECTOR_BOUNDARY = %r{[,'"(\[/\\]}

  LEFT_BRACE = '{'.ord
  RIGHT_BRACE = '}'.ord
  SEMICOLON = ';'.ord
  COMMA = ','.ord
  SLASH = '/'.ord
  ASTERISK = '*'.ord
  AT_SIGN = '@'.ord
  DOUBLE_QUOTE = '"'.ord
  SINGLE_QUOTE = "'".ord
  LEFT_PAREN = '('.ord
  RIGHT_PAREN = ')'.ord
  LEFT_BRACKET = '['.ord
  RIGHT_BRACKET = ']'.ord
  BACKSLASH = '\\'.ord
  ASCII_LIMIT = 0x80

  def self.parse(content)
    new.parse(content)
  end

  def self.parse_attribute(content)
    new.parse_attribute(content)
  end

  def self.parse_selector(content)
    new.parse_selector(content)
  end

  def self.parse_selector_list(content)
    new.parse_selector_list(content)
  end

  def initialize
    @selector_parser = Croissant::Selector::Parser.new
    @declaration_scanner = StringScanner.new('')
    @segment_scanner = StringScanner.new('')
  end

  def parse(content)
    scanner = StringScanner.new(content.to_s.gsub(HTML_COMMENT, ' '))

    Croissant::Stylesheet.new(parse_rule_list(scanner, nested: false))
  end

  def parse_attribute(content)
    declarations = parse_declarations(content.to_s)
    specificity = Croissant::Selector::Specificity.inline

    Croissant::Stylesheet::Rule.new(declarations:, specificity:)
  end

  def parse_selector(content)
    selector_parser.parse(content)
  end

  # Answers nil when any selector in the list cannot be parsed.
  def parse_selector_list(content)
    selectors = split_segments(content.to_s).map { |segment| parse_selector(segment) }
    selectors unless selectors.include?(nil)
  end

  private

  attr_reader :selector_parser

  def parse_rule_list(scanner, nested:) # rubocop:disable Metrics/MethodLength
    string = scanner.string
    rules = []

    until scanner.eos?
      skip_insignificant(scanner)
      break if scanner.eos?

      case string.getbyte(scanner.pos)
      when RIGHT_BRACE
        scanner.pos += 1
        break if nested
      when AT_SIGN then consume_at_rule(scanner, rules)
      else consume_rule(scanner, rules)
      end
    end

    rules
  end

  def parse_declarations(content)
    scanner = @declaration_scanner
    scanner.string = content
    declarations = []

    until scanner.eos?
      segment, _terminator = scan_declaration(scanner)
      declaration = parse_declaration(segment)

      declarations << declaration if declaration
    end

    declarations
  end

  def consume_at_rule(scanner, rules)
    scanner.pos += 1
    name = scanner.scan(AT_RULE_NAME)
    prelude, terminator = scan_prelude(scanner)

    name.downcase!
    at_rule = build_at_rule(scanner, name, prelude.strip, terminator)

    scanner.pos -= 1 if terminator == RIGHT_BRACE
    rules << at_rule unless at_rule.nil? || name.empty?
  end

  def build_at_rule(scanner, name, prelude, terminator)
    return Croissant::Stylesheet::AtRule::Statement.new(name:, prelude:) unless terminator == LEFT_BRACE

    case name
    when *CONDITIONAL_GROUP_NAMES then build_conditional_group(scanner, name, prelude)
    when *DECLARATION_BLOCK_NAMES then build_declaration_block(scanner, name, prelude)
    else build_raw_block(scanner, name, prelude)
    end
  end

  def build_conditional_group(scanner, name, prelude)
    rules = parse_rule_list(scanner, nested: true)
    return if rules.empty?

    Croissant::Stylesheet::AtRule::ConditionalGroup.new(name:, prelude:, rules:)
  end

  def build_declaration_block(scanner, name, prelude)
    block, _terminator = scan_block_body(scanner)
    declarations = parse_declarations(block)
    return if declarations.empty?

    Croissant::Stylesheet::AtRule::DeclarationBlock.new(name:, prelude:, declarations:)
  end

  def build_raw_block(scanner, name, prelude)
    body = scan_raw_block(scanner).strip
    # @page mixes declarations with margin-box at-rules, so it stays raw but is dropped when empty.
    return if name == 'page' && parse_declarations(body).empty?

    Croissant::Stylesheet::AtRule::Block.new(name:, prelude:, body:)
  end

  def consume_rule(scanner, rules)
    prelude, terminator = scan_prelude(scanner)

    consume_declaration_block(scanner, prelude, rules) if terminator == LEFT_BRACE
  end

  def consume_declaration_block(scanner, prelude, rules)
    block, _terminator = scan_block_body(scanner)
    declarations = parse_declarations(block)
    return if declarations.empty?

    segments = split_segments(prelude)
    selectors = segments.map { |segment| parse_selector(segment) }

    # One selector Croissant cannot parse invalidates the whole list, the way it does in a
    # browser, so none of them may be inlined. The rule is kept as written instead.
    return consume_unknown_rule(segments, declarations, rules) if selectors.include?(nil)

    selectors.each { |selector| rules << Croissant::Stylesheet::Rule.new(selector:, declarations:) }
  end

  def consume_unknown_rule(segments, declarations, rules)
    return if segments.all? { |segment| segment.strip.empty? }

    selector = Croissant::Selector::Unknown.new(segments.map(&:strip).join(', ').strip)
    rules << Croissant::Stylesheet::Rule.new(selector:, declarations:)
  end

  def scan_raw_block(scanner) # rubocop:disable Metrics/MethodLength
    string = scanner.string
    start = scanner.pos
    depth = 1

    while depth.positive?
      _segment, terminator = scan_rule_boundary(scanner)

      case terminator
      when LEFT_BRACE then depth += 1
      when RIGHT_BRACE then depth -= 1
      when nil then return string.byteslice(start, scanner.pos - start)
      end
    end

    string.byteslice(start, scanner.pos - 1 - start)
  end

  def parse_declaration(content)
    property, value = content.split(':', 2)
    return unless value

    property = property.strip
    important = value.match?(IMPORTANT)
    value = value.sub(IMPORTANT, '') if important
    value = value.strip

    return if property.empty? || value.empty?

    Croissant::Stylesheet::Declaration.new(property:, value:, important:)
  end

  def split_segments(content)
    scanner = @segment_scanner
    scanner.string = content
    segments = []
    terminator = nil

    until scanner.eos?
      segment, terminator = scan_selector(scanner)
      segments << segment
    end

    # A trailing comma ends the list with an empty selector, which makes it invalid.
    segments << '' if terminator == COMMA

    segments
  end

  def skip_insignificant(scanner)
    loop do
      next if scanner.skip(WHITESPACE)
      break unless scanner.skip(COMMENT_OPEN)

      scanner.skip_until(COMMENT_CLOSE) || scanner.terminate
    end
  end

  def scan_prelude(scanner) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    string = scanner.string
    start = scanner.pos
    comments = nil

    loop do
      unless scanner.skip_until(PRELUDE_BOUNDARY)
        scanner.terminate
        return [build_segment(string, start, scanner.pos, comments), nil]
      end

      case (byte = string.getbyte(scanner.pos - 1))
      when LEFT_BRACE, SEMICOLON, RIGHT_BRACE
        return [build_segment(string, start, scanner.pos - 1, comments), byte]
      when SLASH
        skip_comment_body(scanner) { |span| (comments ||= []) << span }
      else
        advance_nested(scanner, byte)
      end
    end
  end

  def scan_block_body(scanner) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    string = scanner.string
    start = scanner.pos
    comments = nil

    loop do
      unless scanner.skip_until(BLOCK_BOUNDARY)
        scanner.terminate
        return [build_segment(string, start, scanner.pos, comments), nil]
      end

      case (byte = string.getbyte(scanner.pos - 1))
      when RIGHT_BRACE
        return [build_segment(string, start, scanner.pos - 1, comments), byte]
      when SLASH
        skip_comment_body(scanner) { |span| (comments ||= []) << span }
      else
        advance_nested(scanner, byte)
      end
    end
  end

  def scan_rule_boundary(scanner) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    string = scanner.string
    start = scanner.pos
    comments = nil

    loop do
      unless scanner.skip_until(RULE_BOUNDARY)
        scanner.terminate
        return [build_segment(string, start, scanner.pos, comments), nil]
      end

      case (byte = string.getbyte(scanner.pos - 1))
      when LEFT_BRACE, RIGHT_BRACE
        return [build_segment(string, start, scanner.pos - 1, comments), byte]
      when SLASH
        skip_comment_body(scanner) { |span| (comments ||= []) << span }
      else
        advance_nested(scanner, byte)
      end
    end
  end

  def scan_declaration(scanner) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    string = scanner.string
    start = scanner.pos
    comments = nil

    loop do
      unless scanner.skip_until(DECLARATION_BOUNDARY)
        scanner.terminate
        return [build_segment(string, start, scanner.pos, comments), nil]
      end

      case (byte = string.getbyte(scanner.pos - 1))
      when SEMICOLON
        return [build_segment(string, start, scanner.pos - 1, comments), byte]
      when SLASH
        skip_comment_body(scanner) { |span| (comments ||= []) << span }
      else
        advance_nested(scanner, byte)
      end
    end
  end

  def scan_selector(scanner) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    string = scanner.string
    start = scanner.pos
    comments = nil

    loop do
      unless scanner.skip_until(SELECTOR_BOUNDARY)
        scanner.terminate
        return [build_segment(string, start, scanner.pos, comments), nil]
      end

      case (byte = string.getbyte(scanner.pos - 1))
      when COMMA
        return [build_segment(string, start, scanner.pos - 1, comments), byte]
      when SLASH
        skip_comment_body(scanner) { |span| (comments ||= []) << span }
      else
        advance_nested(scanner, byte)
      end
    end
  end

  def skip_comment_body(scanner)
    return unless scanner.string.getbyte(scanner.pos) == ASTERISK

    comment_start = scanner.pos - 1
    scanner.pos += 1
    scanner.skip_until(COMMENT_CLOSE) || scanner.terminate

    yield [comment_start, scanner.pos]
  end

  def build_segment(string, start, finish, comments)
    return string.byteslice(start, finish - start) unless comments

    segment = +''
    cursor = start

    comments.each do |comment_start, comment_finish|
      segment << string.byteslice(cursor, comment_start - cursor) << ' '
      cursor = comment_finish
    end

    segment << string.byteslice(cursor, finish - cursor)
  end

  def advance_nested(scanner, byte)
    case byte
    when BACKSLASH then skip_escaped(scanner)
    when DOUBLE_QUOTE then scanner.skip(QUOTED_DOUBLE) || scanner.terminate
    when SINGLE_QUOTE then scanner.skip(QUOTED_SINGLE) || scanner.terminate
    when LEFT_PAREN then advance_balanced(scanner, LEFT_PAREN, RIGHT_PAREN, PAREN_SPECIALS)
    else advance_balanced(scanner, LEFT_BRACKET, RIGHT_BRACKET, BRACKET_SPECIALS)
    end
  end

  def advance_balanced(scanner, open, close, specials) # rubocop:disable Metrics/MethodLength
    string = scanner.string
    depth = 1

    while depth.positive?
      return scanner.terminate unless scanner.skip_until(specials)

      case string.getbyte(scanner.pos - 1)
      when open then depth += 1
      when close then depth -= 1
      when BACKSLASH then skip_escaped(scanner)
      when DOUBLE_QUOTE then scanner.skip(QUOTED_DOUBLE) || scanner.terminate
      when SINGLE_QUOTE then scanner.skip(QUOTED_SINGLE) || scanner.terminate
      end
    end
  end

  # Only an ASCII character can be mistaken for a boundary, and stepping over one byte of a multibyte
  # character would leave the scanner inside it.
  def skip_escaped(scanner)
    byte = scanner.string.getbyte(scanner.pos)
    scanner.pos += 1 if byte && byte < ASCII_LIMIT
  end
end
