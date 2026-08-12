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

    it 'should compose partial HTML with the inliner' do
      document = described_class.parse('<style>p { color: red }</style><p>hi</p>')

      Croissant::Style::Inliner.new.inline(document)

      expect(document.document.at_css('p')['style']).to eq('color:red')
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

    it 'should compose with the inliner' do
      document = document_for('<html><head><style>p { color: red }</style></head><body><p>hi</p></body></html>')

      Croissant::Style::Inliner.new.inline(document)

      expect(document.document.at_css('p')['style']).to eq('color:red')
    end
  end
end
