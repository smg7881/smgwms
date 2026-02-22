class CreateStdMasterDataManagementTables < ActiveRecord::Migration[8.1]
  def change
    create_table :std_corporations do |t|
      t.string :corp_cd, limit: 20, null: false
      t.string :corp_nm, limit: 120, null: false
      t.string :indstype_cd, limit: 120, null: false
      t.string :bizcond_cd, limit: 120, null: false
      t.string :rptr_nm_cd, limit: 120, null: false
      t.string :compreg_slip_cd, limit: 30
      t.string :upper_corp_cd, limit: 20
      t.string :zip_cd, limit: 20
      t.string :addr_cd, limit: 300
      t.string :dtl_addr_cd, limit: 300
      t.string :vat_sctn_cd, limit: 30
      t.string :use_yn_cd, limit: 1, null: false, default: "Y"
      add_audit_columns(t)
    end
    add_index :std_corporations, :corp_cd, unique: true
    add_index :std_corporations, :corp_nm
    add_index :std_corporations, :use_yn_cd

    create_table :std_corporation_countries do |t|
      t.string :corp_cd, limit: 20, null: false
      t.integer :seq, null: false
      t.string :ctry_cd, limit: 10, null: false
      t.string :aply_mon_unit_cd, limit: 20
      t.string :timezone_cd, limit: 60
      t.string :std_time, limit: 40
      t.string :summer_time, limit: 40
      t.string :sys_lang_slc, limit: 20
      t.decimal :vat_rt, precision: 10, scale: 3
      t.string :rpt_yn_cd, limit: 1, null: false, default: "N"
      t.string :use_yn_cd, limit: 1, null: false, default: "Y"
      add_audit_columns(t)
    end
    add_index :std_corporation_countries, [ :corp_cd, :seq ], unique: true
    add_index :std_corporation_countries, [ :corp_cd, :ctry_cd ]
    add_index :std_corporation_countries, :use_yn_cd

    create_table :std_corporation_histories do |t|
      t.string :corp_cd, limit: 20, null: false
      t.integer :hist_seq, null: false
      t.string :source_kind, limit: 20, null: false
      t.string :source_key, limit: 120
      t.string :changed_col_nm, limit: 120, null: false
      t.text :before_value
      t.text :after_value
      t.string :changed_by, limit: 50
      t.datetime :changed_at
      add_audit_columns(t)
    end
    add_index :std_corporation_histories, [ :corp_cd, :hist_seq ], unique: true, name: "index_std_corp_hist_on_corp_and_seq"
    add_index :std_corporation_histories, [ :corp_cd, :changed_at ], name: "index_std_corp_hist_on_corp_and_changed_at"

    create_table :std_business_certificates do |t|
      t.string :bzac_cd, limit: 20, null: false
      t.string :bzac_nm, limit: 200
      t.string :compreg_slip, limit: 30, null: false
      t.string :bizman_yn_cd, limit: 20, null: false
      t.string :store_nm_cd, limit: 200, null: false
      t.string :rptr_nm_cd, limit: 120, null: false
      t.string :corp_reg_no_cd, limit: 50
      t.string :bizcond_cd, limit: 120
      t.string :indstype_cd, limit: 120
      t.string :dup_bzac_yn_cd, limit: 1, null: false, default: "N"
      t.string :zip_cd, limit: 20
      t.string :zipaddr_cd, limit: 300
      t.string :dtl_addr_cd, limit: 300
      t.text :rmk
      t.date :clbiz_ymd
      t.string :attached_file_nm, limit: 255
      t.string :use_yn_cd, limit: 1, null: false, default: "Y"
      add_audit_columns(t)
    end
    add_index :std_business_certificates, :bzac_cd, unique: true
    add_index :std_business_certificates, :compreg_slip
    add_index :std_business_certificates, :use_yn_cd

    create_table :std_goods do |t|
      t.string :goods_cd, limit: 20, null: false
      t.string :goods_nm, limit: 200, null: false
      t.string :hatae_cd, limit: 30
      t.string :item_grp_cd, limit: 30
      t.string :item_cd, limit: 30
      t.string :hwajong_cd, limit: 30
      t.string :hwajong_grp_cd, limit: 30
      t.string :rmk_cd, limit: 500
      t.string :use_yn_cd, limit: 1, null: false, default: "Y"
      add_audit_columns(t)
    end
    add_index :std_goods, :goods_cd, unique: true
    add_index :std_goods, :goods_nm
    add_index :std_goods, :use_yn_cd

    create_table :std_user_favorite_groups do |t|
      t.string :user_id_code, limit: 16, null: false
      t.string :group_nm, limit: 100, null: false
      t.string :use_yn, limit: 1, null: false, default: "Y"
      add_audit_columns(t)
    end
    add_index :std_user_favorite_groups, [ :user_id_code, :group_nm ], unique: true, name: "index_std_favor_groups_on_user_and_name"
    add_index :std_user_favorite_groups, :use_yn

    create_table :std_user_favorites do |t|
      t.string :user_id_code, limit: 16, null: false
      t.string :menu_cd, limit: 20, null: false
      t.string :menu_nm, limit: 100
      t.string :user_favor_menu_grp, limit: 100
      t.integer :sort_seq, null: false, default: 0
      t.string :use_yn, limit: 1, null: false, default: "Y"
      add_audit_columns(t)
    end
    add_index :std_user_favorites, [ :user_id_code, :menu_cd ], unique: true, name: "index_std_favorites_on_user_and_menu"
    add_index :std_user_favorites, [ :user_id_code, :user_favor_menu_grp ], name: "index_std_favorites_on_user_and_group"
    add_index :std_user_favorites, :use_yn

    create_table :std_interface_infos do |t|
      t.string :corp_cd, limit: 20, null: false
      t.string :if_cd, limit: 11, null: false
      t.string :if_meth_cd, limit: 30, null: false
      t.string :if_sctn_cd, limit: 30, null: false
      t.string :if_nm_cd, limit: 150, null: false
      t.string :send_sys_cd, limit: 30
      t.string :rcv_sys_cd, limit: 30
      t.string :rcv_sctn_cd, limit: 30
      t.string :use_yn_cd, limit: 1, null: false, default: "Y"
      t.string :if_bzac_cd, limit: 20
      t.string :bzac_nm, limit: 200
      t.string :bzac_sys_nm_cd, limit: 150
      t.text :if_desc_cd
      add_audit_columns(t)
    end
    add_index :std_interface_infos, :if_cd, unique: true
    add_index :std_interface_infos, [ :corp_cd, :if_nm_cd ]
    add_index :std_interface_infos, :use_yn_cd

    create_table :std_reserved_jobs do |t|
      t.string :sys_sctn_cd, limit: 30, null: false
      t.string :rsv_work_no, limit: 20, null: false
      t.string :rel_menu_cd, limit: 20
      t.string :rel_menu_nm, limit: 150
      t.string :rsv_work_nm_cd, limit: 150, null: false
      t.string :rsv_work_desc_cd, limit: 300, null: false
      t.string :rel_pgm_cd, limit: 60
      t.string :rel_pgm_nm, limit: 150
      t.string :pgm_sctn_cd, limit: 30
      t.string :rsv_work_cycle_cd, limit: 30, null: false
      t.integer :hms_unit_min
      t.text :rmk_cd
      t.string :use_yn_cd, limit: 1, null: false, default: "Y"
      add_audit_columns(t)
    end
    add_index :std_reserved_jobs, :rsv_work_no, unique: true
    add_index :std_reserved_jobs, [ :sys_sctn_cd, :rsv_work_nm_cd ]
    add_index :std_reserved_jobs, :use_yn_cd

    create_table :std_exchange_rates do |t|
      t.string :ctry_cd, limit: 10, null: false
      t.string :fnc_or_cd, limit: 20, null: false
      t.date :std_ymd, null: false
      t.string :anno_dgrcnt, limit: 20, null: false
      t.string :mon_cd, limit: 20, null: false
      t.decimal :cash_buy, precision: 18, scale: 6
      t.decimal :cash_sell, precision: 18, scale: 6
      t.decimal :sendmoney_sndg, precision: 18, scale: 6
      t.decimal :sendmoney_rcvng, precision: 18, scale: 6
      t.decimal :tc_buy, precision: 18, scale: 6
      t.decimal :fcur_check_sell, precision: 18, scale: 6
      t.decimal :tradg_std_rt, precision: 18, scale: 6
      t.decimal :convmoney_rt, precision: 18, scale: 6
      t.decimal :usd_conv_rt, precision: 18, scale: 6
      t.string :if_yn_cd, limit: 1, null: false, default: "N"
      t.string :use_yn_cd, limit: 1, null: false, default: "Y"
      add_audit_columns(t)
    end
    add_index :std_exchange_rates, [ :ctry_cd, :fnc_or_cd, :std_ymd, :anno_dgrcnt, :mon_cd ], unique: true, name: "index_std_exch_rate_business_key"
    add_index :std_exchange_rates, [ :ctry_cd, :std_ymd ]
    add_index :std_exchange_rates, :use_yn_cd
  end

  private
    def add_audit_columns(table)
      table.string :create_by, limit: 50
      table.datetime :create_time
      table.string :update_by, limit: 50
      table.datetime :update_time
    end
end
