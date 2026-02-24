class EnsureOmOrderOfficersSchema < ActiveRecord::Migration[8.1]
  TABLE_NAME = :om_order_officers
  OLD_UNIQUE_INDEX = "index_om_order_officers_on_ofcr_cd"
  NEW_UNIQUE_INDEX = "idx_om_ord_ofcr_unique"
  NEW_UNIQUE_COLUMNS = %i[ord_chrg_dept_cd cust_cd exp_imp_dom_sctn_cd ofcr_cd].freeze

  def up
    if table_exists?(TABLE_NAME)
      ensure_columns!
    else
      create_table TABLE_NAME do |t|
        t.string :ord_chrg_dept_cd, limit: 50, null: false
        t.string :ord_chrg_dept_nm, limit: 100
        t.string :cust_cd, limit: 20, null: false
        t.string :cust_nm, limit: 120
        t.string :exp_imp_dom_sctn_cd, limit: 30, null: false
        t.string :ofcr_cd, limit: 30, null: false
        t.string :ofcr_nm, limit: 100, null: false
        t.string :tel_no, limit: 30
        t.string :mbp_no, limit: 30
        t.string :use_yn, limit: 1, null: false, default: "Y"
        t.string :create_by, limit: 50
        t.datetime :create_time
        t.string :update_by, limit: 50
        t.datetime :update_time
      end
    end

    normalize_existing_rows!
    ensure_indexes!
  end

  def down
    return unless table_exists?(TABLE_NAME)

    if index_exists?(TABLE_NAME, NEW_UNIQUE_COLUMNS, name: NEW_UNIQUE_INDEX)
      remove_index TABLE_NAME, name: NEW_UNIQUE_INDEX
    end

    if column_exists?(TABLE_NAME, :ofcr_cd)
      if !index_exists?(TABLE_NAME, :ofcr_cd, name: OLD_UNIQUE_INDEX)
        add_index TABLE_NAME, :ofcr_cd, unique: true, name: OLD_UNIQUE_INDEX
      end
    end
  end

  private
    def ensure_columns!
      add_column TABLE_NAME, :ord_chrg_dept_cd, :string, limit: 50, null: false, default: "" unless column_exists?(TABLE_NAME, :ord_chrg_dept_cd)
      add_column TABLE_NAME, :ord_chrg_dept_nm, :string, limit: 100 unless column_exists?(TABLE_NAME, :ord_chrg_dept_nm)
      add_column TABLE_NAME, :cust_cd, :string, limit: 20, null: false, default: "" unless column_exists?(TABLE_NAME, :cust_cd)
      add_column TABLE_NAME, :cust_nm, :string, limit: 120 unless column_exists?(TABLE_NAME, :cust_nm)
      add_column TABLE_NAME, :exp_imp_dom_sctn_cd, :string, limit: 30, null: false, default: "DOMESTIC" unless column_exists?(TABLE_NAME, :exp_imp_dom_sctn_cd)
      add_column TABLE_NAME, :ofcr_nm, :string, limit: 100, null: false, default: "" unless column_exists?(TABLE_NAME, :ofcr_nm)
      add_column TABLE_NAME, :tel_no, :string, limit: 30 unless column_exists?(TABLE_NAME, :tel_no)
      add_column TABLE_NAME, :mbp_no, :string, limit: 30 unless column_exists?(TABLE_NAME, :mbp_no)
      add_column TABLE_NAME, :use_yn, :string, limit: 1, null: false, default: "Y" unless column_exists?(TABLE_NAME, :use_yn)
      add_column TABLE_NAME, :create_by, :string, limit: 50 unless column_exists?(TABLE_NAME, :create_by)
      add_column TABLE_NAME, :create_time, :datetime unless column_exists?(TABLE_NAME, :create_time)
      add_column TABLE_NAME, :update_by, :string, limit: 50 unless column_exists?(TABLE_NAME, :update_by)
      add_column TABLE_NAME, :update_time, :datetime unless column_exists?(TABLE_NAME, :update_time)
    end

    def normalize_existing_rows!
      if column_exists?(TABLE_NAME, :ord_chrg_dept_cd)
        execute("UPDATE #{TABLE_NAME} SET ord_chrg_dept_cd = '' WHERE ord_chrg_dept_cd IS NULL")
      end
      if column_exists?(TABLE_NAME, :cust_cd)
        execute("UPDATE #{TABLE_NAME} SET cust_cd = '' WHERE cust_cd IS NULL")
      end
      if column_exists?(TABLE_NAME, :exp_imp_dom_sctn_cd)
        execute("UPDATE #{TABLE_NAME} SET exp_imp_dom_sctn_cd = 'DOMESTIC' WHERE exp_imp_dom_sctn_cd IS NULL OR TRIM(exp_imp_dom_sctn_cd) = ''")
      end
      if column_exists?(TABLE_NAME, :ofcr_cd)
        execute("UPDATE #{TABLE_NAME} SET ofcr_cd = '' WHERE ofcr_cd IS NULL")
      end
      if column_exists?(TABLE_NAME, :ofcr_nm)
        execute("UPDATE #{TABLE_NAME} SET ofcr_nm = '' WHERE ofcr_nm IS NULL")
      end
      if column_exists?(TABLE_NAME, :use_yn)
        execute("UPDATE #{TABLE_NAME} SET use_yn = 'Y' WHERE use_yn IS NULL OR TRIM(use_yn) = ''")
      end
    end

    def ensure_indexes!
      add_index TABLE_NAME, :ord_chrg_dept_cd unless index_exists?(TABLE_NAME, :ord_chrg_dept_cd)
      add_index TABLE_NAME, :cust_cd unless index_exists?(TABLE_NAME, :cust_cd)
      add_index TABLE_NAME, :use_yn unless index_exists?(TABLE_NAME, :use_yn)

      if index_exists?(TABLE_NAME, :ofcr_cd, name: OLD_UNIQUE_INDEX)
        remove_index TABLE_NAME, name: OLD_UNIQUE_INDEX
      end

      if !index_exists?(TABLE_NAME, NEW_UNIQUE_COLUMNS, name: NEW_UNIQUE_INDEX)
        add_index TABLE_NAME, NEW_UNIQUE_COLUMNS, unique: true, name: NEW_UNIQUE_INDEX
      end
    end
end
