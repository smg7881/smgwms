class SetupStdSellContractMenuAndPermissions < ActiveRecord::Migration[8.1]
  class MigrationAdmMenu < ApplicationRecord
    self.table_name = "adm_menus"
  end

  class MigrationUser < ApplicationRecord
    self.table_name = "adm_users"
  end

  class MigrationAdmUserMenuPermission < ApplicationRecord
    self.table_name = "adm_user_menu_permissions"
  end

  MENU_CD = "SALES_SELL_CONTRACT"

  def up
    return unless table_exists?(:adm_menus)

    menu = MigrationAdmMenu.find_by(menu_cd: MENU_CD)
    if menu.nil?
      return
    end

    menu.update!(
      menu_url: "/std/sell_contracts",
      tab_id: "std-sell-contracts"
    )

    ensure_permissions!
  end

  def down
    return unless table_exists?(:adm_menus)

    menu = MigrationAdmMenu.find_by(menu_cd: MENU_CD)
    if menu.present?
      menu.update!(menu_url: "#", tab_id: nil)
    end

    if table_exists?(:adm_user_menu_permissions)
      MigrationAdmUserMenuPermission.where(menu_cd: MENU_CD).delete_all
    end
  end

  private
    def ensure_permissions!
      return unless table_exists?(:adm_user_menu_permissions)

      now = Time.current
      MigrationUser.find_each do |user|
        permission = MigrationAdmUserMenuPermission.find_or_initialize_by(
          user_id: user.id,
          menu_cd: MENU_CD
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
end
