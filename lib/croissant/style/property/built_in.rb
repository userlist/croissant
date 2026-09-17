# frozen_string_literal: true

color = Croissant::Style::Value::Color | Croissant::Style::Value::Keyword
length = Croissant::Style::Value::Length | Croissant::Style::Value::Percentage | Croissant::Style::Value::Keyword
number = Croissant::Style::Value::Number | Croissant::Style::Value::Keyword
fraction = Croissant::Style::Value::Number | Croissant::Style::Value::Percentage

line_height = Croissant::Style::Value::Number | length

sides = %w[top right bottom left]

boxes = {
  'inset' => ['%s', 'auto', length],
  'margin' => ['margin-%s', '0', length],
  'padding' => ['padding-%s', '0', length],
  'border-color' => ['border-%s-color', 'currentcolor', color],
  'border-style' => ['border-%s-style', 'none', nil],
  'border-width' => ['border-%s-width', 'medium', length]
}.flat_map do |name, (pattern, initial, type)|
  longhands = sides.map { |side| format(pattern, side) }
  shorthand = Croissant::Style::Property::Shorthand.new(name, longhands)

  [shorthand, *longhands.map { |longhand| Croissant::Style::Property.new(longhand, initial:, shorthand:, type:) }]
end

Croissant::Style::Property::BUILT_IN = [
  Croissant::Style::Property.new('border-collapse', initial: 'separate', inherited: true),
  Croissant::Style::Property.new('border-spacing', initial: '0', inherited: true, type: length),
  Croissant::Style::Property.new('caption-side', initial: 'top', inherited: true),
  Croissant::Style::Property.new('color', initial: 'canvastext', inherited: true, type: color),
  Croissant::Style::Property.new('direction', initial: 'ltr', inherited: true),
  Croissant::Style::Property.new('font-family', inherited: true),
  Croissant::Style::Property.new('font-size', initial: 'medium', inherited: true, type: length),
  Croissant::Style::Property.new('font-style', initial: 'normal', inherited: true),
  Croissant::Style::Property.new('font-variant', initial: 'normal', inherited: true),
  Croissant::Style::Property.new('font-weight', initial: 'normal', inherited: true, type: number),
  Croissant::Style::Property.new('letter-spacing', initial: 'normal', inherited: true, type: length),
  Croissant::Style::Property.new('line-height', initial: 'normal', inherited: true, type: line_height),
  Croissant::Style::Property.new('list-style-image', initial: 'none', inherited: true),
  Croissant::Style::Property.new('list-style-position', initial: 'outside', inherited: true),
  Croissant::Style::Property.new('list-style-type', initial: 'disc', inherited: true),
  Croissant::Style::Property.new('text-align', initial: 'start', inherited: true),
  Croissant::Style::Property.new('text-indent', initial: '0', inherited: true, type: length),
  Croissant::Style::Property.new('text-transform', initial: 'none', inherited: true),
  Croissant::Style::Property.new('visibility', initial: 'visible', inherited: true),
  Croissant::Style::Property.new('white-space', initial: 'normal', inherited: true),
  Croissant::Style::Property.new('word-spacing', initial: 'normal', inherited: true, type: length),

  Croissant::Style::Property.new('background-color', initial: 'transparent', type: color),
  Croissant::Style::Property.new('background-image', initial: 'none'),
  Croissant::Style::Property.new('background-position', initial: '0% 0%', type: length),
  Croissant::Style::Property.new('background-repeat', initial: 'repeat'),
  Croissant::Style::Property.new('box-sizing', initial: 'content-box'),
  Croissant::Style::Property.new('clear', initial: 'none'),
  Croissant::Style::Property.new('display', initial: 'inline'),
  Croissant::Style::Property.new('float', initial: 'none'),
  Croissant::Style::Property.new('height', initial: 'auto', type: length),
  Croissant::Style::Property.new('max-height', initial: 'none', type: length),
  Croissant::Style::Property.new('max-width', initial: 'none', type: length),
  Croissant::Style::Property.new('min-height', initial: 'auto', type: length),
  Croissant::Style::Property.new('min-width', initial: 'auto', type: length),
  Croissant::Style::Property.new('opacity', initial: '1', type: fraction),
  Croissant::Style::Property.new('overflow-x', initial: 'visible'),
  Croissant::Style::Property.new('overflow-y', initial: 'visible'),
  Croissant::Style::Property.new('position', initial: 'static'),
  Croissant::Style::Property.new('text-decoration-line', initial: 'none'),
  Croissant::Style::Property.new('vertical-align', initial: 'baseline', type: length),
  Croissant::Style::Property.new('width', initial: 'auto', type: length),
  Croissant::Style::Property.new('z-index', initial: 'auto', type: number),

  *boxes
].freeze
