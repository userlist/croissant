# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Croissant::Style::Cascade do
  def build_rule(selector, property, value, important: false)
    Croissant::Stylesheet::Rule.new(
      selector: Croissant::Stylesheet::Parser.parse_selector(selector),
      declarations: [Croissant::Stylesheet::Declaration.new(property:, value:, important:)]
    )
  end

  def build_declaration(property, value, important: false)
    Croissant::Style::Declaration.new(property, value, important:)
  end

  def build_attribute(css)
    Croissant::Stylesheet::Parser.parse_attribute(css)
  end

  def resolve(*rules)
    described_class.resolve(*rules)
  end

  def value(set, property)
    set[property]&.value
  end

  describe '.new' do
    it 'should be frozen' do
      expect(described_class.new([build_rule('p', 'color', 'red')])).to be_frozen
    end
  end

  describe '.resolve' do
    it 'should return a declaration set' do
      expect(resolve(build_rule('p', 'color', 'black'))).to be_a(Croissant::Style::DeclarationSet)
    end

    it 'should return a mutable declaration set' do
      expect(resolve(build_rule('p', 'color', 'black'))).not_to be_frozen
    end

    it 'should return an empty set without rules' do
      expect(resolve).to be_empty
    end

    it 'should resolve the value of a declared property' do
      expect(value(resolve(build_rule('p', 'color', 'black')), 'color')).to eq('black')
    end

    it 'should convert stylesheet declarations into style declarations' do
      expect(resolve(build_rule('p', 'color', 'black'))['color']).to eq(build_declaration('color', 'black'))
    end

    it 'should let a more specific rule win over a less specific one' do
      set = resolve(
        build_rule('p', 'color', 'black'),
        build_rule('#main', 'color', 'red'),
        build_rule('.intro', 'color', 'blue')
      )

      expect(value(set, 'color')).to eq('red')
    end

    it 'should break ties between equally specific rules by source order' do
      set = resolve(build_rule('.intro', 'color', 'blue'), build_rule('.lead', 'color', 'green'))

      expect(value(set, 'color')).to eq('green')
    end

    it 'should not depend on the order rules are given in' do
      set = resolve(build_rule('#main', 'color', 'red'), build_rule('p', 'color', 'black'))

      expect(value(set, 'color')).to eq('red')
    end

    it 'should let an important declaration win over a more specific normal one' do
      set = resolve(build_rule('#main', 'color', 'red'), build_rule('p', 'color', 'black', important: true))

      expect(value(set, 'color')).to eq('black')
    end

    it 'should break ties between important declarations by specificity and then source order' do
      set = resolve(
        build_rule('p', 'color', 'black', important: true),
        build_rule('.lead', 'color', 'green', important: true),
        build_rule('.intro', 'color', 'blue', important: true)
      )

      expect(value(set, 'color')).to eq('blue')
    end

    it 'should resolve each property independently' do
      set = resolve(build_rule('p', 'color', 'black'), build_rule('.intro', 'font-size', '12px'))

      expect(set.map(&:to_s)).to eq(['color:black', 'font-size:12px'])
    end

    it 'should let the last declaration of a property within a rule win' do
      rule = Croissant::Stylesheet::Rule.new(
        selector: Croissant::Stylesheet::Parser.parse_selector('p'),
        declarations: [
          Croissant::Stylesheet::Declaration.new(property: 'color', value: 'black'),
          Croissant::Stylesheet::Declaration.new(property: 'color', value: 'red')
        ]
      )

      expect(value(resolve(rule), 'color')).to eq('red')
    end

    it 'should order important declarations after normal ones' do
      set = resolve(build_rule('.a', 'display', 'block', important: true), build_rule('#b', 'color', 'red'))

      expect(set.map(&:to_s)).to eq(['color:red', 'display:block !important'])
    end

    it 'should expand a shorthand into its longhands' do
      set = resolve(build_rule('p', 'margin', '10px 20px'))

      expect(set.map(&:to_s)).to eq(['margin-top:10px', 'margin-right:20px', 'margin-bottom:10px', 'margin-left:20px'])
    end

    it 'should let a more specific longhand override part of a shorthand' do
      set = resolve(build_rule('#main', 'margin-top', '5px'), build_rule('p', 'margin', '1px'))

      expect(value(set, 'margin-top')).to eq('5px')
    end

    it 'should let a more specific shorthand override an earlier longhand' do
      set = resolve(build_rule('p', 'margin-top', '5px'), build_rule('#main', 'margin', '1px'))

      expect(value(set, 'margin-top')).to eq('1px')
    end

    it 'should ignore a shorthand declaration with an invalid value' do
      expect(resolve(build_rule('p', 'margin', '1px 2px 3px 4px 5px'))).to be_empty
    end

    it 'should let an important longhand win over a more specific shorthand' do
      set = resolve(build_rule('p', 'margin-top', '5px', important: true), build_rule('#main', 'margin', '1px'))

      expect(value(set, 'margin-top')).to eq('5px')
    end

    it 'should let an inline rule win over the rules' do
      set = resolve(build_rule('#main', 'color', 'red'), build_attribute('color: blue'))

      expect(value(set, 'color')).to eq('blue')
    end

    it 'should let an important rule win over an inline rule' do
      set = resolve(build_rule('p', 'color', 'red', important: true), build_attribute('color: blue'))

      expect(value(set, 'color')).to eq('red')
    end

    it 'should let an important inline rule win over important rules' do
      set = resolve(build_rule('p', 'color', 'red', important: true), build_attribute('color: blue !important'))

      expect(value(set, 'color')).to eq('blue')
    end

    it 'should accept rules given as separate arguments' do
      set = described_class.resolve(build_rule('p', 'color', 'red'), build_rule('p', 'margin-top', '1px'))

      expect(set.map(&:to_s)).to eq(['color:red', 'margin-top:1px'])
    end

    it 'should accept rules splatted from several arrays' do
      rules = [build_rule('p', 'color', 'red')]
      inline = [build_rule('p', 'margin-top', '1px')]

      expect(described_class.resolve(*rules, *inline).map(&:to_s)).to eq(['color:red', 'margin-top:1px'])
    end

    it 'should accept an empty splat' do
      expect(described_class.resolve(*[], build_rule('p', 'color', 'red')).size).to eq(1)
    end

    it 'should let the most specific rule win regardless of position' do
      set = resolve(
        build_rule('.a', 'color', 'blue'),
        build_rule('#main', 'color', 'red'),
        build_rule('p', 'color', 'black'),
        build_rule('.b', 'color', 'green')
      )

      expect(value(set, 'color')).to eq('red')
    end

    it 'should keep equally specific rules in the order given' do
      set = resolve(
        build_rule('p', 'color', 'black'),
        build_rule('.a', 'color', 'blue'),
        build_rule('.b', 'color', 'green'),
        build_rule('.c', 'color', 'yellow'),
        build_rule('div', 'color', 'gray')
      )

      expect(value(set, 'color')).to eq('yellow')
    end

    it 'should not reorder the array the rules were splatted from' do
      rules = [build_rule('p', 'color', 'red'), build_rule('#main', 'color', 'blue')]
      described_class.resolve(*rules)

      expect(rules.map { |rule| rule.selector.to_s }).to eq(['p', '#main'])
    end
  end

  describe '#resolve' do
    it 'should resolve like the class-level method' do
      rules = [build_rule('p', 'color', 'black'), build_rule('#main', 'color', 'red')]

      expect(described_class.new.resolve(*rules)).to eq(described_class.resolve(*rules))
    end

    it 'should use the declarations prepared for the rules given at construction' do
      rule = build_rule('p', 'color', 'red')
      cascade = described_class.new([rule])

      expect(cascade.resolve(rule)['color']).to be(cascade.declarations_for(rule).first)
    end

    it 'should resolve rules it was not built with' do
      cascade = described_class.new([build_rule('p', 'color', 'black')])

      expect(value(cascade.resolve(build_rule('#main', 'color', 'red')), 'color')).to eq('red')
    end
  end

  describe '#declarations_for' do
    def build_declarations(*declarations, important: false)
      rule = Croissant::Stylesheet::Rule.new(
        selector: Croissant::Stylesheet::Parser.parse_selector('p'),
        declarations: declarations.map do |property, value|
          Croissant::Stylesheet::Declaration.new(property:, value:, important:)
        end
      )

      described_class.new.declarations_for(rule)
    end

    it 'should return the same declarations every time for a rule given at construction' do
      rule = build_rule('p', 'color', 'red')
      cascade = described_class.new([rule])
      declarations = cascade.declarations_for(rule)

      expect(cascade.declarations_for(rule)).to be(declarations)
    end

    it 'should freeze the declarations prepared for a rule given at construction' do
      rule = build_rule('p', 'color', 'red')

      expect(described_class.new([rule]).declarations_for(rule)).to be_frozen
    end

    it 'should prepare other rules on the fly' do
      rule = build_rule('p', 'color', 'red')
      cascade = described_class.new
      declarations = cascade.declarations_for(rule)

      expect(cascade.declarations_for(rule)).not_to be(declarations)
    end

    it 'should convert stylesheet declarations into style declarations' do
      expect(build_declarations(%w[color red])).to eq([build_declaration('color', 'red')])
    end

    it 'should keep the important flag' do
      expect(build_declarations(%w[color red], important: true)).to all(be_important)
    end

    it 'should expand shorthands into their longhands' do
      expect(build_declarations(['margin', '1px 2px']).map(&:to_s))
        .to eq(['margin-top:1px', 'margin-right:2px', 'margin-bottom:1px', 'margin-left:2px'])
    end

    it 'should drop shorthands with an invalid value' do
      expect(build_declarations(['margin', '1px 2px 3px 4px 5px'])).to be_empty
    end

    it 'should accept style declarations as they are' do
      declaration = build_declaration('color', 'red')
      rule = Croissant::Stylesheet::Rule.new(declarations: [declaration], specificity: Croissant::Selector::Specificity.inline)

      expect(described_class.new.declarations_for(rule).first).to be(declaration)
    end
  end
end
