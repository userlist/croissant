# frozen_string_literal: true

Croissant::Style::Properties = Croissant::Registry.new do |registry| # rubocop:disable Metrics/BlockLength
  registry.fallback { |name| Croissant::Style::Property.new(name) }

  registry.register Croissant::Style::Property.new('border-collapse', initial: 'separate', inherited: true)
  registry.register Croissant::Style::Property.new('border-spacing', initial: '0', inherited: true)
  registry.register Croissant::Style::Property.new('caption-side', initial: 'top', inherited: true)
  registry.register Croissant::Style::Property.new('color', initial: 'canvastext', inherited: true)
  registry.register Croissant::Style::Property.new('direction', initial: 'ltr', inherited: true)
  registry.register Croissant::Style::Property.new('font-family', inherited: true)
  registry.register Croissant::Style::Property.new('font-size', initial: 'medium', inherited: true)
  registry.register Croissant::Style::Property.new('font-style', initial: 'normal', inherited: true)
  registry.register Croissant::Style::Property.new('font-variant', initial: 'normal', inherited: true)
  registry.register Croissant::Style::Property.new('font-weight', initial: 'normal', inherited: true)
  registry.register Croissant::Style::Property.new('letter-spacing', initial: 'normal', inherited: true)
  registry.register Croissant::Style::Property.new('line-height', initial: 'normal', inherited: true)
  registry.register Croissant::Style::Property.new('list-style-image', initial: 'none', inherited: true)
  registry.register Croissant::Style::Property.new('list-style-position', initial: 'outside', inherited: true)
  registry.register Croissant::Style::Property.new('list-style-type', initial: 'disc', inherited: true)
  registry.register Croissant::Style::Property.new('text-align', initial: 'start', inherited: true)
  registry.register Croissant::Style::Property.new('text-indent', initial: '0', inherited: true)
  registry.register Croissant::Style::Property.new('text-transform', initial: 'none', inherited: true)
  registry.register Croissant::Style::Property.new('visibility', initial: 'visible', inherited: true)
  registry.register Croissant::Style::Property.new('white-space', initial: 'normal', inherited: true)
  registry.register Croissant::Style::Property.new('word-spacing', initial: 'normal', inherited: true)

  registry.register Croissant::Style::Property.new('background-color', initial: 'transparent')
  registry.register Croissant::Style::Property.new('background-image', initial: 'none')
  registry.register Croissant::Style::Property.new('background-position', initial: '0% 0%')
  registry.register Croissant::Style::Property.new('background-repeat', initial: 'repeat')
  registry.register Croissant::Style::Property.new('box-sizing', initial: 'content-box')
  registry.register Croissant::Style::Property.new('clear', initial: 'none')
  registry.register Croissant::Style::Property.new('display', initial: 'inline')
  registry.register Croissant::Style::Property.new('float', initial: 'none')
  registry.register Croissant::Style::Property.new('height', initial: 'auto')
  registry.register Croissant::Style::Property.new('max-height', initial: 'none')
  registry.register Croissant::Style::Property.new('max-width', initial: 'none')
  registry.register Croissant::Style::Property.new('min-height', initial: 'auto')
  registry.register Croissant::Style::Property.new('min-width', initial: 'auto')
  registry.register Croissant::Style::Property.new('opacity', initial: '1')
  registry.register Croissant::Style::Property.new('overflow-x', initial: 'visible')
  registry.register Croissant::Style::Property.new('overflow-y', initial: 'visible')
  registry.register Croissant::Style::Property.new('position', initial: 'static')
  registry.register Croissant::Style::Property.new('text-decoration-line', initial: 'none')
  registry.register Croissant::Style::Property.new('vertical-align', initial: 'baseline')
  registry.register Croissant::Style::Property.new('width', initial: 'auto')
  registry.register Croissant::Style::Property.new('z-index', initial: 'auto')

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

    registry.register shorthand
    longhands.each { |longhand| registry.register Croissant::Style::Property.new(longhand, initial:, shorthand:) }
  end
end
