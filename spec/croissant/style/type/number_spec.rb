# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Croissant::Style::Type::Number do
  def parse(input)
    described_class.new.parse(input)
  end

  describe '#parse' do
    it 'should parse a bare number' do
      expect(parse('1.5')).to be_a(Croissant::Style::Value::Number)
    end

    it 'should refuse a length' do
      expect(parse('10px')).to be_nil
    end

    it 'should refuse a percentage' do
      expect(parse('50%')).to be_nil
    end
  end
end
