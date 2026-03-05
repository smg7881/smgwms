class AddWmRateRetroactMenuAndPermissions < ActiveRecord::Migration[8.1]
  class MigrationAdmMenu < ApplicationRecord
    self.table_name = "adm_menus"
  end

  class MigrationUser < ApplicationRecord
    self.table_name = "adm_users"
  end

  class MigrationAdmUserMenuPermission < ApplicationRecord
    self.table_name = "adm_user_menu_permissions"
  end

  MENU_DEFINITION = {
    menu_cd: "WM_RATE_RETROACT_MNG",
    menu_nm: "요율소급관리",
    menu_url: "/wm/rate_retroacts",
    menu_icon: "history",
    tab_id: "wm-rate-retroacts"
  }.freeze

  def up
    return unless table_exists?(:adm_menus)

    parent_code = ensure_wm_parent_folder!
    ensure_menu!(parent_code)
    ensure_permissions!
  end

  def down
    return unless table_exists?(:adm_menus)

    if table_exists?(:adm_user_menu_permissions)
      MigrationAdmUserMenuPermission.where(menu_cd: MENU_DEFINITION[:menu_cd]).delete_all
    end

    MigrationAdmMenu.where(menu_cd: MENU_DEFINITION[:menu_cd]).delete_all
  end

  private
    def ensure_wm_parent_folder!
      wm_group_menu = MigrationAdmMenu.find_by(menu_cd: "WM_GROUP")
      if wm_group_menu.present?
        return "WM_GROUP"
      end

      wm_menu = MigrationAdmMenu.find_by(menu_cd: "WM")
      if wm_menu.present?
        return "WM"
      end

      menu = MigrationAdmMenu.find_or_initialize_by(menu_cd: "WM_GROUP")
      menu.assign_attributes(
        menu_nm: "보관(WM)",
        parent_cd: nil,
        menu_url: nil,
        menu_icon: "warehouse",
        sort_order: next_root_sort_order,
        menu_level: 1,
        menu_type: "FOLDER",
        use_yn: "Y",
        tab_id: nil
      )
      menu.save!

      "WM_GROUP"
    end

    def ensure_menu!(parent_code)
      menu = MigrationAdmMenu.find_or_initialize_by(menu_cd: MENU_DEFINITION[:menu_cd])
      sort_order = if menu.new_record?
        next_child_sort_order(parent_code)
      else
        menu.sort_order.presence || next_child_sort_order(parent_code)
      end

      menu.assign_attributes(
        menu_nm: MENU_DEFINITION[:menu_nm],
        parent_cd: parent_code,
        menu_url: MENU_DEFINITION[:menu_url],
        menu_icon: MENU_DEFINITION[:menu_icon],
        sort_order: sort_order,
        menu_level: 2,
        menu_type: "MENU",
        use_yn: "Y",
        tab_id: MENU_DEFINITION[:tab_id]
      )
      menu.save!
    end

    def ensure_permissions!
      return unless table_exists?(:adm_user_menu_permissions)

      now = Time.current
      MigrationUser.find_each do |user|
        permission = MigrationAdmUserMenuPermission.find_or_initialize_by(
          user_id: user.id,
          menu_cd: MENU_DEFINITION[:menu_cd]
        )
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

    def next_child_sort_order(parent_code)
      MigrationAdmMenu.where(parent_cd: parent_code)
                      .where.not(menu_cd: MENU_DEFINITION[:menu_cd])
                      .maximum(:sort_order).to_i + 1
    end
end
