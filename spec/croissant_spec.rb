# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Croissant do
  it 'should have a version number' do
    expect(Croissant::VERSION).not_to be_nil
  end

  describe '.process' do
    it 'should process the html with the default pipeline' do
      expect(described_class.process('<style>p { color: red }</style><p>a</p>')).to eq('<p style="color:red">a</p>')
    end
  end
end
