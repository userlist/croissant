# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Croissant::Style::Type do
  def parse(input, type = described_class.complete)
    type.parse(input)
  end

  describe '.complete' do
    let(:colour) { described_class::Color.new | described_class::Keyword.new }

    it 'should read a CSS-wide keyword when it is given no grammar' do
      expect(parse('inherit')).to eq(:inherit)
    end

    it 'should keep anything else as written when it is given no grammar' do
      expect(parse('10px')).to be_a(Croissant::Style::Value::Unparsed)
    end

    it 'should keep the text of what it has no grammar for' do
      expect(parse('10px').to_s).to eq('10px')
    end

    it 'should read the grammar it is given' do
      expect(parse('red', described_class.complete(colour))).to be_a(Croissant::Style::Value::Color)
    end

    it 'should read a CSS-wide keyword beside that grammar' do
      expect(parse('inherit', described_class.complete(colour))).to eq(:inherit)
    end

    it 'should keep a value the grammar does not read as written' do
      narrow = described_class.complete(described_class::Keyword.new(:auto))

      expect(parse('10px', narrow)).to be_a(Croissant::Style::Value::Unparsed)
    end

    it 'should keep the text of a value the grammar does not read' do
      narrow = described_class.complete(described_class::Keyword.new(:auto))

      expect(parse('10px', narrow).to_s).to eq('10px')
    end

    it 'should not read a list for a grammar that does not ask for one' do
      expect(parse('red blue', described_class.complete(colour))).to be_a(Croissant::Style::Value::Unparsed)
    end

    it 'should read a list for a grammar that asks for one' do
      type = described_class.complete(described_class::List.new(colour))

      expect(parse('red blue', type).map(&:to_s)).to eq(['#ff0000', '#0000ff'])
    end
  end

  describe '.global' do
    it 'should parse a CSS-wide keyword' do
      expect(described_class.global.parse('inherit')).to eq(:inherit)
    end

    it 'should cover every CSS-wide keyword' do
      names = %w[inherit initial unset revert revert-layer]
      parsed = names.map { |name| described_class.global.parse(name) }

      expect(parsed).to all(be_a(Croissant::Style::Value::Keyword))
    end

    it 'should not parse anything else' do
      expect(described_class.global.parse('auto')).to be_nil
    end

    it 'should be the same union on every call' do
      first = described_class.global
      second = described_class.global

      expect(first).to be(second)
    end
  end

  describe 'matchers' do
    it 'should read any value of the type when given none' do
      expect(described_class::Number.new.parse('-5').to_s).to eq('-5')
    end

    it 'should narrow with a range' do
      expect(described_class::Number.new(0..).parse('-5')).to be_nil
    end

    it 'should keep what the range covers' do
      expect(described_class::Number.new(0..).parse('5').to_s).to eq('5')
    end

    it 'should narrow with a bounded range' do
      expect(described_class::Percentage.new(0..100).parse('150%')).to be_nil
    end

    it 'should read the bounds of a range as values of the type' do
      expect(described_class::Percentage.new(0..100).parse('50%').to_s).to eq('50%')
    end

    it 'should narrow with a lambda' do
      expect(described_class::Number.new(->(value) { value.to_f > 0 }).parse('0')).to be_nil
    end

    it 'should narrow with a proc built from a symbol' do
      expect(described_class::Color.new(:opaque?.to_proc).parse('rgba(0, 0, 0, 0.5)')).to be_nil
    end

    it 'should keep what the proc accepts' do
      expect(described_class::Color.new(:opaque?.to_proc).parse('red').to_s).to eq('#ff0000')
    end

    it 'should narrow with a class' do
      expect(described_class::Numeric.new(Croissant::Style::Value::Length).parse('50%')).to be_nil
    end

    it 'should narrow with a regexp, since a value stands in for its text' do
      expect(described_class::Numeric.new(/px\z/).parse('10em')).to be_nil
    end

    it 'should still refuse input it cannot read in the first place' do
      expect(described_class::Number.new(0..).parse('auto')).to be_nil
    end

    it 'should take part in equality' do
      expect(described_class::Number.new(0..)).not_to eq(described_class::Number.new)
    end

    it 'should take part in the hash' do
      expect(described_class::Number.new(0..).hash).not_to eq(described_class::Number.new.hash)
    end

    it 'should show in the inspect output' do
      expect(described_class::Number.new(0..).inspect).to eq('#<Croissant::Style::Type::Number 0..>')
    end
  end

  describe '.value_class' do
    it 'should be the value class the type reads' do
      expect(described_class::Length.value_class).to be(Croissant::Style::Value::Length)
    end

    it 'should be the family for a type that reads several of them' do
      expect(described_class::Numeric.value_class).to be(Croissant::Style::Value::Numeric)
    end

    it 'should be any value at all for a type that does not say' do
      expect(described_class.value_class).to be(Croissant::Style::Value)
    end
  end

  describe '#match' do
    it 'should answer the value a caller already holds' do
      value = described_class::Number.new.parse('5')

      expect(described_class::Number.new(0..).match(value)).to be(value)
    end

    it 'should answer the value itself rather than one read again' do
      value = described_class::Length.new.parse('10px')

      expect(described_class::Length.new.match(value)).to be(value)
    end

    it 'should answer nothing for a value the matcher refuses' do
      value = described_class::Number.new.parse('-5')

      expect(described_class::Number.new(0..).match(value)).to be_nil
    end

    it 'should answer any value of the type when there is no matcher' do
      value = described_class::Number.new.parse('-5')

      expect(described_class::Number.new.match(value)).to be(value)
    end

    it 'should refuse a value of a kind none of its types reads' do
      value = described_class::Keyword.new.parse('none')

      expect((described_class::Length.new | :auto).match(value)).to be_nil
    end

    it 'should refuse a value of another kind whatever the matcher would say' do
      value = described_class::Keyword.new.parse('auto')

      expect(described_class::Url.new.match(value)).to be_nil
    end

    it 'should refuse a percentage when a number is asked for' do
      value = described_class::Percentage.new.parse('50%')

      expect(described_class::Number.new.match(value)).to be_nil
    end

    it 'should take an integer where a number is asked for, CSS making one a kind of the other' do
      value = described_class::Integer.new.parse('2')

      expect(described_class::Number.new.match(value)).to be(value)
    end

    it 'should leave something that is not a value at all to the matcher' do
      expect(described_class::Keyword.new(:auto).match(:auto)).to eq(:auto)
    end

    it 'should refuse a symbol the matcher does not name' do
      expect(described_class::Keyword.new(:auto).match(:none)).to be_nil
    end

    it 'should be what #parse checks once it has read the input' do
      expect(described_class::Number.new(0..).parse('-5')).to be_nil
    end

    it 'should answer nothing for nothing' do
      expect(described_class.complete.match(nil)).to be_nil
    end
  end

  describe '#===' do
    it 'should be true for input the type reads' do
      expect(described_class::Length.new === '10px').to be(true) # rubocop:disable Style/CaseEquality
    end

    it 'should be false for input the type refuses' do
      expect(described_class::Length.new === 'auto').to be(false) # rubocop:disable Style/CaseEquality
    end

    it 'should let a type stand where a matcher does' do
      expect(%w[10px auto].grep(described_class::Length.new)).to eq(['10px'])
    end
  end

  describe '#parse' do
    it 'should be left to the types that have a grammar' do
      expect { described_class.new.parse('10px') }.to raise_error(NotImplementedError)
    end
  end
end
