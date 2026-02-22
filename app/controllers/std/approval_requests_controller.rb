class Std::ApprovalRequestsController < Std::BaseController
  def index
    respond_to do |format|
      format.html
      format.json { render json: requests_scope.map { |row| request_json(row) } }
    end
  end

  def request_action
    ids = normalized_request_ids(action_params[:apv_req_nos])
    content = action_params[:apv_req_conts].to_s.strip
    changed_approver = action_params[:apver_chg].to_s.strip.upcase
    request_status = action_params[:apv_stat_cd].to_s.strip.upcase.presence || "REQUESTED"
    request_type = action_params[:apv_type_cd].to_s.strip.upcase.presence
    if ids.blank?
      render json: { success: false, errors: [ "결재요청번호를 선택해주세요." ] }, status: :unprocessable_entity
      return
    end

    ActiveRecord::Base.transaction do
      rows = StdApprovalRequest.where(apv_req_no: ids)
      rows.find_each do |row|
        if content.present?
          row.apv_req_conts = content
        end
        if changed_approver.present?
          row.apver_chg = changed_approver
        end
        row.apv_stat_cd = request_status
        if request_type.present?
          row.apv_type_cd = request_type
        end
        row.apv_req_ymd = Time.current
        row.save!
      end
    end

    render json: { success: true, message: "결재요청 처리가 완료되었습니다." }
  rescue ActiveRecord::RecordInvalid => e
    render json: { success: false, errors: [ e.record.errors.full_messages.join(", ") ] }, status: :unprocessable_entity
  end

  def approve_action
    ids = normalized_request_ids(action_params[:apv_req_nos])
    opinion = action_params[:apv_opi].to_s.strip
    changed_approver = action_params[:apver_chg].to_s.strip.upcase
    approve_status = action_params[:apv_stat_cd].to_s.strip.upcase.presence || "APPROVED"
    approve_type = action_params[:apv_type_cd].to_s.strip.upcase.presence
    if ids.blank?
      render json: { success: false, errors: [ "결재요청번호를 선택해주세요." ] }, status: :unprocessable_entity
      return
    end

    ActiveRecord::Base.transaction do
      rows = StdApprovalRequest.where(apv_req_no: ids)
      rows.find_each do |row|
        if opinion.present?
          row.apv_opi = opinion
        end
        if changed_approver.present?
          row.apver_chg = changed_approver
        end
        row.apv_stat_cd = approve_status
        if approve_type.present?
          row.apv_type_cd = approve_type
        end
        row.apv_apv_ymd = Time.current
        row.save!
      end
    end

    render json: { success: true, message: "결재승인 처리가 완료되었습니다." }
  rescue ActiveRecord::RecordInvalid => e
    render json: { success: false, errors: [ e.record.errors.full_messages.join(", ") ] }, status: :unprocessable_entity
  end

  def batch_save
    operations = batch_save_params
    result = { inserted: 0, updated: 0, deleted: 0 }
    errors = []

    ActiveRecord::Base.transaction do
      Array(operations[:rowsToInsert]).each do |attrs|
        if attrs[:menu_nm].to_s.strip.blank?
          next
        end

        row = StdApprovalRequest.new(request_params_from_row(attrs))
        if row.save
          result[:inserted] += 1
        else
          errors.concat(row.errors.full_messages)
        end
      end

      Array(operations[:rowsToUpdate]).each do |attrs|
        apv_req_no = attrs[:apv_req_no].to_s.strip.upcase
        row = StdApprovalRequest.find_by(apv_req_no: apv_req_no)
        if row.nil?
          errors << "결재요청번호를 찾을 수 없습니다: #{apv_req_no}"
          next
        end

        update_attrs = request_params_from_row(attrs)
        update_attrs.delete(:apv_req_no)
        if row.update(update_attrs)
          result[:updated] += 1
        else
          errors.concat(row.errors.full_messages)
        end
      end

      Array(operations[:rowsToDelete]).each do |apv_req_no|
        row = StdApprovalRequest.find_by(apv_req_no: apv_req_no.to_s.strip.upcase)
        if row.nil?
          next
        end

        if row.update(use_yn: "N", apv_stat_cd: "CANCELED")
          result[:deleted] += 1
        else
          errors.concat(row.errors.full_messages.presence || [ "결재요청 취소에 실패했습니다: #{apv_req_no}" ])
        end
      end

      if errors.any?
        raise ActiveRecord::Rollback
      end
    end

    if errors.any?
      render json: { success: false, errors: errors.uniq }, status: :unprocessable_entity
    else
      render json: { success: true, message: "결재요청 데이터가 저장되었습니다.", data: result }
    end
  end

  private
    def menu_code_for_permission
      "STD_APPROVAL_REQUEST"
    end

    def search_params
      params.fetch(:q, {}).permit(:corp_cd, :menu_cd, :menu_nm, :apv_stat_cd, :apv_reqr, :asmt_apver)
    end

    def action_params
      params.permit(:apv_req_conts, :apv_opi, :apver_chg, :apv_stat_cd, :apv_type_cd, apv_req_nos: [])
    end

    def requests_scope
      scope = StdApprovalRequest.ordered
      if search_corp_cd.present?
        scope = scope.where(corp_cd: search_corp_cd)
      end
      if search_menu_nm.present?
        scope = scope.where("menu_nm LIKE ?", "%#{search_menu_nm}%")
      end
      if search_menu_cd.present?
        scope = scope.where(menu_cd: search_menu_cd)
      end
      if search_apv_stat_cd.present?
        scope = scope.where(apv_stat_cd: search_apv_stat_cd)
      end
      if search_apv_reqr.present?
        scope = scope.where("apv_reqr LIKE ?", "%#{search_apv_reqr}%")
      end
      if search_asmt_apver.present?
        keyword = "%#{search_asmt_apver}%"
        scope = scope.where("asmt_apver LIKE ? OR apver_chg LIKE ?", keyword, keyword)
      end
      scope
    end

    def search_corp_cd
      search_params[:corp_cd].to_s.strip.upcase.presence
    end

    def search_menu_nm
      search_params[:menu_nm].to_s.strip.presence
    end

    def search_menu_cd
      search_params[:menu_cd].to_s.strip.upcase.presence
    end

    def search_apv_stat_cd
      search_params[:apv_stat_cd].to_s.strip.upcase.presence
    end

    def search_apv_reqr
      search_params[:apv_reqr].to_s.strip.upcase.presence
    end

    def search_asmt_apver
      search_params[:asmt_apver].to_s.strip.upcase.presence
    end

    def normalized_request_ids(raw_ids)
      Array(raw_ids).map { |id| id.to_s.strip.upcase }.reject(&:blank?).uniq
    end

    def batch_save_params
      params.permit(
        rowsToDelete: [],
        rowsToInsert: [
          :apv_req_no, :corp_cd, :menu_cd, :menu_nm, :apv_reqr, :asmt_apver, :apver_chg, :user_cd,
          :apv_req_conts, :apv_req_ymd, :apv_opi, :apv_apv_ymd, :apv_stat_cd, :apv_type_cd, :use_yn
        ],
        rowsToUpdate: [
          :apv_req_no, :corp_cd, :menu_cd, :menu_nm, :apv_reqr, :asmt_apver, :apver_chg, :user_cd,
          :apv_req_conts, :apv_req_ymd, :apv_opi, :apv_apv_ymd, :apv_stat_cd, :apv_type_cd, :use_yn
        ]
      )
    end

    def request_params_from_row(row)
      row.permit(
        :apv_req_no, :corp_cd, :menu_cd, :menu_nm, :apv_reqr, :asmt_apver, :apver_chg, :user_cd,
        :apv_req_conts, :apv_req_ymd, :apv_opi, :apv_apv_ymd, :apv_stat_cd, :apv_type_cd, :use_yn
      ).to_h.symbolize_keys
    end

    def request_json(row)
      {
        id: row.apv_req_no,
        apv_req_no: row.apv_req_no,
        corp_cd: row.corp_cd,
        menu_cd: row.menu_cd,
        menu_nm: row.menu_nm,
        apv_reqr: row.apv_reqr,
        asmt_apver: row.asmt_apver,
        apver_chg: row.apver_chg,
        user_cd: row.user_cd,
        apv_req_conts: row.apv_req_conts,
        apv_req_ymd: row.apv_req_ymd,
        apv_opi: row.apv_opi,
        apv_apv_ymd: row.apv_apv_ymd,
        apv_stat_cd: row.apv_stat_cd,
        apv_type_cd: row.apv_type_cd,
        use_yn: row.use_yn,
        create_by: row.create_by,
        create_time: row.create_time,
        update_by: row.update_by,
        update_time: row.update_time
      }
    end
end
