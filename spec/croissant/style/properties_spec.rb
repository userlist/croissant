# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Croissant::Style::Properties do
  describe '.[]' do
    it 'should return the definition of a registered property' do
      property = described_class['margin-top']

      expect(property.initial).to eq('0')
    end

    it 'should return an inherited definition for an inherited property' do
      expect(described_class['color']).to be_inherited
    end

    it 'should return a non-inherited definition for a reset property' do
      expect(described_class['margin-top']).not_to be_inherited
    end

    it 'should return the same definition instance on every lookup' do
      property = described_class['color']

      expect(described_class['color']).to be(property)
    end

    it 'should return a fallback definition named after an unknown property' do
      property = described_class['-webkit-text-size-adjust']

      expect(property.name).to eq('-webkit-text-size-adjust')
    end

    it 'should return a fallback definition without an initial value' do
      expect(described_class['unknown'].initial).to be_nil
    end

    it 'should return a fallback definition that does not inherit' do
      expect(described_class['unknown']).not_to be_inherited
    end

    it 'should return a shorthand definition for a four-side shorthand' do
      expect(described_class['margin']).to be_a(Croissant::Style::Property::Shorthand)
    end

    it 'should map a four-side shorthand onto its longhands' do
      expect(described_class['margin'].longhands).to eq(
        %w[margin-top margin-right margin-bottom margin-left]
      )
    end
  end

  describe 'longhands of a shorthand' do
    it 'should reference their shorthand' do
      expect(described_class['margin-top'].shorthand).to be(described_class['margin'])
    end

    it 'should keep their initial value' do
      expect(described_class['margin-top'].initial).to eq('0')
    end

    it 'should keep their inheritance' do
      expect(described_class['margin-top']).not_to be_inherited
    end

    it 'should not be set on a standalone property' do
      expect(described_class['color'].shorthand).to be_nil
    end

    it 'should link every longhand of every shorthand' do
      shorthands = %w[margin padding inset border-color border-style border-width]

      shorthands.each do |name|
        shorthand = described_class[name]

        expect(shorthand.longhands.map { |longhand| described_class[longhand].shorthand }).to all(be(shorthand))
      end
    end
  end
end
