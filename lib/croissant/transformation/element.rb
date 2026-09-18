# frozen_string_literal: true

class Croissant::Transformation::Element
  class << self
    def selector(*values)
      @selectors = values.flat_map { |value| parse_selector(value) }.freeze
    end

    def selectors
      @selectors ||= []
    end

    def parse_selector(value)
      parser.parse_selector_list(value)
    end

    private

    def parser
      @parser ||= Croissant::Stylesheet::Parser.new
    end
  end

  attr_reader :selectors

  def initialize(selector = nil)
    selectors = Array(selector).flat_map { |value| self.class.parse_selector(value) }

    @selectors = (selectors + self.class.selectors).freeze
  end

  def call(_element)
    raise NotImplementedError, "subclass must implement #{self.class}##{__method__}"
  end
end
