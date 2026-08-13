# frozen_string_literal: true

require 'spec_helper'
require 'nokogiri'

RSpec.describe Croissant::Style::RuleSet do
  def build_rule(selector)
    Croissant::Stylesheet::Rule.new(
      selector: Croissant::Stylesheet::Parser.parse_selector(selector),
      declarations: []
    )
  end

  def element_for(html)
    Nokogiri::HTML.fragment(html).children.first
  end

  describe '#[]' do
    it 'should return rules whose selector matches the element by tag' do
      rule = build_rule('p')
      rule_set = described_class.new([rule])

      expect(rule_set[element_for('<p></p>')]).to eq([rule])
    end

    it 'should return rules whose selector matches the element by class' do
      rule = build_rule('.intro')
      rule_set = described_class.new([rule])

      expect(rule_set[element_for('<p class="intro"></p>')]).to eq([rule])
    end

    it 'should return rules whose selector matches the element by id' do
      rule = build_rule('#main')
      rule_set = described_class.new([rule])

      expect(rule_set[element_for('<p id="main"></p>')]).to eq([rule])
    end

    it 'should return rules with no indexable tag, class, or id' do
      rule = build_rule('[href]')
      rule_set = described_class.new([rule])

      expect(rule_set[element_for('<a href="/"></a>')]).to eq([rule])
    end

    it 'should not return rules whose selector does not match the element' do
      rule = build_rule('.intro')
      rule_set = described_class.new([rule])

      expect(rule_set[element_for('<p class="other"></p>')]).to eq([])
    end

    it 'should ignore rules without a selector' do
      declarations = [Croissant::Stylesheet::Declaration.new(property: 'color', value: 'red')]
      rule = Croissant::Stylesheet::Rule.new(
        declarations: declarations,
        specificity: Croissant::Selector::Specificity.inline
      )
      rule_set = described_class.new([rule])

      expect(rule_set[element_for('<p></p>')]).to eq([])
    end

    it 'should not return a rule more than once when the element matches it through several features' do
      rule = build_rule('p.intro')
      rule_set = described_class.new([rule])

      expect(rule_set[element_for('<p class="intro"></p>')]).to eq([rule])
    end

    it 'should return rules matched through different index buckets in source order' do
      rules = [build_rule('#main'), build_rule('p'), build_rule('.intro'), build_rule('[href]')]
      rule_set = described_class.new(rules)

      expect(rule_set[element_for('<p id="main" class="intro" href="/"></p>')]).to eq(rules)
    end

    it 'should return rules matching any of several classes on the element' do
      rules = [build_rule('.intro'), build_rule('.lead')]
      rule_set = described_class.new(rules)

      expect(rule_set[element_for('<p class="intro lead"></p>')]).to eq(rules)
    end

    it 'should return rules with a universal selector for any element' do
      rule = build_rule('*')
      rule_set = described_class.new([rule])

      expect(rule_set[element_for('<p></p>')]).to eq([rule])
    end

    it 'should not return rules for an element with a different id' do
      rule_set = described_class.new([build_rule('#main')])

      expect(rule_set[element_for('<p id="other"></p>')]).to eq([])
    end

    it 'should return an empty array when built without rules' do
      expect(described_class.new([])[element_for('<p></p>')]).to eq([])
    end
  end

  describe '#freeze' do
    it 'should be frozen after initialization' do
      expect(described_class.new([build_rule('p')])).to be_frozen
    end
  end
end
