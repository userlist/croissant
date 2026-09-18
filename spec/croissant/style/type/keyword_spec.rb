# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Croissant::Style::Type::Keyword do
  def parse(input)
    described_class.new.parse(input)
  end

  describe '#parse' do
    it 'should parse an identifier' do
      expect(parse('auto')).to be_a(Croissant::Style::Value::Keyword)
    end

    it 'should not parse something that is not an identifier' do
      expect(parse('1px solid red')).to be_nil
    end
  end

  describe 'narrowed to a keyword' do
    it 'should read a symbol as the keyword it names' do
      expect(described_class.new(:auto).parse('auto')).to eq(:auto)
    end

    it 'should read a string as the keyword it names' do
      expect(described_class.new('auto').parse('auto')).to eq(:auto)
    end

    it 'should refuse an identifier it does not name' do
      expect(described_class.new(:auto).parse('none')).to be_nil
    end

    it 'should narrow to the keywords a grammar names' do
      allowed = described_class.new(:auto) | described_class.new(:none)

      expect(allowed.parse('block')).to be_nil
    end

    it 'should accept each keyword a grammar names' do
      allowed = described_class.new(:auto) | described_class.new(:none)

      expect(allowed.parse('none')).to eq(:none)
    end

    it 'should combine with another type from the left' do
      type = Croissant::Style::Type::Length.new | :auto

      expect(type.parse('auto')).to eq(:auto)
    end

    it 'should combine with another type from the right' do
      type = described_class.new(:auto) | Croissant::Style::Type::Length.new

      expect(type.parse('10px')).to be_a(Croissant::Style::Value::Length)
    end
  end
end
