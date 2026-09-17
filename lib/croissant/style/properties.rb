# frozen_string_literal: true

Croissant::Style::Properties = Croissant::Registry.new do |registry| # rubocop:disable Metrics/BlockLength
  registry.fallback { |name| Croissant::Style::Property.new(name) }

  # The value types each property wants tried, in order. A type only narrows
  # the reading — nothing here rejects a value, so a property that meets
  # something unexpected still keeps it verbatim.
  #
  # Colour first for colour properties is the whole point: `red` is both a
  # named colour and a plain identifier, and only the property can say which.
  # The generic chain, having no property to ask, reads it as a keyword.
  color = Croissant::Style::Value::Color | Croissant::Style::Value::Keyword
  length = Croissant::Style::Value::Length | Croissant::Style::Value::Percentage | Croissant::Style::Value::Keyword
  number = Croissant::Style::Value::Number | Croissant::Style::Value::Keyword
  fraction = Croissant::Style::Value::Number | Croissant::Style::Value::Percentage

  # `line-height: 1.5` is a multiplier rather than a length, which is the
  # property that made a single generic parser impossible in the first place.
  line_height = Croissant::Style::Value::Number | length

  registry.register Croissant::Style::Property.new('border-collapse', initial: 'separate', inherited: true)
  registry.register Croissant::Style::Property.new('border-spacing', initial: '0', inherited: true, type: length)
  registry.register Croissant::Style::Property.new('caption-side', initial: 'top', inherited: true)
  registry.register Croissant::Style::Property.new('color', initial: 'canvastext', inherited: true, type: color)
  registry.register Croissant::Style::Property.new('direction', initial: 'ltr', inherited: true)
  registry.register Croissant::Style::Property.new('font-family', inherited: true)
  registry.register Croissant::Style::Property.new('font-size', initial: 'medium', inherited: true, type: length)
  registry.register Croissant::Style::Property.new('font-style', initial: 'normal', inherited: true)
  registry.register Croissant::Style::Property.new('font-variant', initial: 'normal', inherited: true)
  registry.register Croissant::Style::Property.new('font-weight', initial: 'normal', inherited: true, type: number)
  registry.register Croissant::Style::Property.new('letter-spacing', initial: 'normal', inherited: true, type: length)
  registry.register Croissant::Style::Property.new('line-height', initial: 'normal', inherited: true, type: line_height)
  registry.register Croissant::Style::Property.new('list-style-image', initial: 'none', inherited: true)
  registry.register Croissant::Style::Property.new('list-style-position', initial: 'outside', inherited: true)
  registry.register Croissant::Style::Property.new('list-style-type', initial: 'disc', inherited: true)
  registry.register Croissant::Style::Property.new('text-align', initial: 'start', inherited: true)
  registry.register Croissant::Style::Property.new('text-indent', initial: '0', inherited: true, type: length)
  registry.register Croissant::Style::Property.new('text-transform', initial: 'none', inherited: true)
  registry.register Croissant::Style::Property.new('visibility', initial: 'visible', inherited: true)
  registry.register Croissant::Style::Property.new('white-space', initial: 'normal', inherited: true)
  registry.register Croissant::Style::Property.new('word-spacing', initial: 'normal', inherited: true, type: length)

  registry.register Croissant::Style::Property.new('background-color', initial: 'transparent', type: color)
  registry.register Croissant::Style::Property.new('background-image', initial: 'none')
  registry.register Croissant::Style::Property.new('background-position', initial: '0% 0%', type: length)
  registry.register Croissant::Style::Property.new('background-repeat', initial: 'repeat')
  registry.register Croissant::Style::Property.new('box-sizing', initial: 'content-box')
  registry.register Croissant::Style::Property.new('clear', initial: 'none')
  registry.register Croissant::Style::Property.new('display', initial: 'inline')
  registry.register Croissant::Style::Property.new('float', initial: 'none')
  registry.register Croissant::Style::Property.new('height', initial: 'auto', type: length)
  registry.register Croissant::Style::Property.new('max-height', initial: 'none', type: length)
  registry.register Croissant::Style::Property.new('max-width', initial: 'none', type: length)
  registry.register Croissant::Style::Property.new('min-height', initial: 'auto', type: length)
  registry.register Croissant::Style::Property.new('min-width', initial: 'auto', type: length)
  registry.register Croissant::Style::Property.new('opacity', initial: '1', type: fraction)
  registry.register Croissant::Style::Property.new('overflow-x', initial: 'visible')
  registry.register Croissant::Style::Property.new('overflow-y', initial: 'visible')
  registry.register Croissant::Style::Property.new('position', initial: 'static')
  registry.register Croissant::Style::Property.new('text-decoration-line', initial: 'none')
  registry.register Croissant::Style::Property.new('vertical-align', initial: 'baseline', type: length)
  registry.register Croissant::Style::Property.new('width', initial: 'auto', type: length)
  registry.register Croissant::Style::Property.new('z-index', initial: 'auto', type: number)

  sides = %w[top right bottom left]

  {
    'inset' => ['%s', 'auto', length],
    'margin' => ['margin-%s', '0', length],
    'padding' => ['padding-%s', '0', length],
    'border-color' => ['border-%s-color', 'currentcolor', color],
    'border-style' => ['border-%s-style', 'none', nil],
    'border-width' => ['border-%s-width', 'medium', length]
  }.each do |name, (pattern, initial, type)|
    longhands = sides.map { |side| format(pattern, side) }
    shorthand = Croissant::Style::Property::Shorthand.new(name, longhands)

    registry.register shorthand

    longhands.each do |longhand|
      registry.register Croissant::Style::Property.new(longhand, initial:, shorthand:, type:)
    end
  end
end
