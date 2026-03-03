class AddDetailFieldsToStdZipCodes < ActiveRecord::Migration[8.1]
  def change
    change_table :std_zip_codes, bulk: true do |t|
      t.string :addr_ri, limit: 80
      t.string :iland_san, limit: 10
      t.string :san_houseno, limit: 20
      t.string :apt_bild_nm, limit: 120
      t.string :strt_houseno_wek, limit: 20
      t.string :strt_houseno_mnst, limit: 20
      t.string :end_houseno_wek, limit: 20
      t.string :end_houseno_mnst, limit: 20
      t.string :dong_rng_strt, limit: 20
      t.string :dong_houseno_end, limit: 20
      t.date :chg_ymd
    end
  end
end
