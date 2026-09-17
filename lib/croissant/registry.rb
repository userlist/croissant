# frozen_string_literal: true

class Croissant::Registry
  include Enumerable

  def initialize(values = [], fallback: nil, normalize: nil, &)
    @registry = {}
    @fallback = fallback
    @normalize = normalize

    register(*values)

    yield(self) if block_given?
  end

  def fallback(&block)
    @fallback = block
  end

  def normalize(&block)
    @normalize = block
  end

  def register(*values)
    values.each do |value|
      next unless name = normalize_name(value.name)

      @registry[name] = value
    end

    self
  end

  def lookup(name)
    name = normalize_name(name)

    @registry.fetch(name) { @fallback&.call(name) }
  end
  alias [] lookup

  def each(&)
    return enum_for(__method__) unless block_given?

    @registry.each_value(&)

    self
  end

  def clear
    @registry.clear

    self
  end

  private

  def normalize_name(name)
    return name unless @normalize

    @normalize.call(name)
  end
end
