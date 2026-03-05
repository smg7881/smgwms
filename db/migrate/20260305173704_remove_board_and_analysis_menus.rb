class RemoveBoardAndAnalysisMenus < ActiveRecord::Migration[8.0]
  def change
    # Remove from AdmMenu
    execute <<-SQL
      DELETE FROM adm_menus WHERE menu_cd IN ('POST', 'POST_LIST', 'POST_NEW', 'ANALYSIS', 'REPORTS');
    SQL

    # Drop posts and reports table if they exist
    drop_table :posts, if_exists: true
    drop_table :reports, if_exists: true
  end
end
