class AddStdClientMenuAndPermissions < ActiveRecord::Migration[8.1]
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

    ensure_std_folder!
    ensure_client_menu!
    ensure_client_permissions!
  end

  def down
    return unless table_exists?(:adm_menus)

    if table_exists?(:adm_user_menu_permissions)
      MigrationAdmUserMenuPermission.where(menu_cd: "STD_CLIENT").delete_all
    end

    MigrationAdmMenu.where(menu_cd: "STD_CLIENT").delete_all
  end

  private
    def ensure_std_folder!
      std_menu = MigrationAdmMenu.find_or_initialize_by(menu_cd: "STD")
      return unless std_menu.new_record?

      std_menu.assign_attributes(
        menu_nm: "Standard",
        parent_cd: nil,
        menu_url: nil,
        menu_icon: "database",
        sort_order: next_root_sort_order,
        menu_level: 1,
        menu_type: "FOLDER",
        use_yn: "Y",
        tab_id: nil
      )
      std_menu.save!
    end

    def ensure_client_menu!
      menu = MigrationAdmMenu.find_or_initialize_by(menu_cd: "STD_CLIENT")
      menu.assign_attributes(
        menu_nm: "Client Management",
        parent_cd: "STD",
        menu_url: "/std/clients",
        menu_icon: "building-2",
        sort_order: next_std_child_sort_order,
        menu_level: 2,
        menu_type: "MENU",
        use_yn: "Y",
        tab_id: "std-clients"
      )
      menu.save!
    end

    def ensure_client_permissions!
      return unless table_exists?(:adm_user_menu_permissions)

      now = Time.current

      MigrationUser.find_each do |user|
        permission = MigrationAdmUserMenuPermission.find_or_initialize_by(user_id: user.id, menu_cd: "STD_CLIENT")
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

    def next_std_child_sort_order
      MigrationAdmMenu.where(parent_cd: "STD")
                      .where.not(menu_cd: "STD_CLIENT")
                      .maximum(:sort_order).to_i + 1
    end
end
