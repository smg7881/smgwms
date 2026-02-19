class CreateAdmMenuLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :adm_menu_logs do |t|
      t.string :user_id
      t.string :user_name
      t.string :menu_id
      t.string :menu_name
      t.string :menu_path
      t.datetime :access_time, null: false
      t.string :ip_address
      t.text :user_agent
      t.string :session_id
      t.string :referrer

      t.timestamps
    end

    add_index :adm_menu_logs, :access_time
    add_index :adm_menu_logs, :user_id
    add_index :adm_menu_logs, :menu_id
    add_index :adm_menu_logs, :session_id
  end
end
