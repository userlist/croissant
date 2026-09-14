# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Croissant::Document::Element do
  def build(html, css: 'p { color: red }')
    document = Croissant::Document.parse("<style>#{css}</style>#{html}")
    node = document.document.css('body *, style ~ *').first || document.document.children.last

    [document, described_class.new(document, node)]
  end

  def element_for(html, css: 'p { color: red }')
    build(html, css:).last
  end

  describe '#name' do
    it 'should return the tag name' do
      expect(element_for('<p></p>').name).to eq('p')
    end
  end

  describe '#[]' do
    it 'should read an attribute' do
      expect(element_for('<p class="a"></p>')['class']).to eq('a')
    end

    it 'should return nil for a missing attribute' do
      expect(element_for('<p></p>')['class']).to be_nil
    end
  end

  describe '#[]=' do
    it 'should write an attribute to the node' do
      element = element_for('<p></p>')
      element['width'] = '100'

      expect(element.node['width']).to eq('100')
    end
  end

  describe '#remove_attribute' do
    it 'should remove an attribute from the node' do
      element = element_for('<p class="a"></p>')
      element.remove_attribute('class')

      expect(element.node['class']).to be_nil
    end
  end

  describe '#document' do
    it 'should return the document' do
      document, element = build('<p></p>')

      expect(element.document).to be(document)
    end
  end

end
