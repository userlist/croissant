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
    described_class.resolve(rules)
  end

  def value(set, property)
    set[property]&.value
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

    it 'should accept several collections of rules' do
      set = described_class.resolve([build_rule('p', 'color', 'red')], [build_rule('p', 'margin-top', '1px')])

      expect(set.map(&:to_s)).to eq(['color:red', 'margin-top:1px'])
    end

    it 'should order rules across collections by specificity' do
      set = described_class.resolve([build_rule('#main', 'color', 'red')], [build_rule('p', 'color', 'blue')])

      expect(value(set, 'color')).to eq('red')
    end

    it 'should break ties across collections by the order of the collections' do
      set = described_class.resolve([build_rule('p', 'color', 'red')], [build_rule('p', 'color', 'blue')])

      expect(value(set, 'color')).to eq('blue')
    end

    it 'should accept empty collections' do
      expect(described_class.resolve([], [build_rule('p', 'color', 'red')]).size).to eq(1)
    end
  end
end
