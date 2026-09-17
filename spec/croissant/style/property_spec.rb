# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Croissant::Style::Property do
  describe '.lookup' do
    it 'should return the definition of a registered property' do
      expect(described_class.lookup('margin-top').initial).to eq(Croissant::Style::Value::Length['0'])
    end

    it 'should return an inherited definition for an inherited property' do
      expect(described_class.lookup('color')).to be_inherited
    end

    it 'should return a non-inherited definition for a reset property' do
      expect(described_class.lookup('margin-top')).not_to be_inherited
    end

    it 'should return the same definition instance on every lookup' do
      first = described_class.lookup('color')
      second = described_class.lookup('color')

      expect(first).to be(second)
    end

    it 'should keep a definition it is handed rather than looking it up' do
      property = described_class.new('color')

      expect(described_class.lookup(property)).to be(property)
    end

    it 'should return a fallback definition named after an unknown property' do
      expect(described_class.lookup('-webkit-text-size-adjust').name).to eq('-webkit-text-size-adjust')
    end

    it 'should return a fallback definition without an initial value' do
      expect(described_class.lookup('unknown').initial).to be_nil
    end

    it 'should return a fallback definition that does not inherit' do
      expect(described_class.lookup('unknown')).not_to be_inherited
    end

    it 'should not memoize a fallback, which would cache on untrusted names' do
      first = described_class.lookup('unknown')
      second = described_class.lookup('unknown')

      expect(first).not_to be(second)
    end

    it 'should return a shorthand definition for a four-side shorthand' do
      expect(described_class.lookup('margin')).to be_a(described_class::Shorthand)
    end

    it 'should map a four-side shorthand onto its longhands' do
      expect(described_class.lookup('margin').longhands).to eq(
        %w[margin-top margin-right margin-bottom margin-left]
      )
    end

    it 'should not set a shorthand on a standalone property' do
      expect(described_class.lookup('color').shorthand).to be_nil
    end

    it 'should link every longhand of every shorthand back to it' do
      %w[margin padding inset border-color border-style border-width].each do |name|
        shorthand = described_class.lookup(name)
        longhands = shorthand.longhands.map { |longhand| described_class.lookup(longhand).shorthand }

        expect(longhands).to all(be(shorthand))
      end
    end
  end

  describe '.registry' do
    it 'should hold every built-in property' do
      expect(described_class.registry.count).to eq(described_class::BUILT_IN.size)
    end

    it 'should be the same registry on every call' do
      first = described_class.registry
      second = described_class.registry

      expect(first).to be(second)
    end
  end

  describe '#initial' do
    it 'should return the initial value' do
      property = described_class.new('color', initial: 'canvastext')

      expect(property.initial).to eq('canvastext')
    end

    it 'should default to nil' do
      expect(described_class.new('font-family').initial).to be_nil
    end

    it 'should read the initial value through the type of the property' do
      expect(described_class.lookup('margin-top').initial).to be_a(Croissant::Style::Value::Length)
    end

    it 'should read a unitless zero initial as a zero length' do
      expect(described_class.lookup('margin-top').initial).to eq(Croissant::Style::Value::Length['0'])
    end

    it 'should read a keyword initial as a keyword' do
      expect(described_class.lookup('width').initial).to be_a(Croissant::Style::Value::Keyword)
    end

    it 'should read a colour initial as a colour' do
      expect(described_class.lookup('background-color').initial).to be_a(Croissant::Style::Value::Color)
    end

    it 'should read a multi-token initial as a list' do
      expect(described_class.lookup('background-position').initial).to be_a(Croissant::Style::Value::List)
    end
  end

  describe '#inherited?' do
    it 'should be true when the property inherits' do
      expect(described_class.new('color', inherited: true)).to be_inherited
    end

    it 'should default to false' do
      expect(described_class.new('margin-top')).not_to be_inherited
    end
  end

  describe '#expand' do
    it 'should return the declaration itself' do
      declaration = Croissant::Style::Declaration.new('color', 'black')

      expect(described_class.new('color').expand(declaration)).to eq([declaration])
    end
  end

  describe '#shorthand' do
    it 'should be nil by default' do
      expect(described_class.new('color').shorthand).to be_nil
    end

    it 'should return the shorthand the property belongs to' do
      shorthand = Croissant::Style::Property::Shorthand.new('margin', %w[margin-top])

      expect(described_class.new('margin-top', shorthand:).shorthand).to be(shorthand)
    end
  end

  describe '#collapse' do
    it 'should return the declaration set unchanged without a shorthand' do
      declarations = Croissant::Style::DeclarationSet.new([Croissant::Style::Declaration.new('color', 'black')])

      expect(described_class.new('color').collapse(declarations)).to be(declarations)
    end

    it 'should defer to its shorthand' do
      shorthand = Croissant::Style::Property::Shorthand.new('margin', %w[margin-top])
      property = described_class.new('margin-top', shorthand:)
      declarations = Croissant::Style::DeclarationSet.new([Croissant::Style::Declaration.new(property, '10px')])

      expect(property.collapse(declarations).map(&:to_s)).to eq(['margin:10px'])
    end
  end

  describe '#==' do
    it 'should be equal when name, initial value, and inheritance match' do
      first = described_class.new('color', initial: 'canvastext', inherited: true)
      second = described_class.new('color', initial: 'canvastext', inherited: true)

      expect(first).to eq(second)
    end

    it 'should not be equal when the name differs' do
      expect(described_class.new('color')).not_to eq(described_class.new('background-color'))
    end

    it 'should not be equal when the initial value differs' do
      first = described_class.new('color', initial: 'canvastext')
      second = described_class.new('color', initial: 'black')

      expect(first).not_to eq(second)
    end

    it 'should not be equal when inheritance differs' do
      first = described_class.new('color', inherited: true)
      second = described_class.new('color', inherited: false)

      expect(first).not_to eq(second)
    end

    it 'should not be equal when the shorthand differs' do
      shorthand = Croissant::Style::Property::Shorthand.new('margin', %w[margin-top])

      expect(described_class.new('margin-top', shorthand:)).not_to eq(described_class.new('margin-top'))
    end

    it 'should not be equal to an object of another class' do
      expect(described_class.new('color')).not_to eq('color')
    end
  end

  describe '#hash' do
    it 'should have the same hash as an equal property' do
      first = described_class.new('color', initial: 'canvastext', inherited: true)
      second = described_class.new('color', initial: 'canvastext', inherited: true)

      expect(first.hash).to eq(second.hash)
    end
  end

  describe '#freeze' do
    it 'should be frozen after initialization' do
      expect(described_class.new('color')).to be_frozen
    end
  end

  describe '#type' do
    it 'should default to the generic chain' do
      expect(described_class.new('color').type).to eq(Croissant::Style::Value.default_type | Croissant::Style::Value.global_type)
    end

    it 'should keep the types it is given' do
      type = Croissant::Style::Value::Color | Croissant::Style::Value::Keyword

      expect(described_class.new('color', type:).type).to eq(type | Croissant::Style::Value.global_type)
    end

    it 'should accept a bare class as a type' do
      property = described_class.new('color', type: Croissant::Style::Value::Color)

      expect(property.parse_value('#fff')).to be_a(Croissant::Style::Value::Color)
    end

    it 'should append the CSS-wide keywords to whatever type it is given' do
      property = described_class.new('color', type: Croissant::Style::Value::Color)

      expect(property.parse_value('inherit')).to eq(:inherit)
    end

    it 'should let a narrowed keyword type still take the CSS-wide keywords' do
      property = described_class.new('width', type: Croissant::Style::Value::Keyword[:auto])

      expect(property.parse_value('initial')).to eq(:initial)
    end

    it 'should still refuse a keyword a narrowed type does not name' do
      property = described_class.new('width', type: Croissant::Style::Value::Keyword[:auto])

      expect(property.parse_value('block')).to be_a(Croissant::Style::Value::Unparsed)
    end

    it 'should not freeze a bare class, which would freeze the class itself' do
      described_class.new('color', type: Croissant::Style::Value::Color)

      expect(Croissant::Style::Value::Color).not_to be_frozen
    end

    it 'should take part in equality' do
      first = described_class.new('color', type: Croissant::Style::Value::Color)
      second = described_class.new('color', type: Croissant::Style::Value::Keyword)

      expect(first).not_to eq(second)
    end

    it 'should take part in the hash' do
      first = described_class.new('color', type: Croissant::Style::Value::Color)
      second = described_class.new('color', type: Croissant::Style::Value::Keyword)

      expect(first.hash).not_to eq(second.hash)
    end
  end

  describe '#parse_value' do
    def build(*types)
      described_class.new('example', type: types.reduce(:|))
    end

    it 'should parse with the types of the property' do
      property = build(Croissant::Style::Value::Color, Croissant::Style::Value::Keyword)

      expect(property.parse_value('red')).to be_a(Croissant::Style::Value::Color)
    end

    it 'should read the same value as a keyword for a property that wants no colour' do
      expect(build.parse_value('red')).to be_a(Croissant::Style::Value::Keyword)
    end

    it 'should keep a value none of its types recognize' do
      expect(build(Croissant::Style::Value::Color).parse_value('auto')).to be_a(Croissant::Style::Value::Unparsed)
    end

    it 'should keep the text of a value it does not recognize' do
      property = build(Croissant::Style::Value::Color)

      expect(property.parse_value('calc(1px + 2px)').to_s).to eq('calc(1px + 2px)')
    end

    it 'should accept only the keywords a narrowed type names' do
      allowed = Croissant::Style::Value::Keyword[:auto] | Croissant::Style::Value::Keyword[:none]

      expect(build(allowed).parse_value('auto')).to eq(:auto)
    end

    it 'should keep a keyword a narrowed type does not name' do
      allowed = Croissant::Style::Value::Keyword[:auto] | Croissant::Style::Value::Keyword[:none]

      expect(build(allowed).parse_value('block')).to be_a(Croissant::Style::Value::Unparsed)
    end

    it 'should return nil for a blank value' do
      expect(build.parse_value('')).to be_nil
    end

    it 'should return a value it is given unchanged' do
      value = Croissant::Style::Value::Keyword.new('auto')

      expect(build.parse_value(value)).to be(value)
    end
  end

  describe 'the built-in types' do
    def parse(name, input)
      described_class.lookup(name).parse_value(input)
    end

    it 'should read z-index as an integer' do
      expect(parse('z-index', '2')).to be_a(Croissant::Style::Value::Integer)
    end

    it 'should refuse a fractional z-index rather than claim to understand it' do
      expect(parse('z-index', '2.5')).to be_a(Croissant::Style::Value::Unparsed)
    end

    it 'should accept auto on width' do
      expect(parse('width', 'auto')).to eq(:auto)
    end

    it 'should refuse auto on max-width, where CSS does not allow it' do
      expect(parse('max-width', 'auto')).to be_a(Croissant::Style::Value::Unparsed)
    end

    it 'should accept none on max-width' do
      expect(parse('max-width', 'none')).to eq(:none)
    end

    it 'should refuse none on width, where CSS does not allow it' do
      expect(parse('width', 'none')).to be_a(Croissant::Style::Value::Unparsed)
    end

    it 'should refuse a keyword the property does not take' do
      expect(parse('width', 'block')).to be_a(Croissant::Style::Value::Unparsed)
    end

    it 'should refuse auto on padding, which takes no keywords of its own' do
      expect(parse('padding-top', 'auto')).to be_a(Croissant::Style::Value::Unparsed)
    end

    it 'should still take the CSS-wide keywords on a narrowed property' do
      expect(parse('padding-top', 'inherit')).to eq(:inherit)
    end

    it 'should read a border style keyword' do
      expect(parse('border-top-style', 'dotted')).to eq(:dotted)
    end

    it 'should refuse a border style that does not exist' do
      expect(parse('border-top-style', 'wiggly')).to be_a(Croissant::Style::Value::Unparsed)
    end

    it 'should keep an open keyword on colour properties, for the system colours' do
      expect(parse('color', 'canvastext')).to be_a(Croissant::Style::Value::Keyword)
    end
  end

  describe 'BUILT_IN' do
    it 'should be frozen' do
      expect(described_class::BUILT_IN).to be_frozen
    end

    it 'should hold property definitions' do
      expect(described_class::BUILT_IN).to all(be_a(described_class))
    end

    it 'should hold frozen definitions' do
      expect(described_class::BUILT_IN).to all(be_frozen)
    end

    it 'should give every property an initial value its own type can read' do
      unreadable = described_class::BUILT_IN.select { |property| property.initial.is_a?(Croissant::Style::Value::Unparsed) }

      expect(unreadable.map(&:name)).to be_empty
    end

    it 'should name each property only once, so nothing silently shadows anything' do
      names = described_class::BUILT_IN.map(&:name)

      expect(names.uniq.size).to eq(names.size)
    end

    it 'should include the four-side shorthands' do
      expected = %w[inset margin padding border-color border-style border-width]

      expect(described_class::BUILT_IN.grep(described_class::Shorthand).map(&:name)).to match_array(expected)
    end

    it 'should include the longhands of every shorthand' do
      longhands = described_class::BUILT_IN.grep(described_class::Shorthand).flat_map(&:longhands)

      expect(described_class::BUILT_IN.map(&:name)).to include(*longhands)
    end
  end
end
