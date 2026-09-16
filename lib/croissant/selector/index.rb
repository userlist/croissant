# frozen_string_literal: true

class Croissant::Selector::Index
  Entry = Struct.new(:selector, :payload, :order)
  private_constant :Entry

  attr_reader :size

  def initialize
    @by_tag = {}
    @by_class = {}
    @by_id = {}
    @universal = []
    @size = 0

    yield self if block_given?

    freeze
  end

  def add(selector, payload)
    bucket_for(selector.index_key) << Entry.new(selector, payload, @size)
    @size += 1

    self
  end

  def [](element)
    matches = []
    contributing = 0

    each_bucket(element) do |bucket|
      size = matches.size
      bucket.each { |entry| matches << entry if entry.selector.matches?(element) }
      contributing += 1 if matches.size > size
    end

    matches.sort! { |a, b| a.order <=> b.order } if contributing > 1 # rubocop:disable Performance/CompareWithBlock
    matches.map!(&:payload)
  end

  def empty?
    @size.zero?
  end

  def freeze
    @by_tag.each_value(&:freeze).freeze
    @by_class.each_value(&:freeze).freeze
    @by_id.each_value(&:freeze).freeze
    @universal.freeze

    super
  end

  private

  def bucket_for(key)
    case key
    when Croissant::Selector::Simple::Id then @by_id[key.name] ||= []
    when Croissant::Selector::Simple::ClassName then @by_class[key.name] ||= []
    when Croissant::Selector::Simple::Type then @by_tag[key.name] ||= []
    else @universal
    end
  end

  def each_bucket(element, &)
    yield @universal unless @universal.empty?

    if (name = element.name) && (bucket = @by_tag[name])
      yield bucket
    end

    each_class_bucket(element, &)

    if (id = element.id) && (bucket = @by_id[id])
      yield bucket
    end
  end

  def each_class_bucket(element)
    return if @by_class.empty?

    seen = nil

    element.classes.each do |name|
      bucket = @by_class[name]
      next if bucket.nil? || seen&.include?(bucket)

      (seen ||= []) << bucket
      yield bucket
    end
  end
end
