class CreateStdFinancialInstitutions < ActiveRecord::Migration[8.1]
  def change
    create_table :std_financial_institutions do |t|
      t.string :fnc_or_cd, limit: 20, null: false
      t.string :fnc_or_nm, limit: 120, null: false
      t.string :fnc_or_eng_nm, limit: 120, null: false
      t.string :ctry_cd, limit: 10
      t.string :ctry_nm, limit: 120
      t.string :use_yn_cd, limit: 1, null: false, default: "Y"
      t.string :create_by, limit: 50
      t.datetime :create_time
      t.string :update_by, limit: 50
      t.datetime :update_time
    end

    add_index :std_financial_institutions, :fnc_or_cd, unique: true
    add_index :std_financial_institutions, :fnc_or_nm
    add_index :std_financial_institutions, :ctry_cd
    add_index :std_financial_institutions, :use_yn_cd
  end
end
