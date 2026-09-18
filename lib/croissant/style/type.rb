# frozen_string_literal: true

class Croissant::Style::Type
  def self.parse(...)
    new.parse(...)
  end

  def self.value_class
    Croissant::Style::Value
  end

  def self.global
    @global ||= Union.new(:inherit, :initial, :unset, :revert, :'revert-layer')
  end

  def self.complete(type = nil)
    base = type ? type | global : global

    base | Unparsed.new
  end

  def self.helper_methods
    mod = Module.new
    mod.define_singleton_method(:included) { |base| base.extend(mod) }

    descendants.each { |type| define_helper(mod, type) }

    mod
  end

  def self.descendants
    subclasses.flat_map { |subclass| [subclass, *subclass.descendants] }
  end

  def self.define_helper(mod, type)
    name = type.name.split('::').last

    mod.const_set(name, type.new)
    mod.define_method(name) { |*args, **kwargs, &block| type.new(*args, **kwargs, &block) }
  end
  private_class_method :define_helper

  attr_reader :matcher

  def initialize(matcher = nil)
    @matcher = matcher

    freeze
  end

  def parse(input)
    value = parse_value(input)

    match(value)
  end

  def match(value)
    value if value && matches?(value)
  end

  def ===(input)
    !parse(input).nil?
  end

  def |(other)
    Union.new(self, other)
  end

  def ==(other)
    other.instance_of?(self.class) && matcher == other.matcher
  end
  alias eql? ==

  def hash
    [self.class, matcher].hash
  end

  def inspect
    return "#<#{self.class}>" if matcher.nil?

    "#<#{self.class} #{matcher.inspect}>"
  end

  private

  def value_class
    self.class.value_class
  end

  def matches?(value)
    return false if value.is_a?(Croissant::Style::Value) && !value.is_a?(value_class)

    matcher.nil? || matcher === value # rubocop:disable Style/CaseEquality
  end

  def parse_value(_input)
    raise NotImplementedError, "#{self.class} does not answer #parse_value"
  end
end

require_relative 'type/union'
require_relative 'type/numeric'
require_relative 'type/number'
require_relative 'type/integer'
require_relative 'type/percentage'
require_relative 'type/length'
require_relative 'type/keyword'
require_relative 'type/color'
require_relative 'type/list'
require_relative 'type/unparsed'
require_relative 'type/url'
