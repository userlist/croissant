# frozen_string_literal: true

# Replaces the document's <style> elements with a single one holding
# everything that cannot be inlined: at-rules such as @media, @font-face, and
# @keyframes, plus rules with pseudo-elements or dynamic pseudo-classes such as
# :hover. It goes at the end of the <head> for a full document, at the top for
# a fragment. Without such rules the <style> elements are simply removed.
class Croissant::Transformation::PreserveStyles < Croissant::Transformation
  def call(document)
    rules = document.stylesheets.flat_map { |stylesheet| stylesheet.rules.reject(&:inlinable?) }

    document.document.xpath('.//style').each(&:remove)
    return if rules.empty?

    style = build_style(document, rules)

    if document.fragment?
      prepend(document.document, style)
    else
      document.head.add_child(style)
    end
  end

  private

  def build_style(document, rules)
    style = Nokogiri::XML::Node.new('style', document.document.document)
    style.content = rules.join("\n")
    style
  end

  def prepend(parent, node)
    if (first = parent.children.first)
      first.add_previous_sibling(node)
    else
      parent.add_child(node)
    end
  end
end
