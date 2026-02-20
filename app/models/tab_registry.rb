class TabRegistry
  Entry = Data.define(:id, :label, :icon, :url, :color_group)

  ENTRIES = [
    Entry.new(id: "overview", label: "대시보드", icon: "bar-chart-3", url: "/", color_group: :primary),
    Entry.new(id: "posts-list", label: "게시물 목록", icon: "clipboard-list", url: "/posts", color_group: :green),
    Entry.new(id: "posts-new", label: "게시물 작성", icon: "square-pen", url: "/posts/new", color_group: :cyan),
    Entry.new(id: "reports", label: "통계", icon: "line-chart", url: "/reports", color_group: :amber),
    Entry.new(id: "system-menus", label: "메뉴관리", icon: "settings", url: "/system/menus", color_group: :rose),
    Entry.new(id: "system-users", label: "사용자관리", icon: "user", url: "/system/users", color_group: :rose),
    Entry.new(id: "system-dept", label: "부서관리", icon: "building-2", url: "/system/dept", color_group: :rose),
    Entry.new(id: "system-menu-log", label: "메뉴로그", icon: "history", url: "/system/menu_logs", color_group: :rose),
    Entry.new(id: "system-excel-import-tasks", label: "엑셀업로드이력", icon: "file-text", url: "/system/excel_import_tasks", color_group: :rose),
    Entry.new(id: "system-login-history", label: "로그인이력", icon: "log-in", url: "/system/login_histories", color_group: :rose),
    Entry.new(id: "system-role-user", label: "역할별 사용자관리", icon: "users", url: "/system/roleUser", color_group: :rose),
    Entry.new(id: "system-user-menu-role", label: "사용자별 메뉴권한", icon: "shield-check", url: "/system/userMenuRole", color_group: :rose)
  ].freeze

  INDEX = ENTRIES.index_by(&:id).freeze

  class << self
    def find(tab_id)
      INDEX[tab_id]
    end

    def valid?(tab_id)
      INDEX.key?(tab_id)
    end

    def url_for(tab_id)
      INDEX[tab_id]&.url
    end

    def color_css(tab_id)
      entry = INDEX[tab_id]
      return "var(--text-muted)" unless entry

      {
        primary: "var(--accent)",
        green: "var(--accent-green)",
        cyan: "var(--accent-cyan)",
        amber: "var(--accent-amber)",
        rose: "var(--accent-rose)"
      }[entry.color_group] || "var(--text-muted)"
    end
  end
end
