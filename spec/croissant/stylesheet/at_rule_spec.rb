# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Croissant::Stylesheet::AtRule do
  describe Croissant::Stylesheet::AtRule::Statement do
    subject(:at_rule) { described_class.new(name: 'import', prelude: 'url(base.css)') }

    it 'should not be inlinable' do
      expect(at_rule.inlinable?).to be(false)
    end

    it 'should serialize as a statement' do
      expect(at_rule.to_s).to eq('@import url(base.css);')
    end

    it 'should serialize without a prelude' do
      expect(described_class.new(name: 'charset', prelude: '').to_s).to eq('@charset;')
    end

    it 'should compare by value' do
      expect(at_rule).to eq(described_class.new(name: 'import', prelude: 'url(base.css)'))
    end

    it 'should hash by value' do
      expect(at_rule.hash).to eq(described_class.new(name: 'import', prelude: 'url(base.css)').hash)
    end

    it 'should not equal a statement with a different prelude' do
      expect(at_rule).not_to eq(described_class.new(name: 'import', prelude: 'url(other.css)'))
    end
  end

  describe Croissant::Stylesheet::AtRule::ConditionalGroup do
    subject(:at_rule) { described_class.new(name: 'media', prelude: 'print', rules: rules) }

    let(:rules) { Croissant::Stylesheet::Parser.parse('p { color: red }').rules }

    it 'should not be inlinable' do
      expect(at_rule.inlinable?).to be(false)
    end

    it 'should serialize with its nested rules' do
      expect(at_rule.to_s).to eq('@media print{p{color:red}}')
    end

    it 'should compare by value including nested rules' do
      expect(at_rule).to eq(described_class.new(name: 'media', prelude: 'print', rules: rules))
    end

    it 'should hash by value including nested rules' do
      expect(at_rule.hash).to eq(described_class.new(name: 'media', prelude: 'print', rules: rules).hash)
    end

    it 'should not equal a group with different rules' do
      expect(at_rule).not_to eq(described_class.new(name: 'media', prelude: 'print', rules: []))
    end
  end

  describe Croissant::Stylesheet::AtRule::DeclarationBlock do
    subject(:at_rule) { described_class.new(name: 'font-face', prelude: '', declarations: declarations) }

    let(:declarations) { Croissant::Stylesheet::Parser.parse_attribute('font-family: Custom; src: url(a.woff)').declarations }

    it 'should not be inlinable' do
      expect(at_rule.inlinable?).to be(false)
    end

    it 'should serialize its declarations minified' do
      expect(at_rule.to_s).to eq('@font-face{font-family:Custom;src:url(a.woff)}')
    end

    it 'should compare by value including the declarations' do
      expect(at_rule).to eq(described_class.new(name: 'font-face', prelude: '', declarations: declarations))
    end

    it 'should hash by value including the declarations' do
      expect(at_rule.hash).to eq(described_class.new(name: 'font-face', prelude: '', declarations: declarations).hash)
    end

    it 'should not equal a block with different declarations' do
      expect(at_rule).not_to eq(described_class.new(name: 'font-face', prelude: '', declarations: []))
    end
  end

  describe Croissant::Stylesheet::AtRule::Block do
    subject(:at_rule) { described_class.new(name: 'font-face', prelude: '', body: 'font-family: Custom') }

    it 'should not be inlinable' do
      expect(at_rule.inlinable?).to be(false)
    end

    it 'should serialize with its raw body' do
      expect(at_rule.to_s).to eq('@font-face{font-family: Custom}')
    end

    it 'should serialize with a prelude' do
      block = described_class.new(name: 'keyframes', prelude: 'spin', body: 'from { opacity: 0 }')

      expect(block.to_s).to eq('@keyframes spin{from { opacity: 0 }}')
    end

    it 'should compare by value including the body' do
      expect(at_rule).to eq(described_class.new(name: 'font-face', prelude: '', body: 'font-family: Custom'))
    end

    it 'should hash by value including the body' do
      expect(at_rule.hash).to eq(described_class.new(name: 'font-face', prelude: '', body: 'font-family: Custom').hash)
    end

    it 'should not equal a block with a different body' do
      expect(at_rule).not_to eq(described_class.new(name: 'font-face', prelude: '', body: 'font-family: Other'))
    end
  end
end
