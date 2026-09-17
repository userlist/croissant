# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Croissant::Style::Unit do
  describe '.lookup' do
    it 'should return the registered unit for a known name' do
      expect(described_class.lookup('px')).to be_a(described_class::Pixel)
    end

    it 'should return the registered unit for rem' do
      expect(described_class.lookup('rem')).to be_a(described_class::Rem)
    end

    it 'should return the same instance on every lookup' do
      unit = described_class.lookup('px')

      expect(described_class.lookup('px')).to be(unit)
    end

    it 'should ignore the case of the name' do
      expect(described_class.lookup('PX')).to be(described_class.lookup('px'))
    end

    it 'should accept a symbol' do
      expect(described_class.lookup(:px)).to be(described_class.lookup('px'))
    end

    it 'should return a plain unit for a name it does not model' do
      expect(described_class.lookup('ch')).to be_an_instance_of(described_class)
    end

    it 'should name the plain unit after the name it was looked up by' do
      expect(described_class.lookup('ch').name).to eq('ch')
    end

    it 'should keep a unit passed in directly' do
      unit = described_class::Pixel.new

      expect(described_class.lookup(unit)).to be(unit)
    end
  end

  describe '#absolutize' do
    it 'should return nil for a unit it does not model' do
      expect(described_class.new('ch').absolutize(2)).to be_nil
    end

    it 'should return the value unchanged for pixels' do
      expect(described_class::Pixel.new.absolutize(10)).to eq(10)
    end

    it 'should convert inches' do
      expect(described_class::Inch.new.absolutize(1)).to eq(96.0)
    end

    it 'should convert picas' do
      expect(described_class::Pica.new.absolutize(1)).to eq(16.0)
    end

    it 'should convert points' do
      expect(described_class::Point.new.absolutize(72)).to eq(96.0)
    end

    it 'should convert centimetres' do
      expect(described_class::Centimeter.new.absolutize(2.54)).to be_within(0.0001).of(96.0)
    end

    it 'should convert millimetres' do
      expect(described_class::Millimeter.new.absolutize(25.4)).to be_within(0.0001).of(96.0)
    end

    it 'should convert rems against a root font size' do
      expect(described_class::Rem.new.absolutize(2, root_font_size: 16)).to eq(32.0)
    end

    it 'should return nil for a rem without a root font size' do
      expect(described_class::Rem.new.absolutize(2)).to be_nil
    end

    it 'should not convert a rem against an element font size' do
      expect(described_class::Rem.new.absolutize(2, font_size: 16)).to be_nil
    end

    it 'should convert ems against a font size' do
      expect(described_class::Em.new.absolutize(2, font_size: 16)).to eq(32.0)
    end

    it 'should return nil for an em without a font size' do
      expect(described_class::Em.new.absolutize(2)).to be_nil
    end
  end

  describe '#==' do
    it 'should be equal to a unit of the same class and name' do
      first = described_class::Pixel.new
      second = described_class::Pixel.new

      expect(first).to eq(second)
    end

    it 'should be equal to a plain unit of the same name' do
      first = described_class.new('ch')
      second = described_class.new('ch')

      expect(first).to eq(second)
    end

    it 'should not be equal to a unit of another name' do
      expect(described_class.new('ch')).not_to eq(described_class.new('ex'))
    end

    it 'should not be equal to a modelled unit of the same name' do
      expect(described_class.new('px')).not_to eq(described_class::Pixel.new)
    end

    it 'should not be equal when compared the other way round' do
      expect(described_class::Pixel.new).not_to eq(described_class.new('px'))
    end
  end

  describe '#hash' do
    it 'should have the same hash as an equal unit' do
      first = described_class::Pixel.new
      second = described_class::Pixel.new

      expect(first.hash).to eq(second.hash)
    end

    it 'should differ from a plain unit of the same name' do
      expect(described_class.new('px').hash).not_to eq(described_class::Pixel.new.hash)
    end
  end

  describe '#freeze' do
    it 'should be frozen after initialization' do
      expect(described_class::Pixel.new).to be_frozen
    end

    it 'should freeze a unit built for a name it does not model' do
      expect(described_class.lookup('ch')).to be_frozen
    end

    it 'should freeze the name it wraps' do
      expect { described_class.lookup('ch').name << '!' }.to raise_error(FrozenError)
    end
  end

  describe '#to_s' do
    it 'should return the name' do
      expect(described_class::Pixel.new.to_s).to eq('px')
    end
  end

  describe '#to_sym' do
    it 'should return the name as a symbol' do
      expect(described_class::Pixel.new.to_sym).to eq(:px)
    end
  end

  describe '#inspect' do
    it 'should show the class and the name' do
      expect(described_class.lookup('px').inspect).to eq('#<Croissant::Style::Unit::Pixel "px">')
    end

    it 'should not leak an object address, which a length would then carry' do
      expect(described_class.lookup('px').inspect).not_to match(/0x\h{8,}/)
    end
  end
end
