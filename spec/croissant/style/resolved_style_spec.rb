# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Croissant::Style::ResolvedStyle do
  def build_rule(selector, property, value, important: false)
    Croissant::Stylesheet::Rule.new(
      selector: Croissant::Stylesheet::Parser.parse_selector(selector),
      declarations: [Croissant::Stylesheet::Declaration.new(property:, value:, important:)]
    )
  end

  describe '#[]' do
    it 'should return the value of a declared property' do
      style = described_class.new([build_rule('p', 'color', 'black')])

      expect(style['color']).to eq('black')
    end

    it 'should return nil for a property that was never declared' do
      style = described_class.new([build_rule('p', 'color', 'black')])

      expect(style['font-size']).to be_nil
    end

    it 'should let a more specific rule win over a less specific one' do
      style = described_class.new([
        build_rule('p', 'color', 'black'),
        build_rule('#main', 'color', 'red'),
        build_rule('.intro', 'color', 'blue')
      ])

      expect(style['color']).to eq('red')
    end

    it 'should break ties between equally specific rules by source order' do
      style = described_class.new([
        build_rule('.intro', 'color', 'blue'),
        build_rule('.lead', 'color', 'green')
      ])

      expect(style['color']).to eq('green')
    end

    it 'should not depend on the order rules are given in' do
      style = described_class.new([
        build_rule('#main', 'color', 'red'),
        build_rule('p', 'color', 'black')
      ])

      expect(style['color']).to eq('red')
    end

    it 'should let an important declaration win over a more specific normal one' do
      style = described_class.new([
        build_rule('#main', 'color', 'red'),
        build_rule('p', 'color', 'black', important: true)
      ])

      expect(style['color']).to eq('black')
    end

    it 'should break ties between important declarations by specificity and then source order' do
      style = described_class.new([
        build_rule('p', 'color', 'black', important: true),
        build_rule('.lead', 'color', 'green', important: true),
        build_rule('.intro', 'color', 'blue', important: true)
      ])

      expect(style['color']).to eq('blue')
    end

    it 'should resolve an unrelated property from another rule' do
      style = described_class.new([
        build_rule('p', 'color', 'black'),
        build_rule('.intro', 'font-size', '12px')
      ])

      expect(style['color']).to eq('black')
    end

    it 'should resolve each property independently' do
      style = described_class.new([
        build_rule('p', 'color', 'black'),
        build_rule('.intro', 'font-size', '12px')
      ])

      expect(style['font-size']).to eq('12px')
    end

    it 'should let the last declaration of a property within a rule win' do
      rule = Croissant::Stylesheet::Rule.new(
        selector: Croissant::Stylesheet::Parser.parse_selector('p'),
        declarations: [
          Croissant::Stylesheet::Declaration.new(property: 'color', value: 'black'),
          Croissant::Stylesheet::Declaration.new(property: 'color', value: 'red')
        ]
      )

      expect(described_class.new([rule])['color']).to eq('red')
    end

    it 'should look up a property given as a Property instance' do
      style = described_class.new([build_rule('p', 'color', 'black')])

      expect(style[Croissant::Stylesheet::Property.new('color')]).to eq('black')
    end

    it 'should resolve a longhand from a shorthand declaration' do
      style = described_class.new([build_rule('p', 'margin', '10px 20px')])

      expect(style['margin-top']).to eq('10px')
    end

    it 'should let a more specific longhand override part of a shorthand' do
      style = described_class.new([
        build_rule('#main', 'margin-top', '5px'),
        build_rule('p', 'margin', '1px')
      ])

      expect(style['margin-top']).to eq('5px')
    end

    it 'should let a more specific shorthand override an earlier longhand' do
      style = described_class.new([
        build_rule('p', 'margin-top', '5px'),
        build_rule('#main', 'margin', '1px')
      ])

      expect(style['margin-top']).to eq('1px')
    end

    it 'should return nil for a shorthand since only longhands are resolved' do
      style = described_class.new([build_rule('p', 'margin', '1px')])

      expect(style['margin']).to be_nil
    end

    it 'should ignore a shorthand declaration with an invalid value' do
      style = described_class.new([build_rule('p', 'margin', '1px 2px 3px 4px 5px')])

      expect(style['margin-top']).to be_nil
    end

    it 'should let an important longhand win over a more specific shorthand' do
      style = described_class.new([
        build_rule('p', 'margin-top', '5px', important: true),
        build_rule('#main', 'margin', '1px')
      ])

      expect(style['margin-top']).to eq('5px')
    end
  end

  describe '#to_s' do
    it 'should format each property and value as declaration syntax' do
      style = described_class.new([build_rule('p', 'color', 'black')])

      expect(style.to_s).to eq('color:black')
    end

    it 'should join multiple properties with a semicolon' do
      style = described_class.new([
        build_rule('p', 'color', 'black'),
        build_rule('p', 'font-size', '12px')
      ])

      expect(style.to_s).to eq('color:black;font-size:12px')
    end

    it 'should collapse a complete set of longhands into their shorthand' do
      style = described_class.new([build_rule('p', 'margin', '0')])

      expect(style.to_s).to eq('margin:0')
    end

    it 'should collapse an overridden longhand back into the shorthand' do
      style = described_class.new([
        build_rule('p', 'margin', '0'),
        build_rule('#b', 'margin-top', '5px')
      ])

      expect(style.to_s).to eq('margin:5px 0 0')
    end

    it 'should collapse independently declared longhands into their shorthand' do
      style = described_class.new([
        build_rule('p', 'margin-top', '1px'),
        build_rule('p', 'margin-right', '2px'),
        build_rule('p', 'margin-bottom', '3px'),
        build_rule('p', 'margin-left', '4px')
      ])

      expect(style.to_s).to eq('margin:1px 2px 3px 4px')
    end

    it 'should emit the shorthand at the position of its first longhand' do
      style = described_class.new([
        build_rule('p', 'margin', '0'),
        build_rule('p', 'color', 'red')
      ])

      expect(style.to_s).to eq('margin:0;color:red')
    end

    it 'should keep longhands when the set is incomplete' do
      style = described_class.new([
        build_rule('p', 'margin-top', '1px'),
        build_rule('p', 'margin-left', '2px')
      ])

      expect(style.to_s).to eq('margin-top:1px;margin-left:2px')
    end

    it 'should keep longhands when their importance differs' do
      style = described_class.new([
        build_rule('p', 'margin', '0'),
        build_rule('p', 'margin-top', '5px', important: true)
      ])

      expect(style.to_s).to eq('margin-right:0;margin-bottom:0;margin-left:0;margin-top:5px !important')
    end

    it 'should return an empty string when no properties were resolved' do
      expect(described_class.new([]).to_s).to eq('')
    end

    it 'should emit the important flag of a winning important declaration' do
      style = described_class.new([build_rule('p', 'color', 'black', important: true)])

      expect(style.to_s).to eq('color:black !important')
    end

    it 'should emit the important flag only on the important declarations' do
      style = described_class.new([
        build_rule('p', 'color', 'black', important: true),
        build_rule('p', 'font-size', '12px')
      ])

      expect(style.to_s).to eq('font-size:12px;color:black !important')
    end

    it 'should emit important declarations after normal ones' do
      style = described_class.new([
        build_rule('.a', 'display', 'block', important: true),
        build_rule('#b', 'color', 'red')
      ])

      expect(style.to_s).to eq('color:red;display:block !important')
    end

    it 'should keep the important flag when collapsing an important shorthand' do
      style = described_class.new([build_rule('p', 'padding', '0', important: true)])

      expect(style.to_s).to eq('padding:0 !important')
    end
  end

  describe '#==' do
    it 'should be equal when the resolved properties match' do
      first = described_class.new([build_rule('p', 'color', 'black')])
      second = described_class.new([build_rule('.intro', 'color', 'black')])

      expect(first).to eq(second)
    end

    it 'should not be equal when the resolved properties differ' do
      first = described_class.new([build_rule('p', 'color', 'black')])
      second = described_class.new([build_rule('p', 'color', 'red')])

      expect(first).not_to eq(second)
    end

    it 'should not be equal to an object of another class' do
      style = described_class.new([build_rule('p', 'color', 'black')])

      expect(style).not_to eq('color:black')
    end
  end

  describe '#hash' do
    it 'should have the same hash as an equal style' do
      first = described_class.new([build_rule('p', 'color', 'black')])
      second = described_class.new([build_rule('.intro', 'color', 'black')])

      expect(first.hash).to eq(second.hash)
    end

    it 'should collapse equal styles when used as a Hash key' do
      first = described_class.new([build_rule('p', 'color', 'black')])
      second = described_class.new([build_rule('.intro', 'color', 'black')])

      expect({ first => 1, second => 2 }.size).to eq(1)
    end
  end

  describe '#freeze' do
    it 'should be frozen after initialization' do
      expect(described_class.new([build_rule('p', 'color', 'black')])).to be_frozen
    end

    it 'should freeze the resolved properties' do
      expect(described_class.new([build_rule('p', 'color', 'black')]).declarations).to be_frozen
    end
  end
end
