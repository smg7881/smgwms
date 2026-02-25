puts "Seeding WM GrPrar (입고관리) Menu..."

# WM 그룹 메뉴 확인
wms_menu = AdmMenu.find_by(menu_cd: "WM_GROUP")
raise "WM_GROUP 메뉴를 찾을 수 없습니다." unless wms_menu

puts "WM_GROUP id: #{wms_menu.id}"

# 입고관리 메뉴 등록/업데이트
gr_menu = AdmMenu.find_or_initialize_by(menu_cd: "WM_GR_PRAR")
gr_menu.menu_nm   = "입고관리"
gr_menu.menu_type = "MENU"
gr_menu.parent_cd = wms_menu.menu_cd
gr_menu.menu_url  = "/wm/gr_prars"
gr_menu.use_yn    = "Y"
gr_menu.sort_order = 10
gr_menu.menu_icon = "package-open"
gr_menu.menu_level = 2
gr_menu.save!
puts "입고관리 메뉴 등록: id=#{gr_menu.id}"

# 사용자 권한 등록 (전체 활성 사용자)
user_count = 0
User.where(work_status: "ACTIVE").each do |user|
  begin
    perm = AdmUserMenuPermission.find_or_initialize_by(user_id: user.id, menu_cd: gr_menu.menu_cd)
    perm.use_yn = "Y"
    perm.save!
    user_count += 1
  rescue => e
    puts "  권한 설정 오류(user #{user.id}): #{e.message}"
  end
end

puts "권한 설정 완료: #{user_count}명"
puts "입고관리 메뉴 및 권한 동기화 완료"
