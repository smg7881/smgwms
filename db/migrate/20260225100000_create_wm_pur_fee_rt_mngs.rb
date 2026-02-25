class CreateWmPurFeeRtMngs < ActiveRecord::Migration[8.1]
  def change
    create_table :tb_wm06001, id: false do |t|
      t.string :wrhs_exca_fee_rt_no, limit: 20, null: false, primary_key: true, comment: '창고정산요율번호'
      t.string :corp_cd, limit: 10, null: false, comment: '법인코드'
      t.string :work_pl_cd, limit: 20, null: false, comment: '작업장코드'
      t.string :sell_buy_sctn_cd, limit: 10, null: false, default: '20', comment: '매출입구분코드(20:매입)'
      t.string :ctrt_cprtco_cd, limit: 20, comment: '계약협력사'
      t.string :sell_buy_attr_cd, limit: 20, comment: '매출입항목코드'
      t.string :pur_dept_cd, limit: 20, comment: '매입부서코드'
      t.string :pur_item_type, limit: 20, comment: '매입아이템유형'
      t.string :pur_item_cd, limit: 20, comment: '매입아이템'
      t.string :pur_unit_clas_cd, limit: 20, comment: '매입단위분류'
      t.string :pur_unit_cd, limit: 20, comment: '매입단위'
      t.string :use_yn, limit: 1, default: 'Y', null: false, comment: '사용여부'
      t.string :auto_yn, limit: 1, default: 'N', null: false, comment: '자동여부'
      t.string :rmk, limit: 500, comment: '비고'
      t.string :create_by, limit: 50
      t.datetime :create_time
      t.string :update_by, limit: 50
      t.datetime :update_time
    end

    create_table :tb_wm06002, id: false, primary_key: [ :wrhs_exca_fee_rt_no, :lineno ] do |t|
      t.string :wrhs_exca_fee_rt_no, limit: 20, null: false, comment: '창고정산요율번호'
      t.integer :lineno, null: false, comment: '라인번호'
      t.string :dcsn_yn, limit: 1, default: 'N', null: false, comment: '확정여부'
      t.string :aply_strt_ymd, limit: 8, null: false, comment: '적용시작일자'
      t.string :aply_end_ymd, limit: 8, null: false, comment: '적용종료일자'
      t.decimal :aply_uprice, precision: 18, scale: 5, null: false, default: 0, comment: '적용단가'
      t.string :cur_cd, limit: 10, null: false, comment: '통화코드'
      t.decimal :std_work_qty, precision: 18, scale: 5, null: false, default: 0, comment: '기준작업물량'
      t.decimal :aply_strt_qty, precision: 18, scale: 5, comment: '적용시작물량'
      t.decimal :aply_end_qty, precision: 18, scale: 5, comment: '적용종료물량'
      t.string :rmk, limit: 500, comment: '비고'
      t.string :create_by, limit: 50
      t.datetime :create_time
      t.string :update_by, limit: 50
      t.datetime :update_time
    end
  end
end
