# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Croissant::Document::Element do
  def build(html, css: 'p { color: red }')
    document = Croissant::Document.parse("<style>#{css}</style>#{html}")
    node = document.at_xpath('.//body//* | .//style/following-sibling::*') || document.children.last

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

  describe '#id' do
    it 'should return the id' do
      expect(element_for('<p id="a"></p>').id).to eq('a')
    end

    it 'should be nil without an id' do
      expect(element_for('<p></p>').id).to be_nil
    end
  end

  describe '#classes' do
    it 'should return the classes' do
      expect(element_for('<p class="a b"></p>').classes).to eq(%w[a b])
    end

    it 'should be empty without a class attribute' do
      expect(element_for('<p></p>').classes).to eq([])
    end

    it 'should split classes on any whitespace' do
      expect(element_for("<p class=\" a\tb\nc \"></p>").classes).to eq(%w[a b c])
    end

    it 'should keep repeated classes' do
      expect(element_for('<p class="a a"></p>').classes).to eq(%w[a a])
    end
  end

  describe '#[]=' do
    it 'should write an attribute to the node' do
      element = element_for('<p></p>')
      element['width'] = '100'

      expect(element.to_html).to eq('<p width="100"></p>')
    end

    it 'should reflect a written class attribute in the classes' do
      element = element_for('<p class="a"></p>')
      element.classes
      element['class'] = 'b'

      expect(element.classes).to eq(%w[b])
    end

    it 'should reflect a written id attribute in the id' do
      element = element_for('<p></p>')
      element.id
      element['id'] = 'a'

      expect(element.id).to eq('a')
    end
  end

  describe '#remove_attribute' do
    it 'should remove an attribute from the node' do
      element = element_for('<p class="a"></p>')
      element.remove_attribute('class')

      expect(element['class']).to be_nil
    end

    it 'should reflect a removed class attribute in the classes' do
      element = element_for('<p class="a"></p>')
      element.classes
      element.remove_attribute('class')

      expect(element.classes).to eq([])
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
      expect(element_for('<p style="color: blue"></p>').style['color']).to eq('#0000ff')
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

      expect(element['style']).to eq('color:  red')
    end
  end

  describe '#computed_style' do
    it 'should include matching stylesheet rules' do
      expect(element_for('<p></p>').computed_style['color']).to eq('#ff0000')
    end

    it 'should include the style attribute' do
      expect(element_for('<p style="margin: 1px"></p>').computed_style['margin-top']).to eq('1px')
    end

    it 'should let the style attribute win over stylesheet rules' do
      element = element_for('<p style="color: blue"></p>', css: '#a { color: red }')

      expect(element.computed_style['color']).to eq('#0000ff')
    end

    it 'should reflect an assigned style' do
      element = element_for('<p></p>')
      element.style = element.style.set('color', 'blue')

      expect(element.computed_style['color']).to eq('#0000ff')
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

      expect(element['style']).to eq('color:  blue')
    end

    it 'should be frozen' do
      expect(element_for('<p></p>').computed_style).to be_frozen
    end
  end

  describe '#style=' do
    it 'should write the style to the attribute' do
      element = element_for('<p></p>')
      element.style = element.style.set('color', 'red')

      expect(element['style']).to eq('color:red')
    end

    it 'should merge with the existing style attribute' do
      element = element_for('<p style="margin: 1px"></p>')
      element.style = element.style.set('color', 'red')

      expect(element['style']).to eq('margin:1px;color:red')
    end

    it 'should remove the attribute when the style is empty' do
      element = element_for('<p style="color: red"></p>')
      element.style = element.style.delete('color')

      expect(element['style']).to be_nil
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

      expect(element['style']).to eq('color:red')
    end

    it 'should not touch an attribute that is already normalized' do
      element = element_for('<p style="color:red"></p>')
      attribute = element['style']
      style = element.style
      element.style = style

      expect(element['style']).to eq(attribute)
    end

    it 'should leave a missing attribute alone when assigned an empty style' do
      element = element_for('<p></p>')
      element.style = Croissant::Style::ElementStyle.new

      expect(element['style']).to be_nil
    end
  end
end
