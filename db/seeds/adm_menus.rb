menus = [
  { menu_cd: "MAIN", menu_nm: "메인", parent_cd: nil, menu_url: nil, menu_icon: nil, sort_order: 1, menu_level: 1, menu_type: "FOLDER", tab_id: nil },
  { menu_cd: "OVERVIEW", menu_nm: "개요", parent_cd: "MAIN", menu_url: "/", menu_icon: "📊", sort_order: 1, menu_level: 2, menu_type: "MENU", tab_id: "overview" },
  { menu_cd: "POST", menu_nm: "게시물", parent_cd: nil, menu_url: nil, menu_icon: "📝", sort_order: 2, menu_level: 1, menu_type: "FOLDER", tab_id: nil },
  { menu_cd: "POST_LIST", menu_nm: "게시물 목록", parent_cd: "POST", menu_url: "/posts", menu_icon: "📋", sort_order: 1, menu_level: 2, menu_type: "MENU", tab_id: "posts-list" },
  { menu_cd: "POST_NEW", menu_nm: "게시물 작성", parent_cd: "POST", menu_url: "/posts/new", menu_icon: "✏️", sort_order: 2, menu_level: 2, menu_type: "MENU", tab_id: "posts-new" },
  { menu_cd: "ANALYSIS", menu_nm: "분석", parent_cd: nil, menu_url: nil, menu_icon: nil, sort_order: 3, menu_level: 1, menu_type: "FOLDER", tab_id: nil },
  { menu_cd: "REPORTS", menu_nm: "통계", parent_cd: "ANALYSIS", menu_url: "/reports", menu_icon: "📈", sort_order: 1, menu_level: 2, menu_type: "MENU", tab_id: "reports" },
  { menu_cd: "SYSTEM", menu_nm: "시스템", parent_cd: nil, menu_url: nil, menu_icon: nil, sort_order: 4, menu_level: 1, menu_type: "FOLDER", tab_id: nil },
  { menu_cd: "SYS_MENU", menu_nm: "메뉴관리", parent_cd: "SYSTEM", menu_url: "/system/menus", menu_icon: "⚙️", sort_order: 1, menu_level: 2, menu_type: "MENU", tab_id: "system-menus" }
]

menus << { menu_cd: "SYS_DEPT", menu_nm: "부서관리", parent_cd: "SYSTEM", menu_url: "/system/dept", menu_icon: "🏢", sort_order: 2, menu_level: 2, menu_type: "MENU", tab_id: "system-dept" }

menus.each do |attrs|
  record = AdmMenu.find_or_initialize_by(menu_cd: attrs[:menu_cd])
  record.assign_attributes(attrs.merge(use_yn: "Y"))
  record.save!
end
