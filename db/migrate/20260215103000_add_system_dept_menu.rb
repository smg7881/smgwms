class AddSystemDeptMenu < ActiveRecord::Migration[8.1]
  class MigrationAdmMenu < ApplicationRecord
    self.table_name = "adm_menus"
  end

  def up
    return unless table_exists?(:adm_menus)

    system_menu = MigrationAdmMenu.find_or_initialize_by(menu_cd: "SYSTEM")
    if system_menu.new_record?
      system_menu.assign_attributes(
        menu_nm: "시스템",
        parent_cd: nil,
        menu_url: nil,
        menu_icon: nil,
        sort_order: next_root_sort_order,
        menu_level: 1,
        menu_type: "FOLDER",
        use_yn: "Y",
        tab_id: nil
      )
      system_menu.save!
    end

    dept_menu = MigrationAdmMenu.find_or_initialize_by(menu_cd: "SYS_DEPT")
    dept_menu.assign_attributes(
      menu_nm: "부서관리",
      parent_cd: "SYSTEM",
      menu_url: "/system/dept",
      menu_icon: "🏢",
      sort_order: next_system_child_sort_order,
      menu_level: 2,
      menu_type: "MENU",
      use_yn: "Y",
      tab_id: "system-dept"
    )
    dept_menu.save!
  end

  def down
    return unless table_exists?(:adm_menus)

    MigrationAdmMenu.where(menu_cd: "SYS_DEPT").delete_all
  end

  private
    def next_root_sort_order
      MigrationAdmMenu.where(parent_cd: nil).maximum(:sort_order).to_i + 1
    end

    def next_system_child_sort_order
      MigrationAdmMenu.where(parent_cd: "SYSTEM").where.not(menu_cd: "SYS_DEPT").maximum(:sort_order).to_i + 1
    end
end
