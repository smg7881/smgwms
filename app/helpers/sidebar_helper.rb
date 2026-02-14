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

  def sidebar_menu_button_from_record(menu, default_icon: "📄")
    icon = menu.menu_icon.presence || default_icon
    if menu.tab_id.present?
      sidebar_menu_button(menu.menu_nm, tab_id: menu.tab_id, icon: icon, url: menu.menu_url)
    elsif menu.menu_url.present?
      content_tag(:a,
        href: menu.menu_url,
        class: "nav-item",
        data: { turbo_frame: "main-content" }
      ) do
        safe_join([ content_tag(:span, icon, class: "icon"), " #{menu.menu_nm} " ])
      end
    end
  end

  def dynamic_sidebar_available?
    defined?(AdmMenu) && AdmMenu.table_exists? && AdmMenu.active.exists?
  rescue ActiveRecord::NoDatabaseError, ActiveRecord::StatementInvalid
    false
  end

  def render_sidebar_folder_tree(folder, grouped)
    children = grouped[folder.menu_cd] || []

    button = content_tag(:button,
      type: "button",
      class: "nav-item has-children",
      data: { action: "click->sidebar#toggleTree" }
    ) do
      safe_join([
        content_tag(:span, folder.menu_icon.presence || "📁", class: "icon"),
        " #{folder.menu_nm}",
        content_tag(:span, "▶", class: "chevron")
      ])
    end

    body = content_tag(:div, class: "nav-tree-children") do
      safe_join(children.filter_map do |child|
        if child.menu_type == "FOLDER"
          render_sidebar_folder_tree(child, grouped)
        else
          sidebar_menu_button_from_record(child)
        end
      end)
    end

    button + body
  end
end
