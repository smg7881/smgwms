class CreateStdOperationTables < ActiveRecord::Migration[8.1]
  def change
    create_table :std_workplaces do |t|
      t.string :corp_cd, limit: 20, null: false
      t.string :workpl_cd, limit: 20, null: false
      t.string :upper_workpl_cd, limit: 20
      t.string :dept_cd, limit: 50, null: false
      t.string :workpl_nm, limit: 120, null: false
      t.string :workpl_sctn_cd, limit: 50, null: false
      t.string :capa_spec_unit_cd, limit: 30
      t.decimal :max_capa, precision: 14, scale: 3
      t.decimal :adpt_capa, precision: 14, scale: 3
      t.string :dimem_spec_unit_cd, limit: 30
      t.decimal :dimem, precision: 14, scale: 3
      t.string :wm_yn_cd, limit: 1, null: false, default: "N"
      t.string :bzac_cd, limit: 20
      t.string :ctry_cd, limit: 10
      t.string :zip_cd, limit: 20
      t.string :addr_cd, limit: 300
      t.string :dtl_addr_cd, limit: 300
      t.string :use_yn_cd, limit: 1, null: false, default: "Y"
      t.text :remk_cd
      t.string :create_by, limit: 50
      t.datetime :create_time
      t.string :update_by, limit: 50
      t.datetime :update_time
    end
    add_index :std_workplaces, :workpl_cd, unique: true
    add_index :std_workplaces, :corp_cd
    add_index :std_workplaces, :workpl_nm
    add_index :std_workplaces, :use_yn_cd

    create_table :std_regions do |t|
      t.string :corp_cd, limit: 20, null: false
      t.string :regn_cd, limit: 10, null: false
      t.string :regn_nm_cd, limit: 120, null: false
      t.string :regn_eng_nm_cd, limit: 120, null: false
      t.string :upper_regn_cd, limit: 10
      t.string :rmk_cd, limit: 500
      t.string :use_yn_cd, limit: 1, null: false, default: "Y"
      t.string :create_by, limit: 50
      t.datetime :create_time
      t.string :update_by, limit: 50
      t.datetime :update_time
    end
    add_index :std_regions, :regn_cd, unique: true
    add_index :std_regions, :corp_cd
    add_index :std_regions, :regn_nm_cd
    add_index :std_regions, :use_yn_cd

    create_table :std_zip_codes do |t|
      t.string :ctry_cd, limit: 10, null: false
      t.string :zipcd, limit: 20, null: false
      t.integer :seq_no, null: false, default: 1
      t.string :zipaddr, limit: 300
      t.string :sido, limit: 80
      t.string :sgng, limit: 80
      t.string :eupdiv, limit: 80
      t.string :use_yn_cd, limit: 1, null: false, default: "Y"
      t.string :create_by, limit: 50
      t.datetime :create_time
      t.string :update_by, limit: 50
      t.datetime :update_time
    end
    add_index :std_zip_codes, [ :ctry_cd, :zipcd, :seq_no ], unique: true
    add_index :std_zip_codes, :zipcd
    add_index :std_zip_codes, :use_yn_cd

    create_table :std_region_zip_mappings do |t|
      t.string :regn_cd, limit: 10, null: false
      t.string :ctry_cd, limit: 10, null: false
      t.string :zipcd, limit: 20, null: false
      t.integer :seq_no, null: false, default: 1
      t.integer :sort_seq, null: false, default: 0
      t.string :create_by, limit: 50
      t.datetime :create_time
      t.string :update_by, limit: 50
      t.datetime :update_time
    end
    add_index :std_region_zip_mappings, [ :regn_cd, :ctry_cd, :zipcd, :seq_no ], unique: true, name: "index_std_region_zip_map_unique"
    add_index :std_region_zip_mappings, [ :regn_cd, :sort_seq ], name: "index_std_region_zip_map_on_regn_and_sort"

    create_table :std_countries do |t|
      t.string :ctry_cd, limit: 10, null: false
      t.string :ctry_nm, limit: 120, null: false
      t.string :ctry_eng_nm, limit: 120, null: false
      t.string :ctry_ar_cd, limit: 30, null: false
      t.string :ctry_telno, limit: 20
      t.string :corp_cd, limit: 20
      t.string :corp_nm, limit: 120
      t.string :use_yn_cd, limit: 1, null: false, default: "Y"
      t.string :create_by, limit: 50
      t.datetime :create_time
      t.string :update_by, limit: 50
      t.datetime :update_time
    end
    add_index :std_countries, :ctry_cd, unique: true
    add_index :std_countries, :ctry_nm
    add_index :std_countries, :use_yn_cd

    create_table :std_holidays do |t|
      t.string :ctry_cd, limit: 10, null: false
      t.date :ymd, null: false
      t.string :holiday_nm_cd, limit: 120, null: false
      t.string :sat_yn_cd, limit: 1, null: false, default: "N"
      t.string :sunday_yn_cd, limit: 1, null: false, default: "N"
      t.string :clsdy_yn_cd, limit: 1, null: false, default: "N"
      t.string :asmt_holday_yn_cd, limit: 1, null: false, default: "N"
      t.string :event_day_yn_cd, limit: 1, null: false, default: "N"
      t.string :rmk_cd, limit: 500
      t.string :use_yn_cd, limit: 1, null: false, default: "Y"
      t.string :create_by, limit: 50
      t.datetime :create_time
      t.string :update_by, limit: 50
      t.datetime :update_time
    end
    add_index :std_holidays, [ :ctry_cd, :ymd ], unique: true
    add_index :std_holidays, :ymd
    add_index :std_holidays, :use_yn_cd

    create_table :std_approvals do |t|
      t.string :corp_cd, limit: 20, null: false
      t.string :corp_nm, limit: 120
      t.string :menu_cd, limit: 30, null: false
      t.string :menu_nm, limit: 120, null: false
      t.string :table_cd, limit: 60
      t.string :col1_cd, limit: 60
      t.string :col2_cd, limit: 60
      t.string :col3_cd, limit: 60
      t.string :col4_cd, limit: 60
      t.string :col5_cd, limit: 60
      t.string :asmt_apver_yn, limit: 1, null: false, default: "Y"
      t.string :chrg_apver, limit: 50
      t.string :not_asmt_apver_resp, limit: 50
      t.string :apv_type_cd, limit: 30
      t.string :apv_delegt_yn, limit: 1, null: false, default: "N"
      t.string :apv_delegate, limit: 50
      t.string :rmk, limit: 500
      t.string :use_yn, limit: 1, null: false, default: "Y"
      t.string :create_by, limit: 50
      t.datetime :create_time
      t.string :update_by, limit: 50
      t.datetime :update_time
    end
    add_index :std_approvals, [ :corp_cd, :menu_cd ], unique: true
    add_index :std_approvals, :menu_nm
    add_index :std_approvals, :use_yn

    create_table :std_approval_requests do |t|
      t.string :apv_req_no, limit: 20, null: false
      t.string :corp_cd, limit: 20, null: false
      t.string :menu_cd, limit: 30
      t.string :menu_nm, limit: 120, null: false
      t.string :apv_reqr, limit: 50, null: false
      t.string :asmt_apver, limit: 50, null: false
      t.string :apver_chg, limit: 50
      t.string :user_cd, limit: 50
      t.text :apv_req_conts
      t.datetime :apv_req_ymd
      t.text :apv_opi
      t.datetime :apv_apv_ymd
      t.string :apv_stat_cd, limit: 30, null: false, default: "REQUESTED"
      t.string :apv_type_cd, limit: 30
      t.string :use_yn, limit: 1, null: false, default: "Y"
      t.string :create_by, limit: 50
      t.datetime :create_time
      t.string :update_by, limit: 50
      t.datetime :update_time
    end
    add_index :std_approval_requests, :apv_req_no, unique: true
    add_index :std_approval_requests, :apv_req_ymd
    add_index :std_approval_requests, :apv_stat_cd
    add_index :std_approval_requests, :apv_reqr
    add_index :std_approval_requests, :asmt_apver
  end
end
