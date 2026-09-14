# frozen_string_literal: true

class Croissant::Transformation::Element
  class << self
    def selector(*values)
      @selectors = values.flat_map { |value| parser.parse_selector_list(value) }.freeze
    end

    def selectors
      @selectors ||= []
    end

    private

    def parser
      @parser ||= Croissant::Stylesheet::Parser.new
    end
  end

  def selectors
    self.class.selectors
  end

  def call(_element)
    raise NotImplementedError, "subclass must implement #{self.class}##{__method__}"
  end
end
