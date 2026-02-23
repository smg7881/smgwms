class Std::RegionsController < Std::BaseController
  def index
    respond_to do |format|
      format.html
      format.json do
        rows = regions_scope.to_a
        corp_name_by_code = build_corp_name_by_code(rows)
        upper_region_name_by_code = build_upper_region_name_by_code(rows)
        payload = rows.map do |row|
          region_json(
            row,
            corp_name_by_code: corp_name_by_code,
            upper_region_name_by_code: upper_region_name_by_code
          )
        end

        render json: payload
      end
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
      params.fetch(:q, {}).permit(:corp_cd, :regn_keyword, :regn_cd, :regn_nm_cd, :use_yn_cd)
    end

    def regions_scope
      scope = StdRegion.ordered
      if search_corp_cd.present?
        scope = scope.where("#{normalized_upper_sql('corp_cd')} = ?", search_corp_cd)
      end
      if search_regn_keyword.present?
        keyword = "%#{search_regn_keyword}%"
        scope = scope.where("regn_cd LIKE ? OR regn_nm_cd LIKE ?", keyword, keyword)
      end
      if search_use_yn_cd.present?
        scope = scope.where(use_yn_cd: search_use_yn_cd)
      end
      scope
    end

    def search_corp_cd
      search_params[:corp_cd].to_s.strip.upcase.presence
    end

    def search_regn_keyword
      value = search_params[:regn_keyword].presence || search_params[:regn_cd].presence || search_params[:regn_nm_cd].presence
      value.to_s.strip.upcase.presence
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

    def region_json(row, corp_name_by_code:, upper_region_name_by_code:)
      regn_cd = row.regn_cd.to_s.strip.upcase
      corp_cd = row.corp_cd.to_s.strip.upcase
      upper_regn_cd = row.upper_regn_cd.to_s.strip.upcase

      {
        id: regn_cd,
        corp_cd: corp_cd,
        corp_nm: resolve_corp_name(corp_cd, corp_name_by_code),
        regn_cd: regn_cd,
        regn_nm_cd: row.regn_nm_cd,
        regn_eng_nm_cd: row.regn_eng_nm_cd,
        upper_regn_cd: upper_regn_cd.presence,
        upper_regn_nm: resolve_upper_region_name(upper_regn_cd, upper_region_name_by_code),
        rmk_cd: row.rmk_cd,
        use_yn_cd: row.use_yn_cd,
        create_by: row.create_by,
        create_time: row.create_time,
        update_by: row.update_by,
        update_time: row.update_time
      }
    end

    def build_corp_name_by_code(rows)
      corp_codes = rows.map { |row| row.corp_cd.to_s.strip.upcase.presence }.compact.uniq
      if corp_codes.empty?
        return {}
      end

      StdCorporation
        .where("#{normalized_upper_sql('corp_cd')} IN (?)", corp_codes)
        .pluck(:corp_cd, :corp_nm)
        .to_h { |corp_cd, corp_nm| [ corp_cd.to_s.strip.upcase, corp_nm ] }
    rescue ActiveRecord::StatementInvalid
      {}
    end

    def build_upper_region_name_by_code(rows)
      upper_region_codes = rows.map { |row| row.upper_regn_cd.to_s.strip.upcase.presence }.compact.uniq
      if upper_region_codes.empty?
        return {}
      end

      StdRegion
        .where("#{normalized_upper_sql('regn_cd')} IN (?)", upper_region_codes)
        .pluck(:regn_cd, :regn_nm_cd)
        .to_h { |regn_cd, regn_nm_cd| [ regn_cd.to_s.strip.upcase, regn_nm_cd ] }
    rescue ActiveRecord::StatementInvalid
      {}
    end

    def resolve_corp_name(corp_cd, corp_name_by_code)
      if corp_cd.blank?
        return nil
      end

      mapped = corp_name_by_code[corp_cd]
      if mapped.present?
        return mapped
      end

      corp_name_fallback_cache[corp_cd] ||= StdCorporation.where("#{normalized_upper_sql('corp_cd')} = ?", corp_cd).pick(:corp_nm)
    rescue ActiveRecord::StatementInvalid
      nil
    end

    def resolve_upper_region_name(upper_regn_cd, upper_region_name_by_code)
      if upper_regn_cd.blank?
        return nil
      end

      mapped = upper_region_name_by_code[upper_regn_cd]
      if mapped.present?
        return mapped
      end

      upper_region_name_fallback_cache[upper_regn_cd] ||= StdRegion.where("#{normalized_upper_sql('regn_cd')} = ?", upper_regn_cd).pick(:regn_nm_cd)
    rescue ActiveRecord::StatementInvalid
      nil
    end

    def corp_name_fallback_cache
      @corp_name_fallback_cache ||= {}
    end

    def upper_region_name_fallback_cache
      @upper_region_name_fallback_cache ||= {}
    end

    def normalized_upper_sql(column_name)
      "TRIM(UPPER(#{column_name}))"
    end
end
