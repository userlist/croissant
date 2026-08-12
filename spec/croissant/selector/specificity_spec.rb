# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Croissant::Selector::Specificity do
  def calculate(value)
    Croissant::Stylesheet::Parser.parse_selector(value).specificity
  end

  describe '.style_attribute' do
    it 'should outrank any selector-based specificity' do
      expect(described_class.style_attribute).to eq(described_class.new(1, 0, 0, 0))
    end

    # rubocop:disable RSpec/IdenticalEqualityAssertion
    it 'should memoize the instance' do
      expect(described_class.style_attribute).to be(described_class.style_attribute)
    end
    # rubocop:enable RSpec/IdenticalEqualityAssertion
  end

  describe 'calculation from a parsed selector' do
    let(:result) { calculate(selector) }

    context 'with an element selector' do
      let(:selector) { 'p' }

      it 'should count the element' do
        expect(result).to eq(described_class.new(0, 0, 0, 1))
      end
    end

    context 'with a class selector' do
      let(:selector) { '.intro' }

      it 'should count the class' do
        expect(result).to eq(described_class.new(0, 0, 1, 0))
      end
    end

    context 'with an id selector' do
      let(:selector) { '#main' }

      it 'should count the id' do
        expect(result).to eq(described_class.new(0, 1, 0, 0))
      end
    end

    context 'with an attribute selector' do
      let(:selector) { 'a[href^="https://"]' }

      it 'should count the attribute as a class and the tag as an element' do
        expect(result).to eq(described_class.new(0, 0, 1, 1))
      end
    end

    context 'with a pseudo-class selector' do
      let(:selector) { 'a:hover' }

      it 'should count the pseudo-class as a class' do
        expect(result).to eq(described_class.new(0, 0, 1, 1))
      end
    end

    context 'with a pseudo-element selector' do
      let(:selector) { 'p::after' }

      it 'should count the pseudo-element as an element' do
        expect(result).to eq(described_class.new(0, 0, 0, 2))
      end
    end

    context 'with multiple ids' do
      let(:selector) { '#a#b' }

      it 'should count each id' do
        expect(result).to eq(described_class.new(0, 2, 0, 0))
      end
    end

    context 'with a compound selector' do
      let(:selector) { 'div#main.content > p.intro:first-child::after' }

      it 'should sum each component across the whole selector' do
        expect(result).to eq(described_class.new(0, 1, 3, 3))
      end
    end

    context 'with :not()' do
      it 'should take on the specificity of a class argument' do
        result = calculate('a:not(.foo)')

        expect(result).to eq(described_class.new(0, 0, 1, 1))
      end

      it 'should take on the specificity of an id argument' do
        result = calculate('a:not(#foo)')

        expect(result).to eq(described_class.new(0, 1, 0, 1))
      end
    end

    context 'with :is()' do
      it 'should take on the specificity of the most specific argument' do
        result = calculate(':is(.a, #b)')

        expect(result).to eq(described_class.new(0, 1, 0, 0))
      end
    end

    context 'with :has()' do
      it "should take on its argument's specificity" do
        result = calculate('div:has(.child)')

        expect(result).to eq(described_class.new(0, 0, 1, 1))
      end
    end

    context 'with :where()' do
      it 'should always contribute zero specificity' do
        result = calculate(':where(#foo)')

        expect(result).to eq(described_class.new(0, 0, 0, 0))
      end
    end

    context 'with functional pseudo-classes nested inside one another' do
      it 'should resolve specificity through the nesting' do
        result = calculate('a:not(:is(.a, .b))')

        expect(result).to eq(described_class.new(0, 0, 1, 1))
      end

      it 'should still contribute zero when :where() wraps the nested argument' do
        result = calculate('a:not(:where(#foo))')

        expect(result).to eq(described_class.new(0, 0, 0, 1))
      end
    end

    context 'with multiple functional pseudo-classes on the same selector' do
      it 'should sum each independently' do
        result = calculate('a:not(.foo):is(#bar, .baz)')

        expect(result).to eq(described_class.new(0, 1, 1, 1))
      end
    end
  end

  describe '#<=>' do
    it 'should rank the style attribute above any selector' do
      expect(described_class.style_attribute).to be > described_class.new(0, 100, 100, 100)
    end

    it 'should rank ids above classes' do
      expect(described_class.new(0, 1, 0, 0)).to be > described_class.new(0, 0, 100, 100)
    end

    it 'should rank classes above elements' do
      expect(described_class.new(0, 0, 1, 0)).to be > described_class.new(0, 0, 0, 100)
    end

    # rubocop:disable RSpec/IdenticalEqualityAssertion
    it 'should treat matching tiers as equal' do
      expect(described_class.new(0, 1, 2, 3)).to eq(described_class.new(0, 1, 2, 3))
    end
    # rubocop:enable RSpec/IdenticalEqualityAssertion

    it 'should be incomparable to other types' do
      expect(described_class.new(0, 0, 0, 1) <=> 'not a specificity').to be_nil
    end

    it 'should sort selectors from lowest to highest specificity' do
      specificities = [
        calculate('p'),
        calculate('#main'),
        calculate('.intro'),
        described_class.style_attribute
      ]

      expect(specificities.sort).to eq([
        described_class.new(0, 0, 0, 1),
        described_class.new(0, 0, 1, 0),
        described_class.new(0, 1, 0, 0),
        described_class.new(1, 0, 0, 0)
      ])
    end
  end
end
