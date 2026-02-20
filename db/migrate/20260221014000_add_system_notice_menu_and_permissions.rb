class AddSystemNoticeMenuAndPermissions < ActiveRecord::Migration[8.1]
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

    ensure_system_folder!
    ensure_notice_menu!
    ensure_notice_permissions!
  end

  def down
    return unless table_exists?(:adm_menus)

    if table_exists?(:adm_user_menu_permissions)
      MigrationAdmUserMenuPermission.where(menu_cd: "SYS_NOTICE").delete_all
    end

    MigrationAdmMenu.where(menu_cd: "SYS_NOTICE").delete_all
  end

  private
    def ensure_system_folder!
      system_menu = MigrationAdmMenu.find_or_initialize_by(menu_cd: "SYSTEM")
      return unless system_menu.new_record?

      system_menu.assign_attributes(
        menu_nm: "시스템",
        parent_cd: nil,
        menu_url: nil,
        menu_icon: "settings",
        sort_order: next_root_sort_order,
        menu_level: 1,
        menu_type: "FOLDER",
        use_yn: "Y",
        tab_id: nil
      )
      system_menu.save!
    end

    def ensure_notice_menu!
      menu = MigrationAdmMenu.find_or_initialize_by(menu_cd: "SYS_NOTICE")
      menu.assign_attributes(
        menu_nm: "공지사항",
        parent_cd: "SYSTEM",
        menu_url: "/system/notice",
        menu_icon: "bell",
        sort_order: next_system_child_sort_order,
        menu_level: 2,
        menu_type: "MENU",
        use_yn: "Y",
        tab_id: "system-notice"
      )
      menu.save!
    end

    def ensure_notice_permissions!
      return unless table_exists?(:adm_user_menu_permissions)

      now = Time.current

      MigrationUser.find_each do |user|
        permission = MigrationAdmUserMenuPermission.find_or_initialize_by(user_id: user.id, menu_cd: "SYS_NOTICE")
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

    def next_system_child_sort_order
      MigrationAdmMenu.where(parent_cd: "SYSTEM")
                      .where.not(menu_cd: "SYS_NOTICE")
                      .maximum(:sort_order).to_i + 1
    end
end
