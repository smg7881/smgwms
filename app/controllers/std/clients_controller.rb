class Std::ClientsController < Std::BaseController
  def index
    @selected_client = params[:selected_client].to_s.strip.upcase.presence

    respond_to do |format|
      format.html
      format.json { render json: clients_scope.map { |client| client_json(client) } }
    end
  end

  def sections
    group_code = params[:bzac_sctn_grp_cd].to_s.strip.upcase
    scope = AdmCodeDetail.active.where(code: "STD_BZAC_SCTN").ordered
    if group_code.present?
      scope = scope.where(upper_detail_code: group_code)
    end

    rows = scope.map do |row|
      {
        detail_code: row.detail_code,
        detail_code_name: row.detail_code_name
      }
    end

    render json: rows
  end

  def contacts
    client = find_client
    rows = client.ofcrs.ordered.map { |contact| contact_json(contact) }
    render json: rows
  end

  def workplaces
    client = find_client
    rows = client.workpls.ordered.map { |workplace| workplace_json(workplace) }
    render json: rows
  end

  def batch_save
    operations = batch_save_params
    result = { inserted: 0, updated: 0, deleted: 0 }
    errors = []

    ActiveRecord::Base.transaction do
      Array(operations[:rowsToInsert]).each do |attrs|
        if attrs[:bzac_nm].to_s.strip.blank? && attrs[:bizman_no].to_s.strip.blank?
          next
        end

        client = StdBzacMst.new(client_params_from_row(attrs))
        if client.save
          result[:inserted] += 1
        else
          errors.concat(client.errors.full_messages)
        end
      end

      Array(operations[:rowsToUpdate]).each do |attrs|
        bzac_cd = attrs[:bzac_cd].to_s.strip.upcase
        client = StdBzacMst.find_by(bzac_cd: bzac_cd)
        if client.nil?
          errors << "거래처를 찾을 수 없습니다: #{bzac_cd}"
          next
        end

        update_attrs = client_params_from_row(attrs)
        update_attrs.delete(:bzac_cd)
        client.assign_attributes(update_attrs)
        tracked_changes = client.changes_to_save.except("update_by", "update_time")

        if client.save
          save_change_histories!(client: client, tracked_changes: tracked_changes)
          result[:updated] += 1
        else
          errors.concat(client.errors.full_messages)
        end
      end

      Array(operations[:rowsToDelete]).each do |bzac_cd|
        normalized_code = bzac_cd.to_s.strip.upcase
        client = StdBzacMst.find_by(bzac_cd: normalized_code)
        if client.nil?
          next
        end

        before_use_yn = client.use_yn_cd
        if client.update(use_yn_cd: "N")
          if before_use_yn != "N"
            save_change_histories!(
              client: client,
              tracked_changes: { "use_yn_cd" => [ before_use_yn, "N" ] }
            )
          end
          result[:deleted] += 1
        else
          errors.concat(client.errors.full_messages.presence || [ "거래처 비활성화에 실패했습니다: #{normalized_code}" ])
        end
      end

      if errors.any?
        raise ActiveRecord::Rollback
      end
    end

    if errors.any?
      render json: { success: false, errors: errors.uniq }, status: :unprocessable_entity
    else
      render json: { success: true, message: "거래처 데이터가 저장되었습니다.", data: result }
    end
  end

  def batch_save_contacts
    client = find_client
    operations = contact_batch_save_params
    result = { inserted: 0, updated: 0, deleted: 0 }
    errors = []

    ActiveRecord::Base.transaction do
      Array(operations[:rowsToInsert]).each do |attrs|
        if attrs[:nm_cd].to_s.strip.blank?
          next
        end

        seq_cd = attrs[:seq_cd].to_i
        if seq_cd <= 0
          seq_cd = next_contact_seq(client.bzac_cd)
        end

        contact = StdBzacOfcr.new(contact_params_from_row(attrs).merge(bzac_cd: client.bzac_cd, seq_cd: seq_cd))
        if contact.save
          result[:inserted] += 1
        else
          errors.concat(contact.errors.full_messages)
        end
      end

      Array(operations[:rowsToUpdate]).each do |attrs|
        seq_cd = attrs[:seq_cd].to_i
        contact = StdBzacOfcr.find_by(bzac_cd: client.bzac_cd, seq_cd: seq_cd)
        if contact.nil?
          errors << "담당자를 찾을 수 없습니다: #{client.bzac_cd}/#{seq_cd}"
          next
        end

        if contact.update(contact_params_from_row(attrs).except(:seq_cd))
          result[:updated] += 1
        else
          errors.concat(contact.errors.full_messages)
        end
      end

      Array(operations[:rowsToDelete]).each do |seq_cd|
        contact = StdBzacOfcr.find_by(bzac_cd: client.bzac_cd, seq_cd: seq_cd.to_i)
        if contact.nil?
          next
        end

        if contact.destroy
          result[:deleted] += 1
        else
          errors.concat(contact.errors.full_messages.presence || [ "담당자 삭제에 실패했습니다: #{client.bzac_cd}/#{seq_cd}" ])
        end
      end

      if errors.any?
        raise ActiveRecord::Rollback
      end
    end

    if errors.any?
      render json: { success: false, errors: errors.uniq }, status: :unprocessable_entity
    else
      render json: { success: true, message: "담당자 데이터가 저장되었습니다.", data: result }
    end
  end

  def batch_save_workplaces
    client = find_client
    operations = workplace_batch_save_params
    result = { inserted: 0, updated: 0, deleted: 0 }
    errors = []

    ActiveRecord::Base.transaction do
      Array(operations[:rowsToInsert]).each do |attrs|
        if attrs[:workpl_nm_cd].to_s.strip.blank?
          next
        end

        seq_cd = attrs[:seq_cd].to_i
        if seq_cd <= 0
          seq_cd = next_workplace_seq(client.bzac_cd)
        end

        workplace = StdBzacWorkpl.new(workplace_params_from_row(attrs).merge(bzac_cd: client.bzac_cd, seq_cd: seq_cd))
        if workplace.save
          result[:inserted] += 1
        else
          errors.concat(workplace.errors.full_messages)
        end
      end

      Array(operations[:rowsToUpdate]).each do |attrs|
        seq_cd = attrs[:seq_cd].to_i
        workplace = StdBzacWorkpl.find_by(bzac_cd: client.bzac_cd, seq_cd: seq_cd)
        if workplace.nil?
          errors << "작업장을 찾을 수 없습니다: #{client.bzac_cd}/#{seq_cd}"
          next
        end

        if workplace.update(workplace_params_from_row(attrs).except(:seq_cd))
          result[:updated] += 1
        else
          errors.concat(workplace.errors.full_messages)
        end
      end

      Array(operations[:rowsToDelete]).each do |seq_cd|
        workplace = StdBzacWorkpl.find_by(bzac_cd: client.bzac_cd, seq_cd: seq_cd.to_i)
        if workplace.nil?
          next
        end

        if workplace.destroy
          result[:deleted] += 1
        else
          errors.concat(workplace.errors.full_messages.presence || [ "작업장 삭제에 실패했습니다: #{client.bzac_cd}/#{seq_cd}" ])
        end
      end

      if errors.any?
        raise ActiveRecord::Rollback
      end
    end

    if errors.any?
      render json: { success: false, errors: errors.uniq }, status: :unprocessable_entity
    else
      render json: { success: true, message: "작업장 데이터가 저장되었습니다.", data: result }
    end
  end

  private
    def menu_code_for_permission
      "STD_CLIENT"
    end

    def find_client
      bzac_cd = params[:id].to_s.strip.upcase
      StdBzacMst.find_by!(bzac_cd: bzac_cd)
    end

    def search_params
      params.fetch(:q, {}).permit(
        :bzac_cd, :bzacCd,
        :bzac_nm, :bzacNm,
        :mngt_corp_cd, :mngtCorpCd,
        :bzac_sctn_grp_cd, :bzacSctnGrpCd,
        :bzac_sctn_cd, :bzacSctnCd,
        :bizman_no, :bizmanNo,
        :use_yn_cd, :useYnCd
      )
    end

    def clients_scope
      scope = StdBzacMst.ordered

      if search_bzac_code.present?
        scope = scope.where("bzac_cd LIKE ?", "%#{search_bzac_code}%")
      end
      if search_bzac_name.present?
        scope = scope.where("bzac_nm LIKE ?", "%#{search_bzac_name}%")
      end
      if search_mngt_corp.present?
        scope = scope.where(mngt_corp_cd: search_mngt_corp)
      end
      if search_sctn_group.present?
        scope = scope.where(bzac_sctn_grp_cd: search_sctn_group)
      end
      if search_sctn.present?
        scope = scope.where(bzac_sctn_cd: search_sctn)
      end
      if search_bizman_no.present?
        scope = scope.where("bizman_no LIKE ?", "%#{search_bizman_no}%")
      end
      if search_use_yn.present?
        scope = scope.where(use_yn_cd: search_use_yn)
      end

      scope
    end

    def search_bzac_code
      value = search_params[:bzac_cd].presence || search_params[:bzacCd].presence
      value.to_s.strip.upcase.presence
    end

    def search_bzac_name
      value = search_params[:bzac_nm].presence || search_params[:bzacNm].presence
      value.to_s.strip.presence
    end

    def search_mngt_corp
      value = search_params[:mngt_corp_cd].presence || search_params[:mngtCorpCd].presence
      value.to_s.strip.upcase.presence
    end

    def search_sctn_group
      value = search_params[:bzac_sctn_grp_cd].presence || search_params[:bzacSctnGrpCd].presence
      value.to_s.strip.upcase.presence
    end

    def search_sctn
      value = search_params[:bzac_sctn_cd].presence || search_params[:bzacSctnCd].presence
      value.to_s.strip.upcase.presence
    end

    def search_bizman_no
      value = search_params[:bizman_no].presence || search_params[:bizmanNo].presence
      value.to_s.gsub(/[^0-9]/, "").presence
    end

    def search_use_yn
      value = search_params[:use_yn_cd].presence || search_params[:useYnCd].presence
      value.to_s.strip.upcase.presence
    end

    def batch_save_params
      params.permit(
        rowsToDelete: [],
        rowsToInsert: [
          :bzac_cd, :bzac_nm, :mngt_corp_cd, :bizman_no,
          :bzac_sctn_grp_cd, :bzac_sctn_cd, :bzac_kind_cd,
          :upper_bzac_cd, :rpt_bzac_cd, :ctry_cd, :tpl_logis_yn_cd,
          :if_yn_cd, :branch_yn_cd, :sell_bzac_yn_cd, :pur_bzac_yn_cd,
          :bilg_bzac_cd, :elec_taxbill_yn_cd, :fnc_or_cd, :acnt_no_cd,
          :zip_cd, :addr_cd, :addr_dtl_cd, :rpt_sales_emp_cd, :rpt_sales_emp_nm,
          :aply_strt_day_cd, :aply_end_day_cd, :use_yn_cd, :remk
        ],
        rowsToUpdate: [
          :bzac_cd, :bzac_nm, :mngt_corp_cd, :bizman_no,
          :bzac_sctn_grp_cd, :bzac_sctn_cd, :bzac_kind_cd,
          :upper_bzac_cd, :rpt_bzac_cd, :ctry_cd, :tpl_logis_yn_cd,
          :if_yn_cd, :branch_yn_cd, :sell_bzac_yn_cd, :pur_bzac_yn_cd,
          :bilg_bzac_cd, :elec_taxbill_yn_cd, :fnc_or_cd, :acnt_no_cd,
          :zip_cd, :addr_cd, :addr_dtl_cd, :rpt_sales_emp_cd, :rpt_sales_emp_nm,
          :aply_strt_day_cd, :aply_end_day_cd, :use_yn_cd, :remk
        ]
      )
    end

    def contact_batch_save_params
      params.permit(
        rowsToDelete: [],
        rowsToInsert: [ :seq_cd, :nm_cd, :ofic_telno_cd, :mbp_no_cd, :email_cd, :rpt_yn_cd, :use_yn_cd ],
        rowsToUpdate: [ :seq_cd, :nm_cd, :ofic_telno_cd, :mbp_no_cd, :email_cd, :rpt_yn_cd, :use_yn_cd ]
      )
    end

    def workplace_batch_save_params
      params.permit(
        rowsToDelete: [],
        rowsToInsert: [ :seq_cd, :workpl_nm_cd, :workpl_sctn_cd, :ofcr_cd, :use_yn_cd ],
        rowsToUpdate: [ :seq_cd, :workpl_nm_cd, :workpl_sctn_cd, :ofcr_cd, :use_yn_cd ]
      )
    end

    def client_params_from_row(row)
      row.permit(
        :bzac_cd, :bzac_nm, :mngt_corp_cd, :bizman_no,
        :bzac_sctn_grp_cd, :bzac_sctn_cd, :bzac_kind_cd,
        :upper_bzac_cd, :rpt_bzac_cd, :ctry_cd, :tpl_logis_yn_cd,
        :if_yn_cd, :branch_yn_cd, :sell_bzac_yn_cd, :pur_bzac_yn_cd,
        :bilg_bzac_cd, :elec_taxbill_yn_cd, :fnc_or_cd, :acnt_no_cd,
        :zip_cd, :addr_cd, :addr_dtl_cd, :rpt_sales_emp_cd, :rpt_sales_emp_nm,
        :aply_strt_day_cd, :aply_end_day_cd, :use_yn_cd, :remk
      ).to_h.symbolize_keys
    end

    def contact_params_from_row(row)
      row.permit(
        :seq_cd, :nm_cd, :ofic_telno_cd, :mbp_no_cd, :email_cd, :rpt_yn_cd, :use_yn_cd
      ).to_h.symbolize_keys
    end

    def workplace_params_from_row(row)
      row.permit(
        :seq_cd, :workpl_nm_cd, :workpl_sctn_cd, :ofcr_cd, :use_yn_cd
      ).to_h.symbolize_keys
    end

    def client_json(client)
      {
        id: client.bzac_cd,
        bzac_cd: client.bzac_cd,
        bzac_nm: client.bzac_nm,
        mngt_corp_cd: client.mngt_corp_cd,
        bizman_no: client.bizman_no,
        bzac_sctn_grp_cd: client.bzac_sctn_grp_cd,
        bzac_sctn_cd: client.bzac_sctn_cd,
        bzac_kind_cd: client.bzac_kind_cd,
        upper_bzac_cd: client.upper_bzac_cd,
        rpt_bzac_cd: client.rpt_bzac_cd,
        ctry_cd: client.ctry_cd,
        tpl_logis_yn_cd: client.tpl_logis_yn_cd,
        if_yn_cd: client.if_yn_cd,
        branch_yn_cd: client.branch_yn_cd,
        sell_bzac_yn_cd: client.sell_bzac_yn_cd,
        pur_bzac_yn_cd: client.pur_bzac_yn_cd,
        bilg_bzac_cd: client.bilg_bzac_cd,
        elec_taxbill_yn_cd: client.elec_taxbill_yn_cd,
        fnc_or_cd: client.fnc_or_cd,
        acnt_no_cd: client.acnt_no_cd,
        zip_cd: client.zip_cd,
        addr_cd: client.addr_cd,
        addr_dtl_cd: client.addr_dtl_cd,
        rpt_sales_emp_cd: client.rpt_sales_emp_cd,
        rpt_sales_emp_nm: client.rpt_sales_emp_nm,
        aply_strt_day_cd: client.aply_strt_day_cd,
        aply_end_day_cd: client.aply_end_day_cd,
        use_yn_cd: client.use_yn_cd,
        remk: client.remk,
        create_by: client.create_by,
        create_time: client.create_time,
        update_by: client.update_by,
        update_time: client.update_time
      }
    end

    def contact_json(contact)
      {
        id: "#{contact.bzac_cd}_#{contact.seq_cd}",
        bzac_cd: contact.bzac_cd,
        seq_cd: contact.seq_cd,
        nm_cd: contact.nm_cd,
        ofic_telno_cd: contact.ofic_telno_cd,
        mbp_no_cd: contact.mbp_no_cd,
        email_cd: contact.email_cd,
        rpt_yn_cd: contact.rpt_yn_cd,
        use_yn_cd: contact.use_yn_cd,
        create_by: contact.create_by,
        create_time: contact.create_time,
        update_by: contact.update_by,
        update_time: contact.update_time
      }
    end

    def workplace_json(workplace)
      {
        id: "#{workplace.bzac_cd}_#{workplace.seq_cd}",
        bzac_cd: workplace.bzac_cd,
        seq_cd: workplace.seq_cd,
        workpl_nm_cd: workplace.workpl_nm_cd,
        workpl_sctn_cd: workplace.workpl_sctn_cd,
        ofcr_cd: workplace.ofcr_cd,
        use_yn_cd: workplace.use_yn_cd,
        create_by: workplace.create_by,
        create_time: workplace.create_time,
        update_by: workplace.update_by,
        update_time: workplace.update_time
      }
    end

    def next_contact_seq(bzac_cd)
      StdBzacOfcr.where(bzac_cd: bzac_cd).maximum(:seq_cd).to_i + 1
    end

    def next_workplace_seq(bzac_cd)
      StdBzacWorkpl.where(bzac_cd: bzac_cd).maximum(:seq_cd).to_i + 1
    end

    def save_change_histories!(client:, tracked_changes:)
      if tracked_changes.blank?
        return
      end

      seq = StdCm04004.next_hist_seq_for(client.bzac_cd)
      now = Time.current
      actor = current_actor

      tracked_changes.each do |column_name, values|
        old_value, new_value = values
        StdCm04004.create!(
          bzac_cd: client.bzac_cd,
          hist_seq: seq,
          changed_col_nm: column_name,
          before_value: old_value.to_s,
          after_value: new_value.to_s,
          changed_by: actor,
          changed_at: now
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
