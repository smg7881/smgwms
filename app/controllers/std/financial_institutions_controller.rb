class Std::FinancialInstitutionsController < Std::BaseController
  def index
    respond_to do |format|
      format.html
      format.json { render json: financial_institutions_scope.map { |row| financial_institution_json(row) } }
    end
  end

  def batch_save
    operations = batch_save_params
    result = { inserted: 0, updated: 0, deleted: 0 }
    errors = []

    ActiveRecord::Base.transaction do
      Array(operations[:rowsToInsert]).each do |attrs|
        if attrs[:fnc_or_cd].to_s.strip.blank? && attrs[:fnc_or_nm].to_s.strip.blank?
          next
        end

        row = StdFinancialInstitution.new(financial_institution_params_from_row(attrs))
        if row.save
          result[:inserted] += 1
        else
          errors.concat(row.errors.full_messages)
        end
      end

      Array(operations[:rowsToUpdate]).each do |attrs|
        fnc_or_cd = attrs[:fnc_or_cd].to_s.strip.upcase
        row = StdFinancialInstitution.find_by(fnc_or_cd: fnc_or_cd)
        if row.nil?
          errors << "금융기관코드를 찾을 수 없습니다: #{fnc_or_cd}"
          next
        end

        update_attrs = financial_institution_params_from_row(attrs)
        update_attrs.delete(:fnc_or_cd)
        if row.update(update_attrs)
          result[:updated] += 1
        else
          errors.concat(row.errors.full_messages)
        end
      end

      Array(operations[:rowsToDelete]).each do |fnc_or_cd|
        row = StdFinancialInstitution.find_by(fnc_or_cd: fnc_or_cd.to_s.strip.upcase)
        if row.nil?
          next
        end

        if row.update(use_yn_cd: "N")
          result[:deleted] += 1
        else
          errors.concat(row.errors.full_messages.presence || [ "금융기관 비활성화에 실패했습니다: #{fnc_or_cd}" ])
        end
      end

      if errors.any?
        raise ActiveRecord::Rollback
      end
    end

    if errors.any?
      render json: { success: false, errors: errors.uniq }, status: :unprocessable_entity
    else
      render json: { success: true, message: "금융기관 정보가 저장되었습니다.", data: result }
    end
  end

  private
    def menu_code_for_permission
      "STD_FIN_ORG"
    end

    def search_params
      params.fetch(:q, {}).permit(:fnc_or_cd, :fnc_or_nm, :ctry_cd, :use_yn_cd)
    end

    def financial_institutions_scope
      scope = StdFinancialInstitution.ordered
      if search_fnc_or_cd.present?
        scope = scope.where("fnc_or_cd LIKE ?", "%#{search_fnc_or_cd}%")
      end
      if search_fnc_or_nm.present?
        scope = scope.where("fnc_or_nm LIKE ? OR fnc_or_eng_nm LIKE ?", "%#{search_fnc_or_nm}%", "%#{search_fnc_or_nm}%")
      end
      if search_ctry_cd.present?
        scope = scope.where(ctry_cd: search_ctry_cd)
      end
      if search_use_yn_cd.present?
        scope = scope.where(use_yn_cd: search_use_yn_cd)
      end
      scope
    end

    def search_fnc_or_cd
      search_params[:fnc_or_cd].to_s.strip.upcase.presence
    end

    def search_fnc_or_nm
      search_params[:fnc_or_nm].to_s.strip.presence
    end

    def search_ctry_cd
      search_params[:ctry_cd].to_s.strip.upcase.presence
    end

    def search_use_yn_cd
      search_params[:use_yn_cd].to_s.strip.upcase.presence
    end

    def batch_save_params
      params.permit(
        rowsToDelete: [],
        rowsToInsert: [ :fnc_or_cd, :fnc_or_nm, :fnc_or_eng_nm, :ctry_cd, :ctry_nm, :use_yn_cd ],
        rowsToUpdate: [ :fnc_or_cd, :fnc_or_nm, :fnc_or_eng_nm, :ctry_cd, :ctry_nm, :use_yn_cd ]
      )
    end

    def financial_institution_params_from_row(row)
      row.permit(
        :fnc_or_cd, :fnc_or_nm, :fnc_or_eng_nm, :ctry_cd, :ctry_nm, :use_yn_cd
      ).to_h.symbolize_keys
    end

    def financial_institution_json(row)
      {
        id: row.fnc_or_cd,
        fnc_or_cd: row.fnc_or_cd,
        fnc_or_nm: row.fnc_or_nm,
        fnc_or_eng_nm: row.fnc_or_eng_nm,
        ctry_cd: row.ctry_cd,
        ctry_nm: row.ctry_nm,
        use_yn_cd: row.use_yn_cd,
        create_by: row.create_by,
        create_time: row.create_time,
        update_by: row.update_by,
        update_time: row.update_time
      }
    end
end
