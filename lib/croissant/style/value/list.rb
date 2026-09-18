# frozen_string_literal: true

class Croissant::Style::Value::List < Croissant::Style::Value
  include Enumerable

  SEPARATORS = { comma: ', ', space: ' ' }.freeze

  attr_reader :separator

  def initialize(values, separator = :space)
    @separator = separator

    super(values)
  end

  def each(&)
    return enum_for(__method__) unless block_given?

    value.each(&)

    self
  end

  def absolutize(**context)
    self.class.new(map { |item| item.absolutize(**context) }, separator)
  end

  def to_s
    to_a.join(SEPARATORS.fetch(separator))
  end

  def ==(other)
    return super unless other.instance_of?(self.class)

    super && separator == other.separator
  end

  def eql?(other)
    super && separator.eql?(other.separator)
  end

  def hash
    [super, separator].hash
  end

  def inspect
    "#<#{self.class} #{value.inspect} #{separator.inspect}>"
  end
end
