# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Croissant::Selector::Unknown do
  subject(:selector) { described_class.new('a: hover, svg|rect') }

  let(:element) { Croissant::Document.parse('<a>x</a>').at_xpath('.//a') }

  it 'should serialize as written' do
    expect(selector.to_s).to eq('a: hover, svg|rect')
  end

  it 'should not be inlinable' do
    expect(selector).not_to be_inlinable
  end

  it 'should not match any element' do
    expect(selector).not_to be_matches(element)
  end

  it 'should have zero specificity' do
    expect(selector.specificity).to eq(Croissant::Selector::Specificity.zero)
  end

  it 'should compare by text' do
    expect(selector).to eq(described_class.new('a: hover, svg|rect'))
  end
end
