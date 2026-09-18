# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Croissant::Style::Type::Color do
  def parse(input)
    described_class.new.parse(input)
  end

  describe '#parse' do
    it 'should parse a colour notation' do
      expect(parse('#fff')).to be_a(Croissant::Style::Value::Color)
    end

    it 'should not parse something that is not a colour' do
      expect(parse('auto')).to be_nil
    end

    it 'should expand a three-digit hex colour' do
      expect(parse('#abc').to_s).to eq('#aabbcc')
    end

    it 'should read the alpha of an rgba colour' do
      expect(parse('rgba(0, 0, 0, 0.5)').alpha).to eq(0.5)
    end

    it 'should ignore the case of a hex colour' do
      expect(parse('#FFF')).to eq(parse('#fff'))
    end

    it 'should read equivalent notations as the same colour' do
      expect(parse('rgb(255, 0, 0)')).to eq(parse('#ff0000'))
    end

    it 'should accept percentage channels' do
      expect(parse('rgb(100% 0% 0%)').to_s).to eq('#ff0000')
    end

    it 'should accept the slash-separated alpha form' do
      expect(parse('rgb(0 0 0 / 50%)').alpha).to eq(0.5)
    end

    it 'should clamp a channel beyond its range' do
      expect(parse('rgb(300, -20, 0)').to_s).to eq('#ff0000')
    end
  end

  describe 'a named colour' do
    it 'should parse a named colour' do
      expect(parse('red').to_s).to eq('#ff0000')
    end

    it 'should ignore the case of a name' do
      expect(parse('RebeccaPurple').to_s).to eq('#663399')
    end

    it 'should equal the same colour written as hex' do
      expect(parse('red')).to eq(parse('#ff0000'))
    end

    it 'should parse transparent as a fully transparent colour' do
      expect(parse('transparent').alpha).to eq(0.0)
    end

    it 'should not parse currentcolor, which needs an element to resolve' do
      expect(parse('currentcolor')).to be_nil
    end

    it 'should not parse an identifier that is not a colour' do
      expect(parse('notacolour')).to be_nil
    end
  end

  describe 'narrowed to an alpha' do
    it 'should narrow to an alpha' do
      expect(described_class.new(nil, 1).parse('rgba(0, 0, 0, 0.5)')).to be_nil
    end

    it 'should keep a colour carrying that alpha' do
      expect(described_class.new(nil, 1).parse('red').to_s).to eq('#ff0000')
    end

    it 'should read a whole number against the alpha it holds' do
      expect(described_class.new(nil, 0).parse('transparent').alpha).to eq(0.0)
    end

    it 'should match the alpha with a range' do
      expect(described_class.new(nil, 0.5..).parse('rgba(0, 0, 0, 0.25)')).to be_nil
    end

    it 'should keep an alpha the range covers' do
      expect(described_class.new(nil, 0.5..).parse('rgba(0, 0, 0, 0.75)').alpha).to eq(0.75)
    end

    it 'should narrow on the colour and the alpha at once' do
      expect(described_class.new(/\A#ff/, 1).parse('rgba(0, 0, 255, 1)')).to be_nil
    end

    it 'should refuse a value that has no alpha rather than ask it for one' do
      keyword = Croissant::Style::Type::Keyword.new.parse('auto')

      expect(described_class.new(nil, 1).match(keyword)).to be_nil
    end

    it 'should take part in equality' do
      expect(described_class.new(nil, 1)).not_to eq(described_class.new(nil, 0))
    end

    it 'should show in the inspect output' do
      expect(described_class.new(nil, 1).inspect).to eq('#<Croissant::Style::Type::Color 1>')
    end
  end
end
