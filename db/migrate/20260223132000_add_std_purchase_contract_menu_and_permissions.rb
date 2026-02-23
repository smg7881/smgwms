class AddStdPurchaseContractMenuAndPermissions < ActiveRecord::Migration[8.1]
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
    menu_cd: "STD_PUR_CONTRACT",
    menu_nm: "매입계약관리",
    menu_url: "/std/purchase_contracts",
    menu_icon: "file-signature",
    tab_id: "std-purchase-contracts"
  }.freeze

  def up
    return unless table_exists?(:adm_menus)

    ensure_std_folder!
    ensure_menu!
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
    def ensure_std_folder!
      std_menu = MigrationAdmMenu.find_or_initialize_by(menu_cd: "STD")
      if std_menu.new_record?
        std_menu.assign_attributes(
          menu_nm: "기준정보",
          parent_cd: nil,
          menu_url: nil,
          menu_icon: "database",
          sort_order: next_root_sort_order,
          menu_level: 1,
          menu_type: "FOLDER",
          use_yn: "Y",
          tab_id: nil
        )
      else
        std_menu.assign_attributes(
          menu_nm: "기준정보",
          menu_icon: "database",
          menu_type: "FOLDER",
          use_yn: "Y"
        )
      end
      std_menu.save!
    end

    def ensure_menu!
      menu = MigrationAdmMenu.find_or_initialize_by(menu_cd: MENU_DEFINITION[:menu_cd])
      sort_order = if menu.new_record?
        next_std_child_sort_order
      else
        menu.sort_order.presence || next_std_child_sort_order
      end

      menu.assign_attributes(
        menu_nm: MENU_DEFINITION[:menu_nm],
        parent_cd: "STD",
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

    def next_std_child_sort_order
      MigrationAdmMenu.where(parent_cd: "STD")
                      .where.not(menu_cd: MENU_DEFINITION[:menu_cd])
                      .maximum(:sort_order).to_i + 1
    end
end
