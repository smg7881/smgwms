class AdjustSystemRoleUserMenuLabel < ActiveRecord::Migration[8.1]
  class MigrationAdmMenu < ApplicationRecord
    self.table_name = "adm_menus"
  end

  def up
    return unless table_exists?(:adm_menus)

    menu = MigrationAdmMenu.find_by(menu_cd: "SYS_ROLE_USER")
    return if menu.nil?

    menu.update!(menu_nm: "역할별 사용자관리", tab_id: "system-role-user")
  end

  def down
    return unless table_exists?(:adm_menus)

    menu = MigrationAdmMenu.find_by(menu_cd: "SYS_ROLE_USER")
    return if menu.nil?

    menu.update!(menu_nm: "역할별사용자관리", tab_id: "system-role-user")
  end
end
