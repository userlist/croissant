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
        expect(rules.first.specificity).to eq(Croissant::Selector::Specificity.element)
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
            Croissant::Selector::Specificity.class_name + Croissant::Selector::Specificity.element,
            Croissant::Selector::Specificity.id
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

      it 'should capture the at-rule as a conditional group' do
        expect(rules.first).to be_a(Croissant::Stylesheet::AtRule::ConditionalGroup)
      end

      it 'should capture the name' do
        expect(rules.first.name).to eq('media')
      end

      it 'should capture the prelude' do
        expect(rules.first.prelude).to eq('print')
      end

      it 'should parse the selectors of nested rules' do
        expect(rules.first.rules.first.selector.to_s).to eq('p')
      end

      it 'should parse the declarations of nested rules' do
        expect(rules.first.rules.first.declarations.first.property).to eq('color')
      end

      it 'should keep following rules in source order' do
        expect(rules.last.selector.to_s).to eq('h1')
      end
    end

    context 'with nested at-rules' do
      let(:value) { '@media print { @media screen { p { color: red } } } h1 { color: blue }' }

      it 'should capture the nested at-rule inside the outer one' do
        nested = rules.first.rules.first

        expect(nested).to be_a(Croissant::Stylesheet::AtRule::ConditionalGroup)
      end

      it 'should capture the prelude of the nested at-rule' do
        expect(rules.first.rules.first.prelude).to eq('screen')
      end

      it 'should parse the rules of the nested at-rule' do
        expect(rules.first.rules.first.rules.first.selector.to_s).to eq('p')
      end

      it 'should keep following rules in source order' do
        expect(rules.last.selector.to_s).to eq('h1')
      end
    end

    context 'with statement at-rules' do
      let(:value) { '@import url(base.css); @charset "utf-8"; p { color: red }' }

      it 'should capture the first statement' do
        statement = Croissant::Stylesheet::AtRule::Statement.new(name: 'import', prelude: 'url(base.css)')

        expect(rules.first).to eq(statement)
      end

      it 'should capture the second statement' do
        statement = Croissant::Stylesheet::AtRule::Statement.new(name: 'charset', prelude: '"utf-8"')

        expect(rules[1]).to eq(statement)
      end

      it 'should keep following rules in source order' do
        expect(rules.last.selector.to_s).to eq('p')
      end
    end

    context 'with a statement at-rule at the end of input' do
      let(:value) { 'p { color: red } @import url(base.css)' }

      it 'should capture the statement' do
        expect(rules.last).to eq(Croissant::Stylesheet::AtRule::Statement.new(name: 'import', prelude: 'url(base.css)'))
      end
    end

    context 'with a statement at-rule terminated by the closing brace of a group' do
      let(:value) { '@media print { @import url(base.css) } h1 { color: blue }' }

      it 'should capture the statement inside the group' do
        nested = rules.first.rules.first

        expect(nested).to eq(Croissant::Stylesheet::AtRule::Statement.new(name: 'import', prelude: 'url(base.css)'))
      end

      it 'should not consume rules after the group' do
        expect(rules.last.selector.to_s).to eq('h1')
      end
    end

    context 'with a font-face at-rule' do
      let(:value) { '@font-face { font-family: Custom; src: url(font.woff) } p { color: red }' }

      it 'should capture the raw block' do
        expect(rules.first).to eq(
          Croissant::Stylesheet::AtRule::Block.new(
            name: 'font-face',
            prelude: '',
            body: 'font-family: Custom; src: url(font.woff)'
          )
        )
      end

      it 'should keep following rules in source order' do
        expect(rules.last.selector.to_s).to eq('p')
      end
    end

    context 'with a keyframes at-rule' do
      let(:value) do
        '@keyframes spin { from { transform: rotate(0) } to { transform: rotate(360deg) } } p { color: red }'
      end

      it 'should capture the nested blocks verbatim' do
        expect(rules.first).to eq(
          Croissant::Stylesheet::AtRule::Block.new(
            name: 'keyframes',
            prelude: 'spin',
            body: 'from { transform: rotate(0) } to { transform: rotate(360deg) }'
          )
        )
      end

      it 'should keep following rules in source order' do
        expect(rules.last.selector.to_s).to eq('p')
      end
    end

    context 'with a supports at-rule' do
      let(:value) { '@supports (display: grid) { p { color: red } } h1 { color: blue }' }

      it 'should capture the at-rule as a conditional group' do
        expect(rules.first).to be_a(Croissant::Stylesheet::AtRule::ConditionalGroup)
      end

      it 'should capture the prelude' do
        expect(rules.first.prelude).to eq('(display: grid)')
      end

      it 'should parse the nested rules' do
        expect(rules.first.rules.first.selector.to_s).to eq('p')
      end
    end

    context 'with an unknown block at-rule' do
      let(:value) { '@layer base { p { color: red } }' }

      it 'should capture the raw block' do
        expect(rules.first).to eq(
          Croissant::Stylesheet::AtRule::Block.new(name: 'layer', prelude: 'base', body: 'p { color: red }')
        )
      end
    end

    context 'with an unterminated at-rule block' do
      let(:value) { '@media print { p { color: red }' }

      it 'should capture the rules up to the end of input' do
        expect(rules.first.rules.first.selector.to_s).to eq('p')
      end
    end

    context 'with an uppercase at-rule name' do
      let(:value) { '@MEDIA PRINT { p { color: red } }' }

      it 'should downcase the name' do
        expect(rules.first.name).to eq('media')
      end

      it 'should keep the prelude verbatim' do
        expect(rules.first.prelude).to eq('PRINT')
      end
    end

    context 'with a comment in an at-rule prelude' do
      let(:value) { '@media /* screen or */ print { p { color: red } }' }

      it 'should splice the comment out of the prelude' do
        expect(rules.first.prelude).to eq('print')
      end
    end

    context 'with a comment in a raw at-rule body' do
      let(:value) { '@font-face { /* local */ font-family: Custom }' }

      it 'should keep the comment in the body' do
        expect(rules.first.body).to eq('/* local */ font-family: Custom')
      end
    end

    context 'with an at-rule without a name' do
      let(:value) { '@ { p { color: red } } h1 { color: blue }' }

      it 'should skip the at-rule but keep following rules' do
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
          specificity: Croissant::Selector::Specificity.inline
        ))
      end

      it 'should have a specificity above any selector' do
        expect(result.specificity)
          .to eq(Croissant::Selector::Specificity.inline)
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
        expect(result.specificity).to eq(Croissant::Selector::Specificity.class_name + Croissant::Selector::Specificity.element)
      end

      it 'should be inlinable' do
        expect(result).to be_inlinable
      end
    end

    context 'with a tag only selector' do
      let(:value) { 'h1' }

      it 'should return a selector counting the element' do
        expect(result.specificity).to eq(Croissant::Selector::Specificity.element)
      end
    end

    context 'with a class only selector' do
      let(:value) { '.intro' }

      it 'should return a selector counting the class' do
        expect(result.specificity).to eq(Croissant::Selector::Specificity.class_name)
      end
    end

    context 'with an ID only selector' do
      let(:value) { '#main' }

      it 'should return a selector counting the ID' do
        expect(result.specificity).to eq(Croissant::Selector::Specificity.id)
      end
    end

    context 'with a attribute selector' do
      let(:value) { 'a[href^="https://"]' }

      it 'should return a selector counting the attribute as a class' do
        expect(result.specificity).to eq(Croissant::Selector::Specificity.class_name + Croissant::Selector::Specificity.element)
      end
    end

    context 'with a pseudo-class selector' do
      let(:value) { 'a:hover' }

      it 'should return a selector counting the pseudo-class as a class' do
        expect(result.specificity).to eq(Croissant::Selector::Specificity.class_name + Croissant::Selector::Specificity.element)
      end

      it 'should not be inlinable' do
        expect(result).not_to be_inlinable
      end
    end

    context 'with a pseudo-element selector' do
      let(:value) { 'p::after' }

      it 'should return a selector counting the pseudo-element as an element' do
        expect(result.specificity).to eq(Croissant::Selector::Specificity.element + Croissant::Selector::Specificity.element)
      end

      it 'should not be inlinable' do
        expect(result).not_to be_inlinable
      end
    end

    context 'with a complex selector' do
      let(:value) { 'div#main.content > p.intro:first-child::after' }

      it 'should return a selector summing each component across the whole selector' do
        expect(result.specificity).to eq(Croissant::Selector::Specificity.build(0, 1, 3, 3))
      end

      it 'should not be inlinable' do
        expect(result).not_to be_inlinable
      end
    end
  end
end
