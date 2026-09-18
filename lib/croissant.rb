# frozen_string_literal: true

module Croissant
  def self.process(html)
    default_pipeline.process(html)
  end

  def self.default_pipeline
    @default_pipeline ||= Croissant::Pipeline.new([
      Croissant::Transformation::Elements.new([
        Croissant::Transformation::InlineStyles.new,
        Croissant::Transformation::PresentationalAttributes.new
      ]),
      Croissant::Transformation::RemoveStyles.new,
      Croissant::Transformation::PreserveStyles.new
    ])
  end
end

require_relative 'croissant/version'
require_relative 'croissant/serializable'
require_relative 'croissant/registry'
require_relative 'croissant/stylesheet'
require_relative 'croissant/selector'
require_relative 'croissant/style'
require_relative 'croissant/document'
require_relative 'croissant/transformation'
require_relative 'croissant/pipeline'
