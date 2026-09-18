# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Croissant::Transformation::PresentationalAttributes do
  def process(html, transformation = described_class.new)
    document = Croissant::Document.parse(html)
    transformations = [Croissant::Transformation::InlineStyles.new, transformation]
    Croissant::Transformation::Elements.new(transformations).call(document)
    document.xpath('.//style').each(&:remove)
    document.to_html.delete("\n")
  end

  it 'should match every element it converts a property for' do
    transformation = described_class.new

    expect(transformation.selectors.map(&:to_s)).to eq(transformation.attributes.keys)
  end

  describe 'a table of its own' do
    let(:table) do
      { 'section' => { 'text-align' => ['align', Croissant::Style::Type::Keyword.new(:center)] } }
    end
    let(:transformation) { described_class.new(table) }

    it 'should convert what that table names' do
      expect(process('<style>section { text-align: center }</style><section>a</section>', transformation))
        .to include('align="center"')
    end

    it 'should match the elements that table names' do
      expect(transformation.selectors.map(&:to_s)).to eq(['section'])
    end

    it 'should leave the elements the default table names alone' do
      html = process('<style>td { text-align: center }</style><table><tr><td>a</td></tr></table>', transformation)

      expect(html).not_to include('align="center"')
    end

    it 'should keep the table it was given' do
      expect(transformation.attributes).to be(table)
    end
  end

  describe 'the directive prefix' do
    let(:transformation) { described_class.new(directive: '-premailer-') }

    def convert(css)
      process("<style>#{css}</style><table><tr><td>a</td></tr></table>", transformation)
    end

    it 'should default to the name of this library' do
      expect(described_class.new.attributes['table'].keys).to include('-croissant-width')
    end

    it 'should name the properties of its table with the prefix it was given' do
      expect(transformation.attributes['table'].keys).to include('-premailer-width')
    end

    it 'should leave the default prefix out of that table' do
      expect(transformation.attributes['table'].keys).not_to include('-croissant-width')
    end

    it 'should read a directive written under the prefix it was given' do
      expect(convert('td { -premailer-width: 120px }')).to include('width="120"')
    end

    it 'should consume it, the way it consumes its own' do
      expect(convert('td { -premailer-width: 120px }')).not_to include('-premailer-width')
    end

    it 'should leave a directive under another prefix to the style attribute' do
      expect(convert('td { -croissant-width: 120px }')).to include('-croissant-width:120px')
    end

    it 'should write no attribute for a directive under another prefix' do
      expect(convert('td { -croissant-width: 120px }')).not_to include('width="120"')
    end

    it 'should still convert the properties that are CSS rather than directives' do
      expect(convert('td { text-align: center }')).to include('align="center"')
    end
  end

  it 'should leave elements without a mapped property alone' do
    expect(process('<style>span { text-align: center }</style><span>a</span>'))
      .to eq('<span style="text-align:center">a</span>')
  end

  it 'should leave properties that map on another element alone' do
    expect(process('<style>p { background-color: red }</style><p>a</p>'))
      .to eq('<p style="background-color:red">a</p>')
  end

  describe 'align' do
    it 'should convert text-align on the block elements that carry it' do
      %w[h1 h2 h3 h4 h5 h6 p div blockquote].each do |name|
        html = process("<style>#{name} { text-align: right }</style><#{name}>a</#{name}>")

        expect(html).to eq(%(<#{name} style="text-align:right" align="right">a</#{name}>))
      end
    end

    it 'should convert the alignment keywords the attribute knows' do
      %w[left center right justify].each do |value|
        expect(process("<style>p { text-align: #{value} }</style><p>a</p>"))
          .to eq(%(<p style="text-align:#{value}" align="#{value}">a</p>))
      end
    end

    it 'should not convert an alignment keyword the attribute has no spelling for' do
      expect(process('<style>p { text-align: start }</style><p>a</p>'))
        .to eq('<p style="text-align:start">a</p>')
    end

    it 'should not convert text-align on a table, where the attribute means something else' do
      expect(process('<style>table { text-align: center }</style><table><tr><td>a</td></tr></table>'))
        .to eq('<table style="text-align:center"><tr><td>a</td></tr></table>')
    end

    it 'should convert the table alignment directive' do
      expect(process('<style>table { -croissant-align: center }</style><table><tr><td>a</td></tr></table>'))
        .to eq('<table align="center"><tr><td>a</td></tr></table>')
    end

    it 'should convert float on an image' do
      expect(process('<style>img { float: left }</style><img src="a.png">'))
        .to eq('<img src="a.png" style="float:left" align="left">')
    end

    it 'should not convert a float keyword the attribute has no spelling for' do
      expect(process('<style>img { float: none }</style><img src="a.png">'))
        .to eq('<img src="a.png" style="float:none">')
    end
  end

  describe 'bgcolor' do
    it 'should convert background-color on the elements that carry it' do
      %w[tr th td].each do |name|
        html = process("<style>#{name} { background-color: red }</style><table><tr><#{name}>a</#{name}></tr></table>")

        expect(html).to include(%(<#{name} style="background-color:red" bgcolor="#ff0000">))
      end
    end

    it 'should convert background-color on the body' do
      html = process('<html><head><style>body { background-color: #abc }</style></head><body>a</body></html>')

      expect(html).to include('<body style="background-color:#abc" bgcolor="#aabbcc">')
    end

    it 'should convert a functional colour to hex' do
      expect(process('<style>td { background-color: rgb(0, 128, 255) }</style><table><tr><td>a</td></tr></table>'))
        .to include('bgcolor="#0080ff"')
    end

    it 'should not convert a translucent colour, which the attribute cannot express' do
      html = process('<style>td { background-color: rgba(0, 0, 0, 0.5) }</style><table><tr><td>a</td></tr></table>')

      expect(html).not_to include('bgcolor')
    end

    it 'should not convert a keyword that is not a colour' do
      html = process('<style>td { background-color: currentcolor }</style><table><tr><td>a</td></tr></table>')

      expect(html).not_to include('bgcolor')
    end
  end

  describe 'valign' do
    it 'should convert vertical-align on a cell' do
      expect(process('<style>td { vertical-align: top }</style><table><tr><td>a</td></tr></table>'))
        .to include('<td style="vertical-align:top" valign="top">')
    end

    it 'should not convert an alignment keyword the attribute has no spelling for' do
      html = process('<style>td { vertical-align: text-bottom }</style><table><tr><td>a</td></tr></table>')

      expect(html).not_to include('valign')
    end

    it 'should not convert a length, which the attribute cannot express' do
      html = process('<style>td { vertical-align: 2px }</style><table><tr><td>a</td></tr></table>')

      expect(html).not_to include('valign')
    end
  end

  describe 'background' do
    it 'should convert background-image on a table' do
      html = process('<style>table { background-image: url(hero.png) }</style><table><tr><td>a</td></tr></table>')

      expect(html).to include('background="hero.png"')
    end

    it 'should unwrap a quoted url' do
      html = process(%(<style>table { background-image: url("a b.png") }</style><table><tr><td>a</td></tr></table>))

      expect(html).to include('background="a b.png"')
    end

    it 'should not convert a keyword' do
      html = process('<style>table { background-image: none }</style><table><tr><td>a</td></tr></table>')

      expect(html).not_to include('background=')
    end

    it 'should not convert several layers, which the attribute cannot express' do
      css = 'table { background-image: url(a.png), url(b.png) }'
      html = process("<style>#{css}</style><table><tr><td>a</td></tr></table>")

      expect(html).not_to include('background=')
    end
  end

  describe 'width and height' do
    it 'should convert the size directives on the elements that carry them' do
      %w[table th td img].each do |name|
        css = "#{name} { -croissant-width: 120; -croissant-height: 60 }"
        html = process("<style>#{css}</style><table><tr><th>a</th><td>b</td></tr></table><img src=\"a.png\">")

        expect(html).to include('width="120"', 'height="60"')
      end
    end

    it 'should convert the height directive on a row' do
      expect(process('<style>tr { -croissant-height: 60 }</style><table><tr><td>a</td></tr></table>'))
        .to include('<tr height="60">')
    end

    it 'should drop the pixel unit the attribute cannot carry' do
      expect(process('<style>td { -croissant-width: 120px }</style><table><tr><td>a</td></tr></table>'))
        .to include('width="120"')
    end

    it 'should convert an absolute unit to pixels' do
      expect(process('<style>td { -croissant-width: 1in }</style><table><tr><td>a</td></tr></table>'))
        .to include('width="96"')
    end

    it 'should keep a percentage, which the attribute can carry' do
      expect(process('<style>table { -croissant-width: 50% }</style><table><tr><td>a</td></tr></table>'))
        .to include('width="50%"')
    end

    it 'should not convert a unit that needs a font size to resolve' do
      html = process('<style>td { -croissant-width: 3em }</style><table><tr><td>a</td></tr></table>')

      expect(html).not_to include('width')
    end

    it 'should not convert a negative length' do
      html = process('<style>td { -croissant-width: -10px }</style><table><tr><td>a</td></tr></table>')

      expect(html).not_to include('width')
    end

    it 'should not convert the width property, which stays a declaration' do
      expect(process('<style>td { width: 120px }</style><table><tr><td>a</td></tr></table>'))
        .to include('<td style="width:120px">')
    end
  end

  describe 'cellpadding and cellspacing' do
    it 'should convert the table spacing directives' do
      css = 'table { -croissant-cellpadding: 4; -croissant-cellspacing: 0 }'

      expect(process("<style>#{css}</style><table><tr><td>a</td></tr></table>"))
        .to include('<table cellpadding="4" cellspacing="0">')
    end

    it 'should not convert a percentage, which the attributes cannot express' do
      html = process('<style>table { -croissant-cellpadding: 50% }</style><table><tr><td>a</td></tr></table>')

      expect(html).not_to include('cellpadding')
    end
  end

  describe 'the declaration behind an attribute' do
    it 'should keep a property that is also valid CSS' do
      expect(process('<style>td { text-align: center }</style><table><tr><td>a</td></tr></table>'))
        .to include('<td style="text-align:center" align="center">')
    end

    it 'should consume a directive, which is not CSS' do
      expect(process('<style>td { -croissant-width: 120 }</style><table><tr><td>a</td></tr></table>'))
        .to include('<td width="120">')
    end

    it 'should consume a directive the attribute has no spelling for' do
      expect(process('<style>td { -croissant-width: 3em }</style><table><tr><td>a</td></tr></table>'))
        .to include('<td>a</td>')
    end

    it 'should leave the other declarations in place' do
      css = 'td { color: red; -croissant-width: 120 }'

      expect(process("<style>#{css}</style><table><tr><td>a</td></tr></table>"))
        .to include('<td style="color:red" width="120">')
    end

    it 'should ignore a directive on an element that has no attribute for it' do
      expect(process('<style>p { -croissant-width: 120 }</style><p>a</p>'))
        .to eq('<p style="-croissant-width:120">a</p>')
    end
  end

  describe 'an attribute the document already carries' do
    it 'should be left alone' do
      expect(process('<style>td { text-align: center }</style><table><tr><td align="left">a</td></tr></table>'))
        .to include('<td align="left" style="text-align:center">')
    end

    it 'should still consume the directive that would have written it' do
      expect(process('<style>td { -croissant-width: 120 }</style><table><tr><td width="80">a</td></tr></table>'))
        .to include('<td width="80">')
    end
  end

  describe 'the cascade' do
    it 'should convert the value that wins' do
      css = 'td { text-align: left } .a { text-align: right }'

      expect(process("<style>#{css}</style><table><tr><td class=\"a\">a</td></tr></table>"))
        .to include('align="right"')
    end

    it 'should convert a value from the style attribute' do
      expect(process('<table><tr><td style="text-align: center">a</td></tr></table>'))
        .to include('align="center"')
    end

    it 'should ignore the !important marker the attribute cannot carry' do
      expect(process('<style>td { text-align: center !important }</style><table><tr><td>a</td></tr></table>'))
        .to include('<td style="text-align:center !important" align="center">')
    end
  end
end
