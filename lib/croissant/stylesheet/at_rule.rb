# frozen_string_literal: true

class Croissant::Stylesheet::AtRule
  attr_reader :name, :prelude

  def initialize(name:, prelude:)
    @name = name
    @prelude = prelude

    freeze
  end

  def inlinable?
    false
  end

  def ==(other)
    other.is_a?(self.class) && name == other.name && prelude == other.prelude
  end
  alias eql? ==

  def hash
    [self.class, name, prelude].hash
  end
end

require_relative 'at_rule/statement'
require_relative 'at_rule/conditional_group'
require_relative 'at_rule/block'
