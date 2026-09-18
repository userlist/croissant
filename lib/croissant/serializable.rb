# frozen_string_literal: true

# Serialising a tree allocates a string per node when every #to_s builds its own and the parent
# joins them. Classes answer #append_to instead, writing into the single buffer the root owns,
# and get #to_s from here, the way Comparable builds its operators on top of #<=>.
module Croissant::Serializable
  def to_s
    append_to(+'')
  end

  private

  def append_each(buffer, items, separator)
    rest = false

    items.each do |item|
      buffer << separator if rest
      rest = true

      append_item(buffer, item)
    end

    buffer
  end

  # Items are not necessarily serialisable themselves, so fall back to their own string.
  def append_item(buffer, item)
    item.is_a?(Croissant::Serializable) ? item.append_to(buffer) : buffer << item.to_s
  end
end
