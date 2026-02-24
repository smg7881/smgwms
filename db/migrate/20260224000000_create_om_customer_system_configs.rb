class CreateOmCustomerSystemConfigs < ActiveRecord::Migration[8.1]
  class MigrationOmCustomerSystemConfig < ApplicationRecord
    self.table_name = "om_customer_system_configs"
  end

  DEFAULT_ROWS = [
    {
      setup_unit_cd: "SYSTEM",
      cust_cd: "",
      lclas_cd: "ORD_RECV",
      mclas_cd: "REQUIRED",
      sclas_cd: "WORK_QTY",
      setup_sctn_cd: "VALIDATE",
      module_nm: "작업물량",
      setup_value: "Y",
      use_yn: "Y"
    },
    {
      setup_unit_cd: "SYSTEM",
      cust_cd: "",
      lclas_cd: "ORD_RECV",
      mclas_cd: "REQUIRED",
      sclas_cd: "ITEM_NM",
      setup_sctn_cd: "VALIDATE",
      module_nm: "품명",
      setup_value: "Y",
      use_yn: "Y"
    },
    {
      setup_unit_cd: "SYSTEM",
      cust_cd: "",
      lclas_cd: "ORD_RECV",
      mclas_cd: "REQUIRED",
      sclas_cd: "ORIGIN",
      setup_sctn_cd: "VALIDATE",
      module_nm: "출발거점",
      setup_value: "Y",
      use_yn: "Y"
    },
    {
      setup_unit_cd: "SYSTEM",
      cust_cd: "",
      lclas_cd: "ORD_RECV",
      mclas_cd: "REQUIRED",
      sclas_cd: "DEST",
      setup_sctn_cd: "VALIDATE",
      module_nm: "도착거점",
      setup_value: "Y",
      use_yn: "Y"
    },
    {
      setup_unit_cd: "SYSTEM",
      cust_cd: "",
      lclas_cd: "ORD_RECV",
      mclas_cd: "REQUIRED",
      sclas_cd: "DUE_DATE",
      setup_sctn_cd: "VALIDATE",
      module_nm: "납기일자",
      setup_value: "Y",
      use_yn: "Y"
    },
    {
      setup_unit_cd: "SYSTEM",
      cust_cd: "",
      lclas_cd: "ORD_RECV",
      mclas_cd: "REQUIRED",
      sclas_cd: "CREDIT_LIMIT",
      setup_sctn_cd: "VALIDATE",
      module_nm: "여신한도체크",
      setup_value: "Y",
      use_yn: "Y"
    },
    {
      setup_unit_cd: "SYSTEM",
      cust_cd: "",
      lclas_cd: "ORD_CREATE",
      mclas_cd: "VALIDATE",
      sclas_cd: "CREATE",
      setup_sctn_cd: "VALIDATE",
      module_nm: "오더생성",
      setup_value: "Y",
      use_yn: "Y"
    },
    {
      setup_unit_cd: "SYSTEM",
      cust_cd: "",
      lclas_cd: "ORD_ALLOC",
      mclas_cd: "VALIDATE",
      sclas_cd: "ALLOC",
      setup_sctn_cd: "VALIDATE",
      module_nm: "오더분배",
      setup_value: "Y",
      use_yn: "Y"
    },
    {
      setup_unit_cd: "SYSTEM",
      cust_cd: "",
      lclas_cd: "ORD_SEND",
      mclas_cd: "VALIDATE",
      sclas_cd: "SEND",
      setup_sctn_cd: "VALIDATE",
      module_nm: "오더전송",
      setup_value: "Y",
      use_yn: "Y"
    }
  ].freeze

  def up
    if table_exists?(:om_customer_system_configs)
      ensure_columns!
      normalize_existing_rows!
    else
      create_table :om_customer_system_configs do |t|
        t.string :setup_unit_cd, limit: 30, null: false
        t.string :cust_cd, limit: 20, null: false, default: ""
        t.string :lclas_cd, limit: 50, null: false
        t.string :mclas_cd, limit: 50, null: false
        t.string :sclas_cd, limit: 50, null: false
        t.string :setup_sctn_cd, limit: 50, null: false
        t.string :module_nm, limit: 150
        t.string :setup_value, limit: 200
        t.string :use_yn, limit: 1, null: false, default: "Y"
        t.string :create_by, limit: 50
        t.datetime :create_time
        t.string :update_by, limit: 50
        t.datetime :update_time
      end
    end

    ensure_indexes!
    seed_default_rows!
  end

  def down
    if table_exists?(:om_customer_system_configs)
      drop_table :om_customer_system_configs
    end
  end

  private
    def ensure_columns!
      add_column :om_customer_system_configs, :setup_unit_cd, :string, limit: 30, default: "SYSTEM", null: false unless column_exists?(:om_customer_system_configs, :setup_unit_cd)
      add_column :om_customer_system_configs, :lclas_cd, :string, limit: 50, default: "ORD_RECV", null: false unless column_exists?(:om_customer_system_configs, :lclas_cd)
      add_column :om_customer_system_configs, :mclas_cd, :string, limit: 50, default: "REQUIRED", null: false unless column_exists?(:om_customer_system_configs, :mclas_cd)
      add_column :om_customer_system_configs, :sclas_cd, :string, limit: 50, default: "ITEM_NM", null: false unless column_exists?(:om_customer_system_configs, :sclas_cd)
      add_column :om_customer_system_configs, :setup_sctn_cd, :string, limit: 50, default: "VALIDATE", null: false unless column_exists?(:om_customer_system_configs, :setup_sctn_cd)
      add_column :om_customer_system_configs, :module_nm, :string, limit: 150 unless column_exists?(:om_customer_system_configs, :module_nm)
      add_column :om_customer_system_configs, :setup_value, :string, limit: 200 unless column_exists?(:om_customer_system_configs, :setup_value)

      if column_exists?(:om_customer_system_configs, :cust_cd)
        change_column_default :om_customer_system_configs, :cust_cd, from: nil, to: ""
        execute("UPDATE om_customer_system_configs SET cust_cd = '' WHERE cust_cd IS NULL")
        change_column_null :om_customer_system_configs, :cust_cd, false
      end

      if column_exists?(:om_customer_system_configs, :use_yn)
        change_column_default :om_customer_system_configs, :use_yn, from: nil, to: "Y"
        execute("UPDATE om_customer_system_configs SET use_yn = 'Y' WHERE use_yn IS NULL OR TRIM(use_yn) = ''")
        change_column_null :om_customer_system_configs, :use_yn, false
      end
    end

    def normalize_existing_rows!
      if column_exists?(:om_customer_system_configs, :config_value) && column_exists?(:om_customer_system_configs, :setup_value)
        execute("UPDATE om_customer_system_configs SET setup_value = COALESCE(setup_value, config_value)")
      end
      if column_exists?(:om_customer_system_configs, :config_key)
        if column_exists?(:om_customer_system_configs, :module_nm)
          execute("UPDATE om_customer_system_configs SET module_nm = COALESCE(module_nm, config_key)")
        end
        if column_exists?(:om_customer_system_configs, :sclas_cd)
          execute("UPDATE om_customer_system_configs SET sclas_cd = COALESCE(NULLIF(TRIM(sclas_cd), ''), config_key)")
        end
      end
      if column_exists?(:om_customer_system_configs, :upper_grp_cd) && column_exists?(:om_customer_system_configs, :lclas_cd)
        execute("UPDATE om_customer_system_configs SET lclas_cd = COALESCE(NULLIF(TRIM(lclas_cd), ''), upper_grp_cd)")
      end
      if column_exists?(:om_customer_system_configs, :grp_cd) && column_exists?(:om_customer_system_configs, :mclas_cd)
        execute("UPDATE om_customer_system_configs SET mclas_cd = COALESCE(NULLIF(TRIM(mclas_cd), ''), grp_cd)")
      end

      execute("UPDATE om_customer_system_configs SET setup_unit_cd = 'SYSTEM' WHERE setup_unit_cd IS NULL OR TRIM(setup_unit_cd) = ''")
      execute("UPDATE om_customer_system_configs SET setup_sctn_cd = 'VALIDATE' WHERE setup_sctn_cd IS NULL OR TRIM(setup_sctn_cd) = ''")
      execute("UPDATE om_customer_system_configs SET lclas_cd = 'ORD_RECV' WHERE lclas_cd IS NULL OR TRIM(lclas_cd) = ''")
      execute("UPDATE om_customer_system_configs SET mclas_cd = 'REQUIRED' WHERE mclas_cd IS NULL OR TRIM(mclas_cd) = ''")
      execute("UPDATE om_customer_system_configs SET sclas_cd = 'ITEM_NM' WHERE sclas_cd IS NULL OR TRIM(sclas_cd) = ''")
    end

    def ensure_indexes!
      add_index :om_customer_system_configs, :setup_unit_cd unless index_exists?(:om_customer_system_configs, :setup_unit_cd)
      add_index :om_customer_system_configs, :cust_cd unless index_exists?(:om_customer_system_configs, :cust_cd)
      add_index :om_customer_system_configs, :use_yn unless index_exists?(:om_customer_system_configs, :use_yn)

      key_columns = [ :setup_unit_cd, :cust_cd, :lclas_cd, :mclas_cd, :sclas_cd, :setup_sctn_cd ]
      unique_name = "index_om_customer_system_configs_on_unique_key"
      if !index_exists?(:om_customer_system_configs, key_columns, name: unique_name)
        if duplicate_key_exists?
          add_index :om_customer_system_configs, key_columns, name: "index_om_customer_system_configs_on_search_key"
        else
          add_index :om_customer_system_configs, key_columns, unique: true, name: unique_name
        end
      end
    end

    def duplicate_key_exists?
      sql = <<~SQL.squish
        SELECT 1
        FROM om_customer_system_configs
        GROUP BY setup_unit_cd, cust_cd, lclas_cd, mclas_cd, sclas_cd, setup_sctn_cd
        HAVING COUNT(*) > 1
        LIMIT 1
      SQL
      result = ActiveRecord::Base.connection.select_value(sql)
      result.present?
    end

    def seed_default_rows!
      return unless table_exists?(:om_customer_system_configs)
      return if MigrationOmCustomerSystemConfig.where(setup_unit_cd: "SYSTEM").exists?

      now = Time.current
      legacy_columns = MigrationOmCustomerSystemConfig.column_names.map(&:to_sym)
      rows = DEFAULT_ROWS.map do |row|
        payload = row.merge(
          create_by: "system",
          create_time: now,
          update_by: "system",
          update_time: now
        )
        if legacy_columns.include?(:upper_grp_cd)
          payload[:upper_grp_cd] = payload[:lclas_cd]
        end
        if legacy_columns.include?(:grp_cd)
          payload[:grp_cd] = payload[:mclas_cd]
        end
        if legacy_columns.include?(:config_key)
          payload[:config_key] = payload[:sclas_cd]
        end
        if legacy_columns.include?(:config_value)
          payload[:config_value] = payload[:setup_value]
        end
        payload.slice(*legacy_columns)
      end
      MigrationOmCustomerSystemConfig.insert_all!(rows)
    end
end
