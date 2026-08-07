# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Croissant::Stylesheet::Selector do
  def parse(value)
    Croissant::Stylesheet::Parser.parse_selector(value)
  end

  describe '.parse' do
    it 'should return a Selector' do
      expect(parse('p.intro')).to be_a(described_class)
    end
  end

  describe '#to_s' do
    it 'should return the original selector string' do
      selector = parse('div#main.content')

      expect(selector.to_s).to eq('div#main.content')
    end
  end

  describe '#to_str' do
    it 'should allow implicit string conversion' do
      selector = parse('p')

      expect("selector: #{selector}").to eq('selector: p')
    end
  end

  describe '#inlinable?' do
    it 'should be inlinable for a plain selector' do
      expect(parse('p.intro')).to be_inlinable
    end

    it 'should not be inlinable for a pseudo-element' do
      expect(parse('p::after')).not_to be_inlinable
    end

    it 'should not be inlinable for a legacy pseudo-element' do
      expect(parse('p:before')).not_to be_inlinable
    end

    it 'should be inlinable for a structural pseudo-class' do
      expect(parse('li:first-child')).to be_inlinable
    end

    it 'should not be inlinable for a dynamic pseudo-class' do
      expect(parse('a:hover')).not_to be_inlinable
    end

    it 'should not be inlinable when :not() wraps a dynamic pseudo-class' do
      expect(parse('a:not(:hover)')).not_to be_inlinable
    end

    it 'should not be inlinable when :is() wraps a dynamic pseudo-class' do
      expect(parse(':is(:focus, .foo)')).not_to be_inlinable
    end

    it 'should not be inlinable when :has() wraps a dynamic pseudo-class' do
      expect(parse('div:has(:hover)')).not_to be_inlinable
    end

    it 'should not be inlinable when :where() wraps a dynamic pseudo-class' do
      expect(parse(':where(:hover)')).not_to be_inlinable
    end

    it 'should not be inlinable when a dynamic pseudo-class is nested inside :not(:is())' do
      expect(parse('a:not(:is(:hover))')).not_to be_inlinable
    end
  end
end
