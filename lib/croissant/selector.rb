# frozen_string_literal: true

class Croissant::Selector
  include Croissant::Serializable

  SAFE_IDENTIFIER = /\A(?:--|-?[A-Za-z_[^\x00-\x7F]])[A-Za-z0-9_\-[^\x00-\x7F]]*\z/
  UNSAFE_IDENTIFIER_CHARACTER = /\A-?\K[0-9]|\A-\z|[^A-Za-z0-9_\-[^\x00-\x7F]]/
  UNSAFE_STRING_CHARACTER = /["\\\x00-\x1F\x7F]/
  CODE_POINT_ESCAPED = /[0-9\x00-\x1F\x7F]/

  def initialize
    freeze
  end

  def append_to(_buffer)
    raise NotImplementedError, "subclass must implement #{self.class}##{__method__}"
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

  private

  def safe_identifier?(identifier)
    SAFE_IDENTIFIER.match?(identifier)
  end

  def append_identifier(buffer, identifier)
    return buffer << identifier if safe_identifier?(identifier)

    buffer << identifier.gsub(UNSAFE_IDENTIFIER_CHARACTER) { escape_character(_1) }
  end

  def append_string(buffer, string)
    string = string.gsub(UNSAFE_STRING_CHARACTER) { escape_character(_1) } if UNSAFE_STRING_CHARACTER.match?(string)

    buffer << '"' << string << '"'
  end

  def escape_character(char)
    CODE_POINT_ESCAPED.match?(char) ? "\\#{char.ord.to_s(16)} " : "\\#{char}"
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
