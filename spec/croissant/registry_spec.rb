# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Croissant::Registry do
  let(:entry_class) { Struct.new(:name) }

  def entry(name)
    entry_class.new(name)
  end

  describe '.new' do
    it 'should yield itself to the block' do
      yielded = nil

      registry = described_class.new { |instance| yielded = instance }

      expect(yielded).to be(registry)
    end

    it 'should make registrations from the block available' do
      pixel = entry('px')
      registry = described_class.new { |instance| instance.register(pixel) }

      expect(registry.lookup('px')).to be(pixel)
    end

    it 'should build an empty registry without a block' do
      expect(described_class.new.lookup('px')).to be_nil
    end

    it 'should register a value from the values it is given' do
      pixel = entry('px')

      expect(described_class.new([pixel]).lookup('px')).to be(pixel)
    end

    it 'should register every value it is given' do
      registry = described_class.new([entry('px'), entry('em')])

      expect(registry.lookup('em').name).to eq('em')
    end

    it 'should build an empty registry from an empty list of values' do
      expect(described_class.new([]).lookup('px')).to be_nil
    end

    it 'should use the fallback passed as a keyword' do
      registry = described_class.new(fallback: ->(name) { entry(name) })

      expect(registry.lookup('rem').name).to eq('rem')
    end

    it 'should register values given alongside a block' do
      registry = described_class.new([entry('px')]) { |instance| instance.register(entry('em')) }

      expect(registry.lookup('px').name).to eq('px')
    end

    it 'should still run the block when values are given' do
      registry = described_class.new([entry('px')]) { |instance| instance.register(entry('em')) }

      expect(registry.lookup('em').name).to eq('em')
    end

    it 'should let the block replace the fallback passed as a keyword' do
      registry = described_class.new(fallback: ->(_name) { entry('keyword') }) do |instance|
        instance.fallback { |_name| entry('block') }
      end

      expect(registry.lookup('rem').name).to eq('block')
    end
  end

  describe '#register' do
    it 'should register a value under its name' do
      registry = described_class.new
      pixel = entry('px')

      registry.register(pixel)

      expect(registry.lookup('px')).to be(pixel)
    end

    it 'should replace a value already registered under the same name' do
      registry = described_class.new
      replacement = entry('px')

      registry.register(entry('px'))
      registry.register(replacement)

      expect(registry.lookup('px')).to be(replacement)
    end

    it 'should allow adding multiple values at once' do
      registry = described_class.new
      pixel = entry('px')
      em = entry('em')

      registry.register(pixel, em)

      aggregate_failures do
        expect(registry.lookup('px')).to be(pixel)
        expect(registry.lookup('em')).to be(em)
      end
    end
  end

  describe '#lookup' do
    it 'should return the registered value' do
      registry = described_class.new
      pixel = entry('px')
      registry.register(pixel)

      expect(registry.lookup('px')).to eq(pixel)
    end

    it 'should return the same instance on every lookup' do
      registry = described_class.new
      registry.register(entry('px'))
      pixel = registry.lookup('px')

      expect(registry.lookup('px')).to be(pixel)
    end

    it 'should return nil for an unknown key without a fallback' do
      expect(described_class.new.lookup('rem')).to be_nil
    end

    it 'should return the fallback value for an unknown key' do
      registry = described_class.new
      registry.fallback { |name| entry(name) }

      expect(registry.lookup('rem').name).to eq('rem')
    end

    it 'should pass the looked up key to the fallback' do
      looked_up = []
      registry = described_class.new
      registry.fallback { |name| looked_up << name }

      registry.lookup('rem')

      expect(looked_up).to eq(['rem'])
    end

    it 'should prefer a registered value over the fallback' do
      looked_up = []
      registry = described_class.new
      registry.fallback { |name| looked_up << name }
      registry.register(entry('px'))

      registry.lookup('px')

      expect(looked_up).to be_empty
    end

    it 'should call the fallback again on every lookup of the same key' do
      looked_up = []
      registry = described_class.new
      registry.fallback { |name| looked_up << name }

      2.times { registry.lookup('rem') }

      expect(looked_up).to eq(%w[rem rem])
    end

    it 'should not register the value the fallback returns' do
      registry = described_class.new
      registry.fallback { |name| entry(name) }
      first = registry.lookup('rem')

      expect(registry.lookup('rem')).not_to be(first)
    end
  end

  describe '#[]' do
    it 'should return the registered value' do
      registry = described_class.new
      pixel = entry('px')
      registry.register(pixel)

      expect(registry['px']).to be(pixel)
    end

    it 'should fall back for an unknown key' do
      registry = described_class.new
      registry.fallback { |name| entry(name) }

      expect(registry['rem'].name).to eq('rem')
    end
  end

  describe '#fallback' do
    it 'should replace a previously set fallback' do
      registry = described_class.new
      registry.fallback { |_name| entry('first') }
      registry.fallback { |_name| entry('second') }

      expect(registry.lookup('rem').name).to eq('second')
    end
  end

  describe '#normalize' do
    it 'should normalize keys registered after it is set' do
      registry = described_class.new
      registry.normalize { |name| name.to_s.downcase }
      pixel = entry('PX')
      registry.register(pixel)

      expect(registry.lookup('px')).to be(pixel)
    end

    it 'should normalize keys looked up after it is set' do
      registry = described_class.new
      registry.normalize { |name| name.to_s.downcase }
      pixel = entry('px')
      registry.register(pixel)

      expect(registry.lookup('PX')).to be(pixel)
    end

    it 'should replace a previously set normalizer' do
      registry = described_class.new
      registry.normalize { |name| name.to_s.upcase }
      registry.normalize { |name| name.to_s.downcase }
      pixel = entry('PX')
      registry.register(pixel)

      expect(registry.lookup('px')).to be(pixel)
    end

    it 'should replace the normalizer passed as a keyword' do
      registry = described_class.new(normalize: ->(name) { name.to_s.upcase })
      registry.normalize { |name| name.to_s.downcase }
      pixel = entry('PX')
      registry.register(pixel)

      expect(registry.lookup('px')).to be(pixel)
    end
  end

  describe 'normalization' do
    let(:downcase) { ->(name) { name.to_s.downcase } }

    it 'should normalize the key a value is registered under' do
      pixel = entry('PX')
      registry = described_class.new([pixel], normalize: downcase)

      expect(registry.lookup('px')).to be(pixel)
    end

    it 'should normalize the key being looked up' do
      pixel = entry('px')
      registry = described_class.new([pixel], normalize: downcase)

      expect(registry.lookup('PX')).to be(pixel)
    end

    it 'should normalize a key given as another type' do
      pixel = entry('px')
      registry = described_class.new([pixel], normalize: downcase)

      expect(registry.lookup(:PX)).to be(pixel)
    end

    it 'should leave the name of the registered value untouched' do
      registry = described_class.new([entry('PX')], normalize: downcase)

      expect(registry.lookup('px').name).to eq('PX')
    end

    it 'should pass the normalized key to the fallback' do
      registry = described_class.new(normalize: downcase, fallback: ->(name) { entry(name) })

      expect(registry.lookup('REM').name).to eq('rem')
    end

    it 'should keep normalizing after a clear' do
      registry = described_class.new([entry('PX')], normalize: downcase)

      registry.clear
      registry.register(entry('EM'))

      expect(registry.lookup('em').name).to eq('EM')
    end

    it 'should match keys verbatim without a normalizer' do
      expect(described_class.new([entry('px')]).lookup('PX')).to be_nil
    end
  end

  describe '#each' do
    let(:yielded) { [] }

    it 'should yield every registered value' do
      registry = described_class.new([entry('px'), entry('em')])

      registry.each { |value| yielded << value.name }

      expect(yielded).to eq(%w[px em])
    end

    it 'should yield the registered value itself' do
      pixel = entry('px')
      registry = described_class.new([pixel])

      registry.each { |value| yielded << value }

      expect(yielded).to eq([pixel])
    end

    it 'should yield in registration order' do
      registry = described_class.new
      %w[pt pc in].each { |name| registry.register(entry(name)) }

      registry.each { |value| yielded << value.name }

      expect(yielded).to eq(%w[pt pc in])
    end

    it 'should yield nothing for an empty registry' do
      described_class.new.each { |value| yielded << value }

      expect(yielded).to be_empty
    end

    it 'should yield nothing after a clear' do
      registry = described_class.new([entry('px')])

      registry.clear
      registry.each { |value| yielded << value }

      expect(yielded).to be_empty
    end

    it 'should not yield a value the fallback produced' do
      registry = described_class.new(fallback: ->(name) { entry(name) })

      registry.lookup('rem')
      registry.each { |value| yielded << value }

      expect(yielded).to be_empty
    end

    it 'should return an enumerator over the registered values without a block' do
      registry = described_class.new([entry('px'), entry('em')])

      expect(registry.each.map(&:name)).to eq(%w[px em])
    end

    it 'should return the registry itself when given a block' do
      registry = described_class.new([entry('px')])

      expect(registry.each { |value| yielded << value }).to be(registry)
    end
  end

  describe 'enumeration' do
    it 'should be enumerable' do
      expect(described_class.new).to be_a(Enumerable)
    end

    it 'should map over the registered values' do
      registry = described_class.new([entry('px'), entry('em')])

      expect(registry.map(&:name)).to eq(%w[px em])
    end

    it 'should select from the registered values' do
      registry = described_class.new([entry('px'), entry('pt'), entry('em')])

      expect(registry.select { |value| value.name.start_with?('p') }.map(&:name)).to eq(%w[px pt])
    end

    it 'should count the registered values' do
      expect(described_class.new([entry('px'), entry('em')]).count).to eq(2)
    end

    it 'should find a registered value' do
      registry = described_class.new([entry('px'), entry('em')])

      expect(registry.find { |value| value.name == 'em' }.name).to eq('em')
    end

    it 'should include a registered value' do
      pixel = entry('px')

      expect(described_class.new([pixel])).to include(pixel)
    end

    it 'should not include a value by the name it is registered under' do
      expect(described_class.new([entry('px')])).not_to include('px')
    end
  end

  describe '#clear' do
    it 'should remove registered values' do
      registry = described_class.new
      registry.register(entry('px'))

      registry.clear

      expect(registry.lookup('px')).to be_nil
    end

    it 'should keep the fallback' do
      registry = described_class.new
      registry.fallback { |name| entry(name) }
      registry.register(entry('px'))

      registry.clear

      expect(registry.lookup('px').name).to eq('px')
    end

    it 'should return the registry itself' do
      registry = described_class.new([entry('px')])

      expect(registry.clear).to be(registry)
    end
  end
end
