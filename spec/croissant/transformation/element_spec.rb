# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Croissant::Transformation::Element do
  describe '.selectors' do
    it 'should return an empty list by default' do
      expect(Class.new(described_class).selectors).to eq([])
    end

    it 'should parse the given selectors' do
      klass = Class.new(described_class) { selector 'table' }

      expect(klass.selectors).to eq([Croissant::Stylesheet::Parser.parse_selector('table')])
    end

    it 'should split selector lists' do
      klass = Class.new(described_class) { selector 'table, td' }

      expect(klass.selectors.map(&:to_s)).to eq(%w[table td])
    end

    it 'should accept several arguments' do
      klass = Class.new(described_class) { selector 'table', 'td' }

      expect(klass.selectors.map(&:to_s)).to eq(%w[table td])
    end

    it 'should return a frozen list' do
      expect(Class.new(described_class) { selector 'p' }.selectors).to be_frozen
    end
  end

  describe '#selectors' do
    it 'should return the class-level selectors' do
      klass = Class.new(described_class) { selector 'p' }

      expect(klass.new.selectors).to eq(klass.selectors)
    end

    it 'should parse a selector the instance was given' do
      expect(described_class.new('span').selectors.map(&:to_s)).to eq(['span'])
    end

    it 'should split a selector list the instance was given' do
      expect(described_class.new('table, td').selectors.map(&:to_s)).to eq(%w[table td])
    end

    it 'should accept several selectors from the instance' do
      expect(described_class.new(%w[span a]).selectors.map(&:to_s)).to eq(%w[span a])
    end

    it 'should read the instance selectors ahead of the ones its class names' do
      klass = Class.new(described_class) { selector 'p' }

      expect(klass.new('span').selectors.map(&:to_s)).to eq(%w[span p])
    end

    it 'should be empty when neither names one' do
      expect(described_class.new.selectors).to eq([])
    end

    it 'should return a frozen list' do
      expect(described_class.new('span').selectors).to be_frozen
    end
  end

  describe '#call' do
    it 'should raise when not implemented' do
      expect { described_class.new.call(nil) }.to raise_error(NotImplementedError)
    end
  end
end
