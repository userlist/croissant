# frozen_string_literal: true

require_relative '../refinements/symbol'

class Croissant::Transformation::PresentationalAttributes < Croissant::Transformation::Element
  using Croissant::Refinements::Symbol
  include Croissant::Style::Type.helper_methods

  def self.build_default_attributes(directive) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    {
      'h1' => { 'text-align' => ['align', :left | :center | :right | :justify] },
      'h2' => { 'text-align' => ['align', :left | :center | :right | :justify] },
      'h3' => { 'text-align' => ['align', :left | :center | :right | :justify] },
      'h4' => { 'text-align' => ['align', :left | :center | :right | :justify] },
      'h5' => { 'text-align' => ['align', :left | :center | :right | :justify] },
      'h6' => { 'text-align' => ['align', :left | :center | :right | :justify] },
      'p' => { 'text-align' => ['align', :left | :center | :right | :justify] },
      'div' => { 'text-align' => ['align', :left | :center | :right | :justify] },
      'blockquote' => { 'text-align' => ['align', :left | :center | :right | :justify] },
      'body' => { 'background-color' => ['bgcolor', Color(nil, 1)] },
      'table' => {
        "#{directive}align" => ['align', :left | :center | :right],
        'background-color' => ['bgcolor', Color(nil, 1)],
        'background-image' => ['background', Url],
        "#{directive}width" => ['width', Number(0..) | Length(0..) | Percentage(0..)],
        "#{directive}height" => ['height', Number(0..) | Length(0..) | Percentage(0..)],
        "#{directive}cellpadding" => ['cellpadding', Number(0..) | Length(0..)],
        "#{directive}cellspacing" => ['cellspacing', Number(0..) | Length(0..)]
      },
      'tr' => {
        'text-align' => ['align', :left | :center | :right | :justify],
        'background-color' => ['bgcolor', Color(nil, 1)],
        "#{directive}height" => ['height', Number(0..) | Length(0..) | Percentage(0..)]
      },
      'th' => {
        'text-align' => ['align', :left | :center | :right | :justify],
        'background-color' => ['bgcolor', Color(nil, 1)],
        'vertical-align' => ['valign', :top | :middle | :bottom | :baseline],
        "#{directive}width" => ['width', Number(0..) | Length(0..) | Percentage(0..)],
        "#{directive}height" => ['height', Number(0..) | Length(0..) | Percentage(0..)]
      },
      'td' => {
        'text-align' => ['align', :left | :center | :right | :justify],
        'background-color' => ['bgcolor', Color(nil, 1)],
        'vertical-align' => ['valign', :top | :middle | :bottom | :baseline],
        "#{directive}width" => ['width', Number(0..) | Length(0..) | Percentage(0..)],
        "#{directive}height" => ['height', Number(0..) | Length(0..) | Percentage(0..)]
      },
      'img' => {
        'float' => ['align', :left | :right],
        "#{directive}width" => ['width', Number(0..) | Length(0..) | Percentage(0..)],
        "#{directive}height" => ['height', Number(0..) | Length(0..) | Percentage(0..)]
      }
    }
  end

  attr_reader :attributes

  def initialize(attributes = nil, directive: '-croissant-')
    @directive = directive
    @attributes = attributes || self.class.build_default_attributes(directive)
    @selector = @attributes.keys

    super(@attributes.keys)
  end

  def call(element)
    properties = attributes[element.name]
    return unless properties

    original = element.style
    style = convert(element, properties, original)

    element.style = style unless style.equal?(original)
  end

  private

  def convert(element, properties, style)
    properties.each do |property, (attribute, type)|
      next unless (declared = style[property])

      write(element, attribute, type.parse(declared)&.to_html)
      style = style.delete(property) if @directive && property.start_with?(@directive)
    end

    style
  end

  def write(element, attribute, value)
    element[attribute] = value if value && element[attribute].nil?
  end
end
