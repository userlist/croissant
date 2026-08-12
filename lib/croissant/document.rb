# frozen_string_literal: true

require 'nokogiri'

class Croissant::Document
  DOCUMENT_PATTERN = /<!doctype\s|<html[\s>]/i

  def self.parse(html)
    if html.match?(DOCUMENT_PATTERN)
      new(Nokogiri::HTML::Document.parse(html))
    else
      new(Nokogiri::HTML::DocumentFragment.parse(html))
    end
  end

  attr_reader :document

  def initialize(document)
    @document = document
  end

  def stylesheets
    document
      .xpath('.//style')
      .map { |element| parser.parse(element.content) }
  end

  private

  def parser
    @parser ||= Croissant::Stylesheet::Parser.new
  end
end
