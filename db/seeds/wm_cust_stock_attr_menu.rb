# 고객재고속성관리 메뉴 및 권한 등록 (AdmMenu, AdmUserMenuPermission)

# 1. 상위 메뉴 (WM 폴더) 조회 (없으면 생성)
wms_menu = AdmMenu.find_by(menu_cd: "WM_GROUP") || AdmMenu.create!(
  menu_cd: "WM_GROUP",
  menu_nm: "보관(WM)",
  menu_type: "FOLDER", # GROUP 대신 FOLDER 사용
  use_yn: "Y"
)

# 2. 고객재고속성관리 메뉴 생성
cust_stock_attr_menu = AdmMenu.find_or_create_by!(menu_cd: "WM_CUST_STOCK_ATTR") do |m|
  m.menu_nm = "고객재고속성관리"
  m.menu_type = "MENU" # SCREEN 대신 MENU 사용
  m.parent_cd = wms_menu.menu_cd # parent_id 가 아니라 parent_cd
  m.menu_url = "/wm/cust_stock_attrs" # url이 아니라 menu_url
  m.use_yn = "Y"
end

# 기존 설정이 있으면 업데이트
cust_stock_attr_menu.update!(
  menu_nm: "고객재고속성관리",
  menu_type: "MENU",
  parent_cd: wms_menu.menu_cd,
  menu_url: "/wm/cust_stock_attrs",
  use_yn: "Y"
)

# 3. 시스템의 모든 활성 사용자에게 기본 메뉴 권한 부여
# (현 프로젝트 구조에선 RoleMenu 대신 AdmUserMenuPermission을 사용하는 것으로 보임)
User.where(work_status: "ACTIVE").each do |user|
  permission = AdmUserMenuPermission.find_or_initialize_by(user_id: user.id, menu_cd: cust_stock_attr_menu.menu_cd)
  permission.use_yn = "Y"
  permission.save!
end

puts "✅ 고객재고속성관리 메뉴 및 권한(AdmUserMenuPermission) 동기화 완료"
