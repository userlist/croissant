# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Croissant::Style::Value do
  let(:generic) do
    base = Croissant::Style::Type::Numeric.new | Croissant::Style::Type::Keyword.new |
           Croissant::Style::Type::Color.new

    base | Croissant::Style::Type::List.new(base) | Croissant::Style::Type::Unparsed.new
  end

  def parse(input)
    generic.parse(input)
  end

  def colour(input)
    Croissant::Style::Type::Color.new.parse(input)
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

    it 'should take a remainder' do
      expect((parse('10px') % 3).to_s).to eq('1px')
    end

    it 'should take a remainder of a value of its own kind' do
      expect((parse('10') % parse('3')).to_s).to eq('1')
    end

    it 'should refuse a remainder of an incompatible value' do
      expect { parse('10px') % parse('50%') }.to raise_error(ArgumentError)
    end

    it 'should divide' do
      expect((parse('10px') / 4).to_s).to eq('2.5px')
    end

    it 'should round' do
      expect(parse('10.567px').round(1).to_s).to eq('10.6px')
    end
  end

  describe 'the number it holds' do
    it 'should keep a whole number whole' do
      expect(parse('10px').inspect).to start_with('#<Croissant::Style::Value::Length 10 ')
    end

    it 'should keep a fractional number as it was written' do
      expect(parse('1.5').inspect).to eq('#<Croissant::Style::Value::Number 1.5>')
    end

    it 'should read a whole number written with a decimal point as whole' do
      expect(parse('10.0px')).to eql(parse('10px'))
    end

    it 'should keep arithmetic on whole numbers exact' do
      expect((parse('10px') + parse('5px')).inspect).to start_with('#<Croissant::Style::Value::Length 15 ')
    end

    it 'should divide without falling into integer division' do
      expect((parse('10') / 4).to_s).to eq('2.5')
    end

    it 'should answer a whole count for a unit that resolves to one' do
      expect(parse('1in').absolutize.inspect).to start_with('#<Croissant::Style::Value::Length 96 ')
    end
  end

  describe '#<=>' do
    it 'should compare two values of the same kind' do
      expect(parse('10px') <=> parse('5px')).to eq(1)
    end

    it 'should compare with a plain number read as a value of its kind' do
      expect(parse('10px') <=> 5).to eq(1)
    end

    it 'should not compare lengths of different units' do
      expect(parse('10px') <=> parse('5em')).to be_nil
    end

    it 'should not compare a length with a percentage' do
      expect(parse('10px') <=> parse('50%')).to be_nil
    end

    it 'should be asked by a range covering the value' do
      expect((0..).cover?(parse('10px'))).to be(true)
    end

    it 'should be asked by a range the value falls outside' do
      expect((0..).cover?(parse('-10px'))).to be(false)
    end

    it 'should read the bounds of a range as values of its own kind' do
      expect((0..100).cover?(parse('50%'))).to be(true)
    end

    it 'should leave a range over another unit covering nothing' do
      expect((parse('0px')..parse('20px')).cover?(parse('10em'))).to be(false)
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

  describe 'a url' do
    def url(source)
      Croissant::Style::Value::Url.new(source)
    end

    it 'should answer the source it names' do
      expect(url('images/hero.png').source).to eq('images/hero.png')
    end

    it 'should serialize as the function around it' do
      expect(url('images/hero.png').to_s).to eq('url("images/hero.png")')
    end

    it 'should quote a source the unquoted form could not hold' do
      expect(url('hero image.png').to_s).to eq('url("hero image.png")')
    end

    it 'should escape a quote in the source' do
      expect(url('hero".png').to_s).to eq('url("hero\\".png")')
    end

    it 'should escape a backslash in the source' do
      expect(url('hero\\.png').to_s).to eq('url("hero\\\\.png")')
    end

    it 'should equal another url naming the same source' do
      first = url('a.png')
      second = url('a.png')

      expect(first).to eq(second)
    end

    it 'should keep itself as specified when absolutized' do
      value = url('a.png')

      expect(value.absolutize).to be(value)
    end

    it 'should be frozen' do
      expect(url('a.png')).to be_frozen
    end
  end

  describe '#to_html' do
    it 'should write a keyword as it is written in CSS' do
      expect(parse('auto').to_html).to eq('auto')
    end

    it 'should write a colour as it is written in CSS' do
      expect(colour('red').to_html).to eq('#ff0000')
    end

    it 'should write a percentage as it is written in CSS' do
      expect(parse('50%').to_html).to eq('50%')
    end

    it 'should write a length in pixels as a bare count' do
      expect(parse('120px').to_html).to eq('120')
    end

    it 'should resolve a length in another absolute unit' do
      expect(parse('1in').to_html).to eq('96')
    end

    it 'should round a count, which is all an attribute holds' do
      expect(parse('10.6px').to_html).to eq('11')
    end

    it 'should round a bare number too' do
      expect(parse('10.6').to_html).to eq('11')
    end

    it 'should not write a length that needs a font size to resolve' do
      expect(parse('3em').to_html).to be_nil
    end

    it 'should not write a length in a unit it does not model' do
      expect(parse('3ch').to_html).to be_nil
    end

    it 'should write a url as the source alone' do
      expect(Croissant::Style::Value::Url.new('images/hero.png').to_html).to eq('images/hero.png')
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
      expect(colour('#abc') == '#abc').to be(false)
    end

    it 'should compare equal to the string a normalizing value serializes to' do
      expect(colour('#abc') == '#aabbcc').to be(true)
    end

    it 'should not raise when a length meets a string that is not one' do
      expect(parse('10px') == 'auto').to be(false)
    end

    it 'should not raise when a colour meets a string that is not one' do
      expect(colour('#abc') == 'auto').to be(false)
    end

    it 'should not raise when a list meets a string that is not one' do
      expect(parse('1px solid red') == 'auto').to be(false)
    end

    it 'should not let a string match by hash the way it matches by ==' do
      length = parse('10px')

      expect([length, '10px'].uniq.size).to eq(2)
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
      expected = '#<Croissant::Style::Value::Length 10 #<Croissant::Style::Unit::Pixel "px">>'

      expect(parse('10px').inspect).to eq(expected)
    end

    it 'should show the packed channels and the alpha of a colour' do
      expect(colour('red').inspect).to eq('#<Croissant::Style::Value::Color 0xff0000 1.0>')
    end

    it 'should show the alpha of a translucent colour, which to_s alone would hide' do
      expect(colour('rgba(0, 0, 0, 0.5)').inspect).to end_with('0x000000 0.5>')
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
      expect(colour('#fff').inspect).not_to match(/0x\h{8,}/)
    end
  end
end
