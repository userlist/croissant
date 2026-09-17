# frozen_string_literal: true

class << Class.new
  module Sugar
    refine Symbol do
      def |(other)
        Croissant::Style::Value::Union.new(self, other)
      end
    end
  end

  using Sugar

  Length = Croissant::Style::Value::Length
  Percentage = Croissant::Style::Value::Percentage
  Color = Croissant::Style::Value::Color
  Keyword = Croissant::Style::Value::Keyword
  Number = Croissant::Style::Value::Number
  Integer = Croissant::Style::Value::Integer

  LengthPercentage = Length | Percentage

  # The CSS-wide keywords are deliberately absent from every type below.
  # Property appends Value.global_type to whatever it is given, so `inherit`,
  # `initial`, `unset` and `revert` work everywhere without being named here.
  # What each type spells out is the keywords that property alone accepts.

  # <length-percentage>, which most of the box properties build on.
  intrinsic = :'min-content' | :'max-content' | :'fit-content'

  # Colour properties keep an open Keyword. Color already reads the 148 named
  # colours and `transparent`; what is left is `currentcolor` and the system
  # colours — a long, UA-dependent tail not worth enumerating to catch.
  color = Color | Keyword

  size = LengthPercentage | :auto | intrinsic
  max_size = LengthPercentage | :none | intrinsic
  offset = LengthPercentage | :auto
  spacing = LengthPercentage
  gap = Length | :normal
  border_width = Length | :thin | :medium | :thick
  fraction = Number | Percentage
  z_index = Integer | :auto
  line_height = Number | LengthPercentage | :normal

  font_size = LengthPercentage | :'xx-small' | :'x-small' | :small | :medium | :large |
              :'x-large' | :'xx-large' | :'xxx-large' | :larger | :smaller
  font_weight = Number | :normal | :bold | :bolder | :lighter
  vertical_align = LengthPercentage | :baseline | :sub | :super | :top |
                   :'text-top' | :middle | :bottom | :'text-bottom'
  background_position = LengthPercentage | :top | :right | :bottom | :left | :center
  border_style = :none | :hidden | :dotted | :dashed | :solid | :double | :groove | :ridge | :inset | :outset

  sides = %w[top right bottom left]

  boxes = {
    'inset' => ['%s', 'auto', offset],
    'margin' => ['margin-%s', '0', offset],
    'padding' => ['padding-%s', '0', spacing],
    'border-color' => ['border-%s-color', 'currentcolor', color],
    'border-style' => ['border-%s-style', 'none', border_style],
    'border-width' => ['border-%s-width', 'medium', border_width]
  }.flat_map do |name, (pattern, initial, type)|
    longhands = sides.map { |side| format(pattern, side) }
    shorthand = Croissant::Style::Property::Shorthand.new(name, longhands)

    [shorthand, *longhands.map { |longhand| Croissant::Style::Property.new(longhand, initial:, shorthand:, type:) }]
  end

  Croissant::Style::Property::BUILT_IN = [
    Croissant::Style::Property.new('border-collapse', initial: 'separate', inherited: true),
    Croissant::Style::Property.new('border-spacing', initial: '0', inherited: true, type: Length),
    Croissant::Style::Property.new('caption-side', initial: 'top', inherited: true),
    Croissant::Style::Property.new('color', initial: 'canvastext', inherited: true, type: color),
    Croissant::Style::Property.new('direction', initial: 'ltr', inherited: true),
    Croissant::Style::Property.new('font-family', inherited: true),
    Croissant::Style::Property.new('font-size', initial: 'medium', inherited: true, type: font_size),
    Croissant::Style::Property.new('font-style', initial: 'normal', inherited: true),
    Croissant::Style::Property.new('font-variant', initial: 'normal', inherited: true),
    Croissant::Style::Property.new('font-weight', initial: 'normal', inherited: true, type: font_weight),
    Croissant::Style::Property.new('letter-spacing', initial: 'normal', inherited: true, type: gap),
    Croissant::Style::Property.new('line-height', initial: 'normal', inherited: true, type: line_height),
    Croissant::Style::Property.new('list-style-image', initial: 'none', inherited: true),
    Croissant::Style::Property.new('list-style-position', initial: 'outside', inherited: true),
    Croissant::Style::Property.new('list-style-type', initial: 'disc', inherited: true),
    Croissant::Style::Property.new('text-align', initial: 'start', inherited: true),
    Croissant::Style::Property.new('text-indent', initial: '0', inherited: true, type: spacing),
    Croissant::Style::Property.new('text-transform', initial: 'none', inherited: true),
    Croissant::Style::Property.new('visibility', initial: 'visible', inherited: true),
    Croissant::Style::Property.new('white-space', initial: 'normal', inherited: true),
    Croissant::Style::Property.new('word-spacing', initial: 'normal', inherited: true, type: gap),

    Croissant::Style::Property.new('background-color', initial: 'transparent', type: color),
    Croissant::Style::Property.new('background-image', initial: 'none'),
    Croissant::Style::Property.new('background-position', initial: '0% 0%', type: background_position),
    Croissant::Style::Property.new('background-repeat', initial: 'repeat'),
    Croissant::Style::Property.new('box-sizing', initial: 'content-box'),
    Croissant::Style::Property.new('clear', initial: 'none'),
    Croissant::Style::Property.new('display', initial: 'inline'),
    Croissant::Style::Property.new('float', initial: 'none'),
    Croissant::Style::Property.new('height', initial: 'auto', type: size),
    Croissant::Style::Property.new('max-height', initial: 'none', type: max_size),
    Croissant::Style::Property.new('max-width', initial: 'none', type: max_size),
    Croissant::Style::Property.new('min-height', initial: 'auto', type: size),
    Croissant::Style::Property.new('min-width', initial: 'auto', type: size),
    Croissant::Style::Property.new('opacity', initial: '1', type: fraction),
    Croissant::Style::Property.new('overflow-x', initial: 'visible'),
    Croissant::Style::Property.new('overflow-y', initial: 'visible'),
    Croissant::Style::Property.new('position', initial: 'static'),
    Croissant::Style::Property.new('text-decoration-line', initial: 'none'),
    Croissant::Style::Property.new('vertical-align', initial: 'baseline', type: vertical_align),
    Croissant::Style::Property.new('width', initial: 'auto', type: size),
    Croissant::Style::Property.new('z-index', initial: 'auto', type: z_index),

    *boxes
  ].freeze
end
