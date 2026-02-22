class Std::ApprovalHistoriesController < Std::BaseController
  def index
    if request.format.html? && params[:q].blank?
      redirect_to std_approval_histories_path(q: { apv_stat_cd: "REQUESTED" })
      return
    end

    respond_to do |format|
      format.html
      format.json { render json: histories_scope.map { |row| history_json(row) } }
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

    render json: { success: true, message: "결재요청 상태로 변경되었습니다." }
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

    render json: { success: true, message: "결재승인 상태로 변경되었습니다." }
  rescue ActiveRecord::RecordInvalid => e
    render json: { success: false, errors: [ e.record.errors.full_messages.join(", ") ] }, status: :unprocessable_entity
  end

  private
    def menu_code_for_permission
      "STD_APPROVAL_HISTORY"
    end

    def search_params
      params.fetch(:q, {}).permit(:corp_cd, :menu_cd, :apv_stat_cd, :apv_reqr, :asmt_apver, :menu_nm)
    end

    def action_params
      params.permit(:apv_req_conts, :apv_opi, :apver_chg, :apv_stat_cd, :apv_type_cd, apv_req_nos: [])
    end

    def histories_scope
      scope = StdApprovalRequest.ordered
      if search_corp_cd.present?
        scope = scope.where(corp_cd: search_corp_cd)
      end
      if search_menu_cd.present?
        scope = scope.where(menu_cd: search_menu_cd)
      end
      if search_menu_nm.present?
        scope = scope.where("menu_nm LIKE ?", "%#{search_menu_nm}%")
      end
      if applied_status_filter.present?
        scope = scope.where(apv_stat_cd: applied_status_filter)
      end
      if search_apv_reqr.present?
        scope = scope.where("apv_reqr LIKE ?", "%#{search_apv_reqr}%")
      end
      if search_asmt_apver.present?
        keyword = "%#{search_asmt_apver}%"
        scope = scope.where("asmt_apver LIKE ? OR apver_chg LIKE ?", keyword, keyword)
      elsif search_apv_reqr.blank? && current_user_code.present?
        scope = scope.where("apv_reqr = :user OR asmt_apver = :user OR apver_chg = :user", user: current_user_code)
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

    def applied_status_filter
      if search_params.key?(:apv_stat_cd)
        search_apv_stat_cd
      else
        "REQUESTED"
      end
    end

    def normalized_request_ids(raw_ids)
      Array(raw_ids).map { |id| id.to_s.strip.upcase }.reject(&:blank?).uniq
    end

    def current_user_code
      Current.user&.user_id_code.to_s.strip.upcase.presence
    end

    def history_json(row)
      {
        id: row.apv_req_no,
        apv_req_no: row.apv_req_no,
        corp_cd: row.corp_cd,
        menu_cd: row.menu_cd,
        menu_nm: row.menu_nm,
        apv_reqr: row.apv_reqr,
        asmt_apver: row.asmt_apver,
        apver_chg: row.apver_chg,
        apv_req_conts: row.apv_req_conts,
        apv_req_ymd: row.apv_req_ymd,
        apv_opi: row.apv_opi,
        apv_apv_ymd: row.apv_apv_ymd,
        apv_stat_cd: row.apv_stat_cd,
        apv_type_cd: row.apv_type_cd,
        update_by: row.update_by,
        update_time: row.update_time
      }
    end
end
