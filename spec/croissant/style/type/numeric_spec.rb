# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Croissant::Style::Type::Numeric do
  def parse(input)
    described_class.new.parse(input)
  end

  describe '#parse' do
    it 'should parse a bare number' do
      expect(parse('1.5')).to be_a(Croissant::Style::Value::Number)
    end

    it 'should parse a length' do
      expect(parse('10px')).to be_a(Croissant::Style::Value::Length)
    end

    it 'should parse a percentage' do
      expect(parse('50%')).to be_a(Croissant::Style::Value::Percentage)
    end

    it 'should not parse something that is not a number' do
      expect(parse('auto')).to be_nil
    end

    it 'should read a unitless zero as a number rather than a length' do
      expect(parse('0')).to be_an_instance_of(Croissant::Style::Value::Number)
    end
  end
end
