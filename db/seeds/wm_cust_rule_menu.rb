# 고객 RULE 관리 메뉴 및 권한 등록 (AdmMenu, AdmUserMenuPermission)

wms_menu = AdmMenu.find_by(menu_cd: "WM_GROUP") || AdmMenu.create!(
  menu_cd: "WM_GROUP",
  menu_nm: "보관(WM)",
  menu_type: "FOLDER",
  use_yn: "Y"
)

cust_rule_menu = AdmMenu.find_or_create_by!(menu_cd: "WM_CUST_RULE") do |m|
  m.menu_nm = "고객 RULE 관리"
  m.menu_type = "MENU"
  m.parent_cd = wms_menu.menu_cd
  m.menu_url = "/wm/cust_rules"
  m.use_yn = "Y"
  m.sort_order = 99
end

cust_rule_menu.update!(
  menu_nm: "고객 RULE 관리",
  menu_type: "MENU",
  parent_cd: wms_menu.menu_cd,
  menu_url: "/wm/cust_rules",
  use_yn: "Y"
)

User.where(work_status: "ACTIVE").each do |user|
  permission = AdmUserMenuPermission.find_or_initialize_by(user_id: user.id, menu_cd: cust_rule_menu.menu_cd)
  permission.use_yn = "Y"
  permission.save!
end

puts "✅ 고객 RULE 관리 메뉴 및 권한 등록 완료"
