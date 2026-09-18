# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Croissant::Style::Type::Length do
  def parse(input)
    described_class.new.parse(input)
  end

  describe '#parse' do
    it 'should parse a length' do
      expect(parse('10px')).to be_a(Croissant::Style::Value::Length)
    end

    it 'should refuse a keyword' do
      expect(parse('auto')).to be_nil
    end

    it 'should read a unitless zero as a length' do
      expect(parse('0')).to be_a(Croissant::Style::Value::Length)
    end

    it 'should give a unitless zero the pixel unit' do
      expect(parse('0').to_s).to eq('0px')
    end

    it 'should refuse any other unitless number' do
      expect(parse('5')).to be_nil
    end
  end

  describe 'narrowed to a unit' do
    it 'should narrow to a unit' do
      expect(described_class.new(nil, 'px').parse('10em')).to be_nil
    end

    it 'should keep a length written in that unit' do
      expect(described_class.new(nil, 'px').parse('10px').to_s).to eq('10px')
    end

    it 'should narrow on the length and the unit at once' do
      expect(described_class.new(0.., 'px').parse('-10px')).to be_nil
    end

    it 'should look the unit up rather than compare its spelling' do
      expect(described_class.new(nil, 'PX').parse('10px').to_s).to eq('10px')
    end

    it 'should match the unit with a matcher of its own' do
      absolute = described_class.new(nil, ->(unit) { !unit.absolutize(1).nil? })

      expect(absolute.parse('1in').to_s).to eq('1in')
    end

    it 'should refuse a unit that matcher does not accept' do
      absolute = described_class.new(nil, ->(unit) { !unit.absolutize(1).nil? })

      expect(absolute.parse('1em')).to be_nil
    end

    it 'should refuse a value that has no unit rather than ask it for one' do
      keyword = Croissant::Style::Type::Keyword.new.parse('auto')

      expect(described_class.new(nil, 'px').match(keyword)).to be_nil
    end

    it 'should take part in equality' do
      expect(described_class.new(nil, 'px')).not_to eq(described_class.new(nil, 'em'))
    end

    it 'should show in the inspect output' do
      expect(described_class.new(nil, 'px').inspect)
        .to eq('#<Croissant::Style::Type::Length #<Croissant::Style::Unit::Pixel "px">>')
    end
  end
end
