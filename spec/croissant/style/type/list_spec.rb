# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Croissant::Style::Type::List do
  let(:generic) do
    base = Croissant::Style::Type::Numeric.new | Croissant::Style::Type::Keyword.new |
           Croissant::Style::Type::Color.new

    base | described_class.new(base) | Croissant::Style::Type::Unparsed.new
  end
  let(:list) { described_class.new(generic) }

  def parse(input)
    (generic | list).parse(input)
  end

  describe '#parse' do
    it 'should parse a space-separated value' do
      expect(list.parse('0 auto')).to be_a(Croissant::Style::Value::List)
    end

    it 'should not parse a single token' do
      expect(list.parse('auto')).to be_nil
    end

    it 'should parse each element in turn' do
      expect(parse('1px solid red').map(&:class)).to eq(
        [Croissant::Style::Value::Length, Croissant::Style::Value::Keyword, Croissant::Style::Value::Keyword]
      )
    end

    it 'should separate on whitespace' do
      expect(parse('0 auto').separator).to eq(:space)
    end

    it 'should separate on commas' do
      expect(parse('Arial, sans-serif').separator).to eq(:comma)
    end

    it 'should not split a comma inside a function' do
      expect(parse('rgb(0, 0, 0) solid').count).to eq(2)
    end

    it 'should not split a space inside a quoted string' do
      expect(parse('"Helvetica Neue", Arial').count).to eq(2)
    end

    it 'should bind commas looser than whitespace' do
      expect(parse('bold 12px Arial, sans-serif').first).to be_a(Croissant::Style::Value::List)
    end

    it 'should keep an element no type reads as written' do
      expect(parse('calc(1px + 2px) solid').first).to be_a(Croissant::Style::Value::Unparsed)
    end
  end

  describe '.split' do
    def split(input)
      described_class.split(input)
    end

    it 'should split on top-level whitespace' do
      expect(split('1px solid red')).to eq(%w[1px solid red])
    end

    it 'should return a single token unsplit' do
      expect(split('1px')).to eq(['1px'])
    end

    it 'should keep a bracketed group together' do
      expect(split('calc(1px + 2px) 3px')).to eq(['calc(1px + 2px)', '3px'])
    end

    it 'should keep a quoted string together' do
      expect(split('"Helvetica Neue" 2px')).to eq(['"Helvetica Neue"', '2px'])
    end

    it 'should split on commas when given the segment pattern' do
      expect(described_class.split('Arial, sans-serif', described_class::SEGMENTS)).to eq(%w[Arial sans-serif])
    end

    it 'should accept something that is not a string' do
      expect(split(nil)).to eq([])
    end
  end
end
