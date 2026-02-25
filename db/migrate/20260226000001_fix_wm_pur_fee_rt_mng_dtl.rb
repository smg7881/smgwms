class FixWmPurFeeRtMngDtl < ActiveRecord::Migration[8.1]
  def change
    drop_table :tb_wm06002 rescue nil

    create_table :tb_wm06002 do |t|
      t.string :wrhs_exca_fee_rt_no, limit: 20, null: false, comment: '창고정산요율번호'
      t.integer :lineno, null: false, default: 1, comment: '라인번호'
      t.string :dcsn_yn, limit: 1, default: 'N', null: false, comment: '확정여부'
      t.string :aply_strt_ymd, limit: 8, null: false, comment: '적용시작일자'
      t.string :aply_end_ymd, limit: 8, null: false, comment: '적용종료일자'
      t.decimal :aply_uprice, precision: 18, scale: 5, null: false, default: 0, comment: '적용단가'
      t.string :cur_cd, limit: 10, null: false, default: 'KRW', comment: '통화코드'
      t.decimal :std_work_qty, precision: 18, scale: 5, null: false, default: 0, comment: '기준작업물량'
      t.decimal :aply_strt_qty, precision: 18, scale: 5, comment: '적용시작물량'
      t.decimal :aply_end_qty, precision: 18, scale: 5, comment: '적용종료물량'
      t.string :rmk, limit: 500, comment: '비고'
      t.string :create_by, limit: 50
      t.datetime :create_time
      t.string :update_by, limit: 50
      t.datetime :update_time
    end

    add_index :tb_wm06002, [ :wrhs_exca_fee_rt_no, :lineno ], name: 'idx_wm06002_rt_lineno'
  end
end
