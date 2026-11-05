# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Croissant::Transformation::PreserveStyles do
  def process(html)
    document = Croissant::Document.parse(html)
    described_class.new.call(document)
    document.to_html
  end

  it 'should re-emit media at-rules' do
    html = process('<style>@media print { p { color: red } }</style><p>a</p>')

    expect(html).to eq('<style>@media print{p{color:red}}</style><p>a</p>')
  end

  it 'should not re-emit empty rule blocks' do
    html = process('<style>a:hover {} @media print { p { } } a:focus { color: red }</style><p>a</p>')

    expect(html).to eq('<style>a:focus{color:red}</style><p>a</p>')
  end

  it 'should not add a style element when only empty rule blocks need preserving' do
    html = process('<style>a:hover {} :root { }</style><p>a</p>')

    expect(html).to eq('<p>a</p>')
  end

  it 'should re-emit keyframes at-rules with their body intact' do
    css = '@keyframes spin { from { transform: rotate(0) } to { transform: rotate(360deg) } }'
    html = process("<style>#{css}</style>")

    preserved = '@keyframes spin{from { transform: rotate(0) } to { transform: rotate(360deg) }}'

    expect(html).to start_with("<style>#{preserved}</style>")
  end

  it 'should re-emit font-face and import at-rules' do
    html = process('<style>@import url(a.css); @font-face { font-family: X }</style>')

    expect(html).to start_with("<style>@import url(a.css);\n@font-face{font-family:X}</style>")
  end

  it 'should re-emit rules with dynamic pseudo-classes' do
    html = process('<style>a:hover { color: red } p { color: blue }</style>')

    expect(html).to start_with('<style>a:hover{color:red}</style>')
  end

  it 'should re-emit rules with pseudo-elements' do
    html = process('<style>p::before { content: "x" } p { color: blue }</style>')

    expect(html).to start_with('<style>p::before{content:"x"}</style>')
  end

  it 'should re-emit rules with escaped class names with their escapes intact' do
    html = process('<style>.body-content a.prose\:button:hover { color: red }</style>')

    expect(html).to start_with('<style>.body-content a.prose\:button:hover{color:red}</style>')
  end

  it 'should not re-emit inlinable rules' do
    expect(process('<style>p { color: blue } p:first-child { color: red }</style><p>a</p>')).to eq('<p>a</p>')
  end

  it 'should remove the original style elements' do
    html = process('<style>a:hover { color: red }</style><p>a</p><style>p { color: blue }</style>')

    expect(html).to eq('<style>a:hover{color:red}</style><p>a</p>')
  end

  it 'should collect rules from several style elements into one' do
    html = process('<style>a:hover { color: red }</style><style>@media print { p { color: red } }</style>')

    expect(html).to start_with("<style>a:hover{color:red}\n@media print{p{color:red}}</style>")
  end

  it 'should prepend the style element to a fragment' do
    html = process('<p>a</p><style>a:hover { color: red }</style>')

    expect(html).to start_with('<style>a:hover{color:red}</style><p>a</p>')
  end

  it 'should not escape the css' do
    html = process('<style>a > b:hover { content: "<" }</style>')

    expect(html).to start_with('<style>a > b:hover{content:"<"}</style>')
  end

  it 'should add the style element to the head of a document' do
    document = Croissant::Document.parse('<html><head><style>a:hover { color: red }</style></head><body></body></html>')
    described_class.new.call(document)

    expect(document.head.xpath('.//style').map(&:text)).to eq(['a:hover{color:red}'])
  end

  it 'should only remove the style elements when nothing needs preserving' do
    expect(process('<style>p { color: blue }</style><p>a</p>')).to eq('<p>a</p>')
  end

  it 'should not add a style element to a document without styles' do
    expect(process('<p>a</p>')).to eq('<p>a</p>')
  end
end
