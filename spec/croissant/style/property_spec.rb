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
end
