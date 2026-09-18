# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Croissant::Style::Type::Integer do
  def parse(input)
    described_class.new.parse(input)
  end

  describe '#parse' do
    it 'should parse integral notation' do
      expect(parse('2').to_s).to eq('2')
    end

    it 'should answer a plain number, being a constraint on what may be written' do
      expect(parse('2')).to be_an_instance_of(Croissant::Style::Value::Number)
    end

    it 'should be a number type, CSS making an integer a kind of number' do
      expect(described_class.new).to be_a(Croissant::Style::Type::Number)
    end
  end

  describe '#match' do
    it 'should accept a whole number it is handed' do
      value = Croissant::Style::Value::Number.new(2.0)

      expect(described_class.new.match(value)).to be(value)
    end

    it 'should refuse a fractional number it is handed' do
      expect(described_class.new.match(Croissant::Style::Value::Number.new(2.5))).to be_nil
    end

    it 'should refuse a value that is no number rather than ask it for a remainder' do
      expect(described_class.new.match(Croissant::Style::Type::Keyword.new.parse('auto'))).to be_nil
    end

    it 'should refuse something that is not a value at all' do
      expect(described_class.new.match(:auto)).to be_nil
    end

    it 'should let a union it sits in read the keyword beside it' do
      expect((described_class.new | :auto).match(:auto)).to eq(:auto)
    end

    it 'should parse a signed integer' do
      expect(parse('-2').to_i).to eq(-2)
    end

    it 'should not parse a fractional number' do
      expect(parse('2.5')).to be_nil
    end

    it 'should not parse a length' do
      expect(parse('2px')).to be_nil
    end
  end

  describe 'the chains it stays out of' do
    it 'should stay out of the numeric family, which reads 2 as a number' do
      expect(Croissant::Style::Type::Numeric.new.parse('2')).to be_an_instance_of(Croissant::Style::Value::Number)
    end
  end
end
