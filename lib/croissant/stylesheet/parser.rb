# frozen_string_literal: true

require 'strscan'

class Croissant::Stylesheet::Parser # rubocop:disable Metrics/ClassLength
  HTML_COMMENT = /<!--|-->/
  IMPORTANT = /!\s*important\s*\z/i

  AT_RULE_NAME = /[\w-]*/
  CONDITIONAL_GROUP_NAMES = %w[media supports].freeze
  WHITESPACE = /\s+/
  COMMENT_OPEN = %r{/\*}
  COMMENT_CLOSE = %r{\*/}

  QUOTED_DOUBLE = /(?:\\.|[^\\"])*"/m
  QUOTED_SINGLE = /(?:\\.|[^\\'])*'/m
  PAREN_SPECIALS = /['"()]/
  BRACKET_SPECIALS = /['"\[\]]/

  PRELUDE_BOUNDARY = %r{[\{;\}'"(\[/]}
  BLOCK_BOUNDARY = %r{[\}'"(\[/]}
  RULE_BOUNDARY = %r{[\{\}'"(\[/]}
  DECLARATION_BOUNDARY = %r{[;'"(\[/]}
  SELECTOR_BOUNDARY = %r{[,'"(\[/]}

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

  def self.parse(content)
    new.parse(content)
  end

  def self.parse_attribute(content)
    new.parse_attribute(content)
  end

  def self.parse_selector(content)
    new.parse_selector(content)
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
    rules << at_rule unless name.empty?
  end

  def build_at_rule(scanner, name, prelude, terminator)
    return Croissant::Stylesheet::AtRule::Statement.new(name:, prelude:) unless terminator == LEFT_BRACE

    if CONDITIONAL_GROUP_NAMES.include?(name)
      rules = parse_rule_list(scanner, nested: true)

      Croissant::Stylesheet::AtRule::ConditionalGroup.new(name:, prelude:, rules:)
    else
      Croissant::Stylesheet::AtRule::Block.new(name:, prelude:, body: scan_raw_block(scanner).strip)
    end
  end

  def consume_rule(scanner, rules)
    prelude, terminator = scan_prelude(scanner)

    consume_declaration_block(scanner, prelude, rules) if terminator == LEFT_BRACE
  end

  def consume_declaration_block(scanner, prelude, rules)
    block, _terminator = scan_block_body(scanner)
    declarations = parse_declarations(block)

    split_segments(prelude).each do |segment|
      selector = parse_selector(segment)
      next unless selector

      rules << Croissant::Stylesheet::Rule.new(selector:, declarations:)
    end
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

    segments << scan_selector(scanner).first until scanner.eos?

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
    when DOUBLE_QUOTE then scanner.skip(QUOTED_DOUBLE) || scanner.terminate
    when SINGLE_QUOTE then scanner.skip(QUOTED_SINGLE) || scanner.terminate
    when LEFT_PAREN then advance_balanced(scanner, LEFT_PAREN, RIGHT_PAREN, PAREN_SPECIALS)
    else advance_balanced(scanner, LEFT_BRACKET, RIGHT_BRACKET, BRACKET_SPECIALS)
    end
  end

  def advance_balanced(scanner, open, close, specials) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength
    string = scanner.string
    depth = 1

    while depth.positive?
      return scanner.terminate unless scanner.skip_until(specials)

      case string.getbyte(scanner.pos - 1)
      when open then depth += 1
      when close then depth -= 1
      when DOUBLE_QUOTE then scanner.skip(QUOTED_DOUBLE) || scanner.terminate
      when SINGLE_QUOTE then scanner.skip(QUOTED_SINGLE) || scanner.terminate
      end
    end
  end
end
