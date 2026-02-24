class AddSysSctnAndRmkToAdmCodeHeaders < ActiveRecord::Migration[8.1]
  def change
    add_column :adm_code_headers, :sys_sctn_cd, :string, limit: 30
    add_column :adm_code_headers, :rmk, :string, limit: 500
  end
end
