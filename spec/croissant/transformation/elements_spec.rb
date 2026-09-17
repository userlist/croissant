# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Croissant::Transformation::Elements do
  let(:recorder) do
    Class.new(Croissant::Transformation::Element) do
      selector 'p, span'

      attr_reader :names

      def initialize
        @names = []
        super
      end

      def call(element)
        names << element.name
      end
    end
  end

  let(:colorer) do
    Class.new(Croissant::Transformation::Element) do
      selector '.red'

      def call(element)
        element.style = element.style.set('color', 'red')
      end
    end
  end

  let(:widther) do
    Class.new(Croissant::Transformation::Element) do
      selector '*'

      def call(element)
        element['width'] = element.style['width'] if element.style['width']
      end
    end
  end

  def process(html, transformations)
    document = Croissant::Document.parse(html)
    described_class.new(transformations).call(document)
    document.to_html
  end

  describe '#call' do
    it 'should run a transformation on every matching element in document order' do
      transformation = recorder.new

      process('<div><p>a</p><span>b</span></div><p>c</p>', [transformation])

      expect(transformation.names).to eq(%w[p span p])
    end

    it 'should run a transformation once when several of its selectors match' do
      klass = Class.new(Croissant::Transformation::Element) do
        selector 'td', '.cell'

        attr_reader :count

        def initialize
          @count = 0
          super
        end

        def call(_element)
          @count += 1
        end
      end
      transformation = klass.new

      process('<table><tr><td class="cell">a</td></tr></table>', [transformation])

      expect(transformation.count).to eq(1)
    end

    it 'should run a transformation at the position of its first matching selector' do
      calls = []
      first = Class.new(Croissant::Transformation::Element) do
        selector 'td', '.cell'
        define_method(:call) { |_element| calls << :first }
      end
      second = Class.new(Croissant::Transformation::Element) do
        selector 'td'
        define_method(:call) { |_element| calls << :second }
      end

      process('<table><tr><td class="cell">a</td></tr></table>', [first.new, second.new])

      expect(calls).to eq(%i[first second])
    end

    it 'should not run a transformation on elements it does not match' do
      transformation = recorder.new

      process('<div><h1>a</h1></div>', [transformation])

      expect(transformation.names).to eq([])
    end

    it 'should write back a changed style' do
      html = process('<p class="red">a</p><p>b</p>', [colorer.new])

      expect(html).to eq('<p class="red" style="color:red">a</p><p>b</p>')
    end

    it 'should merge a changed style with the existing style attribute' do
      html = process('<p class="red" style="margin: 1px">a</p>', [colorer.new])

      expect(html).to eq('<p class="red" style="margin:1px;color:red">a</p>')
    end

    it 'should not touch the style attribute when the style was only read' do
      html = process('<p style="width:  10px">a</p>', [widther.new])

      expect(html).to eq('<p style="width:  10px" width="10px">a</p>')
    end

    it 'should run transformations in pipeline order for each element' do
      html = process('<p class="red" style="width: 5px">a</p>', [colorer.new, widther.new])

      expect(html).to eq('<p class="red" style="width:5px;color:red" width="5px">a</p>')
    end

    it 'should let a later transformation see changes of an earlier one' do
      reader = Class.new(Croissant::Transformation::Element) do
        selector '*'

        def call(element)
          element['data-color'] = element.style['color'].to_s
        end
      end

      html = process('<p class="red">a</p>', [colorer.new, reader.new])

      expect(html).to eq('<p class="red" style="color:red" data-color="#ff0000">a</p>')
    end

    it 'should do nothing without transformations' do
      expect(process('<p>a</p>', [])).to eq('<p>a</p>')
    end
  end

  describe '#transformations' do
    it 'should return the transformations' do
      transformation = recorder.new

      expect(described_class.new([transformation]).transformations).to eq([transformation])
    end
  end

  describe '#freeze' do
    it 'should be frozen after initialization' do
      expect(described_class.new([])).to be_frozen
    end
  end
end
