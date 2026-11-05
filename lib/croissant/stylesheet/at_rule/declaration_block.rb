# frozen_string_literal: true

class Croissant::Stylesheet::AtRule::DeclarationBlock < Croissant::Stylesheet::AtRule
  attr_reader :declarations

  def initialize(name:, prelude:, declarations:)
    @declarations = declarations

    super(name:, prelude:)
  end

  def append_to(buffer)
    append_prelude(buffer) << '{'
    append_each(buffer, declarations, ';')

    buffer << '}'
  end

  def ==(other)
    super && declarations == other.declarations
  end
  alias eql? ==

  def hash
    [self.class, name, prelude, declarations].hash
  end
end
