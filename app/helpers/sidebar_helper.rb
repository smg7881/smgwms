module SidebarHelper
  def sidebar_menu_button(label, tab_id:, icon:, url:, badge: nil)
    is_active = (session[:active_tab] == tab_id)

    content_tag(:button,
      type: "button",
      class: "nav-item #{"active" if is_active}".strip,
      data: {
        action:   "click->tabs#openTab",
        role:     "sidebar-menu-item",
        "tab-id": tab_id,
        label:    label,
        url:      url
      }
    ) do
      parts = []
      parts << content_tag(:span, icon, class: "icon")
      parts << " #{label} "
      if badge
        parts << content_tag(:span, badge, class: "badge")
      end
      safe_join(parts)
    end
  end
end
