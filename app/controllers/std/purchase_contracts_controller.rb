class Std::PurchaseContractsController < Std::BaseController
  def index
    @selected_contract = params[:selected_contract].to_s.strip.upcase.presence

    respond_to do |format|
      format.html
      format.json do
        rows = purchase_contract_scope.to_a
        render json: rows.map { |row| purchase_contract_json(row) }
      end
    end
  end

  def settlements
    contract = find_contract
    rows = contract.settlements.ordered.map { |row| settlement_json(row) }
    render json: rows
  end

  def change_histories
    contract = find_contract
    rows = contract.change_histories.ordered.map { |row| change_history_json(row) }
    render json: rows
  end

  def batch_save
    operations = batch_save_params
    result = { inserted: 0, updated: 0, deleted: 0 }
    errors = []

    ActiveRecord::Base.transaction do
      Array(operations[:rowsToInsert]).each do |attrs|
        if attrs[:pur_ctrt_nm].to_s.strip.blank?
          next
        end

        record = StdPurchaseContract.new(contract_params_from_row(attrs))
        if record.save
          result[:inserted] += 1
        else
          errors.concat(record.errors.full_messages)
        end
      end

      Array(operations[:rowsToUpdate]).each do |attrs|
        pur_ctrt_no = attrs[:pur_ctrt_no].to_s.strip.upcase
        record = StdPurchaseContract.find_by(pur_ctrt_no: pur_ctrt_no)
        if record.nil?
          errors << "매입계약을 찾을 수 없습니다: #{pur_ctrt_no}"
          next
        end

        update_attrs = contract_params_from_row(attrs)
        update_attrs.delete(:pur_ctrt_no)
        record.assign_attributes(update_attrs)
        tracked_changes = record.changes_to_save.except("update_by", "update_time")

        if record.save
          save_change_histories!(
            purchase_contract: record,
            tracked_changes: tracked_changes,
            table_name: "std_purchase_contracts"
          )
          result[:updated] += 1
        else
          errors.concat(record.errors.full_messages)
        end
      end

      Array(operations[:rowsToDelete]).each do |entry|
        pur_ctrt_no = extract_contract_no(entry)
        if pur_ctrt_no.blank?
          next
        end

        record = StdPurchaseContract.find_by(pur_ctrt_no: pur_ctrt_no)
        if record.nil?
          next
        end

        before_use_yn = record.use_yn_cd
        if record.update(use_yn_cd: "N")
          if before_use_yn != "N"
            save_change_histories!(
              purchase_contract: record,
              tracked_changes: { "use_yn_cd" => [ before_use_yn, "N" ] },
              table_name: "std_purchase_contracts"
            )
          end
          result[:deleted] += 1
        else
          errors.concat(record.errors.full_messages.presence || [ "매입계약 비활성화에 실패했습니다: #{pur_ctrt_no}" ])
        end
      end

      if errors.any?
        raise ActiveRecord::Rollback
      end
    end

    if errors.any?
      render json: { success: false, errors: errors.uniq }, status: :unprocessable_entity
    else
      render json: { success: true, message: "매입계약 데이터가 저장되었습니다.", data: result }
    end
  end

  def batch_save_settlements
    contract = find_contract
    operations = settlement_batch_save_params
    result = { inserted: 0, updated: 0, deleted: 0 }
    errors = []

    ActiveRecord::Base.transaction do
      Array(operations[:rowsToInsert]).each do |attrs|
        if attrs[:fnc_or_cd].to_s.strip.blank? && attrs[:acnt_no_cd].to_s.strip.blank?
          next
        end

        seq_no = attrs[:seq_no].to_i
        if seq_no <= 0
          seq_no = next_settlement_seq(contract.id)
        end

        settlement = contract.settlements.new(settlement_params_from_row(attrs).merge(seq_no: seq_no))
        if settlement.save
          result[:inserted] += 1
        else
          errors.concat(settlement.errors.full_messages)
        end
      end

      Array(operations[:rowsToUpdate]).each do |attrs|
        seq_no = attrs[:seq_no].to_i
        settlement = contract.settlements.find_by(seq_no: seq_no)
        if settlement.nil?
          errors << "정산정보를 찾을 수 없습니다: #{contract.pur_ctrt_no}/#{seq_no}"
          next
        end

        update_attrs = settlement_params_from_row(attrs)
        update_attrs.delete(:seq_no)
        settlement.assign_attributes(update_attrs)
        tracked_changes = settlement.changes_to_save.except("update_by", "update_time")

        if settlement.save
          if tracked_changes.present?
            save_change_histories!(
              purchase_contract: contract,
              tracked_changes: tracked_changes.transform_keys { |key| "settlement.#{seq_no}.#{key}" },
              table_name: "std_purchase_contract_settlements"
            )
          end
          result[:updated] += 1
        else
          errors.concat(settlement.errors.full_messages)
        end
      end

      Array(operations[:rowsToDelete]).each do |seq_no|
        settlement = contract.settlements.find_by(seq_no: seq_no.to_i)
        if settlement.nil?
          next
        end

        if settlement.destroy
          save_change_histories!(
            purchase_contract: contract,
            tracked_changes: { "settlement.#{seq_no}.deleted" => [ settlement.attributes.to_json, "" ] },
            table_name: "std_purchase_contract_settlements"
          )
          result[:deleted] += 1
        else
          errors.concat(settlement.errors.full_messages.presence || [ "정산정보 삭제에 실패했습니다: #{contract.pur_ctrt_no}/#{seq_no}" ])
        end
      end

      if errors.any?
        raise ActiveRecord::Rollback
      end
    end

    if errors.any?
      render json: { success: false, errors: errors.uniq }, status: :unprocessable_entity
    else
      render json: { success: true, message: "매입계약 정산정보가 저장되었습니다.", data: result }
    end
  end

  private
    def menu_code_for_permission
      "STD_PUR_CONTRACT"
    end

    def find_contract
      pur_ctrt_no = params[:id].to_s.strip.upcase
      StdPurchaseContract.find_by!(pur_ctrt_no: pur_ctrt_no)
    end

    def search_params
      params.fetch(:q, {}).permit(
        :corp_cd, :corpCd,
        :bzac_cd, :bzacCd,
        :bzac_nm, :bzacNm,
        :ctrt_sctn_cd, :ctrtSctnCd,
        :pur_ctrt_no, :purCtrtNo,
        :inq_prid_from, :inqPridFrom,
        :inq_prid_to, :inqPridTo,
        :use_yn_cd, :useYnCd
      )
    end

    def purchase_contract_scope
      scope = StdPurchaseContract.ordered

      if search_corp_cd.present?
        scope = scope.where(corp_cd: search_corp_cd)
      end
      if search_bzac_cd.present?
        scope = scope.where("bzac_cd LIKE ?", "%#{search_bzac_cd}%")
      end
      if search_bzac_nm.present?
        scope = scope.where(bzac_cd: matched_bzac_codes(search_bzac_nm))
      end
      if search_ctrt_sctn_cd.present?
        scope = scope.where(ctrt_sctn_cd: search_ctrt_sctn_cd)
      end
      if search_pur_ctrt_no.present?
        scope = scope.where("pur_ctrt_no LIKE ?", "%#{search_pur_ctrt_no}%")
      end
      if search_inq_prid_from.present?
        scope = scope.where("ctrt_strt_day >= ?", search_inq_prid_from)
      end
      if search_inq_prid_to.present?
        scope = scope.where("ctrt_strt_day <= ?", search_inq_prid_to)
      end
      if search_use_yn_cd.present?
        scope = scope.where(use_yn_cd: search_use_yn_cd)
      end

      scope
    end

    def matched_bzac_codes(keyword)
      normalized = keyword.to_s.strip
      if normalized.blank?
        return []
      end
      if !defined?(StdBzacMst) || !StdBzacMst.table_exists?
        return []
      end

      StdBzacMst.where("bzac_nm LIKE ?", "%#{normalized}%").limit(500).pluck(:bzac_cd)
    rescue ActiveRecord::StatementInvalid
      []
    end

    def search_corp_cd
      value = search_params[:corp_cd].presence || search_params[:corpCd].presence
      value.to_s.strip.upcase.presence
    end

    def search_bzac_cd
      value = search_params[:bzac_cd].presence || search_params[:bzacCd].presence
      value.to_s.strip.upcase.presence
    end

    def search_bzac_nm
      value = search_params[:bzac_nm].presence || search_params[:bzacNm].presence
      value.to_s.strip.presence
    end

    def search_ctrt_sctn_cd
      value = search_params[:ctrt_sctn_cd].presence || search_params[:ctrtSctnCd].presence
      value.to_s.strip.upcase.presence
    end

    def search_pur_ctrt_no
      value = search_params[:pur_ctrt_no].presence || search_params[:purCtrtNo].presence
      value.to_s.strip.upcase.presence
    end

    def search_inq_prid_from
      value = search_params[:inq_prid_from].presence || search_params[:inqPridFrom].presence
      parse_date(value)
    end

    def search_inq_prid_to
      value = search_params[:inq_prid_to].presence || search_params[:inqPridTo].presence
      parse_date(value)
    end

    def search_use_yn_cd
      value = search_params[:use_yn_cd].presence || search_params[:useYnCd].presence
      value.to_s.strip.upcase.presence
    end

    def batch_save_params
      params.permit(
        rowsToDelete: [],
        rowsToInsert: contract_permitted_fields,
        rowsToUpdate: contract_permitted_fields
      )
    end

    def settlement_batch_save_params
      params.permit(
        rowsToDelete: [],
        rowsToInsert: settlement_permitted_fields,
        rowsToUpdate: settlement_permitted_fields
      )
    end

    def contract_permitted_fields
      [
        :corp_cd, :bzac_cd, :pur_ctrt_no, :pur_ctrt_nm, :bizman_no, :ctrt_sctn_cd, :ctrt_kind_cd,
        :bef_ctrt_no, :cprtco_ofcr_cd, :strt_ctrt_ymd, :ctrt_strt_day, :ctrt_end_day,
        :ctrt_exten_ymd, :ctrt_expi_noti_ymd, :ctrt_cnctr_ymd, :ctrt_cnctr_reason_cd,
        :ctrt_ofcr_cd, :ctrt_ofcr_nm, :ctrt_dept_cd, :ctrt_dept_nm, :loan_limt_over_yn_cd,
        :vat_sctn_cd, :apv_mthd_cd, :apv_type_cd, :bilg_mthd_cd, :dcsn_yn_cd, :use_yn_cd,
        :ctrt_chg_reason_cd, :op_area_cd, :re_ctrt_cond_cd, :ctrt_cnctr_cond_cd,
        :ctrt_cnctr_dtl_reason_cd, :pay_cond_cd, :bzac_sctn_cd, :work_step_no1_cd,
        :work_step_no2_cd, :remk
      ]
    end

    def settlement_permitted_fields
      [
        :seq_no, :fnc_or_cd, :fnc_or_nm, :acnt_no_cd, :dpstr_nm, :mon_cd,
        :aply_fnc_or_cd, :aply_fnc_or_nm, :anno_dgrcnt, :exrt_aply_std_cd, :prvs_cyfd_amt,
        :exca_ofcr_cd, :exca_ofcr_nm, :use_yn_cd, :remk
      ]
    end

    def contract_params_from_row(row)
      row.permit(*contract_permitted_fields).to_h.symbolize_keys
    end

    def settlement_params_from_row(row)
      row.permit(*settlement_permitted_fields).to_h.symbolize_keys
    end

    def purchase_contract_json(row)
      {
        id: row.pur_ctrt_no,
        corp_cd: row.corp_cd,
        bzac_cd: row.bzac_cd,
        bzac_nm: resolve_client_name(row.bzac_cd),
        pur_ctrt_no: row.pur_ctrt_no,
        pur_ctrt_nm: row.pur_ctrt_nm,
        bizman_no: row.bizman_no,
        ctrt_sctn_cd: row.ctrt_sctn_cd,
        ctrt_kind_cd: row.ctrt_kind_cd,
        bef_ctrt_no: row.bef_ctrt_no,
        cprtco_ofcr_cd: row.cprtco_ofcr_cd,
        strt_ctrt_ymd: row.strt_ctrt_ymd,
        ctrt_strt_day: row.ctrt_strt_day,
        ctrt_end_day: row.ctrt_end_day,
        ctrt_exten_ymd: row.ctrt_exten_ymd,
        ctrt_expi_noti_ymd: row.ctrt_expi_noti_ymd,
        ctrt_cnctr_ymd: row.ctrt_cnctr_ymd,
        ctrt_cnctr_reason_cd: row.ctrt_cnctr_reason_cd,
        ctrt_ofcr_cd: row.ctrt_ofcr_cd,
        ctrt_ofcr_nm: row.ctrt_ofcr_nm,
        ctrt_dept_cd: row.ctrt_dept_cd,
        ctrt_dept_nm: row.ctrt_dept_nm,
        loan_limt_over_yn_cd: row.loan_limt_over_yn_cd,
        vat_sctn_cd: row.vat_sctn_cd,
        apv_mthd_cd: row.apv_mthd_cd,
        apv_type_cd: row.apv_type_cd,
        bilg_mthd_cd: row.bilg_mthd_cd,
        dcsn_yn_cd: row.dcsn_yn_cd,
        use_yn_cd: row.use_yn_cd,
        ctrt_chg_reason_cd: row.ctrt_chg_reason_cd,
        op_area_cd: row.op_area_cd,
        re_ctrt_cond_cd: row.re_ctrt_cond_cd,
        ctrt_cnctr_cond_cd: row.ctrt_cnctr_cond_cd,
        ctrt_cnctr_dtl_reason_cd: row.ctrt_cnctr_dtl_reason_cd,
        pay_cond_cd: row.pay_cond_cd,
        bzac_sctn_cd: row.bzac_sctn_cd,
        work_step_no1_cd: row.work_step_no1_cd,
        work_step_no2_cd: row.work_step_no2_cd,
        remk: row.remk,
        create_by: row.create_by,
        create_time: row.create_time,
        update_by: row.update_by,
        update_time: row.update_time
      }
    end

    def settlement_json(row)
      {
        id: "#{row.purchase_contract_id}_#{row.seq_no}",
        seq_no: row.seq_no,
        fnc_or_cd: row.fnc_or_cd,
        fnc_or_nm: row.fnc_or_nm,
        acnt_no_cd: row.acnt_no_cd,
        dpstr_nm: row.dpstr_nm,
        mon_cd: row.mon_cd,
        aply_fnc_or_cd: row.aply_fnc_or_cd,
        aply_fnc_or_nm: row.aply_fnc_or_nm,
        anno_dgrcnt: row.anno_dgrcnt,
        exrt_aply_std_cd: row.exrt_aply_std_cd,
        prvs_cyfd_amt: row.prvs_cyfd_amt,
        exca_ofcr_cd: row.exca_ofcr_cd,
        exca_ofcr_nm: row.exca_ofcr_nm,
        use_yn_cd: row.use_yn_cd,
        remk: row.remk,
        create_by: row.create_by,
        create_time: row.create_time,
        update_by: row.update_by,
        update_time: row.update_time
      }
    end

    def change_history_json(row)
      {
        id: "#{row.purchase_contract_id}_#{row.seq_no}",
        seq_no: row.seq_no,
        chg_tbl_nm: row.chg_tbl_nm,
        chg_col_nm: row.chg_col_nm,
        chg_bef_conts: row.chg_bef_conts,
        chg_aft_conts: row.chg_aft_conts,
        regr_cd: row.regr_cd,
        chg_date: row.chg_date
      }
    end

    def resolve_client_name(bzac_cd)
      code = bzac_cd.to_s.strip.upcase
      if code.blank?
        return ""
      end
      if !defined?(StdBzacMst) || !StdBzacMst.table_exists?
        return code
      end

      row = StdBzacMst.find_by(bzac_cd: code)
      if row.present?
        row.bzac_nm.to_s
      else
        code
      end
    rescue ActiveRecord::StatementInvalid
      code
    end

    def extract_contract_no(entry)
      if entry.respond_to?(:to_h)
        hash = entry.to_h
        value = hash["pur_ctrt_no"].presence || hash[:pur_ctrt_no].presence
      else
        value = entry
      end

      value.to_s.strip.upcase.presence
    end

    def parse_date(value)
      source = value.to_s.strip
      if source.blank?
        nil
      else
        Date.parse(source)
      end
    rescue ArgumentError
      nil
    end

    def next_settlement_seq(contract_id)
      StdPurchaseContractSettlement.where(purchase_contract_id: contract_id).maximum(:seq_no).to_i + 1
    end

    def save_change_histories!(purchase_contract:, tracked_changes:, table_name:)
      if tracked_changes.blank?
        return
      end

      seq = StdPurchaseContractChangeHistory.next_hist_seq_for(purchase_contract.id)
      now = Time.current
      actor = current_actor

      tracked_changes.each do |column_name, values|
        before_value, after_value = values
        StdPurchaseContractChangeHistory.create!(
          purchase_contract_id: purchase_contract.id,
          seq_no: seq,
          chg_tbl_nm: table_name,
          chg_col_nm: column_name.to_s,
          chg_bef_conts: before_value.to_s,
          chg_aft_conts: after_value.to_s,
          regr_cd: actor,
          chg_date: now
        )
        seq += 1
      end
    end

    def current_actor
      if Current.user&.user_id_code.present?
        Current.user.user_id_code
      elsif Current.user&.email_address.present?
        Current.user.email_address
      else
        "system"
      end
    end
end
