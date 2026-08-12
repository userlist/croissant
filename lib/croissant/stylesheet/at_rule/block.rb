# frozen_string_literal: true

class Croissant::Stylesheet::AtRule::Block < Croissant::Stylesheet::AtRule
  attr_reader :body

  def initialize(name:, prelude:, body:)
    @body = body

    super(name:, prelude:)
  end

  def to_s
    prefix = prelude.empty? ? "@#{name}" : "@#{name} #{prelude}"

    "#{prefix}{#{body}}"
  end

  def ==(other)
    super && body == other.body
  end
  alias eql? ==

  def hash
    [self.class, name, prelude, body].hash
  end
end
