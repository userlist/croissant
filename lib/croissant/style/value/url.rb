# frozen_string_literal: true

class Croissant::Style::Value::Url < Croissant::Style::Value
  ESCAPED = /["\\]/

  def initialize(source)
    super(source.to_s)
  end

  def source
    value
  end

  def to_s
    %(url("#{value.gsub(ESCAPED) { |character| "\\#{character}" }}"))
  end

  def to_html
    source
  end
end
