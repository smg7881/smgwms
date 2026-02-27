menus = [
  { menu_cd: "MAIN", menu_nm: "메인", parent_cd: nil, menu_url: nil, menu_icon: "layout-dashboard", sort_order: 1, menu_level: 1, menu_type: "FOLDER", tab_id: nil },
  { menu_cd: "OVERVIEW", menu_nm: "대시보드", parent_cd: "MAIN", menu_url: "/", menu_icon: "bar-chart-3", sort_order: 1, menu_level: 2, menu_type: "MENU", tab_id: "overview" },

  { menu_cd: "POST", menu_nm: "게시판", parent_cd: nil, menu_url: nil, menu_icon: "clipboard-list", sort_order: 2, menu_level: 1, menu_type: "FOLDER", tab_id: nil },
  { menu_cd: "POST_LIST", menu_nm: "게시판목록", parent_cd: "POST", menu_url: "/posts", menu_icon: "clipboard-list", sort_order: 1, menu_level: 2, menu_type: "MENU", tab_id: "posts-list" },
  { menu_cd: "POST_NEW", menu_nm: "게시판생성", parent_cd: "POST", menu_url: "/posts/new", menu_icon: "square-pen", sort_order: 2, menu_level: 2, menu_type: "MENU", tab_id: "posts-new" },

  { menu_cd: "ANALYSIS", menu_nm: "분석", parent_cd: nil, menu_url: nil, menu_icon: "line-chart", sort_order: 3, menu_level: 1, menu_type: "FOLDER", tab_id: nil },
  { menu_cd: "REPORTS", menu_nm: "통계", parent_cd: "ANALYSIS", menu_url: "/reports", menu_icon: "line-chart", sort_order: 1, menu_level: 2, menu_type: "MENU", tab_id: "reports" },

  { menu_cd: "SYSTEM", menu_nm: "시스템", parent_cd: nil, menu_url: nil, menu_icon: "settings", sort_order: 4, menu_level: 1, menu_type: "FOLDER", tab_id: nil },
  { menu_cd: "SYS_MENU", menu_nm: "메뉴관리", parent_cd: "SYSTEM", menu_url: "/system/menus", menu_icon: "settings", sort_order: 1, menu_level: 2, menu_type: "MENU", tab_id: "system-menus" },
  { menu_cd: "SYS_DEPT", menu_nm: "부서관리", parent_cd: "SYSTEM", menu_url: "/system/dept", menu_icon: "building-2", sort_order: 2, menu_level: 2, menu_type: "MENU", tab_id: "system-dept" },
  { menu_cd: "SYS_USER", menu_nm: "사용자관리", parent_cd: "SYSTEM", menu_url: "/system/users", menu_icon: "user", sort_order: 3, menu_level: 2, menu_type: "MENU", tab_id: "system-users" },
  { menu_cd: "SYS_CODE", menu_nm: "공통코드관리", parent_cd: "SYSTEM", menu_url: "/system/code", menu_icon: "binary", sort_order: 4, menu_level: 2, menu_type: "MENU", tab_id: "system-code" },
  { menu_cd: "SYS_NOTICE", menu_nm: "공지사항", parent_cd: "SYSTEM", menu_url: "/system/notice", menu_icon: "bell", sort_order: 5, menu_level: 2, menu_type: "MENU", tab_id: "system-notice" }
]

menus.each do |attrs|
  record = AdmMenu.find_or_initialize_by(menu_cd: attrs[:menu_cd])
  record.assign_attributes(attrs.merge(use_yn: "Y"))
  record.save!
end