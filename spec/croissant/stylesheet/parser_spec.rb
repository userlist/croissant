# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Croissant::Stylesheet::Parser do
  describe '.parse' do
    it 'should parse a stylesheet' do
      stylesheet = described_class.parse('p { color: red }')

      expect(stylesheet).to be_a(Croissant::Stylesheet)
    end
  end

  describe '.parse_attribute' do
    it 'should parse a style attribute' do
      rule = described_class.parse_attribute('color: red')

      expect(rule).to be_a(Croissant::Stylesheet::Rule)
    end
  end

  describe '.parse_selector' do
    it 'should parse a selector' do
      selector = described_class.parse_selector('p.intro')

      expect(selector).to be_a(Croissant::Selector)
    end
  end

  describe '#parse' do
    let(:result) { subject.parse(value) }
    let(:rules) { result.rules }

    context 'with a simple rule' do
      let(:value) { 'p { color: red }' }

      it 'should return a stylesheet' do
        expect(result).to be_a(Croissant::Stylesheet)
      end

      it 'should parse the selector' do
        expect(rules.first.selector.to_s).to eq('p')
      end

      it 'should parse the declaration' do
        declaration = rules.first.declarations.first

        expect(declaration).to eq(Croissant::Stylesheet::Declaration.new(property: 'color', value: 'red'))
      end

      it 'should expose the selector specificity on the rule' do
        expect(rules.first.specificity).to eq(Croissant::Selector::Specificity.new(0, 0, 0, 1))
      end
    end

    context 'with multiple declarations' do
      let(:value) { 'p { color: red; font-size: 12px }' }

      it 'should parse all declarations' do
        expect(rules.first.declarations.map(&:property)).to eq(%w[color font-size])
      end
    end

    context 'with extra semicolons' do
      let(:value) { 'p { ; color: red ;; }' }

      it 'should ignore empty declarations' do
        expect(rules.first.declarations.count).to eq(1)
      end
    end

    context 'with multiple rules' do
      let(:value) { 'p { color: red } h1 { color: blue }' }

      it 'should parse each rule' do
        expect(rules.map { |rule| rule.selector.to_s }).to eq(%w[p h1])
      end
    end

    context 'with multiple selectors' do
      let(:value) { 'p.intro, #main { color: red }' }

      it 'should create a rule per selector' do
        expect(rules.map { |rule| rule.selector.to_s }).to eq(['p.intro', '#main'])
      end

      it 'should assign each selector its own specificity' do
        expect(rules.map(&:specificity))
          .to eq([
            Croissant::Selector::Specificity.new(0, 0, 1, 1),
            Croissant::Selector::Specificity.new(0, 1, 0, 0)
          ])
      end

      it 'should share the same declarations array between the rules' do
        expect(rules.first.declarations).to be(rules.last.declarations)
      end
    end

    context 'with a trailing comma in the selector list' do
      let(:value) { 'div, { color: red }' }

      it 'should only create a rule for the real selector' do
        expect(rules.map { |rule| rule.selector.to_s }).to eq(['div'])
      end
    end

    context 'with a selector containing a quoted comma' do
      let(:value) { 'a[title="x,y"], p { color: red }' }

      it 'should not split the selector at the quoted comma' do
        expect(rules.map { |rule| rule.selector.to_s }).to eq(['a[title="x,y"]', 'p'])
      end
    end

    context 'with an important declaration' do
      let(:value) { 'p { color: red !important }' }

      it 'should flag the declaration as important' do
        expect(rules.first.declarations.first).to be_important
      end

      it 'should strip the important suffix from the value' do
        expect(rules.first.declarations.first.value).to eq('red')
      end
    end

    context 'with an uppercase important declaration' do
      let(:value) { 'p { color: red !IMPORTANT }' }

      it 'should flag the declaration as important' do
        expect(rules.first.declarations.first).to be_important
      end
    end

    context 'with a spaced important declaration' do
      let(:value) { 'p { color: red ! important }' }

      it 'should flag the declaration as important' do
        expect(rules.first.declarations.first).to be_important
      end
    end

    context 'with comments' do
      let(:value) { '/* before */ p { /* inside */ color: /* mid */ red } /* after */' }

      it 'should ignore the comments' do
        expect(rules).to eq([
          Croissant::Stylesheet::Rule.new(
            selector: Croissant::Selector::Compound.new(
              [Croissant::Selector::Simple::Type.new('p')]
            ),
            declarations: [Croissant::Stylesheet::Declaration.new(property: 'color', value: 'red')]
          )
        ])
      end
    end

    context 'with a comment containing braces' do
      let(:value) { '/* } { */ p { color: red }' }

      it 'should not confuse the comment content with structure' do
        expect(rules.count).to eq(1)
      end
    end

    context 'with an unterminated comment' do
      let(:value) { 'p { color: red } /* dangling' }

      it 'should parse the preceding rules' do
        expect(rules.count).to eq(1)
      end
    end

    context 'with HTML comment guards' do
      let(:value) { '<!-- p { color: red } -->' }

      it 'should ignore the guards' do
        expect(rules.first.selector.to_s).to eq('p')
      end
    end

    context 'with a media at-rule' do
      let(:value) { '@media print { p { color: red } } h1 { color: blue }' }

      it 'should skip the block including its rules' do
        expect(rules.map { |rule| rule.selector.to_s }).to eq(['h1'])
      end
    end

    context 'with nested at-rules' do
      let(:value) { '@media print { @media screen { p { color: red } } } h1 { color: blue }' }

      it 'should skip the outer block including any nested blocks' do
        expect(rules.map { |rule| rule.selector.to_s }).to eq(['h1'])
      end
    end

    context 'with statement at-rules' do
      let(:value) { '@import url(base.css); @charset "utf-8"; p { color: red }' }

      it 'should skip the statements' do
        expect(rules.count).to eq(1)
      end
    end

    context 'with a font-face at-rule' do
      let(:value) { '@font-face { font-family: Custom; src: url(font.woff) } p { color: red }' }

      it 'should skip the block' do
        expect(rules.map { |rule| rule.selector.to_s }).to eq(['p'])
      end
    end

    context 'with a keyframes at-rule' do
      let(:value) do
        '@keyframes spin { from { transform: rotate(0) } to { transform: rotate(360deg) } } p { color: red }'
      end

      it 'should skip the nested blocks' do
        expect(rules.map { |rule| rule.selector.to_s }).to eq(['p'])
      end
    end

    context 'with a supports at-rule' do
      let(:value) { '@supports (display: grid) { p { color: red } } h1 { color: blue }' }

      it 'should skip the block including its rules' do
        expect(rules.map { |rule| rule.selector.to_s }).to eq(['h1'])
      end
    end

    context 'with a quoted semicolon in a value' do
      let(:value) { 'p::after { content: ";" }' }

      it 'should keep the value intact' do
        expect(rules.first.declarations.first.value).to eq('";"')
      end
    end

    context 'with a quoted brace in a value' do
      let(:value) { 'p::after { content: "}" } h1 { color: blue }' }

      it 'should keep the value intact' do
        expect(rules.first.declarations.first.value).to eq('"}"')
      end

      it 'should keep parsing subsequent rules' do
        expect(rules.last.selector.to_s).to eq('h1')
      end
    end

    context 'with a data URL containing semicolons' do
      let(:value) { 'p { background: url(data:image/png;base64,iVBORw0KGgo=) }' }

      it 'should parse a single declaration' do
        expect(rules).to eq([
          Croissant::Stylesheet::Rule.new(
            selector: Croissant::Selector::Compound.new(
              [Croissant::Selector::Simple::Type.new('p')]
            ),
            declarations: [
              Croissant::Stylesheet::Declaration.new(
                property: 'background',
                value: 'url(data:image/png;base64,iVBORw0KGgo=)'
              )
            ]
          )
        ])
      end
    end

    context 'with colons in the value' do
      let(:value) { 'p { background-image: url(http://example.com/a.png) }' }

      it 'should split property and value at the first colon' do
        expect(rules).to eq([
          Croissant::Stylesheet::Rule.new(
            selector: Croissant::Selector::Compound.new(
              [Croissant::Selector::Simple::Type.new('p')]
            ),
            declarations: [Croissant::Stylesheet::Declaration.new(property: 'background-image', value: 'url(http://example.com/a.png)')]
          )
        ])
      end
    end

    context 'with garbage before a rule' do
      let(:value) { 'garbage; p { color: red }' }

      it 'should skip the garbage' do
        expect(rules.map { |rule| rule.selector.to_s }).to eq(['p'])
      end
    end

    context 'with a stray closing brace' do
      let(:value) { '} p { color: red }' }

      it 'should ignore the stray brace' do
        expect(rules.count).to eq(1)
      end
    end

    context 'with a declaration without a colon' do
      let(:value) { 'p { color }' }

      it 'should skip the declaration' do
        expect(rules.first.declarations).to be_empty
      end
    end

    context 'with an unclosed block at the end of input' do
      let(:value) { 'p { color: red' }

      it 'should keep the declarations parsed so far' do
        expect(rules.first.declarations.first.value).to eq('red')
      end
    end

    context 'with an unterminated string' do
      let(:value) { 'p { content: "unterminated }' }

      it 'should not raise' do
        expect { rules }.not_to raise_error
      end
    end

    context 'with empty input' do
      let(:value) { '' }

      it 'should return a stylesheet without rules' do
        expect(rules).to be_empty
      end
    end

    context 'with nil input' do
      let(:value) { nil }

      it 'should return a stylesheet without rules' do
        expect(rules).to be_empty
      end
    end

    context 'with whitespace-only input' do
      let(:value) { "  \n\t  " }

      it 'should return a stylesheet without rules' do
        expect(rules).to be_empty
      end
    end
  end

  describe '#parse_attribute' do
    let(:result) { subject.parse_attribute(value) }

    context 'with a simple declaration' do
      let(:value) { 'color: red' }

      it 'should return a rule with a style attribute selector' do
        expect(result).to eq(Croissant::Stylesheet::Rule.new(
          selector: nil,
          declarations: [Croissant::Stylesheet::Declaration.new(property: 'color', value: 'red')],
          specificity: Croissant::Selector::Specificity.style_attribute
        ))
      end

      it 'should have a specificity above any selector' do
        expect(result.specificity)
          .to eq(Croissant::Selector::Specificity.new(1, 0, 0, 0))
      end

      it 'should be inlinable' do
        expect(result).to be_inlinable
      end

      it 'should parse the declaration' do
        expect(result.declarations).to eq([
          Croissant::Stylesheet::Declaration.new(
            property: 'color',
            value: 'red'
          )
        ])
      end
    end

    context 'with an important declaration' do
      let(:value) { 'color: red !important' }

      it 'should flag important declarations' do
        expect(result.declarations).to eq([
          Croissant::Stylesheet::Declaration.new(
            property: 'color',
            value: 'red',
            important: true
          )
        ])
      end
    end

    context 'with multiple declarations' do
      let(:value) { 'color: red; font-size: 12px' }

      it 'should parse all declarations' do
        expect(result.declarations).to eq([
          Croissant::Stylesheet::Declaration.new(
            property: 'color',
            value: 'red'
          ),
          Croissant::Stylesheet::Declaration.new(
            property: 'font-size',
            value: '12px'
          )
        ])
      end
    end

    context 'with quoted semicolons in the value' do
      let(:value) { 'content: ";"' }

      it 'should keep the value intact' do
        expect(result.declarations).to eq([
          Croissant::Stylesheet::Declaration.new(
            property: 'content',
            value: '";"'
          )
        ])
      end
    end

    context 'with data URLs in the value' do
      let(:value) { 'background: url(data:image/png;base64,iVBORw0KGgo=)' }

      it 'should keep the value intact' do
        expect(result.declarations).to eq([
          Croissant::Stylesheet::Declaration.new(
            property: 'background',
            value: 'url(data:image/png;base64,iVBORw0KGgo=)'
          )
        ])
      end
    end

    context 'with comments in the value' do
      let(:value) { 'color: /* comment */ red' }

      it 'should ignore the comments' do
        expect(result.declarations).to eq([
          Croissant::Stylesheet::Declaration.new(
            property: 'color',
            value: 'red'
          )
        ])
      end
    end

    context 'with unparseable content' do
      let(:value) { 'junk' }

      it 'should return a rule with no declarations' do
        expect(result.declarations).to be_empty
      end
    end

    context 'with empty content' do
      let(:value) { '' }

      it 'should return a rule with no declarations' do
        expect(result.declarations).to be_empty
      end
    end

    context 'with nil content' do
      let(:value) { nil }

      it 'should return a rule with no declarations' do
        expect(result.declarations).to be_empty
      end
    end
  end

  describe '#parse_selector' do
    let(:result) { subject.parse_selector(value) }

    context 'with a simple selector' do
      let(:value) { 'p.intro' }

      it 'should return a selector' do
        expect(result).to be_a(Croissant::Selector)
      end

      it 'should count the class' do
        expect(result.specificity).to eq(Croissant::Selector::Specificity.new(0, 0, 1, 1))
      end

      it 'should be inlinable' do
        expect(result).to be_inlinable
      end
    end

    context 'with a tag only selector' do
      let(:value) { 'h1' }

      it 'should return a selector counting the element' do
        expect(result.specificity).to eq(Croissant::Selector::Specificity.new(0, 0, 0, 1))
      end
    end

    context 'with a class only selector' do
      let(:value) { '.intro' }

      it 'should return a selector counting the class' do
        expect(result.specificity).to eq(Croissant::Selector::Specificity.new(0, 0, 1, 0))
      end
    end

    context 'with an ID only selector' do
      let(:value) { '#main' }

      it 'should return a selector counting the ID' do
        expect(result.specificity).to eq(Croissant::Selector::Specificity.new(0, 1, 0, 0))
      end
    end

    context 'with a attribute selector' do
      let(:value) { 'a[href^="https://"]' }

      it 'should return a selector counting the attribute as a class' do
        expect(result.specificity).to eq(Croissant::Selector::Specificity.new(0, 0, 1, 1))
      end
    end

    context 'with a pseudo-class selector' do
      let(:value) { 'a:hover' }

      it 'should return a selector counting the pseudo-class as a class' do
        expect(result.specificity).to eq(Croissant::Selector::Specificity.new(0, 0, 1, 1))
      end

      it 'should not be inlinable' do
        expect(result).not_to be_inlinable
      end
    end

    context 'with a pseudo-element selector' do
      let(:value) { 'p::after' }

      it 'should return a selector counting the pseudo-element as an element' do
        expect(result.specificity).to eq(Croissant::Selector::Specificity.new(0, 0, 0, 2))
      end

      it 'should not be inlinable' do
        expect(result).not_to be_inlinable
      end
    end

    context 'with a complex selector' do
      let(:value) { 'div#main.content > p.intro:first-child::after' }

      it 'should return a selector summing each component across the whole selector' do
        expect(result.specificity).to eq(Croissant::Selector::Specificity.new(0, 1, 3, 3))
      end

      it 'should not be inlinable' do
        expect(result).not_to be_inlinable
      end
    end
  end
end
