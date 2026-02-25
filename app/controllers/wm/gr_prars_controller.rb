class Wm::GrPrarsController < Wm::BaseController
  # GET /wm/gr_prars       HTML/JSON 목록
  def index
    respond_to do |format|
      format.html
      format.json { render json: records_scope.map { |r| header_json(r) } }
    end
  end

  # GET /wm/gr_prars/:id/details.json  입고예정상세 목록
  def details
    gr_prar = Wm::GrPrar.find_by!(gr_prar_no: params[:id])
    dtls = gr_prar.details.order(:lineno)
    render json: dtls.map { |d| detail_json(d) }
  end

  # GET /wm/gr_prars/:id/exec_results.json  입고처리내역 목록
  def exec_results
    results = Wm::ExceRslt
                .where(op_rslt_mngt_no: params[:id])
                .where(exce_rslt_type: [ Wm::ExceRslt::EXCE_RSLT_TYPE_DP, "RC" ])
                .order(:op_rslt_mngt_no_seq, :exce_rslt_no)
    render json: results.map { |r| exec_result_json(r) }
  end

  # GET /wm/gr_prars/staged_locations.json  STAGED 로케이션 목록
  def staged_locations
    workpl_cd = params[:workpl_cd]
    if workpl_cd.blank?
      render json: []
      return
    end

    locs = Wm::Location.where(workpl_cd: workpl_cd)
                       .where("loc_cls = 'STAGED' OR loc_cls LIKE '%STAGE%'")
                       .where(use_yn: "Y")
                       .order(:loc_cd)
    render json: locs.map { |l| { value: l.loc_cd, label: l.loc_cd } }
  end

  # POST /wm/gr_prars/:id/save  입고내역저장 (복잡한 트랜잭션)
  def save_gr
    gr_prar = Wm::GrPrar.find_by!(gr_prar_no: params[:id])
    detail_rows = params[:rows] || []
    errors = []
    actor = current_actor

    ActiveRecord::Base.transaction do
      detail_rows.each do |row|
        lineno  = row[:lineno].to_i
        gr_qty  = row[:gr_qty].to_f
        loc_cd  = row[:gr_loc_cd].to_s.strip

        next if gr_qty <= 0

        dtl = gr_prar.details.find_by(lineno: lineno)
        unless dtl
          errors << "라인번호 #{lineno}를 찾을 수 없습니다."
          next
        end

        if loc_cd.blank?
          errors << "라인 #{lineno}: 입고로케이션을 입력해주세요."
          next
        end

        # 재고속성 데이터 추출
        attr_data = {}
        Wm::GrPrarDtl::STOCK_ATTR_COLS.each do |col|
          attr_data[col] = row[col.to_sym].to_s.strip.presence || dtl.send(col).to_s.strip.presence
        end

        # 1) 재고속성 조회/생성
        stock_attr = Wm::StockAttr.find_or_create_for(
          corp_cd: gr_prar.corp_cd,
          cust_cd: gr_prar.cust_cd,
          item_cd: dtl.item_cd,
          attrs:   attr_data,
          actor:   actor
        )

        # 2) 재고 생성/갱신 (3개 테이블)
        Wm::StockAttrQty.upsert_qty(
          corp_cd:        gr_prar.corp_cd,
          workpl_cd:      gr_prar.workpl_cd,
          stock_attr_no:  stock_attr.stock_attr_no,
          cust_cd:        gr_prar.cust_cd,
          item_cd:        dtl.item_cd,
          basis_unit_cls: dtl.unit_cd.presence || "10",
          basis_unit_cd:  dtl.unit_cd.presence || "EA",
          add_qty:        gr_qty,
          actor:          actor
        )

        Wm::StockAttrLocQty.upsert_qty(
          corp_cd:        gr_prar.corp_cd,
          workpl_cd:      gr_prar.workpl_cd,
          stock_attr_no:  stock_attr.stock_attr_no,
          loc_cd:         loc_cd,
          cust_cd:        gr_prar.cust_cd,
          item_cd:        dtl.item_cd,
          basis_unit_cls: dtl.unit_cd.presence || "10",
          basis_unit_cd:  dtl.unit_cd.presence || "EA",
          add_qty:        gr_qty,
          actor:          actor
        )

        Wm::LocQty.upsert_qty(
          corp_cd:        gr_prar.corp_cd,
          workpl_cd:      gr_prar.workpl_cd,
          cust_cd:        gr_prar.cust_cd,
          loc_cd:         loc_cd,
          item_cd:        dtl.item_cd,
          basis_unit_cls: dtl.unit_cd.presence || "10",
          basis_unit_cd:  dtl.unit_cd.presence || "EA",
          add_qty:        gr_qty,
          actor:          actor
        )

        # 3) 실행실적 생성
        now = Time.current
        Wm::ExceRslt.create!(
          exce_rslt_no:         Wm::ExceRslt.generate_no,
          op_rslt_mngt_no:      gr_prar.gr_prar_no,
          op_rslt_mngt_no_seq:  lineno,
          exce_rslt_type:       Wm::ExceRslt::EXCE_RSLT_TYPE_DP,
          workpl_cd:            gr_prar.workpl_cd,
          corp_cd:              gr_prar.corp_cd,
          cust_cd:              gr_prar.cust_cd,
          item_cd:              dtl.item_cd,
          to_loc:               loc_cd,
          rslt_qty:             gr_qty,
          basis_unit_cls:       dtl.unit_cd.presence || "10",
          basis_unit_cd:        dtl.unit_cd.presence || "EA",
          ord_no:               gr_prar.ord_no,
          exec_ord_no:          gr_prar.exec_ord_no,
          exce_rslt_ymd:        now.strftime("%Y%m%d"),
          exce_rslt_hms:        now.strftime("%H%M%S"),
          stock_attr_no:        stock_attr.stock_attr_no,
          **attr_data.transform_keys { |k| k.to_s.sub("stock_attr_col", "stock_attr_col").to_sym }
        )

        # 4) 입고예정상세 수정
        new_rslt_qty = dtl.gr_rslt_qty.to_f + gr_qty
        new_stat     = new_rslt_qty > 0 ? Wm::GrPrar::GR_STAT_PROCESSED : Wm::GrPrar::GR_STAT_PENDING
        dtl.update!(
          gr_loc_cd:    loc_cd,
          gr_qty:       gr_qty,
          gr_rslt_qty:  new_rslt_qty,
          gr_ymd:       now.strftime("%Y%m%d"),
          gr_hms:       now.strftime("%H%M%S"),
          gr_stat_cd:   new_stat,
          rmk:          row[:rmk].to_s.strip.presence || dtl.rmk,
          **attr_data.transform_keys(&:to_sym)
        )
      end

      raise ActiveRecord::Rollback if errors.any?

      # 5) 입고예정 헤더 수정
      now = Time.current
      total_rslt_qty = gr_prar.details.sum(:gr_rslt_qty)
      new_stat = total_rslt_qty.to_f > 0 ? Wm::GrPrar::GR_STAT_PROCESSED : Wm::GrPrar::GR_STAT_PENDING
      header_rmk = params[:header_rmk].to_s.strip.presence
      gr_prar.update!(
        gr_ymd:      now.strftime("%Y%m%d"),
        gr_hms:      now.strftime("%H%M%S"),
        gr_stat_cd:  new_stat,
        rmk:         header_rmk || gr_prar.rmk
      )
    end

    if errors.any?
      render json: { success: false, errors: errors.uniq }, status: :unprocessable_entity
    else
      render json: { success: true, message: "입고내역이 저장되었습니다." }
    end
  rescue ActiveRecord::RecordNotFound => e
    render json: { success: false, errors: [ e.message ] }, status: :not_found
  rescue => e
    render json: { success: false, errors: [ e.message ] }, status: :unprocessable_entity
  end

  # POST /wm/gr_prars/:id/confirm  입고확정
  def confirm
    gr_prar = Wm::GrPrar.find_by!(gr_prar_no: params[:id])

    unless gr_prar.processed?
      render json: { success: false, errors: [ "입고확정불가: 입고상태가 '입고처리' 상태일 때만 확정이 가능합니다." ] },
             status: :unprocessable_entity
      return
    end

    ActiveRecord::Base.transaction do
      # 오더시스템 연동 stub
      notify_order_system_for_confirm(gr_prar)

      # 입고확정 처리
      gr_prar.update!(gr_stat_cd: Wm::GrPrar::GR_STAT_CONFIRMED)
      gr_prar.details.update_all(gr_stat_cd: Wm::GrPrar::GR_STAT_CONFIRMED)
    end

    render json: { success: true, message: "입고확정 처리가 완료되었습니다." }
  rescue ActiveRecord::RecordNotFound => e
    render json: { success: false, errors: [ e.message ] }, status: :not_found
  rescue => e
    render json: { success: false, errors: [ e.message ] }, status: :unprocessable_entity
  end

  # POST /wm/gr_prars/:id/cancel  입고취소
  def cancel
    gr_prar  = Wm::GrPrar.find_by!(gr_prar_no: params[:id])
    was_confirmed = gr_prar.confirmed?
    actor    = current_actor
    errors   = []

    ActiveRecord::Base.transaction do
      dp_results = Wm::ExceRslt.where(
        op_rslt_mngt_no: gr_prar.gr_prar_no,
        exce_rslt_type:  Wm::ExceRslt::EXCE_RSLT_TYPE_DP
      )

      dp_results.each do |rslt|
        # 재고 가용재고 확인
        loc_stock = Wm::StockAttrLocQty.find_by(
          corp_cd:       rslt.corp_cd,
          workpl_cd:     rslt.workpl_cd,
          stock_attr_no: rslt.stock_attr_no,
          loc_cd:        rslt.to_loc
        )

        avail = loc_stock&.available_qty.to_f
        if avail < rslt.rslt_qty.to_f
          errors << "취소처리할 재고가 존재하지 않습니다.(#{rslt.item_cd}-#{rslt.to_loc}-#{rslt.rslt_qty})"
          next
        end

        # 재고 차감 (3개 테이블)
        Wm::StockAttrQty.upsert_qty(
          corp_cd: rslt.corp_cd, workpl_cd: rslt.workpl_cd,
          stock_attr_no: rslt.stock_attr_no,
          cust_cd: rslt.cust_cd, item_cd: rslt.item_cd,
          basis_unit_cls: rslt.basis_unit_cls, basis_unit_cd: rslt.basis_unit_cd,
          add_qty: rslt.rslt_qty.to_f * -1, actor: actor
        )

        Wm::StockAttrLocQty.upsert_qty(
          corp_cd: rslt.corp_cd, workpl_cd: rslt.workpl_cd,
          stock_attr_no: rslt.stock_attr_no, loc_cd: rslt.to_loc,
          cust_cd: rslt.cust_cd, item_cd: rslt.item_cd,
          basis_unit_cls: rslt.basis_unit_cls, basis_unit_cd: rslt.basis_unit_cd,
          add_qty: rslt.rslt_qty.to_f * -1, actor: actor
        )

        Wm::LocQty.upsert_qty(
          corp_cd: rslt.corp_cd, workpl_cd: rslt.workpl_cd,
          cust_cd: rslt.cust_cd, loc_cd: rslt.to_loc, item_cd: rslt.item_cd,
          basis_unit_cls: rslt.basis_unit_cls, basis_unit_cd: rslt.basis_unit_cd,
          add_qty: rslt.rslt_qty.to_f * -1, actor: actor
        )

        # 취소 실행실적 생성 (CC)
        now = Time.current
        Wm::ExceRslt.create!(
          exce_rslt_no:         Wm::ExceRslt.generate_no,
          op_rslt_mngt_no:      rslt.op_rslt_mngt_no,
          op_rslt_mngt_no_seq:  rslt.op_rslt_mngt_no_seq,
          exce_rslt_type:       Wm::ExceRslt::EXCE_RSLT_TYPE_CC,
          workpl_cd:            rslt.workpl_cd,
          corp_cd:              rslt.corp_cd,
          cust_cd:              rslt.cust_cd,
          item_cd:              rslt.item_cd,
          from_loc:             rslt.from_loc,
          to_loc:               rslt.to_loc,
          rslt_qty:             rslt.rslt_qty.to_f * -1,
          rslt_cbm:             rslt.rslt_cbm.to_f * -1,
          rslt_total_wt:        rslt.rslt_total_wt.to_f * -1,
          rslt_net_wt:          rslt.rslt_net_wt.to_f * -1,
          basis_unit_cls:       rslt.basis_unit_cls,
          basis_unit_cd:        rslt.basis_unit_cd,
          ord_no:               rslt.ord_no,
          exec_ord_no:          rslt.exec_ord_no,
          exce_rslt_ymd:        now.strftime("%Y%m%d"),
          exce_rslt_hms:        now.strftime("%H%M%S"),
          stock_attr_no:        rslt.stock_attr_no,
          stock_attr_col01:     rslt.stock_attr_col01,
          stock_attr_col02:     rslt.stock_attr_col02,
          stock_attr_col03:     rslt.stock_attr_col03,
          stock_attr_col04:     rslt.stock_attr_col04,
          stock_attr_col05:     rslt.stock_attr_col05,
          stock_attr_col06:     rslt.stock_attr_col06,
          stock_attr_col07:     rslt.stock_attr_col07,
          stock_attr_col08:     rslt.stock_attr_col08,
          stock_attr_col09:     rslt.stock_attr_col09,
          stock_attr_col10:     rslt.stock_attr_col10
        )
      end

      raise ActiveRecord::Rollback if errors.any?

      # 입고취소 상태 업데이트
      gr_prar.update!(gr_stat_cd: Wm::GrPrar::GR_STAT_CANCELLED)
      gr_prar.details.update_all(gr_stat_cd: Wm::GrPrar::GR_STAT_CANCELLED)

      if was_confirmed
        # 입고확정 후 취소: 오더시스템 작업단계별실적취소 stub
        notify_order_system_for_cancel(gr_prar)
      else
        # 입고확정 전 취소: 신규 입고예정 생성
        create_new_gr_prar_from(gr_prar)
      end
    end

    if errors.any?
      render json: { success: false, errors: errors.uniq }, status: :unprocessable_entity
    else
      render json: { success: true, message: "입고취소 처리가 완료되었습니다." }
    end
  rescue ActiveRecord::RecordNotFound => e
    render json: { success: false, errors: [ e.message ] }, status: :not_found
  rescue => e
    render json: { success: false, errors: [ e.message ] }, status: :unprocessable_entity
  end

  private
    def search_params
      params.fetch(:q, {}).permit(
        :workpl_cd, :cust_cd, :gr_type_cd, :gr_stat_cd,
        :prar_ymd_from, :prar_ymd_to, :gr_ymd,
        :item_cd, :ord_no, :dptar_type_cd, :dptar_cd, :car_no
      )
    end

    def records_scope
      scope = Wm::GrPrar.ordered

      if search_params[:workpl_cd].present?
        scope = scope.where(workpl_cd: search_params[:workpl_cd])
      end
      if search_params[:cust_cd].present?
        scope = scope.where(cust_cd: search_params[:cust_cd])
      end
      if search_params[:gr_type_cd].present?
        scope = scope.where(gr_type_cd: search_params[:gr_type_cd])
      end
      if search_params[:gr_stat_cd].present?
        scope = scope.where(gr_stat_cd: search_params[:gr_stat_cd])
      end
      if search_params[:prar_ymd_from].present?
        scope = scope.where("prar_ymd >= ?", search_params[:prar_ymd_from].delete("-"))
      end
      if search_params[:prar_ymd_to].present?
        scope = scope.where("prar_ymd <= ?", search_params[:prar_ymd_to].delete("-"))
      end
      if search_params[:gr_ymd].present?
        scope = scope.where(gr_ymd: search_params[:gr_ymd].delete("-"))
      end
      if search_params[:ord_no].present?
        scope = scope.where("ord_no LIKE ?", "%#{search_params[:ord_no]}%")
      end
      if search_params[:car_no].present?
        scope = scope.where("car_no LIKE ?", "%#{search_params[:car_no]}%")
      end

      # 아이템 코드는 상세 테이블과 JOIN
      if search_params[:item_cd].present?
        scope = scope.joins(:details)
                     .where("tb_wm02002.item_cd = ?", search_params[:item_cd])
                     .distinct
      end

      scope
    end

    def header_json(r)
      {
        id:              r.gr_prar_no,
        gr_prar_no:      r.gr_prar_no,
        workpl_cd:       r.workpl_cd,
        corp_cd:         r.corp_cd,
        cust_cd:         r.cust_cd,
        gr_type_cd:      r.gr_type_cd,
        ord_reason_cd:   r.ord_reason_cd,
        gr_stat_cd:      r.gr_stat_cd,
        prar_ymd:        r.prar_ymd,
        gr_ymd:          r.gr_ymd,
        gr_hms:          r.gr_hms,
        ord_no:          r.ord_no,
        rel_gi_ord_no:   r.rel_gi_ord_no,
        exec_ord_no:     r.exec_ord_no,
        dptar_type_cd:   r.dptar_type_cd,
        dptar_cd:        r.dptar_cd,
        car_no:          r.car_no,
        driver_nm:       r.driver_nm,
        driver_telno:    r.driver_telno,
        transco_cd:      r.transco_cd,
        rmk:             r.rmk,
        create_by:       r.create_by,
        create_time:     r.create_time,
        update_by:       r.update_by,
        update_time:     r.update_time
      }
    end

    def detail_json(d)
      {
        id:                "#{d.gr_prar_no}_#{d.lineno}",
        gr_prar_no:        d.gr_prar_no,
        lineno:            d.lineno,
        item_cd:           d.item_cd,
        item_nm:           d.item_nm,
        unit_cd:           d.unit_cd,
        gr_prar_qty:       d.gr_prar_qty,
        gr_loc_cd:         d.gr_loc_cd,
        gr_qty:            d.gr_qty,
        gr_rslt_qty:       d.gr_rslt_qty,
        gr_ymd:            d.gr_ymd,
        gr_hms:            d.gr_hms,
        gr_stat_cd:        d.gr_stat_cd,
        stock_attr_col01:  d.stock_attr_col01,
        stock_attr_col02:  d.stock_attr_col02,
        stock_attr_col03:  d.stock_attr_col03,
        stock_attr_col04:  d.stock_attr_col04,
        stock_attr_col05:  d.stock_attr_col05,
        stock_attr_col06:  d.stock_attr_col06,
        stock_attr_col07:  d.stock_attr_col07,
        stock_attr_col08:  d.stock_attr_col08,
        stock_attr_col09:  d.stock_attr_col09,
        stock_attr_col10:  d.stock_attr_col10,
        rmk:               d.rmk
      }
    end

    def exec_result_json(r)
      {
        id:                    r.exce_rslt_no,
        exce_rslt_no:          r.exce_rslt_no,
        lineno:                r.op_rslt_mngt_no_seq,
        seq:                   r.exce_rslt_no,
        exce_rslt_type:        r.exce_rslt_type,
        item_cd:               r.item_cd,
        to_loc:                r.to_loc,
        rslt_qty:              r.rslt_qty,
        basis_unit_cd:         r.basis_unit_cd,
        exce_rslt_ymd:         r.exce_rslt_ymd,
        exce_rslt_hms:         r.exce_rslt_hms,
        stock_attr_col01:      r.stock_attr_col01,
        stock_attr_col02:      r.stock_attr_col02,
        stock_attr_col03:      r.stock_attr_col03,
        stock_attr_col04:      r.stock_attr_col04,
        stock_attr_col05:      r.stock_attr_col05,
        stock_attr_col06:      r.stock_attr_col06,
        stock_attr_col07:      r.stock_attr_col07,
        stock_attr_col08:      r.stock_attr_col08,
        stock_attr_col09:      r.stock_attr_col09,
        stock_attr_col10:      r.stock_attr_col10
      }
    end

    def current_actor
      Current.user&.user_id_code || Current.user&.email_address || "system"
    end

    # 오더시스템 연동 stub
    def notify_order_system_for_confirm(gr_prar)
      # TODO: 외부 오더시스템 작업단계별실적등록 + 작업단계별실적아이템등록 API 호출
      Rails.logger.info "[입고확정] 오더시스템 연동 stub - gr_prar_no: #{gr_prar.gr_prar_no}"
    end

    # 오더시스템 취소 연동 stub
    def notify_order_system_for_cancel(gr_prar)
      # TODO: 외부 오더시스템 작업단계별실적취소 API 호출
      Rails.logger.info "[입고취소] 오더시스템 취소 연동 stub - gr_prar_no: #{gr_prar.gr_prar_no}"
    end

    # 입고취소 후 신규 입고예정 생성
    def create_new_gr_prar_from(gr_prar)
      new_no = "GR" + Time.current.strftime("%y%m%d%H%M%S") + format("%03d", rand(999))

      new_prar = Wm::GrPrar.create!(
        gr_prar_no:    new_no,
        workpl_cd:     gr_prar.workpl_cd,
        corp_cd:       gr_prar.corp_cd,
        cust_cd:       gr_prar.cust_cd,
        gr_type_cd:    gr_prar.gr_type_cd,
        ord_reason_cd: gr_prar.ord_reason_cd,
        gr_stat_cd:    Wm::GrPrar::GR_STAT_PENDING,
        prar_ymd:      gr_prar.prar_ymd,
        ord_no:        gr_prar.ord_no,
        rel_gi_ord_no: gr_prar.rel_gi_ord_no,
        exec_ord_no:   gr_prar.exec_ord_no,
        dptar_type_cd: gr_prar.dptar_type_cd,
        dptar_cd:      gr_prar.dptar_cd,
        car_no:        gr_prar.car_no,
        driver_nm:     gr_prar.driver_nm,
        driver_telno:  gr_prar.driver_telno,
        transco_cd:    gr_prar.transco_cd,
        rmk:           gr_prar.rmk
      )

      gr_prar.details.each do |dtl|
        Wm::GrPrarDtl.create!(
          gr_prar_no:      new_prar.gr_prar_no,
          lineno:          dtl.lineno,
          item_cd:         dtl.item_cd,
          item_nm:         dtl.item_nm,
          unit_cd:         dtl.unit_cd,
          gr_prar_qty:     dtl.gr_prar_qty,
          gr_qty:          0,
          gr_rslt_qty:     0,
          gr_stat_cd:      Wm::GrPrar::GR_STAT_PENDING
        )
      end
    end
end
