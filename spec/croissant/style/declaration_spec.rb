# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Croissant::Style::Declaration do
  describe '#property' do
    it 'should resolve a name to the registered property definition' do
      expect(described_class.new('color', 'black').property).to be(Croissant::Style::Property.lookup('color'))
    end

    it 'should resolve an unknown name to a fallback definition' do
      expect(described_class.new('unknown', 'black').property.name).to eq('unknown')
    end

    it 'should keep a property definition passed in directly' do
      property = Croissant::Style::Property.new('color')

      expect(described_class.new(property, 'black').property).to be(property)
    end
  end

  describe '#value' do
    it 'should return the value' do
      expect(described_class.new('color', 'black').value).to eq('black')
    end
  end

  describe '#parsed_value' do
    it 'should read the value through the type of the property' do
      expect(described_class.new('color', 'red').parsed_value).to be_a(Croissant::Style::Value::Color)
    end

    it 'should read the same value differently for a property that wants no colour' do
      expect(described_class.new('animation-name', 'red').parsed_value).to be_a(Croissant::Style::Value::Keyword)
    end

    it 'should keep a value the property cannot recognize' do
      expect(described_class.new('color', 'calc(1px + 2px)').parsed_value.to_s).to eq('calc(1px + 2px)')
    end

    it 'should leave the raw value alone' do
      expect(described_class.new('color', 'red').value).to eq('red')
    end

    it 'should not memoize, so a frozen declaration stays frozen' do
      declaration = described_class.new('color', 'red')
      declaration.parsed_value

      expect(declaration).to be_frozen
    end
  end

  describe '#important?' do
    it 'should be true when the declaration is important' do
      expect(described_class.new('color', 'black', important: true)).to be_important
    end

    it 'should default to false' do
      expect(described_class.new('color', 'black')).not_to be_important
    end
  end

  describe '#to_s' do
    it 'should format the declaration as property and value' do
      expect(described_class.new('color', 'black').to_s).to eq('color:black')
    end

    it 'should append the important flag to an important declaration' do
      declaration = described_class.new('color', 'black', important: true)

      expect(declaration.to_s).to eq('color:black !important')
    end
  end

  describe '#==' do
    it 'should be equal when property, value, and importance match' do
      first = described_class.new('color', 'black', important: true)
      second = described_class.new('color', 'black', important: true)

      expect(first).to eq(second)
    end

    it 'should not be equal when the property differs' do
      expect(described_class.new('color', 'black')).not_to eq(described_class.new('background-color', 'black'))
    end

    it 'should not be equal when the value differs' do
      expect(described_class.new('color', 'black')).not_to eq(described_class.new('color', 'red'))
    end

    it 'should not be equal when the importance differs' do
      first = described_class.new('color', 'black', important: true)
      second = described_class.new('color', 'black')

      expect(first).not_to eq(second)
    end

    it 'should not be equal to an object of another class' do
      declaration = Croissant::Stylesheet::Declaration.new(property: 'color', value: 'black')

      expect(described_class.new('color', 'black')).not_to eq(declaration)
    end
  end

  describe '#hash' do
    it 'should have the same hash as an equal declaration' do
      first = described_class.new('color', 'black', important: true)
      second = described_class.new('color', 'black', important: true)

      expect(first.hash).to eq(second.hash)
    end
  end

  describe '#freeze' do
    it 'should be frozen after initialization' do
      expect(described_class.new('color', 'black')).to be_frozen
    end
  end
end
