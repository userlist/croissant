# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Croissant do
  it 'should have a version number' do
    expect(Croissant::VERSION).not_to be_nil
  end

  describe 'the global namespace' do
    it 'should not gain any of the value classes by requiring croissant' do
      names = %i[Union Length Percentage Color Keyword Unparsed List Value Unit Property Declaration]
      leaked = names.select { |name| Object.const_defined?(name, false) }

      expect(leaked).to be_empty
    end

    it 'should keep ::Integer, which Type::Integer shadows inside the library' do
      expect(Integer).not_to be(Croissant::Style::Type::Integer)
    end

    it 'should keep ::Numeric, which Value::Numeric shadows inside the library' do
      expect(Numeric).not_to be(Croissant::Style::Value::Numeric)
    end
  end

  describe '.process' do
    it 'should process the html with the default pipeline' do
      expect(described_class.process('<style>p { color: red }</style><p>a</p>')).to eq('<p style="color:red">a</p>')
    end
  end
end
