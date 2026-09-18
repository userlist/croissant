# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Croissant::Style::Type::Unparsed do
  def parse(input)
    described_class.new.parse(input)
  end

  describe '#parse' do
    it 'should read anything at all' do
      expect(parse('calc(1px + 2px)')).to be_a(Croissant::Style::Value::Unparsed)
    end

    it 'should keep the text exactly as it was written' do
      expect(parse('calc(1px + 2px)').to_s).to eq('calc(1px + 2px)')
    end
  end
end
