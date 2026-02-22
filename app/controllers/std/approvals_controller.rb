class Std::ApprovalsController < Std::BaseController
  def index
    respond_to do |format|
      format.html
      format.json { render json: approvals_scope.map { |row| approval_json(row) } }
    end
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

        row = StdApproval.new(approval_params_from_row(attrs))
        if row.save
          result[:inserted] += 1
        else
          errors.concat(row.errors.full_messages)
        end
      end

      Array(operations[:rowsToUpdate]).each do |attrs|
        corp_cd = attrs[:corp_cd].to_s.strip.upcase
        menu_cd = attrs[:menu_cd].to_s.strip.upcase
        row = StdApproval.find_by(corp_cd: corp_cd, menu_cd: menu_cd)
        if row.nil?
          errors << "결재관리를 찾을 수 없습니다: #{corp_cd}/#{menu_cd}"
          next
        end

        update_attrs = approval_params_from_row(attrs)
        update_attrs.delete(:corp_cd)
        update_attrs.delete(:menu_cd)
        if row.update(update_attrs)
          result[:updated] += 1
        else
          errors.concat(row.errors.full_messages)
        end
      end

      Array(operations[:rowsToDelete]).each do |key|
        corp_cd = key[:corp_cd].to_s.strip.upcase
        menu_cd = key[:menu_cd].to_s.strip.upcase
        row = StdApproval.find_by(corp_cd: corp_cd, menu_cd: menu_cd)
        if row.nil?
          next
        end

        if row.update(use_yn: "N")
          result[:deleted] += 1
        else
          errors.concat(row.errors.full_messages.presence || [ "결재관리 비활성화에 실패했습니다: #{corp_cd}/#{menu_cd}" ])
        end
      end

      if errors.any?
        raise ActiveRecord::Rollback
      end
    end

    if errors.any?
      render json: { success: false, errors: errors.uniq }, status: :unprocessable_entity
    else
      render json: { success: true, message: "결재관리 데이터가 저장되었습니다.", data: result }
    end
  end

  private
    def menu_code_for_permission
      "STD_APPROVAL"
    end

    def search_params
      params.fetch(:q, {}).permit(:corp_cd, :menu_cd, :menu_nm, :use_yn)
    end

    def approvals_scope
      scope = StdApproval.ordered
      if search_corp_cd.present?
        scope = scope.where(corp_cd: search_corp_cd)
      end
      if search_menu_cd.present?
        scope = scope.where("menu_cd LIKE ?", "%#{search_menu_cd}%")
      end
      if search_menu_nm.present?
        scope = scope.where("menu_nm LIKE ?", "%#{search_menu_nm}%")
      end
      if search_use_yn.present?
        scope = scope.where(use_yn: search_use_yn)
      end
      scope
    end

    def search_corp_cd
      search_params[:corp_cd].to_s.strip.upcase.presence
    end

    def search_menu_cd
      search_params[:menu_cd].to_s.strip.upcase.presence
    end

    def search_menu_nm
      search_params[:menu_nm].to_s.strip.presence
    end

    def search_use_yn
      search_params[:use_yn].to_s.strip.upcase.presence
    end

    def batch_save_params
      params.permit(
        rowsToDelete: [ :corp_cd, :menu_cd ],
        rowsToInsert: [
          :corp_cd, :corp_nm, :menu_cd, :menu_nm, :table_cd,
          :col1_cd, :col2_cd, :col3_cd, :col4_cd, :col5_cd,
          :asmt_apver_yn, :chrg_apver, :not_asmt_apver_resp,
          :apv_type_cd, :apv_delegt_yn, :apv_delegate, :rmk, :use_yn
        ],
        rowsToUpdate: [
          :corp_cd, :corp_nm, :menu_cd, :menu_nm, :table_cd,
          :col1_cd, :col2_cd, :col3_cd, :col4_cd, :col5_cd,
          :asmt_apver_yn, :chrg_apver, :not_asmt_apver_resp,
          :apv_type_cd, :apv_delegt_yn, :apv_delegate, :rmk, :use_yn
        ]
      )
    end

    def approval_params_from_row(row)
      row.permit(
        :corp_cd, :corp_nm, :menu_cd, :menu_nm, :table_cd,
        :col1_cd, :col2_cd, :col3_cd, :col4_cd, :col5_cd,
        :asmt_apver_yn, :chrg_apver, :not_asmt_apver_resp,
        :apv_type_cd, :apv_delegt_yn, :apv_delegate, :rmk, :use_yn
      ).to_h.symbolize_keys
    end

    def approval_json(row)
      {
        id: "#{row.corp_cd}_#{row.menu_cd}",
        corp_cd: row.corp_cd,
        corp_nm: row.corp_nm,
        menu_cd: row.menu_cd,
        menu_nm: row.menu_nm,
        table_cd: row.table_cd,
        col1_cd: row.col1_cd,
        col2_cd: row.col2_cd,
        col3_cd: row.col3_cd,
        col4_cd: row.col4_cd,
        col5_cd: row.col5_cd,
        asmt_apver_yn: row.asmt_apver_yn,
        chrg_apver: row.chrg_apver,
        not_asmt_apver_resp: row.not_asmt_apver_resp,
        apv_type_cd: row.apv_type_cd,
        apv_delegt_yn: row.apv_delegt_yn,
        apv_delegate: row.apv_delegate,
        rmk: row.rmk,
        use_yn: row.use_yn,
        create_by: row.create_by,
        create_time: row.create_time,
        update_by: row.update_by,
        update_time: row.update_time
      }
    end
end
