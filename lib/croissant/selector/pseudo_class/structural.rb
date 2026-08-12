# frozen_string_literal: true

class Croissant::Selector::PseudoClass::Structural < Croissant::Selector::PseudoClass
  def inlinable?
    true
  end

  def specificity
    Croissant::Selector::Specificity.class_name
  end
end

require_relative 'structural/first_child'
require_relative 'structural/first_of_type'
require_relative 'structural/last_child'
require_relative 'structural/last_of_type'
require_relative 'structural/only_child'
require_relative 'structural/only_of_type'
require_relative 'structural/nth_child'
require_relative 'structural/nth_of_type'
require_relative 'structural/nth_last_child'
require_relative 'structural/nth_last_of_type'
require_relative 'structural/empty'
require_relative 'structural/root'
