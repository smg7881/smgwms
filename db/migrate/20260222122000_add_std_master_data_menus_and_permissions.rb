class AddStdMasterDataMenusAndPermissions < ActiveRecord::Migration[8.1]
  class MigrationAdmMenu < ApplicationRecord
    self.table_name = "adm_menus"
  end

  class MigrationUser < ApplicationRecord
    self.table_name = "adm_users"
  end

  class MigrationAdmUserMenuPermission < ApplicationRecord
    self.table_name = "adm_user_menu_permissions"
  end

  MENU_DEFINITIONS = [
    { menu_cd: "STD_CORPORATION", menu_nm: "Corporation Management", menu_url: "/std/corporations", menu_icon: "building-2", tab_id: "std-corporations" },
    { menu_cd: "STD_BIZ_CERT", menu_nm: "Business Certificate", menu_url: "/std/business_certificates", menu_icon: "id-card", tab_id: "std-business-certificates" },
    { menu_cd: "STD_GOODS", menu_nm: "Goods Management", menu_url: "/std/goods", menu_icon: "package", tab_id: "std-goods" },
    { menu_cd: "STD_FAVORITE", menu_nm: "Favorite Management", menu_url: "/std/favorites", menu_icon: "star", tab_id: "std-favorites" },
    { menu_cd: "STD_INTERFACE_INFO", menu_nm: "Interface Management", menu_url: "/std/interface_infos", menu_icon: "workflow", tab_id: "std-interface-infos" },
    { menu_cd: "STD_RESERVED_JOB", menu_nm: "Reserved Job", menu_url: "/std/reserved_jobs", menu_icon: "calendar-clock", tab_id: "std-reserved-jobs" },
    { menu_cd: "STD_EXCHANGE_RATE", menu_nm: "Exchange Rate", menu_url: "/std/exchange_rates", menu_icon: "coins", tab_id: "std-exchange-rates" }
  ].freeze

  def up
    return unless table_exists?(:adm_menus)

    ensure_std_folder!
    ensure_child_menus!
    ensure_permissions!
  end

  def down
    return unless table_exists?(:adm_menus)

    if table_exists?(:adm_user_menu_permissions)
      menu_codes = MENU_DEFINITIONS.map { |definition| definition[:menu_cd] }
      MigrationAdmUserMenuPermission.where(menu_cd: menu_codes).delete_all
    end

    MENU_DEFINITIONS.each do |definition|
      MigrationAdmMenu.where(menu_cd: definition[:menu_cd]).delete_all
    end
  end

  private
    def ensure_std_folder!
      std_menu = MigrationAdmMenu.find_or_initialize_by(menu_cd: "STD")
      if std_menu.new_record?
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
      else
        std_menu.assign_attributes(
          menu_nm: "Standard",
          menu_icon: "database",
          menu_type: "FOLDER",
          use_yn: "Y"
        )
      end
      std_menu.save!
    end

    def ensure_child_menus!
      base_sort_order = next_std_child_sort_order_base

      MENU_DEFINITIONS.each_with_index do |definition, index|
        menu = MigrationAdmMenu.find_or_initialize_by(menu_cd: definition[:menu_cd])
        sort_order = if menu.new_record?
          base_sort_order + index + 1
        else
          menu.sort_order.presence || (base_sort_order + index + 1)
        end

        menu.assign_attributes(
          menu_nm: definition[:menu_nm],
          parent_cd: "STD",
          menu_url: definition[:menu_url],
          menu_icon: definition[:menu_icon],
          sort_order: sort_order,
          menu_level: 2,
          menu_type: "MENU",
          use_yn: "Y",
          tab_id: definition[:tab_id]
        )
        menu.save!
      end
    end

    def ensure_permissions!
      return unless table_exists?(:adm_user_menu_permissions)

      now = Time.current
      menu_codes = MENU_DEFINITIONS.map { |definition| definition[:menu_cd] }

      MigrationUser.find_each do |user|
        menu_codes.each do |menu_cd|
          permission = MigrationAdmUserMenuPermission.find_or_initialize_by(user_id: user.id, menu_cd: menu_cd)
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

    def next_root_sort_order
      MigrationAdmMenu.where(parent_cd: nil).maximum(:sort_order).to_i + 1
    end

    def next_std_child_sort_order_base
      new_codes = MENU_DEFINITIONS.map { |definition| definition[:menu_cd] }
      MigrationAdmMenu.where(parent_cd: "STD")
                      .where.not(menu_cd: new_codes)
                      .maximum(:sort_order).to_i
    end
end
