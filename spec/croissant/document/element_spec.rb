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

  describe '#style' do
    it 'should parse the style attribute' do
      expect(element_for('<p style="color: blue"></p>').style['color']).to eq('blue')
    end

    it 'should not include stylesheet rules' do
      expect(element_for('<p></p>').style['color']).to be_nil
    end

    it 'should be empty without a style attribute' do
      expect(element_for('<p></p>').style).to be_empty
    end

    it 'should be empty with a blank style attribute' do
      expect(element_for('<p style=" "></p>').style).to be_empty
    end

    it 'should return the same style on every call' do
      element = element_for('<p></p>')
      style = element.style

      expect(element.style).to be(style)
    end

    it 'should not touch the style attribute when read' do
      element = element_for('<p style="color:  red"></p>')
      element.style['color']

      expect(element.node['style']).to eq('color:  red')
    end
  end

  describe '#computed_style' do
    it 'should include matching stylesheet rules' do
      expect(element_for('<p></p>').computed_style['color']).to eq('red')
    end

    it 'should include the style attribute' do
      expect(element_for('<p style="margin: 1px"></p>').computed_style['margin-top']).to eq('1px')
    end

    it 'should let the style attribute win over stylesheet rules' do
      element = element_for('<p style="color: blue"></p>', css: '#a { color: red }')

      expect(element.computed_style['color']).to eq('blue')
    end

    it 'should reflect an assigned style' do
      element = element_for('<p></p>')
      element.style = element.style.set('color', 'blue')

      expect(element.computed_style['color']).to eq('blue')
    end

    it 'should reflect a deleted property' do
      element = element_for('<p style="margin: 1px"></p>')
      element.style = element.style.delete('margin')

      expect(element.computed_style['margin-top']).to be_nil
    end

    it 'should not change the style' do
      element = element_for('<p></p>')
      element.computed_style

      expect(element.style['color']).to be_nil
    end

    it 'should not touch the style attribute' do
      element = element_for('<p style="color:  blue"></p>')
      element.computed_style

      expect(element.node['style']).to eq('color:  blue')
    end

    it 'should be frozen' do
      expect(element_for('<p></p>').computed_style).to be_frozen
    end
  end

  describe '#style=' do
    it 'should write the style to the attribute' do
      element = element_for('<p></p>')
      element.style = element.style.set('color', 'red')

      expect(element.node['style']).to eq('color:red')
    end

    it 'should merge with the existing style attribute' do
      element = element_for('<p style="margin: 1px"></p>')
      element.style = element.style.set('color', 'red')

      expect(element.node['style']).to eq('margin:1px;color:red')
    end

    it 'should remove the attribute when the style is empty' do
      element = element_for('<p style="color: red"></p>')
      element.style = element.style.delete('color')

      expect(element.node.key?('style')).to be(false)
    end

    it 'should return the assigned style from the reader' do
      element = element_for('<p></p>')
      style = element.style.set('color', 'red')
      element.style = style

      expect(element.style).to be(style)
    end

    it 'should normalize the attribute when assigned an equal style' do
      element = element_for('<p style="color:  red"></p>')
      style = element.style
      element.style = style

      expect(element.node['style']).to eq('color:red')
    end

    it 'should not touch an attribute that is already normalized' do
      element = element_for('<p style="color:red"></p>')
      attribute = element.node.attribute('style')
      style = element.style
      element.style = style

      expect(element.node.attribute('style')).to be(attribute)
    end

    it 'should leave a missing attribute alone when assigned an empty style' do
      element = element_for('<p></p>')
      element.style = Croissant::Style::ElementStyle.new

      expect(element.node.key?('style')).to be(false)
    end
  end
end
