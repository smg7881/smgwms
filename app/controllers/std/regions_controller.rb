class Std::RegionsController < Std::BaseController
  def index
    respond_to do |format|
      format.html
      format.json { render json: regions_scope.map { |row| region_json(row) } }
    end
  end

  def batch_save
    operations = batch_save_params
    result = { inserted: 0, updated: 0, deleted: 0 }
    errors = []

    ActiveRecord::Base.transaction do
      Array(operations[:rowsToInsert]).each do |attrs|
        if attrs[:regn_nm_cd].to_s.strip.blank?
          next
        end

        row = StdRegion.new(region_params_from_row(attrs))
        if row.save
          result[:inserted] += 1
        else
          errors.concat(row.errors.full_messages)
        end
      end

      Array(operations[:rowsToUpdate]).each do |attrs|
        regn_cd = attrs[:regn_cd].to_s.strip.upcase
        row = StdRegion.find_by(regn_cd: regn_cd)
        if row.nil?
          errors << "권역코드를 찾을 수 없습니다: #{regn_cd}"
          next
        end

        update_attrs = region_params_from_row(attrs)
        update_attrs.delete(:regn_cd)
        if row.update(update_attrs)
          result[:updated] += 1
        else
          errors.concat(row.errors.full_messages)
        end
      end

      Array(operations[:rowsToDelete]).each do |regn_cd|
        row = StdRegion.find_by(regn_cd: regn_cd.to_s.strip.upcase)
        if row.nil?
          next
        end

        if row.update(use_yn_cd: "N")
          result[:deleted] += 1
        else
          errors.concat(row.errors.full_messages.presence || [ "권역 비활성화에 실패했습니다: #{regn_cd}" ])
        end
      end

      if errors.any?
        raise ActiveRecord::Rollback
      end
    end

    if errors.any?
      render json: { success: false, errors: errors.uniq }, status: :unprocessable_entity
    else
      render json: { success: true, message: "권역 데이터가 저장되었습니다.", data: result }
    end
  end

  private
    def menu_code_for_permission
      "STD_REGION"
    end

    def search_params
      params.fetch(:q, {}).permit(:corp_cd, :regn_cd, :regn_nm_cd, :use_yn_cd)
    end

    def regions_scope
      scope = StdRegion.ordered
      if search_corp_cd.present?
        scope = scope.where(corp_cd: search_corp_cd)
      end
      if search_regn_cd.present?
        scope = scope.where("regn_cd LIKE ?", "%#{search_regn_cd}%")
      end
      if search_regn_nm_cd.present?
        scope = scope.where("regn_nm_cd LIKE ?", "%#{search_regn_nm_cd}%")
      end
      if search_use_yn_cd.present?
        scope = scope.where(use_yn_cd: search_use_yn_cd)
      end
      scope
    end

    def search_corp_cd
      search_params[:corp_cd].to_s.strip.upcase.presence
    end

    def search_regn_cd
      search_params[:regn_cd].to_s.strip.upcase.presence
    end

    def search_regn_nm_cd
      search_params[:regn_nm_cd].to_s.strip.presence
    end

    def search_use_yn_cd
      search_params[:use_yn_cd].to_s.strip.upcase.presence
    end

    def batch_save_params
      params.permit(
        rowsToDelete: [],
        rowsToInsert: [ :corp_cd, :regn_cd, :regn_nm_cd, :regn_eng_nm_cd, :upper_regn_cd, :rmk_cd, :use_yn_cd ],
        rowsToUpdate: [ :corp_cd, :regn_cd, :regn_nm_cd, :regn_eng_nm_cd, :upper_regn_cd, :rmk_cd, :use_yn_cd ]
      )
    end

    def region_params_from_row(row)
      row.permit(
        :corp_cd, :regn_cd, :regn_nm_cd, :regn_eng_nm_cd, :upper_regn_cd, :rmk_cd, :use_yn_cd
      ).to_h.symbolize_keys
    end

    def region_json(row)
      {
        id: row.regn_cd,
        corp_cd: row.corp_cd,
        regn_cd: row.regn_cd,
        regn_nm_cd: row.regn_nm_cd,
        regn_eng_nm_cd: row.regn_eng_nm_cd,
        upper_regn_cd: row.upper_regn_cd,
        rmk_cd: row.rmk_cd,
        use_yn_cd: row.use_yn_cd,
        create_by: row.create_by,
        create_time: row.create_time,
        update_by: row.update_by,
        update_time: row.update_time
      }
    end
end
