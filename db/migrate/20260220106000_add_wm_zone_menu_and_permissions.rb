class AddWmZoneMenuAndPermissions < ActiveRecord::Migration[8.1]
  class MigrationAdmMenu < ApplicationRecord
    self.table_name = "adm_menus"
  end

  class MigrationUser < ApplicationRecord
    self.table_name = "adm_users"
  end

  class MigrationAdmUserMenuPermission < ApplicationRecord
    self.table_name = "adm_user_menu_permissions"
  end

  def up
    return unless table_exists?(:adm_menus)

    ensure_wm_folder!
    ensure_zone_menu!
    ensure_zone_permissions!
  end

  def down
    return unless table_exists?(:adm_menus)

    if table_exists?(:adm_user_menu_permissions)
      MigrationAdmUserMenuPermission.where(menu_cd: "WM_ZONE").delete_all
    end

    MigrationAdmMenu.where(menu_cd: "WM_ZONE").delete_all
  end

  private
    def ensure_wm_folder!
      wm_menu = MigrationAdmMenu.find_or_initialize_by(menu_cd: "WM")
      return unless wm_menu.new_record?

      wm_menu.assign_attributes(
        menu_nm: "WMS",
        parent_cd: nil,
        menu_url: nil,
        menu_icon: "warehouse",
        sort_order: next_root_sort_order,
        menu_level: 1,
        menu_type: "FOLDER",
        use_yn: "Y",
        tab_id: nil
      )
      wm_menu.save!
    end

    def ensure_zone_menu!
      menu = MigrationAdmMenu.find_or_initialize_by(menu_cd: "WM_ZONE")
      menu.assign_attributes(
        menu_nm: "보관존관리",
        parent_cd: "WM",
        menu_url: "/wm/zone",
        menu_icon: "boxes",
        sort_order: next_wm_child_sort_order,
        menu_level: 2,
        menu_type: "MENU",
        use_yn: "Y",
        tab_id: "wm-zone"
      )
      menu.save!
    end

    def ensure_zone_permissions!
      return unless table_exists?(:adm_user_menu_permissions)

      now = Time.current

      MigrationUser.find_each do |user|
        permission = MigrationAdmUserMenuPermission.find_or_initialize_by(user_id: user.id, menu_cd: "WM_ZONE")
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

    def next_root_sort_order
      MigrationAdmMenu.where(parent_cd: nil).maximum(:sort_order).to_i + 1
    end

    def next_wm_child_sort_order
      MigrationAdmMenu.where(parent_cd: "WM")
                      .where.not(menu_cd: "WM_ZONE")
                      .maximum(:sort_order).to_i + 1
    end
end
