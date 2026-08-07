# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Croissant::Stylesheet::Property do
  describe '.new' do
    it 'should downcase the property' do
      expect(described_class.new('COLOR')).to eq('color')
    end

    it 'should strip surrounding whitespace' do
      expect(described_class.new('  color  ')).to eq('color')
    end

    it 'should stringify non-string input' do
      expect(described_class.new(:color)).to eq('color')
    end

    it 'should be a String' do
      expect(described_class.new('color')).to be_a(String)
    end

    it 'should be frozen' do
      expect(described_class.new('color')).to be_frozen
    end
  end
end
