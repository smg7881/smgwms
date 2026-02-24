module Om
  class OrderWorkProgressesController < ApplicationController
    def index
      @search_form = OpenStruct.new(params.fetch(:q, {}).permit(:ord_no).to_h)

      if request.format.json?
        # 실제 환경에서는 DB에서 파라미터(params[:q][:ord_no])를 기준으로 각 데이터를 조합
        ord_no = params.dig(:q, :ord_no)

        if ord_no.blank?
          return render json: { master: {}, items: [], progresses: [] }
        end

        # 1. 마스터 정보 Mock
        master_data = {
          cust_ord_no: "CUST-#{ord_no}",
          ord_no: ord_no,
          cust_ord_type_nm: [ "출고", "입고", "B2B" ].sample,
          cust_ord_ofcr: "담당자A",
          cust_tel: "010-1234-5678",
          ord_type_nm: "일반출고",
          ctrt_no: "CTRT-#{rand(100..999)}",
          ctrt_cust_nm: "계약사(주)",
          bilg_cust_nm: "청구사(주)",
          ord_req_cust_nm: "고객사(주)",
          cust_expr_yn: [ "Y", "N" ].sample,
          cls_expr_yn: [ "Y", "N" ].sample,
          retrngd_yn: "N",
          ord_stat_nm: "진행중",
          ord_cmpt_nm: "미완료"
        }

        # 2. 아이템 리스트 Mock
        items_data = (1..3).map do |i|
          {
            div_dgr_cnt: i,
            item_cd: "ITEM-#{rand(1000..9999)}",
            item_nm: "테스트 상품 #{i}",
            work_stat: [ "할당", "출고대기", "도착완료" ].sample,
            basis_cd: "EA",
            ord_qty: rand(10..100),
            ord_wgt: rand(5.0..20.0).round(2),
            ord_vol: rand(1.0..5.0).round(2),
            rslt_qty: rand(10..100),
            rslt_wgt: rand(5.0..20.0).round(2),
            rslt_vol: rand(1.0..5.0).round(2)
          }
        end

        # 3. 진행상세 Mock
        progresses_data = (1..2).map do |i|
          {
            car_no: "12가 #{rand(1000..9999)}",
            dpt_ar_nm: "전주물류센터",
            arv_ar_nm: "고객대리점",
            dpt_prar_date: (Time.current + i.days).strftime("%Y-%m-%d %H:%M"),
            dpt_date: i == 1 ? (Time.current + i.days).strftime("%Y-%m-%d %H:%M") : nil,
            arv_prar_date: (Time.current + i.days + 3.hours).strftime("%Y-%m-%d %H:%M"),
            arv_date: nil,
            gi: i == 1 ? "완료" : "대기",
            tran: "운송중",
            gr: "대기",
            dpt: i == 1 ? "출항" : "-",
            arv: "미도착"
          }
        end

        render json: {
          master: master_data,
          items: items_data,
          progresses: progresses_data
        }
      end
    end
  end
end
