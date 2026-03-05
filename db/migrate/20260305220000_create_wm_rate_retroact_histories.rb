class CreateWmRateRetroactHistories < ActiveRecord::Migration[8.1]
  def change
    create_table :wm_rate_retroact_histories do |t|
      t.string :exce_rslt_no, limit: 30, null: false, comment: "실행실적번호"
      t.string :op_rslt_mngt_no, limit: 20, comment: "운영실적관리번호"
      t.integer :op_rslt_mngt_no_seq, comment: "운영실적라인번호"
      t.string :rslt_std_ymd, limit: 8, null: false, comment: "실적기준일자"

      t.string :work_pl_cd, limit: 20, comment: "작업장코드"
      t.string :sell_buy_sctn_cd, limit: 10, comment: "매출입구분코드"
      t.string :bzac_cd, limit: 20, comment: "거래처코드"
      t.string :sell_buy_attr_cd, limit: 20, comment: "매출입항목코드"

      t.decimal :rslt_qty, precision: 18, scale: 5, default: 0, null: false, comment: "실적물량"
      t.decimal :base_uprice, precision: 18, scale: 5, default: 0, null: false, comment: "기존적용단가"
      t.decimal :base_amt, precision: 18, scale: 5, default: 0, null: false, comment: "기존실적금액"
      t.decimal :rtac_uprice, precision: 18, scale: 5, default: 0, null: false, comment: "소급단가"
      t.decimal :rtac_amt, precision: 18, scale: 5, default: 0, null: false, comment: "소급금액"
      t.decimal :uprice_diff, precision: 18, scale: 5, default: 0, null: false, comment: "단가차이"
      t.decimal :amt_diff, precision: 18, scale: 5, default: 0, null: false, comment: "금액차이"
      t.string :cur_cd, limit: 10, default: "KRW", null: false, comment: "통화코드"

      t.string :ref_fee_rt_no, limit: 20, comment: "참조요율번호"
      t.integer :ref_fee_rt_lineno, comment: "참조요율라인번호"
      t.string :prcs_sctn_cd, limit: 1, default: "C", null: false, comment: "처리구분(C/U)"
      t.string :rtac_proc_stat_cd, limit: 20, default: "RTAC", null: false, comment: "소급처리상태코드"

      t.string :create_by, limit: 50
      t.datetime :create_time
      t.string :update_by, limit: 50
      t.datetime :update_time
    end

    add_index :wm_rate_retroact_histories, :exce_rslt_no, unique: true, name: "idx_wm_rate_retroact_histories_exce"
    add_index :wm_rate_retroact_histories, [ :rslt_std_ymd, :work_pl_cd ], name: "idx_wm_rate_retroact_histories_date_workpl"
  end
end
