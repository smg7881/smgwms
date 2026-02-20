class AddWmLocationMenuAndPermissions < ActiveRecord::Migration[8.1]
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
    ensure_location_menu!
    ensure_location_permissions!
  end

  def down
    return unless table_exists?(:adm_menus)

    if table_exists?(:adm_user_menu_permissions)
      MigrationAdmUserMenuPermission.where(menu_cd: "WM_LOCATION").delete_all
    end

    MigrationAdmMenu.where(menu_cd: "WM_LOCATION").delete_all
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

    def ensure_location_menu!
      menu = MigrationAdmMenu.find_or_initialize_by(menu_cd: "WM_LOCATION")
      menu.assign_attributes(
        menu_nm: "로케이션관리",
        parent_cd: "WM",
        menu_url: "/wm/location",
        menu_icon: "map-pin",
        sort_order: next_wm_child_sort_order,
        menu_level: 2,
        menu_type: "MENU",
        use_yn: "Y",
        tab_id: "wm-location"
      )
      menu.save!
    end

    def ensure_location_permissions!
      return unless table_exists?(:adm_user_menu_permissions)

      now = Time.current

      MigrationUser.find_each do |user|
        permission = MigrationAdmUserMenuPermission.find_or_initialize_by(user_id: user.id, menu_cd: "WM_LOCATION")
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
                      .where.not(menu_cd: "WM_LOCATION")
                      .maximum(:sort_order).to_i + 1
    end
end
