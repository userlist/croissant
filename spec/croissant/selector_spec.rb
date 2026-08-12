# frozen_string_literal: true

require 'spec_helper'
require 'nokogiri'

RSpec.describe Croissant::Selector do
  def parse(value)
    Croissant::Stylesheet::Parser.parse_selector(value)
  end

  def element_for(html, css)
    Nokogiri::HTML.fragment(html).at_css(css)
  end

  describe '.parse' do
    it 'should return a Selector' do
      expect(parse('p.intro')).to be_a(described_class)
    end

    it 'should return nil for blank input' do
      expect(parse('')).to be_nil
    end

    it 'should return nil for a lone combinator' do
      expect(parse('>')).to be_nil
    end
  end

  describe '#to_s' do
    it 'should render a compound selector the same way it was written' do
      expect(parse('div#main.content').to_s).to eq('div#main.content')
    end

    it 'should render the universal selector explicitly' do
      expect(parse('*').to_s).to eq('*')
    end

    it 'should render a functional pseudo-element with its argument' do
      expect(parse('custom-element::part(button)').to_s).to eq('custom-element::part(button)')
    end

    it 'should render a pseudo-element name in lowercase' do
      expect(parse('p::AFTER').to_s).to eq('p::after')
    end

    it 'should render an unknown pseudo-class name in lowercase' do
      expect(parse('a:HOVER').to_s).to eq('a:hover')
    end

    it 'should render an attribute selector with its operator, quoted value, and flag' do
      expect(parse('a[href^=foo i]').to_s).to eq('a[href^="foo" i]')
    end

    it 'should render a valueless attribute selector' do
      expect(parse('a[href]').to_s).to eq('a[href]')
    end

    it 'should render the descendant combinator' do
      expect(parse('div p').to_s).to eq('div p')
    end

    it 'should render the child combinator' do
      expect(parse('div > p').to_s).to eq('div > p')
    end

    it 'should render the adjacent sibling combinator' do
      expect(parse('div + p').to_s).to eq('div + p')
    end

    it 'should render the general sibling combinator' do
      expect(parse('div ~ p').to_s).to eq('div ~ p')
    end

    it 'should render a structural pseudo-class' do
      expect(parse('li:nth-child(2n+1)').to_s).to eq('li:nth-child(2n+1)')
    end

    it 'should render :not()/:is() with their arguments' do
      expect(parse('a:not(.foo):is(#bar, .baz)').to_s).to eq('a:not(.foo):is(#bar, .baz)')
    end

    it 'should render :where() with its argument' do
      expect(parse(':where(#foo)').to_s).to eq(':where(#foo)')
    end

    it 'should render :has() with its argument' do
      expect(parse('div:has(> p)').to_s).to eq('div:has(> p)')
    end

    it 'should render :has() with the implicit descendant relation without a leading token' do
      expect(parse('div:has(p)').to_s).to eq('div:has(p)')
    end

    it 'should render :has() with multiple relative selectors, each with its own combinator' do
      expect(parse('div:has(p, ~ span)').to_s).to eq('div:has(p, ~ span)')
    end

    it 'should still render an unimplemented pseudo-class faithfully' do
      expect(parse(':lang(en)').to_s).to eq(':lang(en)')
    end

    it 'should canonicalize a legacy pseudo-element to the modern double-colon form' do
      expect(parse('p:before').to_s).to eq('p::before')
    end

    it 'should canonicalize the odd/even keywords to their equivalent An+B formula' do
      expect(parse('li:nth-child(odd)').to_s).to eq('li:nth-child(2n+1)')
    end
  end

  describe '#to_str' do
    it 'should allow implicit string conversion' do
      selector = parse('p')

      expect("selector: #{selector}").to eq('selector: p')
    end
  end

  describe '#index_key' do
    it 'should prefer an id selector from the rightmost compound' do
      selector = parse('div.content #main.intro')

      expect(selector.index_key).to have_attributes(class: Croissant::Selector::Simple::Id, name: 'main')
    end

    it 'should fall back to a class selector when the rightmost compound has no id' do
      selector = parse('div.wrapper > p.intro.lead')

      expect(selector.index_key)
        .to have_attributes(class: Croissant::Selector::Simple::ClassName, name: 'intro')
    end

    it 'should fall back to the type selector when the rightmost compound has no id or class' do
      selector = parse('div#main.content > p')

      expect(selector.index_key)
        .to have_attributes(class: Croissant::Selector::Simple::Type, name: 'p')
    end

    it 'should be nil when the rightmost compound has no id, class, or type' do
      expect(parse('div #main.intro > *').index_key).to be_nil
    end

    it 'should not consider ids, classes, or types from earlier compounds' do
      expect(parse('#main .intro').index_key)
        .to have_attributes(class: Croissant::Selector::Simple::ClassName, name: 'intro')
    end
  end

  describe '#matches?' do
    it 'should match a plain tag selector' do
      element = element_for('<p></p>', 'p')

      expect(parse('p')).to be_matches(element)
    end

    it 'should match a compound of tag, id, and class' do
      element = element_for('<p id="main" class="intro"></p>', 'p')

      expect(parse('p#main.intro')).to be_matches(element)
    end

    it 'should not match when a required class is missing' do
      element = element_for('<p class="other"></p>', 'p')

      expect(parse('.intro')).not_to be_matches(element)
    end

    it 'should match an attribute selector by operator' do
      element = element_for('<a href="https://example.com"></a>', 'a')

      expect(parse('a[href^="https://"]')).to be_matches(element)
    end

    it 'should not match an attribute selector when the attribute is absent' do
      element = element_for('<a></a>', 'a')

      expect(parse('a[href]')).not_to be_matches(element)
    end

    it 'should match a type selector regardless of its case' do
      element = element_for('<p></p>', 'p')

      expect(parse('P')).to be_matches(element)
    end

    it 'should match an attribute selector regardless of the attribute name case' do
      element = element_for('<a href="https://example.com"></a>', 'a')

      expect(parse('a[HREF]')).to be_matches(element)
    end

    it 'should match an attribute selector case-insensitively with the "i" flag' do
      element = element_for('<a href="FOO-bar"></a>', 'a')

      expect(parse('a[href^=foo i]')).to be_matches(element)
    end

    it 'should not treat a trailing "i" flag as part of an unquoted value' do
      selector = parse('a[href^=foo i]')

      attribute = selector.selectors.grep(Croissant::Selector::Simple::Attribute).first
      expect(attribute.value).to eq('foo')
    end

    it 'should still match case-sensitively without a flag' do
      element = element_for('<a href="FOO-bar"></a>', 'a')

      expect(parse('a[href^="foo"]')).not_to be_matches(element)
    end

    it 'should match a descendant combinator separated by a newline, not just a space' do
      element = element_for('<div id="wrap"><p><span></span></p></div>', 'span')

      expect(parse("#wrap\n\tspan")).to be_matches(element)
    end

    it 'should not lose the earlier compound when the combinator is a newline' do
      element = element_for('<span><p></p></span>', 'p')

      expect(parse("div\n\tp")).not_to be_matches(element)
    end

    it 'should match a descendant combinator against any ancestor' do
      element = element_for('<div id="wrap"><p><span></span></p></div>', 'span')

      expect(parse('#wrap span')).to be_matches(element)
    end

    it 'should not match a child combinator against a non-parent ancestor' do
      element = element_for('<div id="wrap"><p><span></span></p></div>', 'span')

      expect(parse('#wrap > span')).not_to be_matches(element)
    end

    it 'should match a child combinator against the direct parent' do
      element = element_for('<div id="wrap"><span></span></div>', 'span')

      expect(parse('#wrap > span')).to be_matches(element)
    end

    it 'should match an adjacent sibling combinator against the immediately preceding sibling' do
      html = '<ul><li class="first"></li><li class="second"></li></ul>'
      element = element_for(html, 'li.second')

      expect(parse('li.first + li')).to be_matches(element)
    end

    it 'should not match an adjacent sibling combinator across an intervening sibling' do
      html = '<ul><li class="first"></li><li></li><li class="third"></li></ul>'
      element = element_for(html, 'li.third')

      expect(parse('li.first + li')).not_to be_matches(element)
    end

    it 'should match a general sibling combinator across an intervening sibling' do
      html = '<ul><li class="first"></li><li></li><li class="third"></li></ul>'
      element = element_for(html, 'li.third')

      expect(parse('li.first ~ li')).to be_matches(element)
    end

    it 'should match :not() when the element matches none of its arguments' do
      element = element_for('<a class="btn"></a>', 'a')

      expect(parse('a:not(.foo)')).to be_matches(element)
    end

    it 'should not match :not() when the element matches one of its arguments' do
      element = element_for('<a class="btn"></a>', 'a')

      expect(parse('a:not(.btn)')).not_to be_matches(element)
    end

    it 'should not match :not() when the element matches any of several arguments' do
      element = element_for('<li class="first"></li>', 'li')

      expect(parse('li:not(.first, .last)')).not_to be_matches(element)
    end

    it 'should match :is() when the element matches any of its arguments' do
      element = element_for('<p class="intro"></p>', 'p')

      expect(parse(':is(.missing, .intro)')).to be_matches(element)
    end

    it 'should not match :is() when the element matches none of its arguments' do
      element = element_for('<p class="intro"></p>', 'p')

      expect(parse(':is(.missing, #other)')).not_to be_matches(element)
    end

    it 'should match :where() the same way it matches :is()' do
      element = element_for('<p class="lead"></p>', 'p')

      expect(parse(':where(.missing, p.lead)')).to be_matches(element)
    end

    it 'should match :has() when a descendant satisfies its argument' do
      element = element_for('<div><ul><li class="last"></li></ul></div>', 'div')

      expect(parse('div:has(li.last)')).to be_matches(element)
    end

    it 'should not match :has() when no descendant satisfies its argument' do
      element = element_for('<div><ul><li></li></ul></div>', 'div')

      expect(parse('div:has(li.last)')).not_to be_matches(element)
    end

    it "should match :has() with an explicit combinator against the element's own children" do
      element = element_for('<div><p></p></div>', 'div')

      expect(parse('div:has(> p)')).to be_matches(element)
    end

    it 'should not match :has() with a child combinator against a non-child descendant' do
      element = element_for('<div><span><p></p></span></div>', 'div')

      expect(parse('div:has(> p)')).not_to be_matches(element)
    end

    it 'should match :has() with an adjacent sibling combinator against the immediately following sibling' do
      element = element_for('<div></div><p></p>', 'div')

      expect(parse('div:has(+ p)')).to be_matches(element)
    end

    it 'should not match :has() with an adjacent sibling combinator against a later sibling' do
      element = element_for('<div></div><span></span><p></p>', 'div')

      expect(parse('div:has(+ p)')).not_to be_matches(element)
    end

    it 'should match :has() with a general sibling combinator against any following sibling' do
      element = element_for('<div></div><span></span><p></p>', 'div')

      expect(parse('div:has(~ p)')).to be_matches(element)
    end

    it 'should not match :has() with a general sibling combinator against a preceding sibling' do
      element = element_for('<p></p><div></div>', 'div')

      expect(parse('div:has(~ p)')).not_to be_matches(element)
    end

    it 'should support :is() nested inside :has()' do
      element = element_for('<div><span class="foo"></span></div>', 'div')

      expect(parse('div:has(:is(.foo, .bar))')).to be_matches(element)
    end

    it 'should support :not() nested inside :is()' do
      element = element_for('<p class="intro"></p>', 'p')

      expect(parse(':is(.intro, :not(.intro))')).to be_matches(element)
    end

    it 'should never match an unimplemented pseudo-class, rather than risk a crash' do
      element = element_for('<a></a>', 'a')

      expect(parse('a:link')).not_to be_matches(element)
    end

    it "should stay safe even for a pseudo-class Nokogiri's own matcher would crash on" do
      element = element_for('<a></a>', 'a')

      expect { element.matches?('a:link') }.to raise_error(Nokogiri::XML::XPath::SyntaxError)
    end

    it 'should match :first-child for the first element sibling' do
      element = element_for('<ul><li class="a"></li><li class="b"></li></ul>', 'li.a')

      expect(parse('li:first-child')).to be_matches(element)
    end

    it 'should not match :first-child for a later element sibling' do
      element = element_for('<ul><li class="a"></li><li class="b"></li></ul>', 'li.b')

      expect(parse('li:first-child')).not_to be_matches(element)
    end

    it 'should match :last-child for the last element sibling' do
      element = element_for('<ul><li class="a"></li><li class="b"></li></ul>', 'li.b')

      expect(parse('li:last-child')).to be_matches(element)
    end

    it 'should match :only-child when there are no sibling elements' do
      element = element_for('<div><p></p></div>', 'p')

      expect(parse('p:only-child')).to be_matches(element)
    end

    it 'should not match :only-child when there is a sibling element' do
      element = element_for('<div><p></p><span></span></div>', 'p')

      expect(parse('p:only-child')).not_to be_matches(element)
    end

    it 'should match :first-of-type ignoring siblings of a different tag' do
      html = '<div><span></span><p class="target"></p></div>'
      element = element_for(html, 'p.target')

      expect(parse('p:first-of-type')).to be_matches(element)
    end

    it 'should not match :first-of-type when a same-tag sibling precedes it' do
      html = '<div><p></p><p class="second"></p></div>'
      element = element_for(html, 'p.second')

      expect(parse('p:first-of-type')).not_to be_matches(element)
    end

    it 'should match :last-of-type ignoring siblings of a different tag' do
      html = '<div><p class="target"></p><span></span></div>'
      element = element_for(html, 'p.target')

      expect(parse('p:last-of-type')).to be_matches(element)
    end

    it 'should match :only-of-type when no sibling shares its tag' do
      html = '<div><p></p><span></span></div>'
      element = element_for(html, 'p')

      expect(parse('p:only-of-type')).to be_matches(element)
    end

    it 'should not match :only-of-type when a sibling shares its tag' do
      html = '<div><p></p><p class="second"></p></div>'
      element = element_for(html, 'p')

      expect(parse('p:only-of-type')).not_to be_matches(element)
    end

    it 'should match :empty for an element with no children' do
      element = element_for('<div></div>', 'div')

      expect(parse('div:empty')).to be_matches(element)
    end

    it 'should not match :empty for an element with text content' do
      element = element_for('<div>hi</div>', 'div')

      expect(parse('div:empty')).not_to be_matches(element)
    end

    it 'should not match :empty for an element with an element child' do
      element = element_for('<div><span></span></div>', 'div')

      expect(parse('div:empty')).not_to be_matches(element)
    end

    it 'should match :root for the outermost element' do
      element = element_for('<div><p></p></div>', 'div')

      expect(parse(':root')).to be_matches(element)
    end

    it 'should not match :root for a nested element' do
      element = element_for('<div><p></p></div>', 'p')

      expect(parse(':root')).not_to be_matches(element)
    end

    it 'should match :nth-child() by absolute position' do
      html = '<ul><li class="a"></li><li class="b"></li><li class="c"></li></ul>'
      element = element_for(html, 'li.b')

      expect(parse('li:nth-child(2)')).to be_matches(element)
    end

    it 'should match :nth-child(odd) for odd sibling positions' do
      html = '<ul><li class="a"></li><li class="b"></li><li class="c"></li></ul>'
      element = element_for(html, 'li.c')

      expect(parse('li:nth-child(odd)')).to be_matches(element)
    end

    it 'should not match :nth-child(An+B) when the position misses the formula' do
      html = '<ul><li></li><li></li><li class="third"></li><li></li></ul>'
      element = element_for(html, 'li.third')

      expect(parse('li:nth-child(3n+1)')).not_to be_matches(element)
    end

    it 'should match :nth-child(An+B) when the position satisfies the formula' do
      html = '<ul><li></li><li></li><li class="third"></li><li></li></ul>'
      element = element_for(html, 'li.third')

      expect(parse('li:nth-child(2n+1)')).to be_matches(element)
    end

    it 'should match :nth-of-type() counting only same-tag siblings' do
      html = '<div><span></span><p class="target"></p><span></span></div>'
      element = element_for(html, 'p.target')

      expect(parse('p:nth-of-type(1)')).to be_matches(element)
    end

    it 'should match :nth-last-child() counting position from the end' do
      html = '<ul><li class="a"></li><li class="b"></li><li class="c"></li></ul>'
      element = element_for(html, 'li.b')

      expect(parse('li:nth-last-child(2)')).to be_matches(element)
    end

    it 'should not match :nth-last-child() when the position from the end misses' do
      html = '<ul><li class="a"></li><li class="b"></li><li class="c"></li></ul>'
      element = element_for(html, 'li.a')

      expect(parse('li:nth-last-child(2)')).not_to be_matches(element)
    end

    it 'should match :nth-last-of-type() counting only same-tag siblings from the end' do
      html = '<div><span></span><p class="target"></p><span></span></div>'
      element = element_for(html, 'p.target')

      expect(parse('p:nth-last-of-type(1)')).to be_matches(element)
    end
  end

  describe '#inlinable?' do
    it 'should be inlinable for a plain selector' do
      expect(parse('p.intro')).to be_inlinable
    end

    it 'should not be inlinable for a pseudo-element' do
      expect(parse('p::after')).not_to be_inlinable
    end

    it 'should not be inlinable for a legacy pseudo-element' do
      expect(parse('p:before')).not_to be_inlinable
    end

    it 'should not be inlinable for a functional pseudo-element' do
      expect(parse('custom-element::part(button)')).not_to be_inlinable
    end

    it 'should be inlinable for a structural pseudo-class' do
      expect(parse('li:first-child')).to be_inlinable
    end

    it 'should not be inlinable for a dynamic pseudo-class' do
      expect(parse('a:hover')).not_to be_inlinable
    end

    it 'should not be inlinable for an nth formula it cannot parse' do
      expect(parse('li:nth-child(2n of .foo)')).not_to be_inlinable
    end

    it 'should not be inlinable when :not() wraps a dynamic pseudo-class' do
      expect(parse('a:not(:hover)')).not_to be_inlinable
    end

    it 'should not be inlinable when :is() wraps a dynamic pseudo-class' do
      expect(parse(':is(:focus, .foo)')).not_to be_inlinable
    end

    it 'should not be inlinable when :has() wraps a dynamic pseudo-class' do
      expect(parse('div:has(:hover)')).not_to be_inlinable
    end

    it 'should not be inlinable when :where() wraps a dynamic pseudo-class' do
      expect(parse(':where(:hover)')).not_to be_inlinable
    end

    it 'should not be inlinable when a dynamic pseudo-class is nested inside :not(:is())' do
      expect(parse('a:not(:is(:hover))')).not_to be_inlinable
    end
  end
end
