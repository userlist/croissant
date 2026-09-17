# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Croissant::Style::Value::Union do
  let(:colour) { Croissant::Style::Value::Color }
  let(:keyword) { Croissant::Style::Value::Keyword }
  let(:length) { Croissant::Style::Value::Length }

  describe '.new' do
    it 'should keep the types it is given' do
      expect(described_class.new(length, keyword).types).to eq([length, keyword])
    end

    it 'should absorb a union rather than nesting it' do
      expect(described_class.new(length, described_class.new(colour, keyword)).types)
        .to eq([length, colour, keyword])
    end

    it 'should be frozen' do
      expect(described_class.new(length, keyword)).to be_frozen
    end

    it 'should freeze its types' do
      expect(described_class.new(length, keyword).types).to be_frozen
    end
  end

  describe 'symbols as keyword literals' do
    it 'should read a symbol as the keyword it names' do
      expect(described_class.new(length, :auto).types.last).to eq(:auto)
    end

    it 'should build a keyword, not keep the symbol' do
      expect(described_class.new(length, :auto).types.last).to be_a(keyword)
    end

    it 'should let a grammar be written the way CSS writes it' do
      expect((length | :auto).parse('auto')).to eq(:auto)
    end

    it 'should still refuse a keyword it does not name' do
      expect((length | :auto).parse('none')).to be_nil
    end

    it 'should build a whole set from symbols alone' do
      expect(described_class.new(:solid, :dotted).parse('dotted')).to eq(:dotted)
    end

    it 'should leave classes alone' do
      expect(described_class.new(length, :auto).types.first).to be(length)
    end

    it 'should chain through | as well as the initializer' do
      expect((length | :auto | :none).types.length).to eq(3)
    end
  end

  describe '#|' do
    it 'should build a union from two types' do
      expect(length | keyword).to be_a(described_class)
    end

    it 'should extend a union with a further type' do
      expect((length | keyword | colour).types).to eq([length, keyword, colour])
    end

    it 'should not nest when a union is on the right' do
      expect((length | (keyword | colour)).types).to eq([length, keyword, colour])
    end

    it 'should be associative, since the bracketing is only how it was written' do
      expect((length | keyword) | colour).to eq(length | (keyword | colour))
    end
  end

  describe '#parse' do
    it 'should return the value of the first type that recognizes the input' do
      expect((length | keyword).parse('10px')).to be_a(length)
    end

    it 'should fall through to a later type' do
      expect((length | keyword).parse('auto')).to be_a(keyword)
    end

    it 'should return nil when no type recognizes the input' do
      expect((length | colour).parse('auto')).to be_nil
    end

    it 'should ask the types in the order they were combined' do
      expect((colour | keyword).parse('red')).to be_a(colour)
    end

    it 'should read the same input differently in the other order' do
      expect((keyword | colour).parse('red')).to be_a(keyword)
    end
  end

  describe '#==' do
    it 'should be equal to a union of the same types' do
      first = length | keyword
      second = length | keyword

      expect(first).to eq(second)
    end

    it 'should not be equal to a union in a different order' do
      expect(length | keyword).not_to eq(keyword | length)
    end

    it 'should not be equal to a union of different types' do
      expect(length | keyword).not_to eq(length | colour)
    end

    it 'should not be equal to a bare class' do
      expect(described_class.new(length)).not_to eq(length)
    end
  end

  describe '#hash' do
    it 'should have the same hash as an equal union' do
      first = length | keyword
      second = length | keyword

      expect(first.hash).to eq(second.hash)
    end

    it 'should not have the hash of a union in a different order' do
      expect((length | keyword).hash).not_to eq((keyword | length).hash)
    end
  end

  describe '#inspect' do
    it 'should show the types it combines' do
      expected = '#<Croissant::Style::Value::Union ' \
                 '[Croissant::Style::Value::Length, Croissant::Style::Value::Keyword]>'

      expect((length | keyword).inspect).to eq(expected)
    end

    it 'should not leak an object address' do
      expect((length | keyword).inspect).not_to match(/0x\h{8,}/)
    end
  end
end
