# frozen_string_literal: true

# Removes all <style> elements from the document. Use it instead of
# PreserveStyles to drop non-inlinable rules along with the rest.
class Croissant::Transformation::RemoveStyles < Croissant::Transformation
  def call(document)
    document.document.xpath('.//style').each(&:remove)
  end
end
