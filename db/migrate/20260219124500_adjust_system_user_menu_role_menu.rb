class AdjustSystemUserMenuRoleMenu < ActiveRecord::Migration[8.1]
  class MigrationAdmMenu < ApplicationRecord
    self.table_name = "adm_menus"
  end

  def up
    return unless table_exists?(:adm_menus)

    menu = MigrationAdmMenu.find_by(menu_cd: "SYS_USER_MENU_ROLE")
    return if menu.nil?

    menu.update!(
      menu_nm: "사용자별 메뉴권한",
      menu_icon: "shield-check",
      sort_order: 5,
      tab_id: "system-user-menu-role"
    )
  end

  def down
    return unless table_exists?(:adm_menus)

    menu = MigrationAdmMenu.find_by(menu_cd: "SYS_USER_MENU_ROLE")
    return if menu.nil?

    menu.update!(
      menu_nm: "사용자별메뉴권한",
      menu_icon: "list-checks",
      sort_order: 10,
      tab_id: "system-user-menu-role"
    )
  end
end
