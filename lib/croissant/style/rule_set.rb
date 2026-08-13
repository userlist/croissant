# frozen_string_literal: true

class Croissant::Style::RuleSet
  Entry = Struct.new(:rule, :order)
  private_constant :Entry

  def initialize(rules)
    @by_tag = {}
    @by_class = {}
    @by_id = {}
    @universal = []

    rules.each_with_index { |rule, index| append(rule, index) }

    freeze
  end

  def [](element)
    candidates(element)
      .select { |e| e.rule.selector.matches?(element) }
      .sort_by(&:order)
      .map(&:rule)
  end

  def freeze
    @by_tag.freeze
    @by_class.freeze
    @by_id.freeze
    @universal.freeze

    super
  end

  private

  def append(rule, index)
    return unless (selector = rule.selector)

    entry = Entry.new(rule, index)
    key = selector.index_key

    bucket_for(key) << entry
  end

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
    candidates.concat(candidates_by_tag(element)) if element.name
    candidates.concat(candidates_by_classes(element)) unless element.classes.empty?
    candidates.concat(candidates_by_ids(element)) if element['id']
    candidates
  end

  def candidates_by_tag(element)
    @by_tag.fetch(element.name, [])
  end

  def candidates_by_classes(element)
    element.classes.uniq.flat_map { |c| @by_class.fetch(c, []) }
  end

  def candidates_by_ids(element)
    @by_id.fetch(element['id'], [])
  end
end
