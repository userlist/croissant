# frozen_string_literal: true

class Croissant::Style::Value::Color < Croissant::Style::Value
  HEX = /\A#(\h+)\z/
  FUNCTIONAL = /\Argba?\(([^()]*)\)\z/i
  SEPARATOR = %r{[,/\s]+}
  CHANNEL = /\A[-+]?(?:\d+(?:\.\d+)?|\.\d+)%?\z/
  OPAQUE = 1.0
  TRANSPARENT = 'transparent'

  attr_reader :alpha

  class << self
    def parse(input)
      hex(input) || functional(input) || named(input)
    end

    def build(red, green, blue, alpha = OPAQUE)
      new((byte(red) << 16) | (byte(green) << 8) | byte(blue), alpha)
    end

    private

    def hex(input)
      match = HEX.match(input)
      return unless match && [3, 4, 6, 8].include?(match[1].length)

      digits = match[1]
      digits = digits.gsub(/\h/) { |digit| digit * 2 } if digits.length < 6
      red, green, blue, alpha = digits.scan(/\h{2}/).map { |pair| pair.to_i(16) }

      build(red, green, blue, alpha ? alpha / 255.0 : OPAQUE)
    end

    def named(input)
      name = input.downcase

      return new(0x000000, 0.0) if name == TRANSPARENT

      rgb = NAMED[name]

      new(rgb) if rgb
    end

    def functional(input)
      match = FUNCTIONAL.match(input)
      return unless match

      parts = components(match[1])
      return unless parts

      red, green, blue = parts.first(3).map { |part| channel(part) }

      build(red, green, blue, parts[3] ? fraction(parts[3]) : OPAQUE)
    end

    def components(text)
      parts = text.split(SEPARATOR).reject(&:empty?)
      return unless (3..4).cover?(parts.length) && parts.all? { |part| CHANNEL.match?(part) }

      parts
    end

    # A channel is 0-255, or a percentage of it.
    def channel(part)
      part.end_with?('%') ? part.to_f * 255 / 100 : part.to_f
    end

    def fraction(part)
      part.end_with?('%') ? part.to_f / 100 : part.to_f
    end

    def byte(component)
      component.round.clamp(0, 255)
    end
  end

  def initialize(rgb, alpha = OPAQUE)
    @alpha = alpha.to_f.clamp(0.0, OPAQUE)

    super(rgb)
  end

  def red
    (value >> 16) & 0xff
  end

  def green
    (value >> 8) & 0xff
  end

  def blue
    value & 0xff
  end

  def opaque?
    alpha == OPAQUE
  end

  def to_s
    return format('#%<red>02x%<green>02x%<blue>02x', red:, green:, blue:) if opaque?

    "rgba(#{red}, #{green}, #{blue}, #{alpha_text})"
  end

  def ==(other)
    return super unless other.instance_of?(self.class)

    super && alpha == other.alpha
  end

  def eql?(other)
    super && alpha.eql?(other.alpha)
  end

  def hash
    [super, alpha].hash
  end

  def inspect
    format('#<%<class>s 0x%<rgb>06x %<alpha>s>', class: self.class, rgb: value, alpha: alpha.inspect)
  end

  private

  def alpha_text
    rounded = alpha.round(3)

    (rounded % 1).zero? ? rounded.to_i.to_s : rounded.to_s
  end
end

require_relative 'color/named'
