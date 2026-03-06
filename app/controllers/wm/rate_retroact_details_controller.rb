class Wm::RateRetroactDetailsController < Wm::BaseController
  before_action :set_rate_master

  def index
    base_line = selected_rate_line
    base_uprice = resolved_base_uprice(base_line)
    base_cur_cd = resolved_base_cur_cd(base_line)

    result_rows = performance_scope.map do |row|
      history = retro_history_map[row.exce_rslt_no.to_s]
      detail_json(row, base_uprice: base_uprice, base_cur_cd: base_cur_cd, history: history)
    end

    render json: result_rows
  end

  def batch_save
    operations = batch_save_params
    result = { inserted: 0, updated: 0, deleted: 0 }
    errors = []

    ActiveRecord::Base.transaction do
      process_detail_upserts(operations[:rowsToInsert], result, errors, default_process_code: "C")
      process_detail_upserts(operations[:rowsToUpdate], result, errors, default_process_code: "U")
      process_detail_deletes(operations[:rowsToDelete], result, errors)

      if errors.any?
        raise ActiveRecord::Rollback
      end
    end

    if errors.any?
      render json: { success: false, errors: errors.uniq }, status: :unprocessable_entity
    else
      render json: { success: true, message: "실적 데이터가 저장되었습니다.", data: result }
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
        :rslt_std_date_from,
        :rslt_std_date_to
      )
    end

    def batch_save_params
      params.permit(
        :ref_fee_rt_no,
        :ref_fee_rt_lineno,
        rowsToDelete: [],
        rowsToInsert: [
          :exce_rslt_no, :rslt_std_ymd, :op_rslt_mngt_no, :lineno, :rslt_qty,
          :aply_uprice, :rslt_amt, :cur_cd, :rtac_uprice, :rtac_amt, :uprice_diff, :amt_diff
        ],
        rowsToUpdate: [
          :exce_rslt_no, :rslt_std_ymd, :op_rslt_mngt_no, :lineno, :rslt_qty,
          :aply_uprice, :rslt_amt, :cur_cd, :rtac_uprice, :rtac_amt, :uprice_diff, :amt_diff
        ]
      )
    end

    def set_rate_master
      master_key = params[:rate_retroact_id].to_s.strip.upcase
      @rate_master = Wm::SellFeeRtMng.find_by(wrhs_exca_fee_rt_no: master_key)

      if @rate_master.nil?
        render json: { success: false, errors: [ "요율마스터를 찾을 수 없습니다." ] }, status: :not_found
      end
    end

    def selected_rate_line
      lineno = params[:selected_lineno].to_s.strip
      details = @rate_master.details

      if lineno.present?
        selected = details.find_by(lineno: lineno.to_i)
        if selected.present?
          selected
        else
          details.order(:lineno).first
        end
      else
        details.order(:lineno).first
      end
    end

    def resolved_base_uprice(base_line)
      request_value = params[:base_uprice].to_s.strip
      if request_value.present?
        to_decimal(request_value)
      elsif base_line.present?
        to_decimal(base_line.aply_uprice)
      else
        BigDecimal("0")
      end
    end

    def resolved_base_cur_cd(base_line)
      request_value = params[:base_cur_cd].to_s.strip.upcase
      if request_value.present?
        request_value
      elsif base_line.present?
        base_line.cur_cd.to_s.strip.upcase.presence || "KRW"
      else
        "KRW"
      end
    end

    def performance_scope
      scope = Wm::ExceRslt.order(exce_rslt_ymd: :desc, op_rslt_mngt_no: :desc, op_rslt_mngt_no_seq: :desc)

      work_pl_cd = resolved_work_pl_cd
      if work_pl_cd.present?
        scope = scope.where(workpl_cd: work_pl_cd)
      end

      date_from = normalize_ymd(search_params[:rslt_std_date_from])
      date_to = normalize_ymd(search_params[:rslt_std_date_to])

      if date_from.present?
        scope = scope.where("exce_rslt_ymd >= ?", date_from)
      end
      if date_to.present?
        scope = scope.where("exce_rslt_ymd <= ?", date_to)
      end

      scope.limit(500)
    end

    def resolved_work_pl_cd
      requested = search_params[:work_pl_cd].to_s.strip.upcase
      if requested.present?
        requested
      else
        @rate_master.work_pl_cd.to_s.strip.upcase
      end
    end

    def retro_history_map
      @retro_history_map ||= begin
        exce_rslt_nos = performance_scope.map { |row| row.exce_rslt_no.to_s }
        rows = Wm::RateRetroactHistory.where(exce_rslt_no: exce_rslt_nos)
        rows.index_by { |row| row.exce_rslt_no.to_s }
      end
    end

    def detail_json(row, base_uprice:, base_cur_cd:, history:)
      rslt_qty = to_decimal(row.rslt_qty)
      source_uprice = if history.present?
        to_decimal(history.base_uprice)
      else
        base_uprice
      end
      source_amt = if history.present?
        to_decimal(history.base_amt)
      else
        rslt_qty * source_uprice
      end

      retro_uprice = history.present? ? to_decimal(history.rtac_uprice) : BigDecimal("0")
      retro_amt = history.present? ? to_decimal(history.rtac_amt) : BigDecimal("0")
      uprice_diff = if history.present?
        to_decimal(history.uprice_diff)
      else
        BigDecimal("0")
      end
      amt_diff = if history.present?
        to_decimal(history.amt_diff)
      else
        BigDecimal("0")
      end

      {
        id: row.exce_rslt_no,
        selected: false,
        exce_rslt_no: row.exce_rslt_no,
        rslt_std_ymd: row.exce_rslt_ymd,
        rslt_rcgt_sctn: row.exce_rslt_type,
        op_rslt_mngt_no: row.op_rslt_mngt_no,
        lineno: row.op_rslt_mngt_no_seq,
        rslt_qty: rslt_qty.to_f,
        aply_uprice: source_uprice.to_f,
        rslt_amt: source_amt.to_f,
        cur_cd: history&.cur_cd.to_s.strip.upcase.presence || base_cur_cd,
        rtac_uprice: retro_uprice.to_f,
        rtac_amt: retro_amt.to_f,
        uprice_diff: uprice_diff.to_f,
        amt_diff: amt_diff.to_f,
        prcs_sctn_cd: history&.prcs_sctn_cd,
        rtac_proc_stat_cd: history&.rtac_proc_stat_cd
      }
    end

    def process_detail_upserts(rows, result, errors, default_process_code:)
      Array(rows).each do |attrs|
        exce_rslt_no = attrs[:exce_rslt_no].to_s.strip
        if exce_rslt_no.blank?
          next
        end

        history = Wm::RateRetroactHistory.find_or_initialize_by(exce_rslt_no: exce_rslt_no)
        process_code = history.new_record? ? default_process_code : "U"
        history.assign_attributes(history_attrs(attrs, process_code: process_code))

        if history.save
          if history.previous_changes.key?("id")
            result[:inserted] += 1
          else
            result[:updated] += 1
          end
        else
          errors.concat(history.errors.full_messages)
        end
      end
    end

    def process_detail_deletes(rows, result, errors)
      Array(rows).each do |raw|
        exce_rslt_no = extract_delete_key(raw)
        if exce_rslt_no.blank?
          next
        end

        history = Wm::RateRetroactHistory.find_by(exce_rslt_no: exce_rslt_no)
        if history.nil?
          next
        end

        if history.destroy
          result[:deleted] += 1
        else
          errors.concat(history.errors.full_messages.presence || [ "소급이력을 삭제하지 못했습니다: #{exce_rslt_no}" ])
        end
      end
    end

    def extract_delete_key(raw)
      if raw.is_a?(Hash) || raw.is_a?(ActionController::Parameters)
        raw[:exce_rslt_no].to_s.strip.presence || raw["exce_rslt_no"].to_s.strip
      else
        raw.to_s.strip
      end
    end

    def history_attrs(attrs, process_code:)
      {
        op_rslt_mngt_no: attrs[:op_rslt_mngt_no].to_s.strip,
        op_rslt_mngt_no_seq: attrs[:lineno].to_i,
        rslt_std_ymd: normalize_ymd(attrs[:rslt_std_ymd]),
        work_pl_cd: @rate_master.work_pl_cd,
        sell_buy_sctn_cd: @rate_master.sell_buy_sctn_cd,
        bzac_cd: @rate_master.ctrt_cprtco_cd,
        sell_buy_attr_cd: @rate_master.sell_buy_attr_cd,
        rslt_qty: to_decimal(attrs[:rslt_qty]),
        base_uprice: to_decimal(attrs[:aply_uprice]),
        base_amt: to_decimal(attrs[:rslt_amt]),
        rtac_uprice: to_decimal(attrs[:rtac_uprice]),
        rtac_amt: to_decimal(attrs[:rtac_amt]),
        uprice_diff: to_decimal(attrs[:uprice_diff]),
        amt_diff: to_decimal(attrs[:amt_diff]),
        cur_cd: attrs[:cur_cd].to_s.strip.upcase,
        ref_fee_rt_no: resolved_ref_fee_rt_no,
        ref_fee_rt_lineno: resolved_ref_fee_rt_lineno,
        prcs_sctn_cd: process_code,
        rtac_proc_stat_cd: "RTAC"
      }
    end

    def resolved_ref_fee_rt_no
      requested = params[:ref_fee_rt_no].to_s.strip.upcase
      if requested.present?
        requested
      else
        @rate_master.wrhs_exca_fee_rt_no
      end
    end

    def resolved_ref_fee_rt_lineno
      requested = params[:ref_fee_rt_lineno].to_s.strip
      if requested.present?
        requested.to_i
      else
        nil
      end
    end

    def normalize_ymd(value)
      value.to_s.gsub(/[^0-9]/, "").first(8)
    end

    def to_decimal(value)
      BigDecimal(value.to_s)
    rescue ArgumentError
      BigDecimal("0")
    end
end
