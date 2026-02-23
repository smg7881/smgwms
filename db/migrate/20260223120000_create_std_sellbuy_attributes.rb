class CreateStdSellbuyAttributes < ActiveRecord::Migration[8.1]
  def change
    create_table :std_sellbuy_attributes do |t|
      t.string :corp_cd, limit: 20, null: false
      t.string :sellbuy_sctn_cd, limit: 30
      t.string :sellbuy_attr_cd, limit: 20, null: false
      t.string :sellbuy_attr_nm, limit: 150, null: false
      t.string :rdtn_nm, limit: 120, null: false
      t.string :sellbuy_attr_eng_nm, limit: 150, null: false
      t.string :upper_sellbuy_attr_cd, limit: 20

      t.string :sell_yn_cd, limit: 1, null: false, default: "N"
      t.string :pur_yn_cd, limit: 1, null: false, default: "N"
      t.string :tran_yn_cd, limit: 1, null: false, default: "N"
      t.string :fis_air_yn_cd, limit: 1, null: false, default: "N"
      t.string :strg_yn_cd, limit: 1, null: false, default: "N"
      t.string :cgwrk_yn_cd, limit: 1, null: false, default: "N"
      t.string :fis_shpng_yn_cd, limit: 1, null: false, default: "N"
      t.string :dc_extr_yn_cd, limit: 1, null: false, default: "N"
      t.string :tax_payfor_yn_cd, limit: 1, null: false, default: "N"
      t.string :lumpsum_yn_cd, limit: 1, null: false, default: "N"
      t.string :dcnct_reg_pms_yn_cd, limit: 1, null: false, default: "N"

      t.string :sell_dr_acct_cd, limit: 30
      t.string :sell_cr_acct_cd, limit: 30
      t.string :pur_dr_acct_cd, limit: 30
      t.string :pur_cr_acct_cd, limit: 30
      t.string :sys_sctn_cd, limit: 30
      t.string :ndcsn_sell_cr_acct_cd, limit: 30
      t.string :ndcsn_cost_dr_acct_cd, limit: 30

      t.string :rmk_cd, limit: 500
      t.string :use_yn_cd, limit: 1, null: false, default: "Y"

      t.string :create_by, limit: 50
      t.datetime :create_time
      t.string :update_by, limit: 50
      t.datetime :update_time
    end

    add_index :std_sellbuy_attributes, :sellbuy_attr_cd, unique: true
    add_index :std_sellbuy_attributes, :corp_cd
    add_index :std_sellbuy_attributes, :use_yn_cd
  end
end
