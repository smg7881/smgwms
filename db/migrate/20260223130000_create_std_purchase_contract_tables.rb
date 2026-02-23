class CreateStdPurchaseContractTables < ActiveRecord::Migration[8.1]
  def change
    create_table :std_purchase_contracts do |t|
      t.string :corp_cd, limit: 20
      t.string :bzac_cd, limit: 20, null: false
      t.string :pur_ctrt_no, limit: 30, null: false
      t.string :pur_ctrt_nm, limit: 200, null: false
      t.string :bizman_no, limit: 20, null: false
      t.string :ctrt_sctn_cd, limit: 30, null: false
      t.string :ctrt_kind_cd, limit: 30, null: false

      t.string :bef_ctrt_no, limit: 30
      t.string :cprtco_ofcr_cd, limit: 50
      t.date :strt_ctrt_ymd
      t.date :ctrt_strt_day
      t.date :ctrt_end_day
      t.date :ctrt_exten_ymd
      t.date :ctrt_expi_noti_ymd
      t.date :ctrt_cnctr_ymd
      t.string :ctrt_cnctr_reason_cd, limit: 30
      t.string :ctrt_ofcr_cd, limit: 50
      t.string :ctrt_ofcr_nm, limit: 100
      t.string :ctrt_dept_cd, limit: 50
      t.string :ctrt_dept_nm, limit: 100
      t.string :loan_limt_over_yn_cd, limit: 1, null: false, default: "N"
      t.string :vat_sctn_cd, limit: 30
      t.string :apv_mthd_cd, limit: 30
      t.string :apv_type_cd, limit: 30
      t.string :bilg_mthd_cd, limit: 30
      t.string :dcsn_yn_cd, limit: 1, null: false, default: "N"
      t.string :use_yn_cd, limit: 1, null: false, default: "Y"

      t.string :ctrt_chg_reason_cd, limit: 255
      t.string :op_area_cd, limit: 100
      t.string :re_ctrt_cond_cd, limit: 255
      t.string :ctrt_cnctr_cond_cd, limit: 255
      t.string :ctrt_cnctr_dtl_reason_cd, limit: 500
      t.string :pay_cond_cd, limit: 30
      t.string :bzac_sctn_cd, limit: 30
      t.string :work_step_no1_cd, limit: 30
      t.string :work_step_no2_cd, limit: 30
      t.text :remk

      t.string :create_by, limit: 50
      t.datetime :create_time
      t.string :update_by, limit: 50
      t.datetime :update_time
    end

    add_index :std_purchase_contracts, :pur_ctrt_no, unique: true
    add_index :std_purchase_contracts, :bzac_cd
    add_index :std_purchase_contracts, :corp_cd
    add_index :std_purchase_contracts, :ctrt_sctn_cd
    add_index :std_purchase_contracts, :ctrt_strt_day
    add_index :std_purchase_contracts, :use_yn_cd

    create_table :std_purchase_contract_settlements do |t|
      t.references :purchase_contract, null: false, foreign_key: { to_table: :std_purchase_contracts }
      t.integer :seq_no, null: false
      t.string :fnc_or_cd, limit: 50
      t.string :fnc_or_nm, limit: 120
      t.string :acnt_no_cd, limit: 50
      t.string :dpstr_nm, limit: 120
      t.string :mon_cd, limit: 10
      t.string :aply_fnc_or_cd, limit: 50
      t.string :aply_fnc_or_nm, limit: 120
      t.string :anno_dgrcnt, limit: 20
      t.string :exrt_aply_std_cd, limit: 30
      t.decimal :prvs_cyfd_amt, precision: 18, scale: 2
      t.string :exca_ofcr_cd, limit: 50
      t.string :exca_ofcr_nm, limit: 100
      t.string :use_yn_cd, limit: 1, null: false, default: "Y"
      t.text :remk

      t.string :create_by, limit: 50
      t.datetime :create_time
      t.string :update_by, limit: 50
      t.datetime :update_time
    end

    add_index :std_purchase_contract_settlements, [ :purchase_contract_id, :seq_no ], unique: true, name: "index_std_pur_ctrt_stlmnt_on_contract_and_seq"
    add_index :std_purchase_contract_settlements, :use_yn_cd

    create_table :std_purchase_contract_change_histories do |t|
      t.references :purchase_contract, null: false, foreign_key: { to_table: :std_purchase_contracts }
      t.integer :seq_no, null: false
      t.string :chg_tbl_nm, limit: 100, null: false
      t.string :chg_col_nm, limit: 100, null: false
      t.text :chg_bef_conts
      t.text :chg_aft_conts
      t.string :regr_cd, limit: 50
      t.datetime :chg_date

      t.string :create_by, limit: 50
      t.datetime :create_time
      t.string :update_by, limit: 50
      t.datetime :update_time
    end

    add_index :std_purchase_contract_change_histories, [ :purchase_contract_id, :seq_no ], unique: true, name: "index_std_pur_ctrt_hist_on_contract_and_seq"
    add_index :std_purchase_contract_change_histories, [ :purchase_contract_id, :chg_date ], name: "index_std_pur_ctrt_hist_on_contract_and_date"
  end
end
