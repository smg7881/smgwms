require "ostruct"

class Om::OrderInquiriesController < Om::BaseController
  def index
    @search_form = OpenStruct.new(params.fetch(:q, { date_type: "creat_ymd", strt_ymd: Date.current, end_ymd: Date.current }).permit!.to_h)

    respond_to do |format|
      format.html
      format.json do
        cust_cd = params.dig(:q, :cust_cd)
        strt_ymd = params.dig(:q, :strt_ymd)
        _end_ymd = params.dig(:q, :end_ymd)

        # 고객코드가 없으면 초기 렌더 또는 빈 데이터 리턴
        if cust_cd.blank?
          return render json: []
        end

        # 마스터(오더) Mock Data 반환
        orders = (1..5).map do |i|
          ord_no = "ORD-20260224-#{i.to_s.rjust(3, '0')}"
          {
            id: ord_no,
            ord_stat_cd: [ "오더생성", "할당완료", "출고대기", "출고완료" ].sample,
            ord_no: ord_no,
            creat_ymd: strt_ymd || Date.current.strftime("%Y-%m-%d"),
            ord_type_cd: [ "벌크내수운송", "포장출고", "B2B출고" ].sample,
            cust_bzac_nm: "고객사_#{cust_cd}",
            dpt_ar_nm: [ "대전센터", "장항센터", "부산센터" ].sample,
            arv_ar_nm: [ "서울강남대리점", "수원물류점", "판교고객사" ].sample,

            # 검색 필터 목베이터 (사용자 입력 검증용 필드)
            ord_kind_cd: params.dig(:q, :ord_kind_cd),
            cmpt_sctn_cd: params.dig(:q, :cmpt_sctn_cd),
            ord_sctn_cd: params.dig(:q, :ord_sctn_cd)
          }
        end

        render json: orders
      end
    end
  end

  def show
    ord_no = params[:id]

      # 디테일(아이템) Mock Data 반환
      items = (1..rand(2..5)).map do |i|
        {
          id: "#{ord_no}-item-#{i}",
          seq: i,
          item_cd: "ITEM-#{rand(1000..9999)}",
          item_nm: "검색된 상세 품목 #{i}",
          ord_qty: rand(10..100),
          qty_unit_cd: [ "EA", "BOX", "PLT" ].sample,
          ord_wgt: rand(5.0..20.0).round(2),
          wgt_unit_cd: "KG",
          ord_vol: rand(0.5..5.0).round(2),
          vol_unit_cd: "CBM"
        }
      end

    render json: items
  end

  private
    def menu_code_for_permission
      "OM_ORD_INQ"
    end
end
