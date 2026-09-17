# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Croissant::Style::Value do
  def parse(input)
    described_class.parse(input)
  end

  describe '.parse' do
    it 'should parse a bare number as a number' do
      expect(described_class.parse('1.5')).to be_a(Croissant::Style::Value::Number)
    end

    it 'should parse a length as a length' do
      expect(described_class.parse('10px')).to be_a(Croissant::Style::Value::Length)
    end

    it 'should parse the unit of a length' do
      expect(described_class.parse('10em').unit).to be(Croissant::Style::Unit.lookup('em'))
    end

    it 'should ignore the case of a unit' do
      expect(described_class.parse('10PX')).to eq(described_class.parse('10px'))
    end

    it 'should parse a percentage as a percentage' do
      expect(described_class.parse('50%')).to be_a(Croissant::Style::Value::Percentage)
    end

    it 'should parse a leading decimal point' do
      expect(described_class.parse('.5em').to_f).to eq(0.5)
    end

    it 'should parse a signed number' do
      expect(described_class.parse('-10px').to_f).to eq(-10.0)
    end

    it 'should strip surrounding whitespace' do
      expect(described_class.parse('  10px  ')).to eq(described_class.parse('10px'))
    end

    it 'should parse an identifier as a keyword' do
      expect(described_class.parse('auto')).to be_a(Croissant::Style::Value::Keyword)
    end

    it 'should parse a hyphenated identifier as a keyword' do
      expect(described_class.parse('sans-serif')).to be_a(Croissant::Style::Value::Keyword)
    end

    it 'should parse a vendor-prefixed identifier as a keyword' do
      expect(described_class.parse('-webkit-box')).to be_a(Croissant::Style::Value::Keyword)
    end

    it 'should parse a custom property name as a keyword' do
      expect(described_class.parse('--brand-color')).to be_a(Croissant::Style::Value::Keyword)
    end

    it 'should parse a space-separated value as a list' do
      expect(described_class.parse('1px solid red')).to be_a(Croissant::Style::Value::List)
    end

    it 'should parse a comma-separated value as a list' do
      expect(described_class.parse('Arial, sans-serif')).to be_a(Croissant::Style::Value::List)
    end

    it 'should parse a hex colour as a colour' do
      expect(described_class.parse('#fff')).to be_a(Croissant::Style::Value::Color)
    end

    it 'should parse a six-digit hex colour as a colour' do
      expect(described_class.parse('#ff0000')).to be_a(Croissant::Style::Value::Color)
    end

    it 'should parse an rgb colour as a colour' do
      expect(described_class.parse('rgb(255, 0, 0)')).to be_a(Croissant::Style::Value::Color)
    end

    it 'should parse an rgba colour as a colour' do
      expect(described_class.parse('rgba(0, 0, 0, 0.5)')).to be_a(Croissant::Style::Value::Color)
    end

    it 'should parse a hex colour of an impossible length as unparsed' do
      expect(described_class.parse('#fffff')).to be_a(Croissant::Style::Value::Unparsed)
    end

    it 'should parse a non-hex colour as unparsed' do
      expect(described_class.parse('#gggggg')).to be_a(Croissant::Style::Value::Unparsed)
    end

    it 'should parse an rgb colour with too few channels as unparsed' do
      expect(described_class.parse('rgb(1, 2)')).to be_a(Croissant::Style::Value::Unparsed)
    end

    it 'should parse a named colour as a keyword, having no property context' do
      expect(described_class.parse('red')).to be_a(Croissant::Style::Value::Keyword)
    end

    it 'should parse a function it does not know as unparsed' do
      expect(described_class.parse('calc(1px + 2px)')).to be_a(Croissant::Style::Value::Unparsed)
    end

    it 'should parse a quoted string as unparsed' do
      expect(described_class.parse('"Helvetica Neue"')).to be_a(Croissant::Style::Value::Unparsed)
    end

    it 'should return nil for an empty value' do
      expect(described_class.parse('')).to be_nil
    end

    it 'should return nil for nil' do
      expect(described_class.parse(nil)).to be_nil
    end

    it 'should return a value it is given unchanged' do
      value = described_class.parse('10px')

      expect(described_class.parse(value)).to be(value)
    end

    it 'should try only the types it is given' do
      keyword = Croissant::Style::Value::Keyword

      expect(described_class.parse('10px', keyword)).to be_a(Croissant::Style::Value::Unparsed)
    end

    it 'should keep the text of a value none of its types recognize' do
      keyword = Croissant::Style::Value::Keyword

      expect(described_class.parse('10px', keyword).to_s).to eq('10px')
    end

    it 'should read a named colour as a colour when its types ask for one' do
      colour = Croissant::Style::Value::Color | Croissant::Style::Value::Keyword

      expect(described_class.parse('red', colour)).to be_a(Croissant::Style::Value::Color)
    end

    it 'should read a keyword a colour cannot resolve as a keyword' do
      colour = Croissant::Style::Value::Color | Croissant::Style::Value::Keyword

      expect(described_class.parse('currentcolor', colour)).to be_a(Croissant::Style::Value::Keyword)
    end

    it 'should apply its types to each element of a list' do
      colour = Croissant::Style::Value::Color | Croissant::Style::Value::Keyword

      expect(described_class.parse('red blue', colour).map(&:to_s)).to eq(['#ff0000', '#0000ff'])
    end

    it 'should still build a list when none of its types match the whole value' do
      colour = Croissant::Style::Value::Color | Croissant::Style::Value::Keyword

      expect(described_class.parse('red blue', colour)).to be_a(Croissant::Style::Value::List)
    end
  end

  describe '.[]' do
    it 'should parse the input' do
      expect(described_class['10px']).to be_a(described_class::Length)
    end

    it 'should parse through the class it is called on' do
      expect(described_class::Number['10px']).to be_nil
    end

    it 'should return nil for input the class does not recognize' do
      expect(described_class::Length['auto']).to be_nil
    end

    it 'should build a keyword from a symbol' do
      expect(described_class::Keyword[:auto]).to eq(described_class::Keyword.new(:auto))
    end

    it 'should take a type the way .parse does' do
      colour = described_class::Color | described_class::Keyword

      expect(described_class['red', colour]).to be_a(described_class::Color)
    end
  end

  describe '.split' do
    def split(input)
      described_class::List.split(input)
    end

    it 'should split on top-level whitespace' do
      expect(split('1px solid red')).to eq(%w[1px solid red])
    end

    it 'should return a single token unsplit' do
      expect(split('1px')).to eq(['1px'])
    end

    it 'should keep a bracketed group together' do
      expect(split('calc(1px + 2px) 3px')).to eq(['calc(1px + 2px)', '3px'])
    end

    it 'should keep a quoted string together' do
      expect(split('"Helvetica Neue" 2px')).to eq(['"Helvetica Neue"', '2px'])
    end

    it 'should split on commas when given the segment pattern' do
      segments = described_class::List::SEGMENTS

      expect(described_class::List.split('Arial, sans-serif', segments)).to eq(%w[Arial sans-serif])
    end

    it 'should accept something that is not a string' do
      expect(split(nil)).to eq([])
    end
  end

  describe '.global_type' do
    it 'should parse a CSS-wide keyword' do
      expect(described_class.global_type.parse('inherit')).to eq(:inherit)
    end

    it 'should cover every CSS-wide keyword' do
      names = %w[inherit initial unset revert revert-layer]
      parsed = names.map { |name| described_class.global_type.parse(name) }

      expect(parsed).to all(be_a(described_class::Keyword))
    end

    it 'should not parse anything else' do
      expect(described_class.global_type.parse('auto')).to be_nil
    end

    it 'should be the same union on every call' do
      first = described_class.global_type
      second = described_class.global_type

      expect(first).to be(second)
    end
  end

  describe 'an integer' do
    it 'should parse integral notation' do
      expect(described_class::Integer['2']).to be_a(described_class::Integer)
    end

    it 'should parse a signed integer' do
      expect(described_class::Integer['-2'].to_i).to eq(-2)
    end

    it 'should not parse a fractional number' do
      expect(described_class::Integer['2.5']).to be_nil
    end

    it 'should not parse a length' do
      expect(described_class::Integer['2px']).to be_nil
    end

    it 'should be a number, since CSS makes integers a subset of them' do
      expect(described_class::Integer['2']).to be_a(described_class::Number)
    end

    it 'should serialize without a decimal point' do
      expect(described_class::Integer['2'].to_s).to eq('2')
    end

    it 'should stay out of the generic chain, which has no property to ask' do
      expect(described_class.parse('2')).to be_an_instance_of(described_class::Number)
    end

    it 'should stay out of the numeric chain too' do
      expect(described_class::Numeric.parse('2')).to be_an_instance_of(described_class::Number)
    end
  end

  describe '#absolutize' do
    it 'should convert an absolute unit to pixels' do
      expect(parse('1in').absolutize.to_s).to eq('96px')
    end

    it 'should convert an em against a font size' do
      expect(parse('2em').absolutize(font_size: 16).to_s).to eq('32px')
    end

    it 'should keep an em without a font size as specified' do
      expect(parse('2em').absolutize.to_s).to eq('2em')
    end

    it 'should keep a unit it does not model as specified' do
      expect(parse('2ch').absolutize.to_s).to eq('2ch')
    end

    it 'should convert a rem against a root font size' do
      expect(parse('2rem').absolutize(root_font_size: 16).to_s).to eq('32px')
    end

    it 'should keep a rem without a root font size as specified' do
      expect(parse('2rem').absolutize.to_s).to eq('2rem')
    end

    it 'should convert a percentage against a base' do
      expect(parse('50%').absolutize(base: 200).to_s).to eq('100px')
    end

    it 'should keep a percentage without a base as specified' do
      expect(parse('50%').absolutize.to_s).to eq('50%')
    end

    it 'should keep a number as specified' do
      value = parse('1.5')

      expect(value.absolutize).to be(value)
    end

    it 'should keep a keyword as specified' do
      value = parse('auto')

      expect(value.absolutize).to be(value)
    end

    it 'should keep a percentage as specified when the base is nil' do
      expect(parse('50%').absolutize(base: nil).to_s).to eq('50%')
    end

    it 'should ignore context it has no use for' do
      expect(parse('1in').absolutize(base: 200).to_s).to eq('96px')
    end
  end

  describe 'arithmetic' do
    it 'should add a numeric' do
      expect((parse('10px') + 5).to_s).to eq('15px')
    end

    it 'should add a bare number' do
      expect((parse('10px') + parse('5')).to_s).to eq('15px')
    end

    it 'should add a length of the same unit' do
      expect((parse('10px') + parse('5px')).to_s).to eq('15px')
    end

    it 'should subtract a length of the same unit' do
      expect((parse('10px') - parse('5px')).to_s).to eq('5px')
    end

    it 'should refuse to combine lengths of different units' do
      expect { parse('10px') + parse('5em') }.to raise_error(ArgumentError)
    end

    it 'should refuse to combine a length with a percentage' do
      expect { parse('10px') + parse('50%') }.to raise_error(ArgumentError)
    end

    it 'should keep the unit when scaling' do
      expect((parse('10em') * 2).to_s).to eq('20em')
    end

    it 'should scale by a percentage' do
      expect((parse('10px') * parse('50%')).to_s).to eq('5px')
    end

    it 'should refuse to scale by a length' do
      expect { parse('10px') * parse('2px') }.to raise_error(ArgumentError)
    end

    it 'should refuse to scale by a keyword' do
      expect { parse('10px') * parse('auto') }.to raise_error(ArgumentError)
    end

    it 'should refuse to scale by something that is not a value' do
      expect { parse('10px') * 'foo' }.to raise_error(ArgumentError)
    end

    it 'should refuse to scale by nil' do
      expect { parse('10px') * nil }.to raise_error(ArgumentError)
    end

    it 'should add a bare number to a percentage' do
      expect((parse('50%') + parse('10')).to_s).to eq('60%')
    end

    it 'should refuse to add a percentage to a bare number' do
      expect { parse('10') + parse('50%') }.to raise_error(ArgumentError)
    end

    it 'should add a percentage to a percentage' do
      expect((parse('50%') + parse('50%')).to_s).to eq('100%')
    end

    it 'should divide' do
      expect((parse('10px') / 4).to_s).to eq('2.5px')
    end

    it 'should round' do
      expect(parse('10.567px').round(1).to_s).to eq('10.6px')
    end
  end

  describe '#==' do
    it 'should be equal to a value of the same class and value' do
      first = parse('10px')
      second = parse('10px')

      expect(first).to eq(second)
    end

    it 'should not be equal to a length of another unit' do
      expect(parse('10px')).not_to eq(parse('10em'))
    end

    it 'should not be equal to a percentage of the same number' do
      expect(parse('50')).not_to eq(parse('50%'))
    end

    it 'should treat a value built by hand as equal to a parsed one' do
      expect(described_class::Length.new(10)).to eq(parse('10px'))
    end
  end

  describe '#eql?' do
    it 'should treat a value built by hand as eql to a parsed one' do
      expect(described_class::Length.new(10)).to eql(parse('10px'))
    end

    it 'should not be eql to a length of another unit' do
      expect(parse('10px')).not_to eql(parse('10em'))
    end
  end

  describe '#hash' do
    it 'should have the same hash as an equal value' do
      expect(parse('10px').hash).to eq(described_class::Length.new(10).hash)
    end

    it 'should find a parsed value under a key built by hand' do
      expect({ described_class::Length.new(10) => 'found' }[parse('10px')]).to eq('found')
    end
  end

  describe '#to_s' do
    it 'should print a whole number without a decimal point' do
      expect(parse('10.0px').to_s).to eq('10px')
    end

    it 'should print a fractional number' do
      expect(parse('1.5').to_s).to eq('1.5')
    end

    it 'should append the unit of a length' do
      expect(parse('10em').to_s).to eq('10em')
    end

    it 'should append the sign of a percentage' do
      expect(parse('50%').to_s).to eq('50%')
    end

    it 'should print the name of a keyword' do
      expect(parse('auto').to_s).to eq('auto')
    end

    it 'should print an unparsed value exactly as it was written' do
      expect(parse('calc(1px + 2px)').to_s).to eq('calc(1px + 2px)')
    end
  end

  describe '#freeze' do
    it 'should be frozen after initialization' do
      expect(parse('10px')).to be_frozen
    end

    it 'should freeze a value derived by arithmetic' do
      expect(parse('10px') + parse('5px')).to be_frozen
    end

    it 'should freeze a value derived by absolutizing' do
      expect(parse('1in').absolutize).to be_frozen
    end

    it 'should freeze the text an unparsed value wraps' do
      expect { parse('calc(1px + 2px)').to_s << '!' }.to raise_error(FrozenError)
    end
  end

  describe 'a percentage' do
    it 'should not be a number' do
      expect(parse('50%')).not_to be_a(described_class::Number)
    end

    it 'should be a value' do
      expect(parse('50%')).to be_a(described_class)
    end

    it 'should scale another value' do
      expect(parse('50%')).to be_scalar
    end

    it 'should read as its fraction' do
      expect(parse('50%').to_f).to eq(0.5)
    end

    it 'should convert to the number it stands for' do
      expect(parse('50%').to_number.to_s).to eq('0.5')
    end

    it 'should convert to itself as a percentage' do
      value = parse('50%')

      expect(value.to_percentage).to be(value)
    end
  end

  describe 'a number' do
    it 'should parse a bare number' do
      expect(described_class::Numeric.parse('1.5')).to be_a(described_class::Number)
    end

    it 'should parse a length through the numeric family' do
      expect(described_class::Numeric.parse('10px')).to be_a(described_class::Length)
    end

    it 'should parse a percentage through the numeric family' do
      expect(described_class::Numeric.parse('50%')).to be_a(described_class::Percentage)
    end

    it 'should not parse something that is not a number' do
      expect(described_class::Numeric.parse('auto')).to be_nil
    end

    it 'should scale another value' do
      expect(parse('2')).to be_scalar
    end

    it 'should convert to the percentage it stands for' do
      expect(parse('2').to_percentage.to_s).to eq('200%')
    end

    it 'should convert to itself as a number' do
      value = parse('2')

      expect(value.to_number).to be(value)
    end
  end

  describe 'a length' do
    it 'should not scale another value' do
      expect(parse('10px')).not_to be_scalar
    end
  end

  describe 'a keyword' do
    it 'should parse an identifier' do
      expect(described_class::Keyword.parse('auto')).to be_a(described_class::Keyword)
    end

    it 'should not parse something that is not an identifier' do
      expect(described_class::Keyword.parse('1px solid red')).to be_nil
    end

    it 'should parse itself when used as a type' do
      keyword = described_class::Keyword.new(:auto)

      expect(keyword.parse('auto')).to be(keyword)
    end

    it 'should not parse a keyword other than itself' do
      expect(described_class::Keyword.new(:auto).parse('none')).to be_nil
    end

    it 'should build a union when keywords are chained' do
      allowed = described_class::Keyword[:auto] | described_class::Keyword[:none]

      expect(allowed).to be_a(described_class::Union)
    end

    it 'should accept only the keywords chained into it' do
      allowed = described_class::Keyword[:auto] | described_class::Keyword[:none]

      expect(allowed.parse('block')).to be_nil
    end

    it 'should accept each keyword chained into it' do
      allowed = described_class::Keyword[:auto] | described_class::Keyword[:none]

      expect(allowed.parse('none')).to eq(:none)
    end

    it 'should combine with a class type from the left' do
      type = described_class::Length | described_class::Keyword[:auto]

      expect(type.parse('auto')).to eq(:auto)
    end

    it 'should combine with a class type from the right' do
      type = described_class::Keyword[:auto] | described_class::Length

      expect(type.parse('10px')).to be_a(described_class::Length)
    end

    it 'should equal another keyword of the same name' do
      expect(parse('auto')).to eq(described_class::Keyword.new('auto'))
    end

    it 'should equal its name as a string' do
      expect(parse('auto')).to eq('auto')
    end

    it 'should be found equal by a string of its name' do
      name = 'auto'

      expect(name).to eq(parse('auto'))
    end

    it 'should be found among strings' do
      names = ['auto']

      expect(names).to include(parse('auto'))
    end

    it 'should equal its name as a symbol' do
      expect(parse('auto')).to eq(:auto)
    end

    it 'should not equal a different name' do
      expect(parse('auto')).not_to eq('none')
    end

    it 'should return false when compared to nil' do
      expect(parse('auto') == nil).to be(false) # rubocop:disable Style/NilComparison
    end

    it 'should not equal a number' do
      expect(parse('auto')).not_to eq(5)
    end

    it 'should not equal an unparsed value of the same text' do
      expect(parse('auto')).not_to eq(described_class::Unparsed.new('auto'))
    end

    it 'should not equal a unit of the same name' do
      expect(parse('px')).not_to eq(Croissant::Style::Unit.lookup('px'))
    end

    it 'should survive being searched for among foreign objects' do
      expect([parse('auto')]).not_to include(5)
    end

    it 'should not be eql to its name, since hash keys must not cross types' do
      expect(parse('auto')).not_to eql('auto')
    end
  end

  describe 'a colour' do
    it 'should parse a colour notation' do
      expect(described_class::Color.parse('#fff')).to be_a(described_class::Color)
    end

    it 'should not parse something that is not a colour' do
      expect(described_class::Color.parse('auto')).to be_nil
    end

    it 'should expand a three-digit hex colour' do
      expect(parse('#abc').to_s).to eq('#aabbcc')
    end

    it 'should read its channels' do
      expect([parse('#ff8000').red, parse('#ff8000').green, parse('#ff8000').blue]).to eq([255, 128, 0])
    end

    it 'should be opaque without an alpha channel' do
      expect(parse('#fff')).to be_opaque
    end

    it 'should read the alpha of an rgba colour' do
      expect(parse('rgba(0, 0, 0, 0.5)').alpha).to eq(0.5)
    end

    it 'should ignore the case of a hex colour' do
      expect(parse('#FFF')).to eq(parse('#fff'))
    end

    it 'should treat equivalent notations as equal' do
      expect(parse('rgb(255, 0, 0)')).to eq(parse('#ff0000'))
    end

    it 'should hash equivalent notations alike' do
      expect(parse('rgb(255, 0, 0)').hash).to eq(parse('#ff0000').hash)
    end

    it 'should not equal the same channels at a different alpha' do
      expect(parse('rgba(0, 0, 0, 0.5)')).not_to eq(parse('#000000'))
    end

    it 'should accept percentage channels' do
      expect(parse('rgb(100% 0% 0%)').to_s).to eq('#ff0000')
    end

    it 'should accept the slash-separated alpha form' do
      expect(parse('rgb(0 0 0 / 50%)').alpha).to eq(0.5)
    end

    it 'should clamp a channel beyond its range' do
      expect(parse('rgb(300, -20, 0)').to_s).to eq('#ff0000')
    end

    it 'should serialize an opaque colour as hex' do
      expect(parse('rgb(255, 0, 0)').to_s).to eq('#ff0000')
    end

    it 'should serialize a translucent colour as rgba' do
      expect(parse('rgba(0, 0, 0, 0.5)').to_s).to eq('rgba(0, 0, 0, 0.5)')
    end

    it 'should keep itself as specified when absolutized' do
      value = parse('#fff')

      expect(value.absolutize).to be(value)
    end

    it 'should be frozen' do
      expect(parse('#fff')).to be_frozen
    end
  end

  describe 'a list' do
    it 'should parse a space-separated value' do
      expect(described_class::List.parse('0 auto')).to be_a(described_class::List)
    end

    it 'should not parse a single token' do
      expect(described_class::List.parse('auto')).to be_nil
    end

    it 'should parse each element in turn' do
      expect(parse('1px solid red').map(&:class)).to eq(
        [described_class::Length, described_class::Keyword, described_class::Keyword]
      )
    end

    it 'should separate on whitespace' do
      expect(parse('0 auto').separator).to eq(:space)
    end

    it 'should separate on commas' do
      expect(parse('Arial, sans-serif').separator).to eq(:comma)
    end

    it 'should not split a comma inside a function' do
      expect(parse('rgb(0, 0, 0) solid').count).to eq(2)
    end

    it 'should not split a space inside a quoted string' do
      expect(parse('"Helvetica Neue", Arial').count).to eq(2)
    end

    it 'should bind commas looser than whitespace' do
      expect(parse('bold 12px Arial, sans-serif').first).to be_a(described_class::List)
    end

    it 'should absolutize each element' do
      expect(parse('1em 2in').absolutize(font_size: 16).to_s).to eq('16px 192px')
    end

    it 'should keep an element it cannot resolve' do
      expect(parse('1em 50%').absolutize.to_s).to eq('1em 50%')
    end

    it 'should not equal the same elements under another separator' do
      expect(parse('Arial sans-serif')).not_to eq(parse('Arial, sans-serif'))
    end

    it 'should normalize the spacing of a comma list' do
      expect(parse('Arial,sans-serif').to_s).to eq('Arial, sans-serif')
    end

    it 'should be frozen' do
      expect(parse('0 auto')).to be_frozen
    end
  end

  describe 'an unparsed value' do
    it 'should offer no symbol form, unlike a keyword' do
      expect(parse('url(data:image/png;base64,AAAA)')).not_to respond_to(:to_sym)
    end

    it 'should not be equal to a keyword of the same text' do
      expect(parse('calc(1px + 2px)')).not_to eq(described_class::Keyword.new('calc(1px + 2px)'))
    end

    it 'should keep itself as specified when absolutized' do
      value = parse('calc(1px + 2px)')

      expect(value.absolutize).to be(value)
    end

    it 'should not be a numeric value' do
      expect(parse('calc(1px + 2px)')).not_to be_a(described_class::Numeric)
    end
  end

  describe '#to_str' do
    it 'should convert to its serialized form' do
      expect(parse('10px').to_str).to eq('10px')
    end

    it 'should let a value stand in for a string' do
      expect(format('width: %s', parse('10px'))).to eq('width: 10px')
    end

    it 'should compare equal to its string from the string side' do
      length = parse('10px')
      text = '10px'

      expect(text == length).to be(true)
    end

    it 'should compare equal to its string from the value side' do
      expect(parse('10px') == '10px').to be(true)
    end

    it 'should not compare equal to a different string' do
      expect(parse('10px') == '10em').to be(false)
    end

    it 'should not compare equal to a string for a value that normalizes' do
      expect(Croissant::Style::Value::Color.parse('#abc') == '#abc').to be(false)
    end

    it 'should compare equal to the string a normalizing value serializes to' do
      expect(Croissant::Style::Value::Color.parse('#abc') == '#aabbcc').to be(true)
    end

    it 'should not raise when a length meets a string that is not one' do
      expect(parse('10px') == 'auto').to be(false)
    end

    it 'should not raise when a colour meets a string that is not one' do
      expect(Croissant::Style::Value::Color.parse('#abc') == 'auto').to be(false)
    end

    it 'should not raise when a list meets a string that is not one' do
      expect(parse('1px solid red') == 'auto').to be(false)
    end

    it 'should not let a string match by hash the way it matches by ==' do
      length = parse('10px')

      expect([length, '10px'].uniq.size).to eq(2)
    end
  end

  describe '.parse on a subclass' do
    it 'should narrow a length to a length' do
      expect(Croissant::Style::Value::Length.parse('10px')).to be_a(Croissant::Style::Value::Length)
    end

    it 'should refuse a length when asked for a number' do
      expect(Croissant::Style::Value::Number.parse('10px')).to be_nil
    end

    it 'should refuse a length when asked for a percentage' do
      expect(Croissant::Style::Value::Percentage.parse('10px')).to be_nil
    end

    it 'should refuse a percentage when asked for a number' do
      expect(Croissant::Style::Value::Number.parse('50%')).to be_nil
    end

    it 'should still parse every member of the family from the head' do
      expect(Croissant::Style::Value::Numeric.parse('50%')).to be_a(Croissant::Style::Value::Percentage)
    end

    it 'should read a unitless zero as a length' do
      expect(Croissant::Style::Value::Length.parse('0')).to be_a(Croissant::Style::Value::Length)
    end

    it 'should give a unitless zero the pixel unit' do
      expect(Croissant::Style::Value::Length.parse('0').to_s).to eq('0px')
    end

    it 'should refuse any other unitless number as a length' do
      expect(Croissant::Style::Value::Length.parse('5')).to be_nil
    end

    it 'should still read a unitless zero as a number from the head' do
      expect(Croissant::Style::Value::Numeric.parse('0')).to be_a(Croissant::Style::Value::Number)
    end
  end

  describe 'a named colour' do
    def colour(input)
      Croissant::Style::Value::Color.parse(input)
    end

    it 'should parse a named colour' do
      expect(colour('red').to_s).to eq('#ff0000')
    end

    it 'should ignore the case of a name' do
      expect(colour('RebeccaPurple').to_s).to eq('#663399')
    end

    it 'should equal the same colour written as hex' do
      expect(colour('red')).to eq(colour('#ff0000'))
    end

    it 'should parse transparent as a fully transparent colour' do
      expect(colour('transparent').alpha).to eq(0.0)
    end

    it 'should not parse currentcolor, which needs an element to resolve' do
      expect(colour('currentcolor')).to be_nil
    end

    it 'should not parse an identifier that is not a colour' do
      expect(colour('notacolour')).to be_nil
    end
  end

  describe '#inspect' do
    it 'should show the class and the wrapped value' do
      expect(parse('auto').inspect).to eq('#<Croissant::Style::Value::Keyword :auto>')
    end

    it 'should show the text of an unparsed value' do
      expected = '#<Croissant::Style::Value::Unparsed "calc(1px + 2px)">'

      expect(parse('calc(1px + 2px)').inspect).to eq(expected)
    end

    it 'should show the unit of a length' do
      expected = '#<Croissant::Style::Value::Length 10.0 #<Croissant::Style::Unit::Pixel "px">>'

      expect(parse('10px').inspect).to eq(expected)
    end

    it 'should show the packed channels and the alpha of a colour' do
      expect(described_class::Color.parse('red').inspect).to eq('#<Croissant::Style::Value::Color 0xff0000 1.0>')
    end

    it 'should show the alpha of a translucent colour, which to_s alone would hide' do
      expect(described_class::Color.parse('rgba(0, 0, 0, 0.5)').inspect).to end_with('0x000000 0.5>')
    end

    it 'should tell a space list from a comma list' do
      expect(parse('1px solid red').inspect).to end_with(':space>')
    end

    it 'should show the separator of a comma list' do
      expect(parse('Arial, sans-serif').inspect).to end_with(':comma>')
    end

    it 'should not leak an object address through a nested value' do
      expect(parse('1px solid red').inspect).not_to match(/0x\h{8,}/)
    end

    it 'should not leak an object address from a colour' do
      expect(described_class::Color.parse('#fff').inspect).not_to match(/0x\h{8,}/)
    end
  end
end
