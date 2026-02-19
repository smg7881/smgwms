class CreateAdmLoginHistories < ActiveRecord::Migration[8.1]
  def change
    create_table :adm_login_histories do |t|
      t.string :user_id_code, limit: 16
      t.string :user_nm, limit: 20
      t.datetime :login_time, null: false
      t.boolean :login_success, null: false
      t.string :ip_address, limit: 45
      t.string :user_agent, limit: 500
      t.string :browser, limit: 100
      t.string :os, limit: 100
      t.string :failure_reason, limit: 200
    end

    add_index :adm_login_histories, :user_id_code
    add_index :adm_login_histories, :login_time
    add_index :adm_login_histories, :login_success
    add_index :adm_login_histories, [ :user_id_code, :login_time ]
  end
end
