# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Croissant::Stylesheet::Declaration do
  describe '#initialize' do
    it 'should normalize the property into a Property' do
      declaration = described_class.new(property: 'COLOR', value: 'red')

      expect(declaration.property).to eq('color')
    end

    it 'should keep the value as given' do
      declaration = described_class.new(property: 'color', value: 'RED')

      expect(declaration.value).to eq('RED')
    end

    it 'should default important to false' do
      declaration = described_class.new(property: 'color', value: 'red')

      expect(declaration).not_to be_important
    end
  end

  describe '#important?' do
    it 'should be false when not marked important' do
      declaration = described_class.new(property: 'color', value: 'red')

      expect(declaration).not_to be_important
    end

    it 'should be true when marked important' do
      declaration = described_class.new(property: 'color', value: 'red', important: true)

      expect(declaration).to be_important
    end
  end

  describe '#to_s' do
    it 'should format the property and value' do
      declaration = described_class.new(property: 'color', value: 'red')

      expect(declaration.to_s).to eq('color:red')
    end

    it 'should append the important suffix when important' do
      declaration = described_class.new(property: 'color', value: 'red', important: true)

      expect(declaration.to_s).to eq('color:red !important')
    end
  end
end
