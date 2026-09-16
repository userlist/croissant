# frozen_string_literal: true

class Croissant::Transformation::RemoveStyles < Croissant::Transformation
  def call(document)
    document.xpath('.//style').each(&:remove)
  end
end
