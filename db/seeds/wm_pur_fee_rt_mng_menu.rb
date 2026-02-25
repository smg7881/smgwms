# 매입요율관리 메뉴 및 권한 등록
puts "메뉴 등록 시작..."

# 1. WM 상위 폴더 확인
wms_menu = AdmMenu.find_or_create_by!(menu_cd: "WM_GROUP") do |m|
  m.menu_nm = "보관(WM)"
  m.menu_type = "FOLDER"
  m.menu_level = 1
  m.sort_order = 100
  m.use_yn = "Y"
end
puts "WM_GROUP: #{wms_menu.id}, level=#{wms_menu.menu_level}"

# 2. 매입요율관리 메뉴 등록
pur_fee_rt_menu = AdmMenu.find_or_initialize_by(menu_cd: "WM_PUR_FEE_RT_MNG")
pur_fee_rt_menu.menu_nm = "매입요율관리"
pur_fee_rt_menu.menu_type = "MENU"
pur_fee_rt_menu.parent_cd = wms_menu.menu_cd
pur_fee_rt_menu.menu_url = "/wm/pur_fee_rt_mngs"
pur_fee_rt_menu.menu_level = wms_menu.menu_level + 1
pur_fee_rt_menu.sort_order = 140
pur_fee_rt_menu.use_yn = "Y"
pur_fee_rt_menu.save!
puts "매입요율관리 메뉴: #{pur_fee_rt_menu.id}"

# 3. 사용자 권한 등록
user_count = 0
User.where(work_status: "ACTIVE").find_each do |user|
  begin
    perm = AdmUserMenuPermission.find_or_initialize_by(user_id: user.id, menu_cd: pur_fee_rt_menu.menu_cd)
    perm.use_yn = "Y"
    perm.save!
    user_count += 1
  rescue => e
    puts "권한 설정 오류(user #{user.id}): #{e.message}"
  end
end
puts "권한 설정: #{user_count}명"
puts "✅ 매입요율관리 메뉴 등록 완료"
