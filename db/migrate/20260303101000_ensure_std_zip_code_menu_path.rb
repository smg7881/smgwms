class EnsureStdZipCodeMenuPath < ActiveRecord::Migration[8.1]
  class MigrationAdmMenu < ApplicationRecord
    self.table_name = "adm_menus"
  end

  class MigrationUser < ApplicationRecord
    self.table_name = "adm_users"
  end

  class MigrationAdmUserMenuPermission < ApplicationRecord
    self.table_name = "adm_user_menu_permissions"
  end

  MENU_CODE = "STD_ZIP_CODE".freeze

  def up
    return unless table_exists?(:adm_menus)

    ensure_zip_menu!
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
    def ensure_zip_menu!
      menu = MigrationAdmMenu.find_or_initialize_by(menu_cd: MENU_CODE)
      parent_menu = MigrationAdmMenu.find_by(menu_cd: "STD_CODE_BIZ")

      menu.menu_nm = "우편번호관리"
      menu.parent_cd = "STD_CODE_BIZ"
      menu.menu_url = "/std/zipcodes"
      menu.menu_icon = "mail"
      menu.menu_type = "MENU"
      menu.use_yn = "Y"
      menu.tab_id = "std-zipcodes"
      menu.menu_level = if parent_menu
        parent_menu.menu_level.to_i + 1
      else
        4
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
        siblings_max_sort = MigrationAdmMenu.where(parent_cd: "STD_CODE_BIZ").where.not(menu_cd: MENU_CODE).maximum(:sort_order).to_i
        siblings_max_sort + 10
      end
    end
end
