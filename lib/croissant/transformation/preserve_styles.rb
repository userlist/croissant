# frozen_string_literal: true

class Croissant::Transformation::PreserveStyles < Croissant::Transformation
  def call(document)
    rules = document.stylesheets.flat_map { |stylesheet| stylesheet.rules.reject(&:inlinable?) }

    document.xpath('.//style').each(&:remove)
    return if rules.empty?

    style = build_style(document, rules)

    if document.fragment?
      prepend(document, style)
    else
      document.head.add_child(style)
    end
  end

  private

  def build_style(document, rules)
    style = document.create_node('style')
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
