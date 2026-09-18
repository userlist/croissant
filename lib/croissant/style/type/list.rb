# frozen_string_literal: true

class Croissant::Style::Type::List < Croissant::Style::Type
  def self.value_class
    Croissant::Style::Value::List
  end

  QUOTED = /"(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*'/
  GROUP = /\((?:[^()]|\([^()]*\))*\)/

  SEGMENTS = /(?:#{QUOTED}|#{GROUP}|[^,])+/
  TOKENS = /(?:#{QUOTED}|#{GROUP}|\S)+/

  def self.split(input, pattern = TOKENS)
    input.to_s.scan(pattern).map(&:strip).reject(&:empty?)
  end

  attr_reader :type

  def initialize(type = nil, matcher = nil)
    @type = type
    @fallback = Croissant::Style::Type::Unparsed.new

    super(matcher)
  end

  def ==(other)
    super && type == other.type
  end
  alias eql? ==

  def hash
    [super, type].hash
  end

  def inspect
    "#<#{self.class} #{[type.inspect, *matcher&.inspect].join(' ')}>"
  end

  private

  attr_reader :fallback

  def parse_value(input)
    segments = self.class.split(input, SEGMENTS)
    return build(segments, :comma) if segments.length > 1

    tokens = self.class.split(input)
    build(tokens, :space) if tokens.length > 1
  end

  def build(parts, separator)
    value_class.new(parts.map { |part| item(part) }, separator)
  end

  def item(part)
    type.parse(part) || parse(part) || fallback.parse(part)
  end
end
