class AddSalesCustomerClientMenuAndPermissions < ActiveRecord::Migration[8.1]
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
    menu_cd: "SALES_CUST_CLIENT",
    menu_nm: "고객거래처관리",
    menu_url: "/std/customer_clients",
    menu_icon: "building-2",
    tab_id: "std-customer-clients"
  }.freeze

  def up
    return unless table_exists?(:adm_menus)

    ensure_sales_folder!
    ensure_sales_client_folder!
    ensure_customer_client_menu!
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
    def ensure_sales_folder!
      menu = MigrationAdmMenu.find_or_initialize_by(menu_cd: "SALES")
      if menu.new_record?
        menu.assign_attributes(
          menu_nm: "영업관리",
          parent_cd: nil,
          menu_url: nil,
          menu_icon: "briefcase-business",
          sort_order: next_root_sort_order,
          menu_level: 1,
          menu_type: "FOLDER",
          use_yn: "Y",
          tab_id: nil
        )
      else
        menu.assign_attributes(
          menu_nm: "영업관리",
          menu_icon: menu.menu_icon.presence || "briefcase-business",
          menu_type: "FOLDER",
          use_yn: "Y"
        )
      end
      menu.save!
    end

    def ensure_sales_client_folder!
      menu = MigrationAdmMenu.find_or_initialize_by(menu_cd: "SALES_CLIENT")
      if menu.new_record?
        menu.assign_attributes(
          menu_nm: "거래처관리",
          parent_cd: "SALES",
          menu_url: nil,
          menu_icon: "building",
          sort_order: next_sales_child_sort_order,
          menu_level: 2,
          menu_type: "FOLDER",
          use_yn: "Y",
          tab_id: nil
        )
      else
        menu.assign_attributes(
          menu_nm: "거래처관리",
          parent_cd: "SALES",
          menu_icon: menu.menu_icon.presence || "building",
          menu_type: "FOLDER",
          use_yn: "Y"
        )
      end
      menu.save!
    end

    def ensure_customer_client_menu!
      menu = MigrationAdmMenu.find_or_initialize_by(menu_cd: MENU_DEFINITION[:menu_cd])
      sort_order = if menu.new_record?
        next_sales_client_child_sort_order
      else
        menu.sort_order.presence || next_sales_client_child_sort_order
      end

      menu.assign_attributes(
        menu_nm: MENU_DEFINITION[:menu_nm],
        parent_cd: "SALES_CLIENT",
        menu_url: MENU_DEFINITION[:menu_url],
        menu_icon: MENU_DEFINITION[:menu_icon],
        sort_order: sort_order,
        menu_level: 3,
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
        permission = MigrationAdmUserMenuPermission.find_or_initialize_by(user_id: user.id, menu_cd: MENU_DEFINITION[:menu_cd])
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

    def next_sales_child_sort_order
      MigrationAdmMenu.where(parent_cd: "SALES").maximum(:sort_order).to_i + 1
    end

    def next_sales_client_child_sort_order
      MigrationAdmMenu.where(parent_cd: "SALES_CLIENT")
                      .where.not(menu_cd: MENU_DEFINITION[:menu_cd])
                      .maximum(:sort_order).to_i + 1
    end
end
