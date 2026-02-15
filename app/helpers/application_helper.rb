module ApplicationHelper
  LUCIDE_ICON_ALIASES = {
    "📁" => "folder",
    "📄" => "file",
    "📊" => "bar-chart-3",
    "📋" => "clipboard-list",
    "✏️" => "square-pen",
    "📈" => "line-chart",
    "⚙️" => "settings",
    "👤" => "user",
    "🏢" => "building-2",
    "🔍" => "search",
    "🔔" => "bell",
    "🚪" => "log-out",
    "📝" => "notebook-pen"
  }.freeze

  def normalize_lucide_icon(icon_name, fallback: "circle")
    candidate = icon_name.to_s.strip
    return fallback if candidate.blank?

    (LUCIDE_ICON_ALIASES[candidate] || candidate).tr("_", "-")
  end

  def lucide_icon(icon_name, css_class: nil, fallback: "circle")
    content_tag(
      :i,
      nil,
      class: [ "lucide-icon", css_class ].compact.join(" "),
      data: { lucide: normalize_lucide_icon(icon_name, fallback: fallback) },
      "aria-hidden": "true"
    )
  end
end
