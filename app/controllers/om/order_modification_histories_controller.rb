module Om
  class OrderModificationHistoriesController < ApplicationController
    def index
      @search_form = OpenStruct.new(params.fetch(:q, {}).permit(:ord_no, :hist_seq).to_h)

      if request.format.json?
        ord_no = params.dig(:q, :ord_no)
        hist_seq = params.dig(:q, :hist_seq)

        if ord_no.blank?
          return render json: []
        end

        # 이력 목록 Mock Data
        histories = (1..3).map do |i|
          seq = 4 - i
          # hist_seq 파라미터가 있을 경우 필터링
          next if hist_seq.present? && seq.to_s != hist_seq

          {
            id: "#{ord_no}-#{seq}",
            hist_seq: seq,
            sctn: i == 1 ? "수정" : (i == 3 ? "생성" : "수정"),
            ord_no: ord_no,
            cust_ord_no: "CUST-#{ord_no.split('-').last || rand(1000..9999)}",
            ord_type_cd: [ "일반출고", "B2B출고", "반품입고" ].sample,
            cust_cd: "고객사(주)",
            ctrt_cust_cd: "계약사(주)",
            ord_req_cust_cd: "요청사(주)",
            bilg_cust_cd: "청구사(주)",
            ctrt_no: "CTRT-#{rand(100..999)}",
            ord_stat_cd: i == 3 ? "대기" : "진행중",
            ord_chrg_dept_cd: "물류운영팀",
            ord_ofcr: "담당자B",
            retrngd_yn: "N",
            back_ord_yn: "N",
            cust_expr_yn: [ "Y", "N" ].sample,
            cls_expr_yn: [ "Y", "N" ].sample,
            prcl: i == 1 ? "수량 변경으로 인한 수정" : ""
          }
        end.compact

        render json: histories
      end
    end

    def show
      # id는 "ord_no-hist_seq" 형태의 Mock 식별자라고 가정이지만 현재 Mock에서는 사용 안함
      _ord_no, _hist_seq = params[:id].split("-")

      # 탭 1, 2, 3 영역에 들어갈 상세 Mock 정보
      detail_form = {
        # 출도착지정보
        sctn: "수정",
        dpt_ar_cd: "성북센터",
        dpt_ar_addr: "서울시 성북구",
        strt_req_date: (Time.current + 1.day).strftime("%Y-%m-%d %H:%M"),
        dpt_ar_ofcr: "김출발",
        dpt_ar_tel_no: "010-1111-2222",
        arv_ar_cd: "고객대리점",
        arv_ar_addr: "경기도 수원시",
        aptd_req_date: (Time.current + 2.days).strftime("%Y-%m-%d %H:%M"),
        arv_ar_ofcr: "박도착",
        arv_ar_tel_no: "010-3333-4444",
        prcl: "파손주의",

        # 사전오더
        ord_type_cd_pre: "일반출고",
        cust_ord_recp_date: (Time.current - 1.day).strftime("%Y-%m-%d %H:%M"),
        cust_ord_recp_chn: "B2B 연동 API",
        ord_req_cust_cd_pre: "고객대리점",
        cust_ofcr_nm: "최고객",
        cust_tel_no: "02-1234-5678",

        # 오더진행정보
        creat_date: (Time.current - 1.day + 1.hour).strftime("%Y-%m-%d %H:%M"),
        cncl_date: nil,
        ord_cncl_reason_cd: nil,
        ord_reason_cd: "정상출고",
        cmpt_date: nil
      }

      # 탭 4 영역에 들어갈 아이템 목록 Mock 정보
      detail_items = (1..2).map do |i|
        {
          sctn: "이력",
          seq: i,
          item_cd: "ITEM-#{rand(1000..9999)}",
          item_nm: "테스트 상품 #{i}",
          basis_unit_clas_cd: "EA",
          ord_qty: rand(10..50),
          ord_wgt: rand(2.0..10.0).round(2),
          ord_vol: rand(0.5..2.0).round(2),
          unit_cd: "EA" # 단위는 모두 EA 가상 처리
        }
      end

      render json: {
        form: detail_form,
        items: detail_items
      }
    end
  end
end
