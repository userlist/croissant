# frozen_string_literal: true

class Croissant::Style::Unit
  attr_reader :name

  def self.lookup(unit)
    return unit if unit.is_a?(self)

    registry.lookup(unit)
  end

  def self.registry # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    @registry ||= Croissant::Registry.new do |registry|
      registry.normalize { |name| name.to_s.downcase }
      registry.fallback { |name| Croissant::Style::Unit.new(name) }

      registry.register(Croissant::Style::Unit::Pixel.new)
      registry.register(Croissant::Style::Unit::Em.new)
      registry.register(Croissant::Style::Unit::Rem.new)
      registry.register(Croissant::Style::Unit::Point.new)
      registry.register(Croissant::Style::Unit::Pica.new)
      registry.register(Croissant::Style::Unit::Inch.new)
      registry.register(Croissant::Style::Unit::Centimeter.new)
      registry.register(Croissant::Style::Unit::Millimeter.new)
    end
  end

  def initialize(name)
    @name = name

    freeze
  end

  def absolutize(_value, **)
    nil
  end

  def ==(other)
    other.instance_of?(self.class) && name == other.name
  end

  def eql?(other)
    other.instance_of?(self.class) && name.eql?(other.name)
  end

  def to_sym
    name.to_sym
  end

  def to_s
    name.to_s
  end

  def to_str
    name.to_str
  end

  def inspect
    "#<#{self.class} #{name.inspect}>"
  end

  def hash
    [self.class, name].hash
  end

  def freeze
    @name.freeze

    super
  end
end

require_relative 'unit/pixel'
require_relative 'unit/em'
require_relative 'unit/rem'
require_relative 'unit/point'
require_relative 'unit/pica'
require_relative 'unit/inch'
require_relative 'unit/centimeter'
require_relative 'unit/millimeter'
