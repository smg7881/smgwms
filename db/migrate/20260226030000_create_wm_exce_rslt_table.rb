class CreateWmExceRsltTable < ActiveRecord::Migration[8.1]
  def change
    create_table :tb_wm05001, id: false do |t|
      t.string  :exce_rslt_no,         limit: 10,  null: false, comment: "실행실적번호(PK)"
      t.string  :op_rslt_mngt_no,      limit: 20,               comment: "운영실적관리번호(=입고예정번호)"
      t.integer :op_rslt_mngt_no_seq,                           comment: "운영실적관리번호순번(=라인번호)"
      t.string  :exce_rslt_type,       limit: 10,               comment: "실행실적유형(공통113):DP입고,CC취소"
      t.string  :workpl_cd,            limit: 20,               comment: "작업장코드"
      t.string  :corp_cd,              limit: 10,               comment: "법인코드"
      t.string  :cust_cd,              limit: 20,               comment: "고객코드"
      t.string  :item_cd,              limit: 30,               comment: "아이템코드"
      t.string  :from_loc,             limit: 20,               comment: "출발 로케이션"
      t.string  :to_loc,               limit: 20,               comment: "입고 로케이션"
      t.decimal :rslt_qty,             precision: 18, scale: 3, comment: "실적물량"
      t.decimal :rslt_cbm,             precision: 18, scale: 5, comment: "실적CBM"
      t.decimal :rslt_total_wt,        precision: 18, scale: 5, comment: "실적총중량"
      t.decimal :rslt_net_wt,          precision: 18, scale: 5, comment: "실적순중량"
      t.string  :basis_unit_cls,       limit: 10,               comment: "기본단위분류"
      t.string  :basis_unit_cd,        limit: 10,               comment: "기본단위코드"
      t.string  :ord_no,               limit: 30,               comment: "오더번호"
      t.string  :exec_ord_no,          limit: 30,               comment: "실행오더번호"
      t.string  :exce_rslt_ymd,        limit: 8,                comment: "실행실적일자(YYYYMMDD)"
      t.string  :exce_rslt_hms,        limit: 6,                comment: "실행실적시간(HHMMSS)"
      t.string  :stock_attr_no,        limit: 10,               comment: "재고속성번호"
      t.string  :stock_attr_col01,     limit: 100,              comment: "재고속성01"
      t.string  :stock_attr_col02,     limit: 100,              comment: "재고속성02"
      t.string  :stock_attr_col03,     limit: 100,              comment: "재고속성03"
      t.string  :stock_attr_col04,     limit: 100,              comment: "재고속성04"
      t.string  :stock_attr_col05,     limit: 100,              comment: "재고속성05"
      t.string  :stock_attr_col06,     limit: 100,              comment: "재고속성06"
      t.string  :stock_attr_col07,     limit: 100,              comment: "재고속성07"
      t.string  :stock_attr_col08,     limit: 100,              comment: "재고속성08"
      t.string  :stock_attr_col09,     limit: 100,              comment: "재고속성09"
      t.string  :stock_attr_col10,     limit: 100,              comment: "재고속성10"
      t.string  :create_by,            limit: 50,               comment: "생성자"
      t.datetime :create_time,                                  comment: "생성일시"
      t.string  :update_by,            limit: 50,               comment: "수정자"
      t.datetime :update_time,                                  comment: "수정일시"
    end

    execute "ALTER TABLE tb_wm05001 ADD PRIMARY KEY (exce_rslt_no)" rescue nil

    add_index :tb_wm05001, :op_rslt_mngt_no
    add_index :tb_wm05001, :exce_rslt_type
    add_index :tb_wm05001, :exce_rslt_ymd
  end
end
