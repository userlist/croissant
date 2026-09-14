# frozen_string_literal: true

module Croissant::Style::Properties
  @registry = {}

  class << self
    def [](name)
      @registry[name] || Croissant::Style::Property.new(name)
    end

    private

    def register(property)
      @registry[property.name] = property
    end
  end

  register Croissant::Style::Property.new('border-collapse', initial: 'separate', inherited: true)
  register Croissant::Style::Property.new('border-spacing', initial: '0', inherited: true)
  register Croissant::Style::Property.new('caption-side', initial: 'top', inherited: true)
  register Croissant::Style::Property.new('color', initial: 'canvastext', inherited: true)
  register Croissant::Style::Property.new('direction', initial: 'ltr', inherited: true)
  register Croissant::Style::Property.new('font-family', inherited: true)
  register Croissant::Style::Property.new('font-size', initial: 'medium', inherited: true)
  register Croissant::Style::Property.new('font-style', initial: 'normal', inherited: true)
  register Croissant::Style::Property.new('font-variant', initial: 'normal', inherited: true)
  register Croissant::Style::Property.new('font-weight', initial: 'normal', inherited: true)
  register Croissant::Style::Property.new('letter-spacing', initial: 'normal', inherited: true)
  register Croissant::Style::Property.new('line-height', initial: 'normal', inherited: true)
  register Croissant::Style::Property.new('list-style-image', initial: 'none', inherited: true)
  register Croissant::Style::Property.new('list-style-position', initial: 'outside', inherited: true)
  register Croissant::Style::Property.new('list-style-type', initial: 'disc', inherited: true)
  register Croissant::Style::Property.new('text-align', initial: 'start', inherited: true)
  register Croissant::Style::Property.new('text-indent', initial: '0', inherited: true)
  register Croissant::Style::Property.new('text-transform', initial: 'none', inherited: true)
  register Croissant::Style::Property.new('visibility', initial: 'visible', inherited: true)
  register Croissant::Style::Property.new('white-space', initial: 'normal', inherited: true)
  register Croissant::Style::Property.new('word-spacing', initial: 'normal', inherited: true)

  register Croissant::Style::Property.new('background-color', initial: 'transparent')
  register Croissant::Style::Property.new('background-image', initial: 'none')
  register Croissant::Style::Property.new('background-position', initial: '0% 0%')
  register Croissant::Style::Property.new('background-repeat', initial: 'repeat')
  register Croissant::Style::Property.new('box-sizing', initial: 'content-box')
  register Croissant::Style::Property.new('clear', initial: 'none')
  register Croissant::Style::Property.new('display', initial: 'inline')
  register Croissant::Style::Property.new('float', initial: 'none')
  register Croissant::Style::Property.new('height', initial: 'auto')
  register Croissant::Style::Property.new('max-height', initial: 'none')
  register Croissant::Style::Property.new('max-width', initial: 'none')
  register Croissant::Style::Property.new('min-height', initial: 'auto')
  register Croissant::Style::Property.new('min-width', initial: 'auto')
  register Croissant::Style::Property.new('opacity', initial: '1')
  register Croissant::Style::Property.new('overflow-x', initial: 'visible')
  register Croissant::Style::Property.new('overflow-y', initial: 'visible')
  register Croissant::Style::Property.new('position', initial: 'static')
  register Croissant::Style::Property.new('text-decoration-line', initial: 'none')
  register Croissant::Style::Property.new('vertical-align', initial: 'baseline')
  register Croissant::Style::Property.new('width', initial: 'auto')
  register Croissant::Style::Property.new('z-index', initial: 'auto')

  sides = %w[top right bottom left]

  {
    'inset' => ['%s', 'auto'],
    'margin' => ['margin-%s', '0'],
    'padding' => ['padding-%s', '0'],
    'border-color' => ['border-%s-color', 'currentcolor'],
    'border-style' => ['border-%s-style', 'none'],
    'border-width' => ['border-%s-width', 'medium']
  }.each do |name, (pattern, initial)|
    longhands = sides.map { |side| format(pattern, side) }
    shorthand = Croissant::Style::Property::Shorthand.new(name, longhands)

    register shorthand
    longhands.each { |longhand| register Croissant::Style::Property.new(longhand, initial:, shorthand:) }
  end
end
