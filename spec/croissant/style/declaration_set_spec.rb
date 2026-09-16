# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Croissant::Style::DeclarationSet do
  def build_declaration(property, value, important: false)
    Croissant::Style::Declaration.new(property, value, important:)
  end

  def build_set(*declarations)
    described_class.new(declarations)
  end

  describe '.new' do
    it 'should be empty by default' do
      expect(described_class.new).to be_empty
    end

    it 'should keep the declarations in order' do
      set = build_set(build_declaration('color', 'black'), build_declaration('display', 'block'))

      expect(set.map(&:to_s)).to eq(['color:black', 'display:block'])
    end

    it 'should keep only the last declaration of a property' do
      set = build_set(build_declaration('color', 'black'), build_declaration('color', 'red'))

      expect(set.map(&:to_s)).to eq(['color:red'])
    end

    it 'should keep an important declaration over a later normal one' do
      set = build_set(build_declaration('color', 'black', important: true), build_declaration('color', 'red'))

      expect(set.map(&:to_s)).to eq(['color:black !important'])
    end

    it 'should cascade several collections in order' do
      set = described_class.new(
        [build_declaration('color', 'black'), build_declaration('display', 'block')],
        [build_declaration('color', 'red')]
      )

      expect(set.map(&:to_s)).to eq(['display:block', 'color:red'])
    end

    it 'should accept a set as a collection' do
      set = described_class.new(build_set(build_declaration('color', 'black')), [build_declaration('float', 'left')])

      expect(set.map(&:to_s)).to eq(['color:black', 'float:left'])
    end

    it 'should move a repeated property to the position of its last declaration' do
      set = build_set(
        build_declaration('color', 'black'), build_declaration('display', 'block'), build_declaration('color', 'red')
      )

      expect(set.map(&:to_s)).to eq(['display:block', 'color:red'])
    end
  end

  describe '#[]' do
    it 'should return the declaration of a property' do
      declaration = build_declaration('color', 'black')

      expect(build_set(declaration)['color']).to be(declaration)
    end

    it 'should return nil for a property that is not present' do
      expect(build_set(build_declaration('color', 'black'))['display']).to be_nil
    end
  end

  describe '#size' do
    it 'should count the declarations' do
      expect(build_set(build_declaration('color', 'black'), build_declaration('display', 'block')).size).to eq(2)
    end
  end

  describe '#merge' do
    it 'should return a new set' do
      set = build_set(build_declaration('color', 'black'))

      expect(set.merge([build_declaration('display', 'block')])).not_to be(set)
    end

    it 'should leave the original set untouched' do
      set = build_set(build_declaration('color', 'black'))
      set.merge([build_declaration('display', 'block')])

      expect(set.size).to eq(1)
    end

    it 'should append the declarations in order' do
      set = build_set(build_declaration('color', 'black'))
        .merge([build_declaration('display', 'block'), build_declaration('float', 'left')])

      expect(set.map(&:to_s)).to eq(['color:black', 'display:block', 'float:left'])
    end

    it 'should let a merged declaration win and move it to the end' do
      set = build_set(build_declaration('color', 'black'), build_declaration('display', 'block'))
        .merge([build_declaration('color', 'red')])

      expect(set.map(&:to_s)).to eq(['display:block', 'color:red'])
    end

    it 'should accept another set' do
      set = build_set(build_declaration('color', 'black')).merge(build_set(build_declaration('display', 'block')))

      expect(set.map(&:to_s)).to eq(['color:black', 'display:block'])
    end
  end

  describe '#expand' do
    it 'should return an equal set when it holds no shorthand' do
      set = build_set(build_declaration('color', 'black'))

      expect(set.expand).to eq(set)
    end

    it 'should leave the original set untouched' do
      set = build_set(build_declaration('margin', '10px'))
      set.expand

      expect(set.size).to eq(1)
    end

    it 'should expand a shorthand into its longhands in place' do
      set = build_set(
        build_declaration('color', 'black'),
        build_declaration('margin', '10px 20px'),
        build_declaration('display', 'block')
      )

      expect(set.expand.map(&:to_s)).to eq([
        'color:black',
        'margin-top:10px', 'margin-right:20px', 'margin-bottom:10px', 'margin-left:20px',
        'display:block'
      ])
    end

    it 'should let a later longhand override part of an earlier shorthand' do
      set = build_set(build_declaration('margin', '10px'), build_declaration('margin-top', '0'))

      expect(set.expand.map(&:to_s)).to eq(
        ['margin-right:10px', 'margin-bottom:10px', 'margin-left:10px', 'margin-top:0']
      )
    end

    it 'should let a later shorthand override an earlier longhand' do
      set = build_set(build_declaration('margin-top', '0'), build_declaration('margin', '10px'))

      expect(set.expand['margin-top'].value).to eq('10px')
    end

    it 'should carry the important flag onto the longhands' do
      set = build_set(build_declaration('margin', '10px', important: true))

      expect(set.expand).to all(be_important)
    end

    it 'should drop a shorthand with an invalid value' do
      expect(build_set(build_declaration('margin', '1px 2px 3px 4px 5px')).expand).to be_empty
    end
  end

  describe '#collapse' do
    it 'should fold a complete set of longhands into a shorthand' do
      set = build_set(
        build_declaration('margin-top', '10px'), build_declaration('margin-right', '20px'),
        build_declaration('margin-bottom', '30px'), build_declaration('margin-left', '40px')
      )

      expect(set.collapse.map(&:to_s)).to eq(['margin:10px 20px 30px 40px'])
    end

    it 'should fold several shorthands independently' do
      set = build_set(build_declaration('margin', '10px'), build_declaration('padding', '5px')).expand

      expect(set.collapse.map(&:to_s)).to eq(['margin:10px', 'padding:5px'])
    end

    it 'should keep an incomplete set of longhands' do
      set = build_set(build_declaration('margin-top', '10px'), build_declaration('margin-left', '10px'))

      expect(set.collapse.map(&:to_s)).to eq(['margin-top:10px', 'margin-left:10px'])
    end

    it 'should return the same set when nothing folds' do
      set = build_set(build_declaration('color', 'black'))

      expect(set.collapse).to be(set)
    end

    it 'should leave the original set untouched' do
      set = build_set(build_declaration('margin', '10px')).expand
      set.collapse

      expect(set.size).to eq(4)
    end
  end

  describe '#replace' do
    it 'should replace the named declarations with one at the position of the first' do
      set = build_set(
        build_declaration('color', 'black'), build_declaration('margin-top', '10px'),
        build_declaration('display', 'block'), build_declaration('margin-left', '10px')
      )

      replaced = set.replace(%w[margin-top margin-left], build_declaration('margin', '10px'))

      expect(replaced.map(&:to_s)).to eq(['color:black', 'margin:10px', 'display:block'])
    end

    it 'should return a new set' do
      set = build_set(build_declaration('margin-top', '10px'))

      expect(set.replace(%w[margin-top], build_declaration('margin', '10px'))).not_to be(set)
    end
  end

  describe '#each' do
    it 'should yield the declarations in insertion order' do
      set = build_set(build_declaration('color', 'black'), build_declaration('display', 'block'))

      expect(set.map(&:to_s)).to eq(['color:black', 'display:block'])
    end

    it 'should yield important declarations after normal ones' do
      set = build_set(build_declaration('color', 'black', important: true), build_declaration('display', 'block'))

      expect(set.map(&:to_s)).to eq(['display:block', 'color:black !important'])
    end

    it 'should keep the insertion order within the normal and the important declarations' do
      set = build_set(
        build_declaration('color', 'black', important: true),
        build_declaration('display', 'block'),
        build_declaration('margin-top', '1px', important: true),
        build_declaration('padding-top', '2px')
      )

      expect(set.map(&:to_s)).to eq(
        ['display:block', 'padding-top:2px', 'color:black !important', 'margin-top:1px !important']
      )
    end

    it 'should return an enumerator without a block' do
      expect(build_set.each).to be_an(Enumerator)
    end
  end

  describe '#to_s' do
    it 'should join the declarations with a semicolon' do
      set = build_set(build_declaration('color', 'black'), build_declaration('display', 'block', important: true))

      expect(set.to_s).to eq('color:black;display:block !important')
    end

    it 'should be empty for an empty set' do
      expect(described_class.new.to_s).to eq('')
    end
  end

  describe '#==' do
    it 'should be equal when the declarations match in order' do
      first = build_set(build_declaration('color', 'black'), build_declaration('display', 'block'))
      second = build_set(build_declaration('color', 'black'), build_declaration('display', 'block'))

      expect(first).to eq(second)
    end

    it 'should not be equal when the order differs' do
      first = build_set(build_declaration('color', 'black'), build_declaration('display', 'block'))
      second = build_set(build_declaration('display', 'block'), build_declaration('color', 'black'))

      expect(first).not_to eq(second)
    end

    it 'should not be equal when a declaration differs' do
      expect(build_set(build_declaration('color', 'black'))).not_to eq(build_set(build_declaration('color', 'red')))
    end

    it 'should not be equal to an object of another class' do
      expect(build_set(build_declaration('color', 'black'))).not_to eq([build_declaration('color', 'black')])
    end
  end

  describe '#hash' do
    it 'should have the same hash as an equal set' do
      first = build_set(build_declaration('color', 'black'))
      second = build_set(build_declaration('color', 'black'))

      expect(first.hash).to eq(second.hash)
    end
  end

  describe '#add' do
    it 'should add the declaration' do
      set = build_set(build_declaration('color', 'black'))
      set.add(build_declaration('display', 'block'))

      expect(set.map(&:to_s)).to eq(['color:black', 'display:block'])
    end

    it 'should replace an existing declaration of the same property and move it to the end' do
      set = build_set(build_declaration('color', 'black'), build_declaration('display', 'block'))
      set.add(build_declaration('color', 'red'))

      expect(set.map(&:to_s)).to eq(['display:block', 'color:red'])
    end

    it 'should replace a normal declaration with an important one' do
      set = build_set(build_declaration('color', 'black'))
      set.add(build_declaration('color', 'red', important: true))

      expect(set.map(&:to_s)).to eq(['color:red !important'])
    end

    it 'should replace an important declaration with another important one' do
      set = build_set(build_declaration('color', 'black', important: true))
      set.add(build_declaration('color', 'red', important: true))

      expect(set.map(&:to_s)).to eq(['color:red !important'])
    end

    it 'should not replace an important declaration with a normal one' do
      set = build_set(build_declaration('color', 'black', important: true), build_declaration('display', 'block'))
      set.add(build_declaration('color', 'red'))

      expect(set.map(&:to_s)).to eq(['display:block', 'color:black !important'])
    end

    it 'should return true when the declaration was added' do
      expect(build_set.add(build_declaration('color', 'black'))).to be(true)
    end

    it 'should return false when the declaration was not added' do
      set = build_set(build_declaration('color', 'black', important: true))

      expect(set.add(build_declaration('color', 'red'))).to be(false)
    end

    it 'should raise when the set is frozen' do
      set = build_set.freeze

      expect { set.add(build_declaration('color', 'black')) }.to raise_error(FrozenError)
    end
  end

  describe '#<<' do
    it 'should add the declaration' do
      set = build_set
      set << build_declaration('color', 'black')

      expect(set.map(&:to_s)).to eq(['color:black'])
    end

    it 'should return the set' do
      set = build_set

      expect(set << build_declaration('color', 'black')).to be(set)
    end
  end

  describe '#delete' do
    it 'should delete the declaration for the property' do
      set = build_set(build_declaration('color', 'black'), build_declaration('display', 'block'))
      set.delete('color')

      expect(set.map(&:to_s)).to eq(['display:block'])
    end

    it 'should accept a property instance' do
      set = build_set(build_declaration('color', 'black'))
      set.delete(Croissant::Style::Property.lookup('color'))

      expect(set).to be_empty
    end

    it 'should ignore unknown properties' do
      set = build_set(build_declaration('color', 'black'))
      set.delete('display')

      expect(set.map(&:to_s)).to eq(['color:black'])
    end

    it 'should delete the longhands of a shorthand' do
      set = build_set(build_declaration('margin', '1px')).expand
      set.add(build_declaration('color', 'black'))
      set.delete('margin')

      expect(set.map(&:to_s)).to eq(['color:black'])
    end

    it 'should delete a shorthand declaration itself' do
      set = build_set(build_declaration('margin', '1px'))
      set.delete('margin')

      expect(set).to be_empty
    end

    it 'should only delete the given longhand' do
      set = build_set(build_declaration('margin', '1px')).expand
      set.delete('margin-top')

      expect(set.map(&:to_s)).to eq(['margin-right:1px', 'margin-bottom:1px', 'margin-left:1px'])
    end

    it 'should return the set' do
      set = build_set(build_declaration('color', 'black'))

      expect(set.delete('color')).to be(set)
    end

    it 'should raise when the set is frozen' do
      set = build_set(build_declaration('color', 'black')).freeze

      expect { set.delete('color') }.to raise_error(FrozenError)
    end
  end

  describe '#freeze' do
    it 'should not be frozen after initialization' do
      expect(described_class.new).not_to be_frozen
    end

    it 'should freeze the result of #merge when frozen' do
      expect(build_set.freeze.merge([build_declaration('color', 'black')])).to be_frozen
    end

    it 'should freeze the result of #expand when frozen' do
      expect(build_set(build_declaration('margin', '10px')).freeze.expand).to be_frozen
    end

    it 'should freeze the result of #collapse when frozen' do
      expect(build_set(build_declaration('margin', '10px')).freeze.expand.collapse).to be_frozen
    end

    it 'should freeze the result of #replace when frozen' do
      set = build_set(build_declaration('color', 'black')).freeze

      expect(set.replace(['color'], build_declaration('color', 'red'))).to be_frozen
    end

    it 'should not freeze the result of #merge when not frozen' do
      expect(build_set.merge([build_declaration('color', 'black')])).not_to be_frozen
    end

    it 'should not freeze the result of #expand when not frozen' do
      expect(build_set(build_declaration('margin', '10px')).expand).not_to be_frozen
    end

    it 'should not freeze the result of #replace when not frozen' do
      set = build_set(build_declaration('color', 'black'))

      expect(set.replace(['color'], build_declaration('color', 'red'))).not_to be_frozen
    end

    it 'should freeze the set' do
      expect(described_class.new.freeze).to be_frozen
    end

    it 'should freeze the declarations' do
      expect(described_class.new.freeze.instance_variable_get(:@declarations)).to be_frozen
    end
  end
end
