class EnsureStdWorkStepMenuPath < ActiveRecord::Migration[8.1]
  class MigrationAdmMenu < ApplicationRecord
    self.table_name = "adm_menus"
  end

  class MigrationUser < ApplicationRecord
    self.table_name = "adm_users"
  end

  class MigrationAdmUserMenuPermission < ApplicationRecord
    self.table_name = "adm_user_menu_permissions"
  end

  MENU_CODE = "STD_WORK_STEP".freeze
  PARENT_MENU_CODE = "STD_WORK_ROUTING".freeze

  def up
    return unless table_exists?(:adm_menus)

    ensure_menu!
    ensure_permissions!
  end

  def down
    return unless table_exists?(:adm_menus)

    menu = MigrationAdmMenu.find_by(menu_cd: MENU_CODE)
    if menu
      menu.update!(menu_url: "#", tab_id: nil)
    end
  end

  private
    def ensure_menu!
      menu = MigrationAdmMenu.find_or_initialize_by(menu_cd: MENU_CODE)
      parent_menu = MigrationAdmMenu.find_by(menu_cd: PARENT_MENU_CODE)

      menu.menu_nm = "기본작업단계관리"
      menu.parent_cd = PARENT_MENU_CODE
      menu.menu_url = "/std/work_steps"
      menu.menu_icon = "workflow"
      menu.menu_type = "MENU"
      menu.use_yn = "Y"
      menu.tab_id = "std-work-steps"
      menu.menu_level = if parent_menu
        parent_menu.menu_level.to_i + 1
      else
        5
      end
      menu.sort_order = resolve_sort_order(menu)
      menu.save!
    end

    def ensure_permissions!
      return unless table_exists?(:adm_user_menu_permissions)

      now = Time.current
      MigrationUser.find_each do |user|
        permission = MigrationAdmUserMenuPermission.find_or_initialize_by(user_id: user.id, menu_cd: MENU_CODE)
        permission.use_yn = "Y"
        permission.update_by = "system"
        permission.update_time = now
        if permission.new_record?
          permission.create_by = "system"
          permission.create_time = now
        end
        permission.save!
      end
    end

    def resolve_sort_order(menu)
      if menu.sort_order.present?
        menu.sort_order
      else
        siblings_max_sort = MigrationAdmMenu.where(parent_cd: PARENT_MENU_CODE).where.not(menu_cd: MENU_CODE).maximum(:sort_order).to_i
        siblings_max_sort + 10
      end
    end
end
