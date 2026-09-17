# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Croissant::Style::Property do
  describe '#initial' do
    it 'should return the initial value' do
      property = described_class.new('color', initial: 'canvastext')

      expect(property.initial).to eq('canvastext')
    end

    it 'should default to nil' do
      expect(described_class.new('font-family').initial).to be_nil
    end
  end

  describe '#inherited?' do
    it 'should be true when the property inherits' do
      expect(described_class.new('color', inherited: true)).to be_inherited
    end

    it 'should default to false' do
      expect(described_class.new('margin-top')).not_to be_inherited
    end
  end

  describe '#expand' do
    it 'should return the declaration itself' do
      declaration = Croissant::Style::Declaration.new('color', 'black')

      expect(described_class.new('color').expand(declaration)).to eq([declaration])
    end
  end

  describe '#shorthand' do
    it 'should be nil by default' do
      expect(described_class.new('color').shorthand).to be_nil
    end

    it 'should return the shorthand the property belongs to' do
      shorthand = Croissant::Style::Property::Shorthand.new('margin', %w[margin-top])

      expect(described_class.new('margin-top', shorthand:).shorthand).to be(shorthand)
    end
  end

  describe '#collapse' do
    it 'should return the declaration set unchanged without a shorthand' do
      declarations = Croissant::Style::DeclarationSet.new([Croissant::Style::Declaration.new('color', 'black')])

      expect(described_class.new('color').collapse(declarations)).to be(declarations)
    end

    it 'should defer to its shorthand' do
      shorthand = Croissant::Style::Property::Shorthand.new('margin', %w[margin-top])
      property = described_class.new('margin-top', shorthand:)
      declarations = Croissant::Style::DeclarationSet.new([Croissant::Style::Declaration.new(property, '10px')])

      expect(property.collapse(declarations).map(&:to_s)).to eq(['margin:10px'])
    end
  end

  describe '#==' do
    it 'should be equal when name, initial value, and inheritance match' do
      first = described_class.new('color', initial: 'canvastext', inherited: true)
      second = described_class.new('color', initial: 'canvastext', inherited: true)

      expect(first).to eq(second)
    end

    it 'should not be equal when the name differs' do
      expect(described_class.new('color')).not_to eq(described_class.new('background-color'))
    end

    it 'should not be equal when the initial value differs' do
      first = described_class.new('color', initial: 'canvastext')
      second = described_class.new('color', initial: 'black')

      expect(first).not_to eq(second)
    end

    it 'should not be equal when inheritance differs' do
      first = described_class.new('color', inherited: true)
      second = described_class.new('color', inherited: false)

      expect(first).not_to eq(second)
    end

    it 'should not be equal when the shorthand differs' do
      shorthand = Croissant::Style::Property::Shorthand.new('margin', %w[margin-top])

      expect(described_class.new('margin-top', shorthand:)).not_to eq(described_class.new('margin-top'))
    end

    it 'should not be equal to an object of another class' do
      expect(described_class.new('color')).not_to eq('color')
    end
  end

  describe '#hash' do
    it 'should have the same hash as an equal property' do
      first = described_class.new('color', initial: 'canvastext', inherited: true)
      second = described_class.new('color', initial: 'canvastext', inherited: true)

      expect(first.hash).to eq(second.hash)
    end
  end

  describe '#freeze' do
    it 'should be frozen after initialization' do
      expect(described_class.new('color')).to be_frozen
    end
  end

  describe '#type' do
    it 'should default to the generic chain' do
      expect(described_class.new('color').type).to eq(Croissant::Style::Value.default_type)
    end

    it 'should keep the types it is given' do
      type = Croissant::Style::Value::Color | Croissant::Style::Value::Keyword

      expect(described_class.new('color', type:).type).to eq(type)
    end

    it 'should keep a bare class as a type of its own' do
      expect(described_class.new('color', type: Croissant::Style::Value::Color).type)
        .to be(Croissant::Style::Value::Color)
    end

    it 'should not freeze a bare class, which would freeze the class itself' do
      described_class.new('color', type: Croissant::Style::Value::Color)

      expect(Croissant::Style::Value::Color).not_to be_frozen
    end

    it 'should take part in equality' do
      first = described_class.new('color', type: Croissant::Style::Value::Color)
      second = described_class.new('color', type: Croissant::Style::Value::Keyword)

      expect(first).not_to eq(second)
    end

    it 'should take part in the hash' do
      first = described_class.new('color', type: Croissant::Style::Value::Color)
      second = described_class.new('color', type: Croissant::Style::Value::Keyword)

      expect(first.hash).not_to eq(second.hash)
    end
  end

  describe '#parse_value' do
    def build(*types)
      described_class.new('example', type: types.reduce(:|))
    end

    it 'should parse with the types of the property' do
      property = build(Croissant::Style::Value::Color, Croissant::Style::Value::Keyword)

      expect(property.parse_value('red')).to be_a(Croissant::Style::Value::Color)
    end

    it 'should read the same value as a keyword for a property that wants no colour' do
      expect(build.parse_value('red')).to be_a(Croissant::Style::Value::Keyword)
    end

    it 'should keep a value none of its types recognize' do
      expect(build(Croissant::Style::Value::Color).parse_value('auto')).to be_a(Croissant::Style::Value::Unparsed)
    end

    it 'should keep the text of a value it does not recognize' do
      property = build(Croissant::Style::Value::Color)

      expect(property.parse_value('calc(1px + 2px)').to_s).to eq('calc(1px + 2px)')
    end

    it 'should accept only the keywords a narrowed type names' do
      allowed = Croissant::Style::Value::Keyword[:auto] | Croissant::Style::Value::Keyword[:none]

      expect(build(allowed).parse_value('auto')).to eq(:auto)
    end

    it 'should keep a keyword a narrowed type does not name' do
      allowed = Croissant::Style::Value::Keyword[:auto] | Croissant::Style::Value::Keyword[:none]

      expect(build(allowed).parse_value('block')).to be_a(Croissant::Style::Value::Unparsed)
    end

    it 'should return nil for a blank value' do
      expect(build.parse_value('')).to be_nil
    end

    it 'should return a value it is given unchanged' do
      value = Croissant::Style::Value::Keyword.new('auto')

      expect(build.parse_value(value)).to be(value)
    end
  end
end
