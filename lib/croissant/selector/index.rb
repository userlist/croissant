# frozen_string_literal: true

# Indexes payloads by the id, class, or tag of their selector's rightmost
# compound so that looking up an element only tests the selectors it could
# plausibly match. Payloads come back in registration order.
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
    matches = candidates(element).select { |entry| entry.selector.matches?(element) }
    matches.sort_by!(&:order)
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

  def candidates(element)
    candidates = @universal.dup
    candidates.concat(@by_tag.fetch(element.name, [])) if element.name
    candidates.concat(candidates_by_classes(element)) unless @by_class.empty?
    candidates.concat(@by_id.fetch(element['id'], [])) if element['id']
    candidates
  end

  def candidates_by_classes(element)
    classes = element.classes
    return [] if classes.empty?

    classes.uniq.flat_map { |name| @by_class.fetch(name, []) }
  end
end
