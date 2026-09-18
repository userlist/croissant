# frozen_string_literal: true

class Croissant::Stylesheet::Rule
  include Croissant::Serializable

  attr_reader :selector, :declarations, :specificity

  def initialize(declarations:, selector: nil, specificity: nil)
    raise ArgumentError, 'selector and specificity cannot both be nil' if selector.nil? && specificity.nil?

    @selector = selector
    @declarations = declarations
    @specificity = specificity || selector.specificity

    freeze
  end

  def append_to(buffer)
    buffer << selector.to_s << '{'
    append_each(buffer, declarations, ';')

    buffer << '}'
  end

  def inlinable?
    selector.nil? || selector.inlinable?
  end

  def ==(other)
    other.is_a?(self.class) &&
      selector == other.selector &&
      declarations == other.declarations &&
      specificity == other.specificity
  end
  alias eql? ==

  def hash
    [self.class, selector, declarations, specificity].hash
  end
end
