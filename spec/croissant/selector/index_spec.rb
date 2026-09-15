# frozen_string_literal: true

require 'spec_helper'
require 'nokogiri'

RSpec.describe Croissant::Selector::Index do
  def selector(value)
    Croissant::Stylesheet::Parser.parse_selector(value)
  end

  def element_for(html)
    Nokogiri::HTML.fragment(html).children.first
  end

  def build(entries)
    described_class.new do |index|
      entries.each { |payload, value| index.add(selector(value), payload) }
    end
  end

  describe '#[]' do
    it 'should return payloads whose selector matches by tag' do
      expect(build([[:p, 'p']])[element_for('<p></p>')]).to eq([:p])
    end

    it 'should return payloads whose selector matches by class' do
      expect(build([[:a, '.a']])[element_for('<p class="a"></p>')]).to eq([:a])
    end

    it 'should return payloads whose selector matches by id' do
      expect(build([[:a, '#a']])[element_for('<p id="a"></p>')]).to eq([:a])
    end

    it 'should return payloads with a universal selector for any element' do
      expect(build([[:all, '*']])[element_for('<p></p>')]).to eq([:all])
    end

    it 'should return payloads with an unindexable selector' do
      expect(build([[:attr, '[href]']])[element_for('<a href="#"></a>')]).to eq([:attr])
    end

    it 'should not return payloads whose selector does not match' do
      expect(build([[:p, 'p']])[element_for('<h1></h1>')]).to eq([])
    end

    it 'should not return payloads indexed by an unmatched class' do
      expect(build([[:a, '.a']])[element_for('<p class="b"></p>')]).to eq([])
    end

    it 'should return payloads in registration order regardless of bucket' do
      index = build([[:first, '*'], [:second, '#a'], [:third, 'p'], [:fourth, '.a']])

      expect(index[element_for('<p id="a" class="a"></p>')]).to eq(%i[first second third fourth])
    end

    it 'should return a payload once per matching selector' do
      index = build([[:cell, 'td'], [:cell, '.cell']])

      expect(index[element_for('<td class="cell"></td>')]).to eq(%i[cell cell])
    end

    it 'should return a payload once when the element repeats a class' do
      index = build([[:a, '.a']])

      expect(index[element_for('<p class="a a"></p>')]).to eq([:a])
    end

    it 'should find payloads for classes separated by any whitespace' do
      index = build([[:a, '.a'], [:b, '.b']])

      expect(index[element_for("<p class=\" a\t\nb \"></p>")]).to eq(%i[a b])
    end

    it 'should keep registration order across several class buckets' do
      index = build([[:b, '.b'], [:a, '.a']])

      expect(index[element_for('<p class="a b"></p>')]).to eq(%i[b a])
    end

    it 'should match descendants through a parent walk' do
      index = build([[:nested, 'div p']])
      element = element_for('<div><section><p></p></section></div>').at_css('p')

      expect(index[element]).to eq([:nested])
    end

    it 'should return an empty array for an empty index' do
      expect(described_class.new[element_for('<p></p>')]).to eq([])
    end
  end

  describe '#size' do
    it 'should count registrations' do
      expect(build([[:cell, 'td'], [:cell, 'th']]).size).to eq(2)
    end
  end

  describe '#empty?' do
    it 'should be true without payloads' do
      expect(described_class.new).to be_empty
    end

    it 'should be false with payloads' do
      expect(build([[:p, 'p']])).not_to be_empty
    end
  end

  describe '#freeze' do
    it 'should be frozen after initialization' do
      expect(build([[:p, 'p']])).to be_frozen
    end

    it 'should not accept payloads after initialization' do
      expect { build([]).add(selector('p'), :p) }.to raise_error(FrozenError)
    end
  end
end
