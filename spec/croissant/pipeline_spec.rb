# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Croissant::Pipeline do
  describe '#process' do
    def process(html)
      Croissant.default_pipeline.process(html)
    end

    it 'should inline styles and remove the style element' do
      expect(process('<style>p { color: red }</style><p>a</p>')).to eq('<p style="color:red">a</p>')
    end

    it 'should preserve non-inlinable rules in a new style element' do
      html = process('<style>p { color: red } a:hover { color: blue }</style><p>a</p>')

      expect(html).to eq('<style>a:hover{color:blue}</style><p style="color:red">a</p>')
    end

    context 'with a full document' do
      let(:html) do
        process(<<~HTML)
          <!doctype html>
          <html>
            <head><style>p { color: red } a:hover { color: blue }</style></head>
            <body><p>a</p></body>
          </html>
        HTML
      end

      it 'should inline and preserve styles' do
        expect(html).to include('<style>a:hover{color:blue}</style>', '<p style="color:red">a</p>')
      end

      it 'should remove the original style element' do
        expect(html).not_to include('<style>p { color: red }')
      end
    end

    context 'with an invalid selector' do
      let(:css) { 'div: p { color: red } a, b: hover { color: blue }' }
      let(:html) { process("<style>#{css}</style><div><p>a</p><a>b</a></div>") }

      it 'should not inline it, nor the other selectors in its list' do
        expect(html).not_to include('style="')
      end

      it 'should preserve the rules as written' do
        expect(html).to start_with("<style>div: p{color:red}\na, b: hover{color:blue}</style>")
      end
    end

    context 'with a :root rule' do
      let(:html) do
        process(<<~HTML)
          <!doctype html>
          <html>
            <head><style>:root { --brand: red; color: blue } p { color: red }</style></head>
            <body><p>a</p></body>
          </html>
        HTML
      end

      it 'should not inline the rule into the html element' do
        expect(html).to include('<html>')
      end

      it 'should preserve the rule in a style element' do
        expect(html).to include('<style>:root{--brand:red;color:blue}</style>')
      end

      it 'should still inline the other rules' do
        expect(html).to include('<p style="color:red">a</p>')
      end
    end

    it 'should leave html without styles untouched' do
      expect(process('<p>a</p>')).to eq('<p>a</p>')
    end

    it 'should return a string' do
      expect(process('<p>a</p>')).to be_a(String)
    end

    context 'when regressing media queries' do
      let(:css) { '@media (max-width: 600px) { .col { display: block } } .col { display: inline }' }
      let(:html) { process("<style>#{css}</style><div class=\"col\">a</div>") }

      it 'should never inline rules from inside a media query' do
        expect(html).to include('<div class="col" style="display:inline">a</div>')
      end

      it 'should preserve the media query' do
        expect(html).to start_with('<style>@media (max-width: 600px){.col{display:block}}</style>')
      end
    end

    context 'when regressing keyframes' do
      let(:css) { '@keyframes spin { from { opacity: 0 } to { opacity: 1 } } p { animation: spin 1s }' }
      let(:html) { process("<style>#{css}</style><p>a</p>") }

      it 'should preserve the keyframes intact' do
        expect(html).to start_with('<style>@keyframes spin{from { opacity: 0 } to { opacity: 1 }}</style>')
      end

      it 'should inline the rule referencing the animation' do
        expect(html).to end_with('<p style="animation:spin 1s">a</p>')
      end
    end
  end

  describe '#transform' do
    it 'should run the transformations against a document' do
      document = Croissant::Document.parse('<style>p { color: red }</style><p>a</p>')

      Croissant.default_pipeline.transform(document)

      expect(document.to_html).to eq('<p style="color:red">a</p>')
    end

    it 'should return the document' do
      document = Croissant::Document.parse('<p>a</p>')

      expect(described_class.new([]).transform(document)).to be(document)
    end

    it 'should run the transformations in order' do
      calls = []
      transformations = %i[first second].map do |name|
        Class.new(Croissant::Transformation) { define_method(:call) { |_document| calls << name } }.new
      end

      described_class.new(transformations).transform(Croissant::Document.parse('<p>a</p>'))

      expect(calls).to eq(%i[first second])
    end
  end

  describe '#transformations' do
    it 'should return a copy' do
      transformations = [Croissant::Transformation::RemoveStyles.new]
      pipeline = described_class.new(transformations)
      transformations.clear

      expect(pipeline.transformations.size).to eq(1)
    end

    it 'should return a frozen list' do
      expect(described_class.new([]).transformations).to be_frozen
    end
  end

  describe '#freeze' do
    it 'should be frozen after initialization' do
      expect(described_class.new([])).to be_frozen
    end
  end
end
