# frozen_string_literal: true

class Croissant::Stylesheet
  include Croissant::Serializable

  attr_reader :rules

  def initialize(rules)
    @rules = rules

    freeze
  end

  def append_to(buffer)
    append_each(buffer, rules, "\n")
  end

  def ==(other)
    other.is_a?(self.class) && rules == other.rules
  end
  alias eql? ==

  def hash
    [self.class, rules].hash
  end
end

require_relative 'stylesheet/parser'
require_relative 'stylesheet/declaration'
require_relative 'stylesheet/property'
require_relative 'stylesheet/rule'
require_relative 'stylesheet/at_rule'
