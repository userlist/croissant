# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Croissant::Style::Type::Percentage do
  def parse(input)
    described_class.new.parse(input)
  end

  describe '#parse' do
    it 'should parse a percentage' do
      expect(parse('50%')).to be_a(Croissant::Style::Value::Percentage)
    end

    it 'should refuse a length' do
      expect(parse('10px')).to be_nil
    end
  end
end
