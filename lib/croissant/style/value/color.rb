# frozen_string_literal: true

class Croissant::Style::Value::Color < Croissant::Style::Value
  OPAQUE = 1.0

  attr_reader :alpha

  class << self
    def build(red, green, blue, alpha = OPAQUE)
      new((byte(red) << 16) | (byte(green) << 8) | byte(blue), alpha)
    end

    private

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
