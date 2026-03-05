class MoveWorkplaceAreaZoneLocationToStorageMenu < ActiveRecord::Migration[8.1]
  def up
    # Find the "보관" menu. It could be named '보관', '보관(WM)', or have code 'WM_GROUP'
    storage_menu = AdmMenu.find_by(menu_nm: '보관') ||
                   AdmMenu.find_by(menu_nm: '보관(WM)') ||
                   AdmMenu.find_by(menu_nm: '보관관리') ||
                   AdmMenu.find_by(menu_cd: 'WM_GROUP')

    if storage_menu
      target_names = [ '작업장관리', '구역관리', '보관존관리', '로케이션관리' ]
      menus = AdmMenu.where(menu_nm: target_names)

      say "Found storage menu: #{storage_menu.menu_nm} (#{storage_menu.menu_cd})"

      menus.each do |menu|
        say "Moving #{menu.menu_nm} (#{menu.menu_cd}) to #{storage_menu.menu_nm}"
        menu.update!(
          parent_cd: storage_menu.menu_cd,
          menu_level: storage_menu.menu_level + 1
        )
      end
    else
      say "Storage (보관) menu not found!"
    end
  end

  def down
    # Revert to WMS (WM) folder for WM_ prefixed menus, and STD_CODE_REGION for STD_WORKPLACE
    menus = AdmMenu.where(menu_nm: [ '작업장관리', '구역관리', '보관존관리', '로케이션관리' ])
    menus.each do |menu|
      if menu.menu_cd.start_with?('WM_')
        wm_menu = AdmMenu.find_by(menu_cd: 'WM')
        if wm_menu
          menu.update!(parent_cd: wm_menu.menu_cd, menu_level: wm_menu.menu_level + 1)
        end
      elsif menu.menu_cd == 'STD_WORKPLACE'
        std_region = AdmMenu.find_by(menu_cd: 'STD_CODE_REGION')
        if std_region
          menu.update!(parent_cd: std_region.menu_cd, menu_level: std_region.menu_level + 1)
        end
      end
    end
  end
end
