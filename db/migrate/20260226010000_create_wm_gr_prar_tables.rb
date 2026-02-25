class CreateWmGrPrarTables < ActiveRecord::Migration[8.1]
  def change
    # 입고예정 헤더 테이블
    create_table :tb_wm02001, id: false do |t|
      t.string :gr_prar_no,      limit: 20,  null: false, comment: "입고예정번호(PK)"
      t.string :workpl_cd,       limit: 20,  null: false, comment: "작업장코드"
      t.string :corp_cd,         limit: 10,  null: false, comment: "법인코드"
      t.string :cust_cd,         limit: 20,  null: false, comment: "고객코드"
      t.string :gr_type_cd,      limit: 10,               comment: "입고유형코드(공통152)"
      t.string :ord_reason_cd,   limit: 10,               comment: "오더사유코드(공통87)"
      t.string :gr_stat_cd,      limit: 10,  null: false, default: "10", comment: "입고상태(공통153):10미입고,20처리,30확정,40취소"
      t.string :prar_ymd,        limit: 8,                comment: "입고예정일자(YYYYMMDD)"
      t.string :gr_ymd,          limit: 8,                comment: "입고일자(YYYYMMDD)"
      t.string :gr_hms,          limit: 6,                comment: "입고시간(HHMMSS)"
      t.string :ord_no,          limit: 30,               comment: "오더번호"
      t.string :rel_gi_ord_no,   limit: 30,               comment: "관련출고오더번호"
      t.string :exec_ord_no,     limit: 30,               comment: "실행오더번호"
      t.string :dptar_type_cd,   limit: 10,               comment: "출발지유형코드"
      t.string :dptar_cd,        limit: 20,               comment: "출발지코드"
      t.string :car_no,          limit: 20,               comment: "차량번호"
      t.string :driver_nm,       limit: 50,               comment: "기사명"
      t.string :driver_telno,    limit: 20,               comment: "기사전화번호"
      t.string :transco_cd,      limit: 20,               comment: "운송사코드"
      t.string :rmk,             limit: 500,              comment: "비고"
      t.string :create_by,       limit: 50,               comment: "생성자"
      t.datetime :create_time,                            comment: "생성일시"
      t.string :update_by,       limit: 50,               comment: "수정자"
      t.datetime :update_time,                            comment: "수정일시"
    end

    execute "ALTER TABLE tb_wm02001 ADD PRIMARY KEY (gr_prar_no)" rescue nil

    add_index :tb_wm02001, :workpl_cd
    add_index :tb_wm02001, :cust_cd
    add_index :tb_wm02001, :gr_stat_cd
    add_index :tb_wm02001, :prar_ymd
    add_index :tb_wm02001, :gr_ymd

    # 입고예정 상세 테이블
    create_table :tb_wm02002, id: false do |t|
      t.string  :gr_prar_no,       limit: 20,  null: false, comment: "입고예정번호(복합PK)"
      t.integer :lineno,                        null: false, comment: "라인번호(복합PK)"
      t.string  :item_cd,          limit: 30,  null: false, comment: "아이템코드"
      t.string  :item_nm,          limit: 200,              comment: "아이템명(비정규화)"
      t.string  :unit_cd,          limit: 10,               comment: "단위코드"
      t.decimal :gr_prar_qty,      precision: 18, scale: 3, comment: "입고예정수량"
      t.string  :gr_loc_cd,        limit: 20,               comment: "입고로케이션코드"
      t.decimal :gr_qty,           precision: 18, scale: 3, default: 0, comment: "입고물량"
      t.decimal :gr_rslt_qty,      precision: 18, scale: 3, default: 0, comment: "입고실적물량(누적)"
      t.string  :gr_ymd,           limit: 8,                comment: "입고일자"
      t.string  :gr_hms,           limit: 6,                comment: "입고시간"
      t.string  :gr_stat_cd,       limit: 10,  default: "10", comment: "입고상태"
      t.string  :stock_attr_col01, limit: 100,              comment: "재고속성01"
      t.string  :stock_attr_col02, limit: 100,              comment: "재고속성02"
      t.string  :stock_attr_col03, limit: 100,              comment: "재고속성03"
      t.string  :stock_attr_col04, limit: 100,              comment: "재고속성04(날짜YYYY-MM-DD)"
      t.string  :stock_attr_col05, limit: 100,              comment: "재고속성05"
      t.string  :stock_attr_col06, limit: 100,              comment: "재고속성06"
      t.string  :stock_attr_col07, limit: 100,              comment: "재고속성07"
      t.string  :stock_attr_col08, limit: 100,              comment: "재고속성08"
      t.string  :stock_attr_col09, limit: 100,              comment: "재고속성09"
      t.string  :stock_attr_col10, limit: 100,              comment: "재고속성10"
      t.string  :rmk,              limit: 500,              comment: "비고"
      t.string  :create_by,        limit: 50,               comment: "생성자"
      t.datetime :create_time,                              comment: "생성일시"
      t.string  :update_by,        limit: 50,               comment: "수정자"
      t.datetime :update_time,                              comment: "수정일시"
    end

    execute "ALTER TABLE tb_wm02002 ADD PRIMARY KEY (gr_prar_no, lineno)" rescue nil

    add_index :tb_wm02002, :item_cd
    add_index :tb_wm02002, :gr_stat_cd
  end
end
