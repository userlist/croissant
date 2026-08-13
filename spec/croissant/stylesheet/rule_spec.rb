# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Croissant::Stylesheet::Rule do
  let(:selector) { Croissant::Stylesheet::Parser.parse_selector('p') }
  let(:declarations) { [Croissant::Stylesheet::Declaration.new(property: 'color', value: 'red')] }

  describe '#initialize' do
    it 'should take the specificity from the selector when none is given' do
      rule = described_class.new(selector:, declarations:)

      expect(rule.specificity).to eq(selector.specificity)
    end

    it 'should use the given specificity instead of calculating one' do
      specificity = Croissant::Selector::Specificity.inline
      rule = described_class.new(declarations:, specificity:)

      expect(rule.specificity).to be(specificity)
    end

    it 'should raise an error when both selector and specificity are nil' do
      expect { described_class.new(declarations:) }
        .to raise_error(ArgumentError, /selector and specificity cannot both be nil/)
    end
  end

  describe '#to_s' do
    it 'should format the selector and declaration' do
      rule = described_class.new(selector:, declarations:)

      expect(rule.to_s).to eq('p{color:red}')
    end

    it 'should join multiple declarations with a semicolon' do
      declarations = [
        Croissant::Stylesheet::Declaration.new(property: 'color', value: 'red'),
        Croissant::Stylesheet::Declaration.new(property: 'font-size', value: '12px')
      ]

      rule = described_class.new(selector:, declarations:)

      expect(rule.to_s).to eq('p{color:red;font-size:12px}')
    end
  end

  describe '#inlinable?' do
    it 'should be inlinable when the selector is inlinable' do
      rule = described_class.new(selector:, declarations:)

      expect(rule).to be_inlinable
    end

    it 'should not be inlinable when the selector is not inlinable' do
      hover_selector = Croissant::Stylesheet::Parser.parse_selector('a:hover')
      rule = described_class.new(selector: hover_selector, declarations:)

      expect(rule).not_to be_inlinable
    end

    it 'should be inlinable without a selector' do
      rule = described_class.new(declarations:, specificity: Croissant::Selector::Specificity.inline)

      expect(rule).to be_inlinable
    end
  end
end
