# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Croissant::Document::Node do
  def build(html, xpath)
    document = Croissant::Document.parse(html)

    [document, document.at_xpath(xpath)]
  end

  def node_for(html, xpath)
    build(html, xpath).last
  end

  describe '#document' do
    it 'should return the document' do
      document, node = build('<p></p>', './/p')

      expect(node.document).to be(document)
    end
  end

  describe '#name' do
    it 'should return the tag name' do
      expect(node_for('<p></p>', './/p').name).to eq('p')
    end
  end

  describe '#element?' do
    it 'should be true for an element' do
      expect(node_for('<p></p>', './/p')).to be_element
    end

    it 'should be false for a text node' do
      expect(node_for('<p>hi</p>', './/p').children.first).not_to be_element
    end
  end

  describe '#text?' do
    it 'should be true for a text node' do
      expect(node_for('<p>hi</p>', './/p').children.first).to be_text
    end
  end

  describe '#content' do
    it 'should return the text of a text node' do
      expect(node_for('<p>hi</p>', './/p').children.first.content).to eq('hi')
    end
  end

  describe '#parent' do
    it 'should return the view the document holds for the parent' do
      document, node = build('<div><p></p></div>', './/p')

      expect(node.parent).to be(document.at_xpath('.//div'))
    end

    it 'should be nil at the top of the tree' do
      expect(node_for('<p></p>', './/p').parent).to be_nil
    end

    it 'should return the same parent on every call' do
      node = node_for('<div><p></p></div>', './/p')
      parent = node.parent

      expect(node.parent).to be(parent)
    end
  end

  describe '#previous_element' do
    it 'should return the view the document holds for the previous element' do
      document, node = build('<b></b><p></p>', './/p')

      expect(node.previous_element).to be(document.at_xpath('.//b'))
    end

    it 'should be nil for the first element' do
      expect(node_for('<p></p>', './/p').previous_element).to be_nil
    end
  end

  describe '#next_element' do
    it 'should return the view the document holds for the next element' do
      document, node = build('<p></p><b></b>', './/p')

      expect(node.next_element).to be(document.at_xpath('.//b'))
    end
  end

  describe '#element_children' do
    it 'should return the child elements as elements' do
      children = node_for('<div>text<p></p><b></b></div>', './/div').element_children

      expect(children).to all(be_a(Croissant::Document::Element))
    end

    it 'should skip text children' do
      children = node_for('<div>text<p></p><b></b></div>', './/div').element_children

      expect(children.map(&:name)).to eq(%w[p b])
    end
  end

  describe '#children' do
    it 'should view text children as plain nodes' do
      children = node_for('<div>text<p></p></div>', './/div').children

      expect(children.map(&:class)).to eq([described_class, Croissant::Document::Element])
    end
  end
end
