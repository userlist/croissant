# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Croissant::Style::ElementStyle do
  def build(css = nil)
    return described_class.new if css.nil?

    described_class.new(Croissant::Style::Cascade.resolve([Croissant::Stylesheet::Parser.parse_attribute(css)]))
  end

  describe '.new' do
    it 'should be empty by default' do
      expect(described_class.new).to be_empty
    end

    it 'should wrap the given declaration set' do
      declarations = Croissant::Style::DeclarationSet.new

      expect(described_class.new(declarations).declarations).to be(declarations)
    end
  end

  describe '#[]' do
    it 'should return the value of a property' do
      expect(build('color: red')['color']).to eq('red')
    end

    it 'should return nil for an undeclared property' do
      expect(build['color']).to be_nil
    end

    it 'should return the value of a longhand from a shorthand' do
      expect(build('margin: 1px 2px')['margin-left']).to eq('2px')
    end

    it 'should return nil for a shorthand since only longhands are stored' do
      expect(build('margin: 1px')['margin']).to be_nil
    end

    it 'should look up a property given as a Property instance' do
      expect(build('color: red')[Croissant::Style::Property.lookup('color')]).to eq('red')
    end
  end

  describe '#set' do
    it 'should return a style with the property set' do
      expect(build.set('color', 'red').to_s).to eq('color:red')
    end

    it 'should return a new style' do
      style = build

      expect(style.set('color', 'red')).not_to be(style)
    end

    it 'should not change the style itself' do
      style = build
      style.set('color', 'red')

      expect(style).to be_empty
    end

    it 'should set a normal property by default' do
      expect(build.set('color', 'red')).not_to be_important('color')
    end

    it 'should set an important property' do
      expect(build.set('color', 'red', important: true).to_s).to eq('color:red !important')
    end

    it 'should override an existing property' do
      expect(build('color: red').set('color', 'blue')['color']).to eq('blue')
    end

    it 'should move an overridden property to the end' do
      expect(build('color: red; display: block').set('color', 'blue').to_s).to eq('display:block;color:blue')
    end

    it 'should override an important property with an important one' do
      expect(build('color: red !important').set('color', 'blue', important: true).to_s).to eq('color:blue !important')
    end

    it 'should override a normal property with an important one' do
      expect(build('color: red').set('color', 'blue', important: true).to_s).to eq('color:blue !important')
    end

    it 'should not override an important property with a normal one' do
      expect(build('color: red !important').set('color', 'blue').to_s).to eq('color:red !important')
    end

    it 'should return the style itself when nothing changed' do
      style = build('color: red !important')

      expect(style.set('color', 'blue')).to be(style)
    end

    it 'should expand a shorthand into its longhands' do
      expect(build.set('margin', '1px 2px')['margin-left']).to eq('2px')
    end

    it 'should set the longhands that are not important' do
      expect(build('margin-top: 1px !important').set('margin', '2px').to_s).to eq(
        'margin-top:1px !important;margin-right:2px;margin-bottom:2px;margin-left:2px'
      )
    end

    it 'should return a frozen style' do
      expect(build.set('color', 'red')).to be_frozen
    end
  end

  describe '#delete' do
    it 'should return a style without the property' do
      expect(build('color: red; margin: 1px').delete('color').to_s).to eq('margin:1px')
    end

    it 'should return a new style' do
      style = build('color: red')

      expect(style.delete('color')).not_to be(style)
    end

    it 'should not change the style itself' do
      style = build('color: red')
      style.delete('color')

      expect(style['color']).to eq('red')
    end

    it 'should delete the longhands of a shorthand' do
      expect(build('margin-top: 1px; margin-left: 2px; color: red').delete('margin').to_s).to eq('color:red')
    end

    it 'should keep important declarations important' do
      expect(build('color: red !important; margin: 1px').delete('margin').to_s).to eq('color:red !important')
    end

    it 'should return the style itself when the property is not present' do
      style = build('color: red')

      expect(style.delete('display')).to be(style)
    end
  end

  describe '#important?' do
    it 'should be true for an important property' do
      expect(build('color: red !important')).to be_important('color')
    end

    it 'should be false for a normal property' do
      expect(build('color: red')).not_to be_important('color')
    end

    it 'should be false for an undeclared property' do
      expect(build).not_to be_important('color')
    end
  end

  describe '#each' do
    it 'should yield the declarations' do
      expect(build('color: red; margin: 1px').map(&:to_s)).to eq(
        ['color:red', 'margin-top:1px', 'margin-right:1px', 'margin-bottom:1px', 'margin-left:1px']
      )
    end
  end

  describe '#empty?' do
    it 'should be true without declarations' do
      expect(build).to be_empty
    end

    it 'should be false with declarations' do
      expect(build('color: red')).not_to be_empty
    end
  end

  describe '#to_s' do
    it 'should format each property and value as declaration syntax' do
      expect(build('color: black').to_s).to eq('color:black')
    end

    it 'should join multiple properties with a semicolon' do
      expect(build('color: black; font-size: 12px').to_s).to eq('color:black;font-size:12px')
    end

    it 'should collapse a complete set of longhands into their shorthand' do
      css = 'margin-top: 1px; margin-right: 1px; margin-bottom: 1px; margin-left: 1px'

      expect(build(css).to_s).to eq('margin:1px')
    end

    it 'should collapse an overridden longhand back into the shorthand' do
      expect(build('margin: 0').set('margin-top', '5px').to_s).to eq('margin:5px 0 0')
    end

    it 'should emit the shorthand at the position of its first longhand' do
      expect(build('margin: 0; color: red').to_s).to eq('margin:0;color:red')
    end

    it 'should keep longhands when the set is incomplete' do
      expect(build('margin-top: 1px; margin-left: 2px').to_s).to eq('margin-top:1px;margin-left:2px')
    end

    it 'should keep longhands when their importance differs' do
      expect(build('margin: 0; margin-top: 5px !important').to_s).to eq(
        'margin-right:0;margin-bottom:0;margin-left:0;margin-top:5px !important'
      )
    end

    it 'should emit important declarations after normal ones' do
      expect(build('display: block !important; color: red').to_s).to eq('color:red;display:block !important')
    end

    it 'should keep the important flag when collapsing an important shorthand' do
      expect(build('padding: 0 !important').to_s).to eq('padding:0 !important')
    end

    it 'should serialize an empty style as an empty string' do
      expect(build.to_s).to eq('')
    end
  end

  describe '#==' do
    it 'should be equal when the declarations match' do
      first = build('color: black')
      second = build('color: black')

      expect(first).to eq(second)
    end

    it 'should not be equal when the declarations differ' do
      expect(build('color: black')).not_to eq(build('color: red'))
    end

    it 'should not be equal to an object of another class' do
      expect(build('color: black')).not_to eq('color:black')
    end
  end

  describe '#hash' do
    it 'should have the same hash as an equal style' do
      first = build('color: black')
      second = build('color: black')

      expect(first.hash).to eq(second.hash)
    end

    it 'should collapse equal styles when used as a Hash key' do
      first = build('color: black')
      second = build('color: black')

      expect({ first => 1, second => 2 }.size).to eq(1)
    end
  end

  describe '#freeze' do
    it 'should be frozen after initialization' do
      expect(build).to be_frozen
    end

    it 'should freeze the declarations' do
      expect(described_class.new(Croissant::Style::DeclarationSet.new).declarations).to be_frozen
    end
  end
end
