# frozen_string_literal: true

class Croissant::Selector
  def initialize
    freeze
  end

  def matches?(_)
    raise NotImplementedError, "subclass must implement #{self.class}##{__method__}"
  end

  def specificity
    raise NotImplementedError, "subclass must implement #{self.class}##{__method__}"
  end

  def inlinable?
    raise NotImplementedError, "subclass must implement #{self.class}##{__method__}"
  end

  def index_key
    nil
  end

  def to_str
    to_s
  end

  def ==(other)
    other.is_a?(self.class) &&
      to_s == other.to_s
  end
  alias eql? ==

  def hash
    [self.class, to_s].hash
  end
end

require_relative 'selector/specificity'
require_relative 'selector/simple'
require_relative 'selector/compound'
require_relative 'selector/combinator'
require_relative 'selector/relative'
require_relative 'selector/pseudo_element'
require_relative 'selector/pseudo_class'
require_relative 'selector/parser'
require_relative 'selector/index'
