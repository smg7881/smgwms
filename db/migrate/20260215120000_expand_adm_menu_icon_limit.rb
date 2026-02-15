class ExpandAdmMenuIconLimit < ActiveRecord::Migration[8.1]
  def change
    change_column :adm_menus, :menu_icon, :string, limit: 50
  end
end
