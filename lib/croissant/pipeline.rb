# frozen_string_literal: true

class Croissant::Pipeline
  attr_reader :transformations

  def initialize(transformations)
    @transformations = transformations.dup.freeze

    freeze
  end

  def process(html)
    document = Croissant::Document.parse(html)

    transform(document).to_html
  end

  def transform(document)
    transformations.each { |transformation| transformation.call(document) }

    document
  end
end
