# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Croissant::Style::Property::Shorthand do
  def build_shorthand(name: 'margin', longhands: %w[margin-top margin-right margin-bottom margin-left])
    described_class.new(name, longhands)
  end

  describe '#name' do
    it 'should return the shorthand name' do
      expect(build_shorthand.name).to eq('margin')
    end
  end

  describe '#longhands' do
    it 'should return the longhand property names' do
      expect(build_shorthand.longhands).to eq(%w[margin-top margin-right margin-bottom margin-left])
    end

    it 'should be frozen' do
      expect(build_shorthand.longhands).to be_frozen
    end
  end

  describe '#expand' do
    def expand(value, important: false)
      declaration = Croissant::Style::Declaration.new('margin', value, important:)

      build_shorthand.expand(declaration).to_h { |longhand| [longhand.property.name.to_s, longhand.value] }
    end

    it 'should apply a single value to all four sides' do
      expect(expand('10px')).to eq(
        'margin-top' => '10px',
        'margin-right' => '10px',
        'margin-bottom' => '10px',
        'margin-left' => '10px'
      )
    end

    it 'should keep a bracketed group together rather than splitting inside it' do
      expect(expand('calc(1px + 2px) 3px')).to eq(
        'margin-top' => 'calc(1px + 2px)',
        'margin-right' => '3px',
        'margin-bottom' => 'calc(1px + 2px)',
        'margin-left' => '3px'
      )
    end

    it 'should keep a quoted string together rather than splitting inside it' do
      expect(expand('"Helvetica Neue"')).to eq(
        'margin-top' => '"Helvetica Neue"',
        'margin-right' => '"Helvetica Neue"',
        'margin-bottom' => '"Helvetica Neue"',
        'margin-left' => '"Helvetica Neue"'
      )
    end

    it 'should apply two values vertically and horizontally' do
      expect(expand('10px 20px')).to eq(
        'margin-top' => '10px',
        'margin-right' => '20px',
        'margin-bottom' => '10px',
        'margin-left' => '20px'
      )
    end

    it 'should apply three values to top, sides, and bottom' do
      expect(expand('10px 20px 30px')).to eq(
        'margin-top' => '10px',
        'margin-right' => '20px',
        'margin-bottom' => '30px',
        'margin-left' => '20px'
      )
    end

    it 'should apply four values clockwise from the top' do
      expect(expand('10px 20px 30px 40px')).to eq(
        'margin-top' => '10px',
        'margin-right' => '20px',
        'margin-bottom' => '30px',
        'margin-left' => '40px'
      )
    end

    it 'should ignore extra whitespace between values' do
      expect(expand("  10px \t 20px  ")).to eq(
        'margin-top' => '10px',
        'margin-right' => '20px',
        'margin-bottom' => '10px',
        'margin-left' => '20px'
      )
    end

    it 'should not split inside parentheses' do
      expect(expand('calc(10px + 2em) 20px')).to eq(
        'margin-top' => 'calc(10px + 2em)',
        'margin-right' => '20px',
        'margin-bottom' => 'calc(10px + 2em)',
        'margin-left' => '20px'
      )
    end

    it 'should resolve each longhand through the registry' do
      declaration = Croissant::Style::Declaration.new('margin', '10px')

      expect(build_shorthand.expand(declaration).map(&:property)).to eq(
        %w[margin-top margin-right margin-bottom margin-left].map { |name| Croissant::Style::Property.lookup(name) }
      )
    end

    it 'should carry the important flag onto every longhand declaration' do
      declaration = Croissant::Style::Declaration.new('margin', '10px', important: true)

      expect(build_shorthand.expand(declaration)).to all(be_important)
    end

    it 'should return no declarations for an empty value' do
      expect(expand('')).to be_empty
    end

    it 'should return no declarations for too many values' do
      expect(expand('1px 2px 3px 4px 5px')).to be_empty
    end
  end

  describe '#collapse' do
    def build_declaration(property, value, important: false)
      Croissant::Style::Declaration.new(property, value, important:)
    end

    def build_declarations(top: '10px', right: '20px', bottom: '30px', left: '40px', important: false)
      sides = { 'margin-top' => top, 'margin-right' => right, 'margin-bottom' => bottom, 'margin-left' => left }

      Croissant::Style::DeclarationSet.new(
        sides.compact.map { |property, value| build_declaration(property, value, important:) }
      )
    end

    def collapse(declarations)
      build_shorthand.collapse(declarations).map(&:to_s)
    end

    it 'should collapse four equal values into one' do
      expect(collapse(build_declarations(right: '10px', bottom: '10px', left: '10px'))).to eq(['margin:10px'])
    end

    it 'should collapse matching vertical and horizontal values into two' do
      expect(collapse(build_declarations(bottom: '10px', left: '20px'))).to eq(['margin:10px 20px'])
    end

    it 'should collapse matching horizontal values into three' do
      expect(collapse(build_declarations(left: '20px'))).to eq(['margin:10px 20px 30px'])
    end

    it 'should keep four distinct values' do
      expect(collapse(build_declarations)).to eq(['margin:10px 20px 30px 40px'])
    end

    it 'should place the shorthand at the position of its first longhand' do
      declarations = Croissant::Style::DeclarationSet.new([
        build_declaration('color', 'black'),
        build_declaration('margin-top', '10px'),
        build_declaration('display', 'block'),
        build_declaration('margin-right', '10px'),
        build_declaration('margin-bottom', '10px'),
        build_declaration('margin-left', '10px')
      ])

      expect(collapse(declarations)).to eq(['color:black', 'margin:10px', 'display:block'])
    end

    it 'should keep the important flag when all longhands are important' do
      expect(build_shorthand.collapse(build_declarations(important: true))).to all(be_important)
    end

    it 'should return a new declaration set' do
      declarations = build_declarations

      expect(build_shorthand.collapse(declarations)).not_to be(declarations)
    end

    it 'should return the declaration set unchanged when a longhand is missing' do
      declarations = build_declarations(left: nil)

      expect(build_shorthand.collapse(declarations)).to be(declarations)
    end

    it 'should return the declaration set unchanged when the longhands disagree on importance' do
      declarations = Croissant::Style::DeclarationSet.new([
        build_declaration('margin-top', '10px', important: true),
        build_declaration('margin-right', '10px'),
        build_declaration('margin-bottom', '10px'),
        build_declaration('margin-left', '10px')
      ])

      expect(build_shorthand.collapse(declarations)).to be(declarations)
    end
  end

  describe '#==' do
    it 'should be equal when name and longhands match' do
      first = build_shorthand
      second = build_shorthand

      expect(first).to eq(second)
    end

    it 'should not be equal when the longhands differ' do
      other = build_shorthand(longhands: %w[padding-top padding-right padding-bottom padding-left])

      expect(build_shorthand).not_to eq(other)
    end

    it 'should not be equal to a plain property' do
      expect(build_shorthand).not_to eq(Croissant::Style::Property.new('margin'))
    end
  end

  describe '#hash' do
    it 'should have the same hash as an equal shorthand' do
      first = build_shorthand
      second = build_shorthand

      expect(first.hash).to eq(second.hash)
    end
  end

  describe '#freeze' do
    it 'should be frozen after initialization' do
      expect(build_shorthand).to be_frozen
    end
  end
end
