class AddStdOperationMenusAndPermissions < ActiveRecord::Migration[8.1]
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
    { menu_cd: "STD_WORKPLACE", menu_nm: "작업장관리", menu_url: "/std/workplaces", menu_icon: "map-pinned", tab_id: "std-workplaces" },
    { menu_cd: "STD_REGION", menu_nm: "권역관리", menu_url: "/std/regions", menu_icon: "map", tab_id: "std-regions" },
    { menu_cd: "STD_REGION_ZIP", menu_nm: "권역별우편번호관리", menu_url: "/std/region_zipcodes", menu_icon: "mail", tab_id: "std-region-zipcodes" },
    { menu_cd: "STD_COUNTRY", menu_nm: "국가코드관리", menu_url: "/std/countries", menu_icon: "globe-2", tab_id: "std-countries" },
    { menu_cd: "STD_HOLIDAY", menu_nm: "공휴일관리", menu_url: "/std/holidays", menu_icon: "calendar-days", tab_id: "std-holidays" },
    { menu_cd: "STD_APPROVAL", menu_nm: "결재관리", menu_url: "/std/approvals", menu_icon: "file-check", tab_id: "std-approvals" },
    { menu_cd: "STD_APPROVAL_REQUEST", menu_nm: "결재요청승인", menu_url: "/std/approval_requests", menu_icon: "stamp", tab_id: "std-approval-requests" },
    { menu_cd: "STD_APPROVAL_HISTORY", menu_nm: "결재이력관리", menu_url: "/std/approval_histories", menu_icon: "history", tab_id: "std-approval-histories" }
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
      menu_codes = MENU_DEFINITIONS.map { |row| row[:menu_cd] }
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
        if menu.new_record?
          sort_order = base_sort_order + index + 1
        else
          sort_order = menu.sort_order.presence || (base_sort_order + index + 1)
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
      menu_codes = MENU_DEFINITIONS.map { |row| row[:menu_cd] }

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
      new_codes = MENU_DEFINITIONS.map { |row| row[:menu_cd] }
      MigrationAdmMenu.where(parent_cd: "STD")
                      .where.not(menu_cd: new_codes)
                      .maximum(:sort_order).to_i
    end
end
