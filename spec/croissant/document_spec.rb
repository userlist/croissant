# frozen_string_literal: true

require 'spec_helper'
require 'nokogiri'

RSpec.describe Croissant::Document do
  def document_for(html)
    described_class.new(Nokogiri::HTML.parse(html))
  end

  describe '.parse' do
    it 'should return a document' do
      document = described_class.parse('<html><body><p>hi</p></body></html>')

      expect(document).to be_a(described_class)
    end

    it 'should wrap a Nokogiri document' do
      document = described_class.parse('<html><body><p>hi</p></body></html>')

      expect(document.document).to be_a(Nokogiri::HTML::Document)
    end

    it 'should wrap a Nokogiri document when the string has a doctype' do
      document = described_class.parse("<!doctype html>\n<p>hi</p>")

      expect(document.document).to be_a(Nokogiri::HTML::Document)
    end

    it 'should wrap a Nokogiri fragment when the string is partial HTML' do
      document = described_class.parse('<p>hi</p>')

      expect(document.document).to be_a(Nokogiri::HTML::DocumentFragment)
    end

    it 'should not wrap partial HTML in html and body elements' do
      document = described_class.parse('<p>hi</p>')

      expect(document.document.to_html).to eq('<p>hi</p>')
    end

    it 'should parse style elements of partial HTML' do
      document = described_class.parse('<style>p { color: red }</style><p>hi</p>')

      expect(document.stylesheets.map(&:to_s)).to eq(['p{color:red}'])
    end
  end

  describe '#to_html' do
    it 'should serialize the document' do
      document = described_class.parse('<html><head></head><body><p>hi</p></body></html>')

      expect(document.to_html).to include('<html>', '<body><p>hi</p></body>')
    end

    it 'should serialize a fragment without wrapper elements' do
      document = described_class.parse('<p>hi</p>')

      expect(document.to_html).to eq('<p>hi</p>')
    end
  end

  describe '#fragment?' do
    it 'should be true for partial HTML' do
      expect(described_class.parse('<p>hi</p>')).to be_fragment
    end

    it 'should be false for a full document' do
      expect(described_class.parse('<html><body></body></html>')).not_to be_fragment
    end
  end

  describe '#style_for' do
    def element_for(html)
      document = document_for('')

      Croissant::Document::Element.new(document, Nokogiri::HTML.fragment(html).children.first)
    end

    it 'should return an element style' do
      expect(document_for('').style_for(element_for('<p></p>'))).to be_a(Croissant::Style::ElementStyle)
    end

    it 'should compile the style attribute' do
      expect(document_for('').style_for(element_for('<p style="color: red"></p>'))['color']).to eq('red')
    end

    it 'should expand shorthands' do
      expect(document_for('').style_for(element_for('<p style="margin: 1px 2px"></p>'))['margin-left']).to eq('2px')
    end

    it 'should keep important declarations' do
      expect(document_for('').style_for(element_for('<p style="color: red !important"></p>'))).to be_important('color')
    end

    it 'should not include stylesheet rules' do
      document = document_for('<html><head><style>p { color: red }</style></head></html>')

      expect(document.style_for(element_for('<p></p>'))['color']).to be_nil
    end

    it 'should be empty without a style attribute' do
      expect(document_for('').style_for(element_for('<p></p>'))).to be_empty
    end

    it 'should be empty with a blank style attribute' do
      expect(document_for('').style_for(element_for('<p style=" "></p>'))).to be_empty
    end
  end

  describe '#computed_style_for' do
    def build(html, css: 'p { color: red }')
      document = document_for("<html><head><style>#{css}</style></head><body>#{html}</body></html>")

      [document, Croissant::Document::Element.new(document, document.document.at_css('body > *'))]
    end

    def computed_for(html, css: 'p { color: red }')
      document, element = build(html, css:)
      document.computed_style_for(element)
    end

    it 'should return an element style' do
      expect(computed_for('<p></p>')).to be_a(Croissant::Style::ElementStyle)
    end

    it 'should include matching stylesheet rules' do
      expect(computed_for('<p></p>')['color']).to eq('red')
    end

    it 'should not include rules that do not match' do
      expect(computed_for('<h1></h1>')['color']).to be_nil
    end

    it 'should not include rules that cannot be inlined' do
      expect(computed_for('<p></p>', css: 'p:hover { color: red }')['color']).to be_nil
    end

    it 'should include the style attribute' do
      expect(computed_for('<p style="margin: 1px"></p>')['margin-top']).to eq('1px')
    end

    it 'should let the style attribute win over stylesheet rules' do
      expect(computed_for('<p id="a" style="color: blue"></p>', css: '#a { color: red }')['color']).to eq('blue')
    end

    it 'should let an important stylesheet rule win over the style attribute' do
      expect(computed_for('<p style="color: blue"></p>', css: 'p { color: red !important }')['color']).to eq('red')
    end

    it 'should resolve stylesheet rules by specificity' do
      expect(computed_for('<p class="a"></p>', css: 'p { color: red } .a { color: blue }')['color']).to eq('blue')
    end

    it 'should let a later rule win over an earlier equally specific one' do
      expect(computed_for('<p></p>', css: 'p { color: red } p { color: blue }')['color']).to eq('blue')
    end

    it 'should include rules from all stylesheets' do
      document = document_for(<<~HTML)
        <html>
          <head><style>p { color: red }</style></head>
          <body><style>p { margin: 1px }</style><p></p></body>
        </html>
      HTML

      element = Croissant::Document::Element.new(document, document.document.at_css('p'))

      expect(document.computed_style_for(element).to_s).to eq('color:red;margin:1px')
    end

    it 'should reflect modifications to the document' do
      document, element = build('<p></p>')
      document.computed_style_for(element)

      document.document.at_css('style').remove

      expect(document.computed_style_for(element)).to be_empty
    end

    it 'should not touch the style attribute' do
      document, element = build('<p style="color:  blue"></p>')
      document.computed_style_for(element)

      expect(element['style']).to eq('color:  blue')
    end
  end

  describe '#each_element' do
    it 'should yield document elements' do
      document = described_class.parse('<p>hi</p>')

      expect(document.each_element.to_a).to all(be_a(Croissant::Document::Element))
    end

    it 'should yield elements bound to the document' do
      document = described_class.parse('<p>hi</p>')

      expect(document.each_element.first.document).to be(document)
    end

    it 'should yield every element in document order' do
      document = described_class.parse('<div><p>hi</p><span>x</span></div><b>y</b>')

      expect(document.each_element.map(&:name)).to eq(%w[div p span b])
    end

    it 'should return an enumerator without a block' do
      expect(described_class.parse('<p>hi</p>').each_element).to be_a(Enumerator)
    end

    it 'should yield the html element of a full document' do
      document = document_for('<html><body><p>hi</p></body></html>')

      expect(document.each_element.map(&:name)).to eq(%w[html body p])
    end
  end

  describe '#head' do
    it 'should return the existing head' do
      document = document_for('<html><head><title>t</title></head><body></body></html>')

      expect(document.head.at_css('title').text).to eq('t')
    end

    it 'should create a head before the body when missing' do
      document = document_for('<html><body></body></html>')

      document.head

      expect(document.document.root.children.map(&:name)).to eq(%w[head body])
    end

    it 'should return nil for a fragment' do
      expect(described_class.parse('<p>hi</p>').head).to be_nil
    end
  end

  describe '#body' do
    it 'should return the existing body' do
      document = document_for('<html><head></head><body><p>hi</p></body></html>')

      expect(document.body.at_css('p').text).to eq('hi')
    end

    it 'should create a body after the head when missing' do
      document = described_class.new(Nokogiri::HTML::Document.parse('<html><head><title>t</title></head></html>'))

      document.body

      expect(document.document.root.children.map(&:name)).to eq(%w[head body])
    end

    it 'should create html and body for an empty document' do
      document = described_class.new(Nokogiri::HTML::Document.new)

      document.body

      expect(document.document.root.children.map(&:name)).to eq(%w[body])
    end

    it 'should return nil for a fragment' do
      expect(described_class.parse('<p>hi</p>').body).to be_nil
    end
  end

  describe '#stylesheets' do
    it 'should parse a style element into a stylesheet' do
      document = document_for('<html><head><style>p { color: red }</style></head></html>')

      expect(document.stylesheets.first).to be_a(Croissant::Stylesheet)
    end

    it 'should parse the rules of a style element' do
      document = document_for('<html><head><style>p { color: red }</style></head></html>')

      expect(document.stylesheets.first.to_s).to eq('p{color:red}')
    end

    it 'should return one stylesheet per style element in document order' do
      document = document_for(<<~HTML)
        <html>
          <head><style>p { color: red }</style></head>
          <body><style>h1 { color: blue }</style></body>
        </html>
      HTML

      expect(document.stylesheets.map(&:to_s)).to eq(['p{color:red}', 'h1{color:blue}'])
    end

    it 'should reflect modifications to the document' do
      document = document_for('<html><head><style>p { color: red }</style></head></html>')
      document.stylesheets

      document.document.at_css('style').content = 'h1 { color: blue }'

      expect(document.stylesheets.map(&:to_s)).to eq(['h1{color:blue}'])
    end

    it 'should consume style elements with a screen media attribute' do
      document = document_for('<html><head><style media="screen">p { color: red }</style></head></html>')

      expect(document.stylesheets.map(&:to_s)).to eq(['p{color:red}'])
    end

    it 'should consume style elements with an all media attribute regardless of case' do
      document = document_for('<html><head><style media="ALL">p { color: red }</style></head></html>')

      expect(document.stylesheets.map(&:to_s)).to eq(['p{color:red}'])
    end

    it 'should consume style elements with a blank media attribute' do
      document = document_for('<html><head><style media=" ">p { color: red }</style></head></html>')

      expect(document.stylesheets.map(&:to_s)).to eq(['p{color:red}'])
    end

    it 'should leave the style elements in the document' do
      document = document_for('<html><head><style>p { color: red }</style></head></html>')

      document.stylesheets

      expect(document.document.at_css('style').text).to eq('p { color: red }')
    end

    it 'should return an empty list for a document without style elements' do
      document = document_for('<html><body><p>hi</p></body></html>')

      expect(document.stylesheets).to be_empty
    end
  end
end
