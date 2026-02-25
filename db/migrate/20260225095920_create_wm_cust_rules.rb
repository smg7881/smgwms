class CreateWmCustRules < ActiveRecord::Migration[8.1]
  def change
    create_table :wm_cust_rules do |t|
      t.string :workpl_cd, limit: 50, null: false, comment: "작업장코드"
      t.string :cust_cd, limit: 50, null: false, comment: "고객코드"
      t.string :inout_sctn, limit: 50, null: false, comment: "입출고구분"
      t.string :inout_type, limit: 50, null: false, comment: "입출고유형"
      t.string :rule_sctn, limit: 50, null: false, comment: "RULE 구분"
      t.string :aply_yn, limit: 1, default: "Y", null: false, comment: "적용여부"
      t.string :remark, limit: 500, comment: "비고"

      t.string :create_by, limit: 50
      t.datetime :create_time
      t.string :update_by, limit: 50
      t.datetime :update_time
    end

    add_index :wm_cust_rules, [ :workpl_cd, :cust_cd, :inout_sctn, :inout_type, :rule_sctn ], unique: true, name: 'idx_wm_cust_rules_unique'
  end
end
