# frozen_string_literal: true

class Croissant::Selector::PseudoClass < Croissant::Selector
  def append_to(buffer)
    buffer << ':' << keyword
  end

  private

  def keyword
    raise NotImplementedError, "subclass must implement #{self.class}##{__method__}"
  end
end

require_relative 'pseudo_class/unknown'
require_relative 'pseudo_class/structural'
require_relative 'pseudo_class/functional'
