class Wm::RateRetroactsController < Wm::BaseController
  def index
    if request.format.html? && params[:q].blank?
      redirect_to wm_rate_retroacts_path(q: default_search_query) and return
    end

    respond_to do |format|
      format.html
      format.json { render json: rate_scope.map { |row| rate_json(row) } }
    end
  end

  def batch_save
    operations = batch_save_params
    result = { inserted: 0, updated: 0, deleted: 0 }
    errors = []

    ActiveRecord::Base.transaction do
      if Array(operations[:rowsToInsert]).any?
        errors << "요율소급관리에서는 마스터 신규 등록을 지원하지 않습니다."
      end

      process_master_updates(operations[:rowsToUpdate], result, errors)
      process_master_deletes(operations[:rowsToDelete], result, errors)

      if errors.any?
        raise ActiveRecord::Rollback
      end
    end

    if errors.any?
      render json: { success: false, errors: errors.uniq }, status: :unprocessable_entity
    else
      render json: { success: true, message: "요율 데이터가 저장되었습니다.", data: result }
    end
  end

  def apply_retro_rates
    operations = apply_params
    retro_uprice = to_decimal(operations[:retro_uprice])
    retro_cur_cd = operations[:retro_cur_cd].to_s.strip.upcase.presence || "KRW"

    rows = Array(operations[:rows]).map do |attrs|
      qty = to_decimal(attrs[:rslt_qty])
      aply_uprice = to_decimal(attrs[:aply_uprice])
      aply_amt = qty * aply_uprice
      rtac_amt = qty * retro_uprice
      uprice_diff = retro_uprice - aply_uprice
      amt_diff = rtac_amt - aply_amt

      {
        exce_rslt_no: attrs[:exce_rslt_no].to_s,
        rslt_qty: qty.to_f,
        aply_uprice: aply_uprice.to_f,
        rslt_amt: aply_amt.to_f,
        cur_cd: retro_cur_cd,
        rtac_uprice: retro_uprice.to_f,
        rtac_amt: rtac_amt.to_f,
        uprice_diff: uprice_diff.to_f,
        amt_diff: amt_diff.to_f
      }
    end

    render json: { success: true, message: "소급요율이 적용되었습니다.", data: { rows: rows } }
  end

  def process_retroacts
    operations = process_params
    rows = Array(operations[:rows])
    result = { inserted: 0, updated: 0, skipped: 0 }
    errors = []

    ActiveRecord::Base.transaction do
      rows.each do |attrs|
        qty = to_decimal(attrs[:rslt_qty])
        if qty <= 0
          result[:skipped] += 1
          next
        end

        exce_rslt_no = attrs[:exce_rslt_no].to_s.strip
        if exce_rslt_no.blank?
          result[:skipped] += 1
          next
        end

        history = Wm::RateRetroactHistory.find_or_initialize_by(exce_rslt_no: exce_rslt_no)
        processing_code = if history.new_record?
          "C"
        else
          "U"
        end

        history.assign_attributes(
          op_rslt_mngt_no: attrs[:op_rslt_mngt_no],
          op_rslt_mngt_no_seq: attrs[:lineno],
          rslt_std_ymd: attrs[:rslt_std_ymd],
          work_pl_cd: operations[:work_pl_cd],
          sell_buy_sctn_cd: operations[:sell_buy_sctn_cd],
          bzac_cd: operations[:bzac_cd],
          sell_buy_attr_cd: operations[:sell_buy_attr_cd],
          rslt_qty: qty,
          base_uprice: to_decimal(attrs[:aply_uprice]),
          base_amt: to_decimal(attrs[:rslt_amt]),
          rtac_uprice: to_decimal(attrs[:rtac_uprice]),
          rtac_amt: to_decimal(attrs[:rtac_amt]),
          uprice_diff: to_decimal(attrs[:uprice_diff]),
          amt_diff: to_decimal(attrs[:amt_diff]),
          cur_cd: attrs[:cur_cd],
          ref_fee_rt_no: operations[:ref_fee_rt_no],
          ref_fee_rt_lineno: operations[:ref_fee_rt_lineno],
          prcs_sctn_cd: processing_code,
          rtac_proc_stat_cd: "RTAC"
        )

        if history.save
          if processing_code == "C"
            result[:inserted] += 1
          else
            result[:updated] += 1
          end
        else
          errors.concat(history.errors.full_messages)
        end
      end

      if errors.any?
        raise ActiveRecord::Rollback
      end
    end

    if errors.any?
      render json: { success: false, errors: errors.uniq }, status: :unprocessable_entity
    else
      render json: { success: true, message: "요율소급처리가 완료되었습니다.", data: result }
    end
  end

  private
    def menu_code_for_permission
      "WM_RATE_RETROACT_MNG"
    end

    def search_params
      params.fetch(:q, {}).permit(
        :work_pl_cd,
        :sell_buy_sctn_cd,
        :bzac_cd,
        :sell_buy_attr_cd,
        :use_yn,
        :aply_date_from,
        :aply_date_to,
        :rslt_std_date_from,
        :rslt_std_date_to
      )
    end

    def default_search_query
      {
        sell_buy_sctn_cd: "10",
        use_yn: "Y",
        aply_date_from: Time.current.beginning_of_year.strftime("%Y-%m-%d"),
        aply_date_to: Time.current.strftime("%Y-%m-%d"),
        rslt_std_date_from: 30.days.ago.strftime("%Y-%m-%d"),
        rslt_std_date_to: Time.current.strftime("%Y-%m-%d")
      }
    end

    def rate_scope
      detail_table = Wm::SellFeeRtMngDtl.table_name
      scope = Wm::SellFeeRtMng.joins(:details)

      if search_work_pl_cd.present?
        scope = scope.where(work_pl_cd: search_work_pl_cd)
      end
      if search_sell_buy_sctn_cd.present?
        scope = scope.where(sell_buy_sctn_cd: search_sell_buy_sctn_cd)
      end
      if search_bzac_cd.present?
        scope = scope.where(ctrt_cprtco_cd: search_bzac_cd)
      end
      if search_sell_buy_attr_cd.present?
        scope = scope.where(sell_buy_attr_cd: search_sell_buy_attr_cd)
      end
      if search_use_yn.present?
        scope = scope.where(use_yn: search_use_yn)
      end

      if search_aply_date_from.present?
        scope = scope.where("#{detail_table}.aply_end_ymd >= ?", search_aply_date_from)
      end
      if search_aply_date_to.present?
        scope = scope.where("#{detail_table}.aply_strt_ymd <= ?", search_aply_date_to)
      end

      scope
        .select(
          "wm_sell_fee_rt_mngs.wrhs_exca_fee_rt_no",
          "wm_sell_fee_rt_mngs.sell_buy_attr_cd",
          "wm_sell_fee_rt_mngs.sell_buy_sctn_cd",
          "wm_sell_fee_rt_mngs.sell_unit_cd",
          "wm_sell_fee_rt_mngs.work_pl_cd",
          "wm_sell_fee_rt_mngs.ctrt_cprtco_cd",
          "#{detail_table}.lineno AS rate_lineno",
          "#{detail_table}.aply_uprice AS aply_feert",
          "#{detail_table}.aply_strt_ymd",
          "#{detail_table}.aply_end_ymd",
          "#{detail_table}.cur_cd"
        )
        .order("wm_sell_fee_rt_mngs.wrhs_exca_fee_rt_no DESC", "#{detail_table}.lineno ASC")
    end

    def apply_params
      params.permit(
        :retro_uprice,
        :retro_cur_cd,
        rows: [ :exce_rslt_no, :rslt_qty, :aply_uprice ]
      )
    end

    def process_params
      params.permit(
        :work_pl_cd,
        :sell_buy_sctn_cd,
        :bzac_cd,
        :sell_buy_attr_cd,
        :ref_fee_rt_no,
        :ref_fee_rt_lineno,
        rows: [
          :exce_rslt_no,
          :rslt_std_ymd,
          :op_rslt_mngt_no,
          :lineno,
          :rslt_qty,
          :aply_uprice,
          :rslt_amt,
          :cur_cd,
          :rtac_uprice,
          :rtac_amt,
          :uprice_diff,
          :amt_diff
        ]
      )
    end

    def search_work_pl_cd
      search_params[:work_pl_cd].to_s.strip.upcase.presence
    end

    def search_sell_buy_sctn_cd
      value = search_params[:sell_buy_sctn_cd].to_s.strip.upcase
      if value.present?
        value
      else
        "10"
      end
    end

    def search_bzac_cd
      search_params[:bzac_cd].to_s.strip.upcase.presence
    end

    def search_sell_buy_attr_cd
      search_params[:sell_buy_attr_cd].to_s.strip.upcase.presence
    end

    def search_use_yn
      normalized = search_params[:use_yn].to_s.strip.upcase
      if normalized == "N"
        "N"
      else
        "Y"
      end
    end

    def search_aply_date_from
      normalize_ymd(search_params[:aply_date_from])
    end

    def search_aply_date_to
      normalize_ymd(search_params[:aply_date_to])
    end

    def normalize_ymd(value)
      value.to_s.gsub(/[^0-9]/, "").first(8)
    end

    def normalize_code(value)
      value.to_s.strip.upcase
    end

    def to_decimal(value)
      BigDecimal(value.to_s)
    rescue ArgumentError
      BigDecimal("0")
    end

    def rate_json(row)
      {
        id: "#{row.wrhs_exca_fee_rt_no}_#{row.rate_lineno}",
        wrhs_exca_fee_rt_no: row.wrhs_exca_fee_rt_no,
        rate_lineno: row.rate_lineno,
        sell_buy_sctn_cd: row.sell_buy_sctn_cd,
        work_pl_cd: row.work_pl_cd,
        work_pl_nm: workplace_name(row.work_pl_cd),
        bzac_cd: row.ctrt_cprtco_cd,
        bzac_nm: client_name(row.ctrt_cprtco_cd),
        sell_buy_attr_cd: row.sell_buy_attr_cd,
        sell_buy_attr_nm: sellbuy_attr_name(row.sell_buy_attr_cd),
        sell_buy_unit: row.sell_unit_cd,
        aply_feert: to_decimal(row.aply_feert).to_f,
        aply_strt_ymd: row.aply_strt_ymd,
        aply_end_ymd: row.aply_end_ymd,
        cur_cd: row.cur_cd,
        rtac_feert: nil
      }
    end

    def workplace_name(code)
      lookup_name(workplace_name_map, code)
    end

    def client_name(code)
      lookup_name(client_name_map, code)
    end

    def sellbuy_attr_name(code)
      lookup_name(sellbuy_attr_name_map, code)
    end

    def lookup_name(map, code)
      normalized_code = code.to_s.strip.upcase
      map[normalized_code]
    end

    def workplace_name_map
      @workplace_name_map ||= begin
        if defined?(StdWorkplace) && StdWorkplace.table_exists?
          StdWorkplace.where(use_yn_cd: "Y")
                     .pluck(:workpl_cd, :workpl_nm)
                     .to_h { |cd, nm| [ cd.to_s.strip.upcase, nm.to_s.strip ] }
        else
          {}
        end
      rescue ActiveRecord::StatementInvalid
        {}
      end
    end

    def client_name_map
      @client_name_map ||= begin
        if defined?(StdBzacMst) && StdBzacMst.table_exists?
          StdBzacMst.where(use_yn_cd: "Y")
                    .pluck(:bzac_cd, :bzac_nm)
                    .to_h { |cd, nm| [ cd.to_s.strip.upcase, nm.to_s.strip ] }
        else
          {}
        end
      rescue ActiveRecord::StatementInvalid
        {}
      end
    end

    def sellbuy_attr_name_map
      @sellbuy_attr_name_map ||= begin
        if defined?(StdSellbuyAttribute) && StdSellbuyAttribute.table_exists?
          StdSellbuyAttribute.where(use_yn_cd: "Y")
                             .pluck(:sellbuy_attr_cd, :sellbuy_attr_nm)
                             .to_h { |cd, nm| [ cd.to_s.strip.upcase, nm.to_s.strip ] }
        else
          {}
        end
      rescue ActiveRecord::StatementInvalid
        {}
      end
    end
end
    def batch_save_params
      params.permit(
        rowsToDelete: [],
        rowsToInsert: [ :wrhs_exca_fee_rt_no, :rtac_feert ],
        rowsToUpdate: [ :wrhs_exca_fee_rt_no, :rtac_feert ]
      )
    end

    def process_master_updates(rows, result, errors)
      Array(rows).each do |attrs|
        rate_no = normalize_code(attrs[:wrhs_exca_fee_rt_no])
        if rate_no.blank?
          next
        end

        record = Wm::SellFeeRtMng.find_by(wrhs_exca_fee_rt_no: rate_no)
        if record.nil?
          errors << "요율번호를 찾을 수 없습니다: #{rate_no}"
        else
          result[:updated] += 1
        end
      end
    end

    def process_master_deletes(rows, result, errors)
      Array(rows).each do |value|
        rate_no = normalize_code(value)
        if rate_no.blank?
          next
        end

        record = Wm::SellFeeRtMng.find_by(wrhs_exca_fee_rt_no: rate_no)
        if record.nil?
          next
        end

        errors << "요율소급관리에서는 마스터 삭제를 지원하지 않습니다: #{rate_no}"
      end

      result[:deleted] += 0
    end
