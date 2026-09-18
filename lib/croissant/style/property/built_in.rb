# frozen_string_literal: true

require_relative '../../refinements/symbol'

class << Class.new
  using Croissant::Refinements::Symbol
  include Croissant::Style::Type.helper_methods

  LengthPercentage = Length | Percentage

  intrinsic = :'min-content' | :'max-content' | :'fit-content'
  color = Color | Keyword
  size = LengthPercentage | :auto | intrinsic
  max_size = LengthPercentage | :none | intrinsic
  offset = LengthPercentage | :auto
  spacing = LengthPercentage
  gap = Length | :normal
  overflow = :visible | :hidden | :clip | :scroll | :auto

  place = LengthPercentage | :top | :right | :bottom | :left | :center
  repeat = :repeat | :'repeat-x' | :'repeat-y' | :'no-repeat' | :space | :round
  decoration = :underline | :overline | :'line-through' | :blink

  sides = %w[top right bottom left]

  boxes = {
    'inset' => ['%s', 'auto', offset],
    'margin' => ['margin-%s', '0', offset],
    'padding' => ['padding-%s', '0', spacing],
    'border-color' => ['border-%s-color', 'currentcolor', color],
    'border-style' => ['border-%s-style', 'none',
                       :none | :hidden | :dotted | :dashed | :solid | :double | :groove | :ridge | :inset | :outset],
    'border-width' => ['border-%s-width', 'medium', Length | :thin | :medium | :thick]
  }.flat_map do |name, (pattern, initial, type)|
    longhands = sides.map { |side| format(pattern, side) }
    shorthand = Croissant::Style::Property::Shorthand.new(name, longhands)

    [shorthand, *longhands.map { |longhand| Croissant::Style::Property.new(longhand, initial:, shorthand:, type:) }]
  end

  Croissant::Style::Property::BUILT_IN = [
    Croissant::Style::Property.new(
      'border-collapse',
      initial: 'separate',
      inherited: true,
      type: :collapse | :separate
    ),
    Croissant::Style::Property.new(
      'border-spacing',
      initial: '0',
      inherited: true,
      type: Length | List(Length)
    ),
    Croissant::Style::Property.new(
      'caption-side',
      initial: 'top',
      inherited: true,
      type: :top | :bottom
    ),
    Croissant::Style::Property.new(
      'color',
      initial: 'canvastext',
      inherited: true,
      type: color
    ),
    Croissant::Style::Property.new(
      'direction',
      initial: 'ltr',
      inherited: true,
      type: :ltr | :rtl
    ),
    Croissant::Style::Property.new(
      'font-family',
      inherited: true,
      type: Keyword | List(Keyword)
    ),
    Croissant::Style::Property.new(
      'font-size',
      initial: 'medium',
      inherited: true,
      type: LengthPercentage | :'xx-small' | :'x-small' | :small | :medium | :large | :'x-large' |
            :'xx-large' | :'xxx-large' | :larger | :smaller
    ),
    Croissant::Style::Property.new(
      'font-style',
      initial: 'normal',
      inherited: true,
      type: :normal | :italic | :oblique
    ),
    Croissant::Style::Property.new(
      'font-variant',
      initial: 'normal',
      inherited: true,
      type: :normal | :'small-caps'
    ),
    Croissant::Style::Property.new(
      'font-weight',
      initial: 'normal',
      inherited: true,
      type: Number | :normal | :bold | :bolder | :lighter
    ),
    Croissant::Style::Property.new(
      'letter-spacing',
      initial: 'normal',
      inherited: true,
      type: gap
    ),
    Croissant::Style::Property.new(
      'line-height',
      initial: 'normal',
      inherited: true,
      type: Number | LengthPercentage | :normal
    ),
    Croissant::Style::Property.new(
      'list-style-image',
      initial: 'none',
      inherited: true,
      type: Url | :none
    ),
    Croissant::Style::Property.new(
      'list-style-position',
      initial: 'outside',
      inherited: true,
      type: :inside | :outside
    ),
    Croissant::Style::Property.new(
      'list-style-type',
      initial: 'disc',
      inherited: true,
      type: :disc | :circle | :square | :decimal | :'decimal-leading-zero' | :'lower-roman' | :'upper-roman' |
            :'lower-greek' | :'lower-latin' | :'upper-latin' | :'lower-alpha' | :'upper-alpha' | :armenian |
            :georgian | :none
    ),
    Croissant::Style::Property.new(
      'text-align',
      initial: 'start',
      inherited: true,
      type: :left | :right | :center | :justify | :start | :end | :'match-parent' | :'justify-all'
    ),
    Croissant::Style::Property.new(
      'text-indent',
      initial: '0',
      inherited: true,
      type: spacing
    ),
    Croissant::Style::Property.new(
      'text-transform',
      initial: 'none',
      inherited: true,
      type: :none | :capitalize | :uppercase | :lowercase | :'full-width' | :'full-size-kana'
    ),
    Croissant::Style::Property.new(
      'visibility',
      initial: 'visible',
      inherited: true,
      type: :visible | :hidden | :collapse
    ),
    Croissant::Style::Property.new(
      'white-space',
      initial: 'normal',
      inherited: true,
      type: :normal | :pre | :nowrap | :'pre-wrap' | :'pre-line' | :'break-spaces'
    ),
    Croissant::Style::Property.new(
      'word-spacing',
      initial: 'normal',
      inherited: true,
      type: gap
    ),

    Croissant::Style::Property.new(
      'background-color',
      initial: 'transparent',
      type: color
    ),
    Croissant::Style::Property.new(
      'background-image',
      initial: 'none',
      type: Url | Keyword
    ),
    Croissant::Style::Property.new(
      'background-position',
      initial: '0% 0%',
      type: place | List(place)
    ),
    Croissant::Style::Property.new(
      'background-repeat',
      initial: 'repeat',
      type: repeat | List(repeat)
    ),
    Croissant::Style::Property.new(
      'box-sizing',
      initial: 'content-box',
      type: :'content-box' | :'border-box'
    ),
    Croissant::Style::Property.new(
      'clear',
      initial: 'none',
      type: :none | :left | :right | :both | :'inline-start' | :'inline-end'
    ),
    Croissant::Style::Property.new(
      'display',
      initial: 'inline',
      type: :inline | :block | :'inline-block' | :'flow-root' | :flex | :'inline-flex' | :grid | :'inline-grid' |
            :contents | :none | :'list-item' | :table | :'inline-table' | :'table-row' | :'table-row-group' |
            :'table-header-group' | :'table-footer-group' | :'table-column' | :'table-column-group' |
            :'table-cell' | :'table-caption'
    ),
    Croissant::Style::Property.new(
      'float',
      initial: 'none',
      type: :none | :left | :right | :'inline-start' | :'inline-end'
    ),
    Croissant::Style::Property.new(
      'height',
      initial: 'auto',
      type: size
    ),
    Croissant::Style::Property.new(
      'max-height',
      initial: 'none',
      type: max_size
    ),
    Croissant::Style::Property.new(
      'max-width',
      initial: 'none',
      type: max_size
    ),
    Croissant::Style::Property.new(
      'min-height',
      initial: 'auto',
      type: size
    ),
    Croissant::Style::Property.new(
      'min-width',
      initial: 'auto',
      type: size
    ),
    Croissant::Style::Property.new(
      'opacity',
      initial: '1',
      type: Number | Percentage
    ),
    Croissant::Style::Property.new(
      'overflow-x',
      initial: 'visible',
      type: overflow
    ),
    Croissant::Style::Property.new(
      'overflow-y',
      initial: 'visible',
      type: overflow
    ),
    Croissant::Style::Property.new(
      'position',
      initial: 'static',
      type: :static | :relative | :absolute | :fixed | :sticky
    ),
    Croissant::Style::Property.new(
      'text-decoration-line',
      initial: 'none',
      type: :none | decoration | List(decoration)
    ),
    Croissant::Style::Property.new(
      'vertical-align',
      initial: 'baseline',
      type: LengthPercentage | :baseline | :sub | :super | :top | :'text-top' | :middle | :bottom | :'text-bottom'
    ),
    Croissant::Style::Property.new(
      'width',
      initial: 'auto',
      type: size
    ),
    Croissant::Style::Property.new(
      'z-index',
      initial: 'auto',
      type: Integer | :auto
    ),
    *boxes
  ].freeze
end
