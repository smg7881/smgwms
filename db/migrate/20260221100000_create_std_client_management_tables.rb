class CreateStdClientManagementTables < ActiveRecord::Migration[8.1]
  def change
    create_table :std_bzac_mst do |t|
      t.string :bzac_cd, limit: 20, null: false
      t.string :bzac_nm, limit: 200, null: false
      t.string :mngt_corp_cd, limit: 50, null: false
      t.string :mngt_corp_nm, limit: 100
      t.string :bizman_no, limit: 20, null: false
      t.string :bzac_sctn_grp_cd, limit: 50, null: false
      t.string :bzac_sctn_cd, limit: 50, null: false
      t.string :bzac_kind_cd, limit: 50, null: false
      t.string :upper_bzac_cd, limit: 20
      t.string :rpt_bzac_cd, limit: 20
      t.string :ctry_cd, limit: 10, null: false, default: "KR"
      t.string :tpl_logis_yn_cd, limit: 1, null: false, default: "N"
      t.string :if_yn_cd, limit: 1, null: false, default: "N"
      t.string :branch_yn_cd, limit: 1, null: false, default: "N"
      t.string :sell_bzac_yn_cd, limit: 1, null: false, default: "Y"
      t.string :pur_bzac_yn_cd, limit: 1, null: false, default: "Y"
      t.string :bilg_bzac_cd, limit: 20
      t.string :elec_taxbill_yn_cd, limit: 1, null: false, default: "N"
      t.string :fnc_or_cd, limit: 50
      t.string :acnt_no_cd, limit: 50
      t.string :zip_cd, limit: 20
      t.string :addr_cd, limit: 300
      t.string :addr_dtl_cd, limit: 300
      t.string :rpt_sales_emp_cd, limit: 50, null: false
      t.string :rpt_sales_emp_nm, limit: 100
      t.date :aply_strt_day_cd, null: false
      t.date :aply_end_day_cd
      t.string :use_yn_cd, limit: 1, null: false, default: "Y"
      t.text :remk
      t.string :create_by, limit: 50
      t.datetime :create_time
      t.string :update_by, limit: 50
      t.datetime :update_time
    end

    add_index :std_bzac_mst, :bzac_cd, unique: true
    add_index :std_bzac_mst, :bizman_no
    add_index :std_bzac_mst, :bzac_nm
    add_index :std_bzac_mst, :mngt_corp_cd
    add_index :std_bzac_mst, :bzac_sctn_grp_cd
    add_index :std_bzac_mst, :bzac_sctn_cd
    add_index :std_bzac_mst, :use_yn_cd

    create_table :std_bzac_ofcr do |t|
      t.string :bzac_cd, limit: 20, null: false
      t.integer :seq_cd, null: false
      t.string :nm_cd, limit: 100, null: false
      t.string :ofic_telno_cd, limit: 30
      t.string :mbp_no_cd, limit: 30
      t.string :email_cd, limit: 120
      t.string :rpt_yn_cd, limit: 1, null: false, default: "N"
      t.string :use_yn_cd, limit: 1, null: false, default: "Y"
      t.string :create_by, limit: 50
      t.datetime :create_time
      t.string :update_by, limit: 50
      t.datetime :update_time
    end

    add_index :std_bzac_ofcr, [ :bzac_cd, :seq_cd ], unique: true
    add_index :std_bzac_ofcr, :bzac_cd
    add_index :std_bzac_ofcr, :use_yn_cd

    create_table :std_bzac_workpl do |t|
      t.string :bzac_cd, limit: 20, null: false
      t.integer :seq_cd, null: false
      t.string :workpl_nm_cd, limit: 120, null: false
      t.string :workpl_sctn_cd, limit: 50
      t.string :ofcr_cd, limit: 50
      t.string :use_yn_cd, limit: 1, null: false, default: "Y"
      t.string :create_by, limit: 50
      t.datetime :create_time
      t.string :update_by, limit: 50
      t.datetime :update_time
    end

    add_index :std_bzac_workpl, [ :bzac_cd, :seq_cd ], unique: true
    add_index :std_bzac_workpl, :bzac_cd
    add_index :std_bzac_workpl, :use_yn_cd

    create_table :std_cm04004 do |t|
      t.string :bzac_cd, limit: 20, null: false
      t.integer :hist_seq, null: false
      t.string :changed_col_nm, limit: 100, null: false
      t.text :before_value
      t.text :after_value
      t.string :changed_by, limit: 50
      t.datetime :changed_at
      t.string :create_by, limit: 50
      t.datetime :create_time
      t.string :update_by, limit: 50
      t.datetime :update_time
    end

    add_index :std_cm04004, [ :bzac_cd, :hist_seq ], unique: true
    add_index :std_cm04004, [ :bzac_cd, :changed_at ]
  end
end
