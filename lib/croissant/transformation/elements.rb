# frozen_string_literal: true

# Walks the document once and runs every matching element transformation on
# each element, in pipeline order.
class Croissant::Transformation::Elements < Croissant::Transformation
  attr_reader :transformations

  def initialize(transformations)
    @transformations = transformations.dup.freeze
    @index = Croissant::Selector::Index.new do |index|
      @transformations.each do |transformation|
        transformation.selectors.each { |selector| index.add(selector, transformation) }
      end
    end

    super()
  end

  def call(document)
    return if @index.empty?

    document.each_element do |element|
      transformations = @index[element.node]
      next if transformations.empty?

      # A transformation registered under several selectors runs once, at the
      # position of its first matching selector.
      transformations.uniq!

      transformations.each { |transformation| transformation.call(element) }
    end
  end
end
