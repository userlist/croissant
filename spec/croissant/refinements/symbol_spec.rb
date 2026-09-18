# frozen_string_literal: true

require 'spec_helper'
require 'croissant/refinements/symbol'

RSpec.describe Croissant::Refinements::Symbol do
  using Croissant::Refinements::Symbol # rubocop:disable RSpec/DescribedClass

  it 'should build a union from two symbols' do
    expect(:left | :center).to be_a(Croissant::Style::Type::Union)
  end

  it 'should read each symbol as the keyword it names' do
    expect((:left | :center).parse('center')).to eq(:center)
  end

  it 'should refuse a keyword it does not name' do
    expect((:left | :center).parse('right')).to be_nil
  end

  it 'should chain into a single union rather than nesting' do
    expect((:left | :center | :right).types.length).to eq(3)
  end

  it 'should combine with a type on the right' do
    expect((:auto | Croissant::Style::Type::Length.new).parse('10px').to_s).to eq('10px')
  end
end
