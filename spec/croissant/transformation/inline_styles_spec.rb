# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Croissant::Transformation::InlineStyles do
  def process(html)
    document = Croissant::Document.parse(html)
    Croissant::Transformation::Elements.new([described_class.new]).call(document)
    document.document.xpath('.//style').each(&:remove)
    document.to_html
  end

  it 'should match every element' do
    expect(described_class.selectors.map(&:to_s)).to eq(['*'])
  end

  it 'should inline matching rules' do
    expect(process('<style>p { color: red }</style><p>a</p>')).to eq('<p style="color:red">a</p>')
  end

  it 'should leave elements without matching rules alone' do
    expect(process('<style>p { color: red }</style><h1>a</h1>')).to eq('<h1>a</h1>')
  end

  it 'should normalize the style attribute without matching rules' do
    html = process('<style>p { color: red }</style><h1 style="color:  blue">a</h1>')

    expect(html).to eq('<h1 style="color:blue">a</h1>')
  end

  it 'should normalize the style attribute when it already holds the computed style' do
    html = process('<style>p { color: red }</style><p style="color:  red">a</p>')

    expect(html).to eq('<p style="color:red">a</p>')
  end

  it 'should resolve the cascade by specificity' do
    html = process('<style>.a { color: blue } p { color: red }</style><p class="a">a</p>')

    expect(html).to eq('<p class="a" style="color:blue">a</p>')
  end

  it 'should resolve equally specific rules by source order' do
    html = process('<style>p { color: red } p { color: blue }</style><p>a</p>')

    expect(html).to eq('<p style="color:blue">a</p>')
  end

  it 'should let the existing style attribute win' do
    html = process('<style>#a { color: red }</style><p id="a" style="color: blue">a</p>')

    expect(html).to eq('<p id="a" style="color:blue">a</p>')
  end

  it 'should let an important rule win over the style attribute' do
    html = process('<style>p { color: red !important }</style><p style="color: blue">a</p>')

    expect(html).to eq('<p style="color:red !important">a</p>')
  end

  it 'should merge declarations from several rules and the style attribute' do
    html = process('<style>p { margin: 1px } .a { padding: 2px }</style><p class="a" style="color: red">a</p>')

    expect(html).to eq('<p class="a" style="margin:1px;padding:2px;color:red">a</p>')
  end

  it 'should merge longhands into a shorthand' do
    html = process('<style>p { margin: 1px } .a { margin-top: 5px }</style><p class="a">a</p>')

    expect(html).to eq('<p class="a" style="margin:5px 1px 1px">a</p>')
  end

  it 'should inline rules from several style elements' do
    html = process('<style>p { color: red }</style><style>p { margin: 1px }</style><p>a</p>')

    expect(html).to eq('<p style="color:red;margin:1px">a</p>')
  end

  it 'should not inline rules with pseudo-elements' do
    expect(process('<style>p::before { content: "x" }</style><p>a</p>')).to eq('<p>a</p>')
  end

  it 'should not inline rules with dynamic pseudo-classes' do
    expect(process('<style>p:hover { color: red }</style><p>a</p>')).to eq('<p>a</p>')
  end

  it 'should inline rules with structural pseudo-classes' do
    html = process('<style>p:first-child { color: red }</style><div><p>a</p><p>b</p></div>')

    expect(html.delete("\n")).to eq('<div><p style="color:red">a</p><p>b</p></div>')
  end
end
