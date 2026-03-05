wms_menu = AdmMenu.find_by(menu_cd: "WM_GROUP") || AdmMenu.create!(
  menu_cd: "WM_GROUP",
  menu_nm: "보관(WM)",
  menu_type: "FOLDER",
  menu_level: 1,
  sort_order: 100,
  use_yn: "Y"
)

stock_move_menu = AdmMenu.find_or_initialize_by(menu_cd: "WM_STOCK_MOVE")
stock_move_menu.menu_nm = "재고관리"
stock_move_menu.menu_type = "MENU"
stock_move_menu.parent_cd = wms_menu.menu_cd
stock_move_menu.menu_url = "/wm/stock_moves"
stock_move_menu.menu_icon = "package-search"
stock_move_menu.sort_order = 160
stock_move_menu.menu_level = wms_menu.menu_level + 1
stock_move_menu.use_yn = "Y"
stock_move_menu.save!

User.where(work_status: "ACTIVE").find_each do |user|
  permission = AdmUserMenuPermission.find_or_initialize_by(user_id: user.id, menu_cd: stock_move_menu.menu_cd)
  permission.use_yn = "Y"
  permission.save!
end
