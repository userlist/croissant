# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Croissant::Transformation::RemoveStyles do
  def process(html)
    document = Croissant::Document.parse(html)
    described_class.new.call(document)
    document.to_html
  end

  it 'should remove style elements' do
    expect(process('<style>p { color: red }</style><p>a</p>')).to eq('<p>a</p>')
  end

  it 'should remove style elements anywhere in the document' do
    html = process('<html><head><style>a{}</style></head><body><style>b{}</style><p>a</p></body></html>')

    expect(html).not_to include('<style>')
  end

  it 'should leave documents without style elements alone' do
    expect(process('<p>a</p>')).to eq('<p>a</p>')
  end

  it 'should keep the parsed stylesheets available to later transformations' do
    document = Croissant::Document.parse('<style>p { color: red }</style><p>a</p>')
    described_class.new.call(document)

    expect(document.stylesheets.map(&:to_s)).to eq(['p{color:red}'])
  end

  it 'should keep the computed styles available to later transformations' do
    document = Croissant::Document.parse('<style>p { color: red }</style><p>a</p>')
    described_class.new.call(document)
    element = document.each_element.first

    expect(document.computed_style_for(element)['color']).to eq('red')
  end
end
