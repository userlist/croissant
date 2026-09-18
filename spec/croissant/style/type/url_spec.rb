# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Croissant::Style::Type::Url do
  def parse(input)
    described_class.new.parse(input)
  end

  describe '#parse' do
    it 'should read an unquoted source' do
      expect(parse('url(images/hero.png)').source).to eq('images/hero.png')
    end

    it 'should read a double-quoted source' do
      expect(parse('url("images/hero.png")').source).to eq('images/hero.png')
    end

    it 'should read a single-quoted source' do
      expect(parse("url('images/hero.png')").source).to eq('images/hero.png')
    end

    it 'should ignore the space inside the brackets' do
      expect(parse('url(  images/hero.png  )').source).to eq('images/hero.png')
    end

    it 'should ignore the case of the function' do
      expect(parse('URL(a.png)')).to be_a(Croissant::Style::Value::Url)
    end

    it 'should keep the space inside a quoted source' do
      expect(parse('url("hero image.png")').source).to eq('hero image.png')
    end

    it 'should read a data uri, commas and all' do
      expect(parse('url(data:image/png;base64,AAAA)').source).to eq('data:image/png;base64,AAAA')
    end

    it 'should not read a url naming nothing' do
      expect(parse('url()')).to be_nil
    end

    it 'should not read something that is not a url' do
      expect(parse('none')).to be_nil
    end

    it 'should not read a url with something after it' do
      expect(parse('url(a.png) no-repeat')).to be_nil
    end

    it 'should take a matcher like any other type' do
      type = described_class.new(->(url) { url.source.end_with?('.png') })

      expect(type.parse('url(hero.gif)')).to be_nil
    end
  end

  describe 'the value it reads' do
    it 'should serialize back to a url' do
      expect(parse('url(images/hero.png)').to_s).to eq('url("images/hero.png")')
    end

    it 'should write the source alone as an attribute' do
      expect(parse('url(images/hero.png)').to_html).to eq('images/hero.png')
    end

    it 'should drop the quotes with the function' do
      expect(parse('url("images/hero.png")').to_html).to eq('images/hero.png')
    end
  end
end
