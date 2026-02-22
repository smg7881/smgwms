class Std::CountriesController < Std::BaseController
  def index
    respond_to do |format|
      format.html
      format.json { render json: countries_scope.map { |row| country_json(row) } }
    end
  end

  def batch_save
    operations = batch_save_params
    result = { inserted: 0, updated: 0, deleted: 0 }
    errors = []

    ActiveRecord::Base.transaction do
      Array(operations[:rowsToInsert]).each do |attrs|
        if attrs[:ctry_nm].to_s.strip.blank?
          next
        end

        row = StdCountry.new(country_params_from_row(attrs))
        if row.save
          result[:inserted] += 1
        else
          errors.concat(row.errors.full_messages)
        end
      end

      Array(operations[:rowsToUpdate]).each do |attrs|
        ctry_cd = attrs[:ctry_cd].to_s.strip.upcase
        row = StdCountry.find_by(ctry_cd: ctry_cd)
        if row.nil?
          errors << "국가코드를 찾을 수 없습니다: #{ctry_cd}"
          next
        end

        update_attrs = country_params_from_row(attrs)
        update_attrs.delete(:ctry_cd)
        if row.update(update_attrs)
          result[:updated] += 1
        else
          errors.concat(row.errors.full_messages)
        end
      end

      Array(operations[:rowsToDelete]).each do |ctry_cd|
        row = StdCountry.find_by(ctry_cd: ctry_cd.to_s.strip.upcase)
        if row.nil?
          next
        end

        if row.update(use_yn_cd: "N")
          result[:deleted] += 1
        else
          errors.concat(row.errors.full_messages.presence || [ "국가코드 비활성화에 실패했습니다: #{ctry_cd}" ])
        end
      end

      if errors.any?
        raise ActiveRecord::Rollback
      end
    end

    if errors.any?
      render json: { success: false, errors: errors.uniq }, status: :unprocessable_entity
    else
      render json: { success: true, message: "국가코드 데이터가 저장되었습니다.", data: result }
    end
  end

  private
    def menu_code_for_permission
      "STD_COUNTRY"
    end

    def search_params
      params.fetch(:q, {}).permit(:corp_cd, :ctry_cd, :ctry_nm, :use_yn_cd)
    end

    def countries_scope
      scope = StdCountry.ordered
      if search_corp_cd.present?
        scope = scope.where(corp_cd: search_corp_cd)
      end
      if search_ctry_cd.present?
        scope = scope.where("ctry_cd LIKE ?", "%#{search_ctry_cd}%")
      end
      if search_ctry_nm.present?
        scope = scope.where("ctry_nm LIKE ? OR ctry_eng_nm LIKE ?", "%#{search_ctry_nm}%", "%#{search_ctry_nm}%")
      end
      if search_use_yn_cd.present?
        scope = scope.where(use_yn_cd: search_use_yn_cd)
      end
      scope
    end

    def search_corp_cd
      search_params[:corp_cd].to_s.strip.upcase.presence
    end

    def search_ctry_cd
      search_params[:ctry_cd].to_s.strip.upcase.presence
    end

    def search_ctry_nm
      search_params[:ctry_nm].to_s.strip.presence
    end

    def search_use_yn_cd
      search_params[:use_yn_cd].to_s.strip.upcase.presence
    end

    def batch_save_params
      params.permit(
        rowsToDelete: [],
        rowsToInsert: [ :ctry_cd, :ctry_nm, :ctry_eng_nm, :ctry_ar_cd, :ctry_telno, :corp_cd, :corp_nm, :use_yn_cd ],
        rowsToUpdate: [ :ctry_cd, :ctry_nm, :ctry_eng_nm, :ctry_ar_cd, :ctry_telno, :corp_cd, :corp_nm, :use_yn_cd ]
      )
    end

    def country_params_from_row(row)
      row.permit(
        :ctry_cd, :ctry_nm, :ctry_eng_nm, :ctry_ar_cd, :ctry_telno, :corp_cd, :corp_nm, :use_yn_cd
      ).to_h.symbolize_keys
    end

    def country_json(row)
      {
        id: row.ctry_cd,
        ctry_cd: row.ctry_cd,
        ctry_nm: row.ctry_nm,
        ctry_eng_nm: row.ctry_eng_nm,
        ctry_ar_cd: row.ctry_ar_cd,
        ctry_telno: row.ctry_telno,
        corp_cd: row.corp_cd,
        corp_nm: row.corp_nm,
        use_yn_cd: row.use_yn_cd,
        create_by: row.create_by,
        create_time: row.create_time,
        update_by: row.update_by,
        update_time: row.update_time
      }
    end
end
