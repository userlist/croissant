# frozen_string_literal: true

class Croissant::Style::Type::Color < Croissant::Style::Type
  def self.value_class
    Croissant::Style::Value::Color
  end

  HEX = /\A#(\h{3,8})\z/
  HEX_SIZES = [3, 4, 6, 8].freeze
  FUNCTIONAL = /\Argba?\(([^()]*)\)\z/i
  SEPARATOR = %r{[,/\s]+}
  CHANNEL = /\A#{Numeric::NUMBER}%?\z/
  TRANSPARENT = 'transparent'

  OPAQUE = Croissant::Style::Value::Color::OPAQUE

  private_constant :OPAQUE

  attr_reader :alpha

  def initialize(matcher = nil, alpha = nil)
    @alpha = alpha

    super(matcher)
  end

  def ==(other)
    super && alpha == other.alpha
  end
  alias eql? ==

  def hash
    [super, alpha].hash
  end

  def inspect
    return super if alpha.nil?

    "#<#{self.class} #{[*matcher&.inspect, alpha.inspect].join(' ')}>"
  end

  private

  def matches?(value)
    super && alpha?(value)
  end

  def alpha?(value)
    return true if alpha.nil?

    value.is_a?(value_class) && alpha === value.alpha # rubocop:disable Style/CaseEquality
  end

  def parse_value(input)
    hex(input) || functional(input) || named(input)
  end

  def hex(input)
    match = HEX.match(input)
    return unless match && HEX_SIZES.include?(match[1].length)

    red, green, blue, alpha = hex_channels(match[1])

    value_class.build(red, green, blue, alpha ? alpha / 255.0 : OPAQUE)
  end

  # The three and four digit forms repeat every digit (#abc is #aabbcc), which is a scale by 17.
  def hex_channels(digits)
    short = digits.length < 6
    bits = short ? 4 : 8
    mask = short ? 0x0f : 0xff
    scale = short ? 17 : 1
    packed = digits.to_i(16)
    count = short ? digits.length : digits.length / 2

    Array.new(count) { |index| ((packed >> ((count - index - 1) * bits)) & mask) * scale }
  end

  def named(input)
    name = input.to_s.downcase

    return value_class.new(0x000000, 0.0) if name == TRANSPARENT

    rgb = NAMED[name]

    value_class.new(rgb) if rgb
  end

  def functional(input)
    match = FUNCTIONAL.match(input)
    return unless match

    parts = components(match[1])
    return unless parts

    red, green, blue = parts.first(3).map { |part| channel(part) }

    value_class.build(red, green, blue, parts[3] ? fraction(parts[3]) : OPAQUE)
  end

  def components(text)
    parts = text.split(SEPARATOR).reject(&:empty?)
    return unless (3..4).cover?(parts.length) && parts.all? { |part| CHANNEL.match?(part) }

    parts
  end

  def channel(part)
    part.end_with?('%') ? part.to_f * 255 / 100 : part.to_f
  end

  def fraction(part)
    part.end_with?('%') ? part.to_f / 100 : part.to_f
  end
end

require_relative 'color/named'
