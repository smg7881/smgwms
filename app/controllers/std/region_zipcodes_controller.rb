class Std::RegionZipcodesController < Std::BaseController
  def index
    default_corp = resolve_default_corporation
    @default_corp_code = default_corp&.corp_cd.to_s.strip.upcase
    @default_corp_name = default_corp&.corp_nm.to_s.strip
    @default_country_code = "KR"
    @default_country_name = "한국"
  end

  def mapped_zipcodes
    regn_cd = params[:regn_cd].to_s.strip.upcase
    corp_cd = normalized_corp_cd
    persist_selected_corp!(corp_cd)

    if regn_cd.blank?
      render json: []
      return
    end

    if region_out_of_corp_scope?(regn_cd: regn_cd, corp_cd: corp_cd)
      render json: []
      return
    end

    rows = StdRegionZipMapping.where(regn_cd: regn_cd).ordered.map do |mapping|
      zip = StdZipCode.find_by(ctry_cd: mapping.ctry_cd, zipcd: mapping.zipcd, seq_no: mapping.seq_no)
      mapping_json(mapping, zip)
    end

    render json: rows
  end

  def unmapped_zipcodes
    regn_cd = params[:regn_cd].to_s.strip.upcase
    corp_cd = normalized_corp_cd
    persist_selected_corp!(corp_cd)

    if regn_cd.present? && region_out_of_corp_scope?(regn_cd: regn_cd, corp_cd: corp_cd)
      render json: []
      return
    end

    scope = StdZipCode.active.ordered

    ctry_cd = params[:ctry_cd].to_s.strip.upcase
    if ctry_cd.present?
      scope = scope.where(ctry_cd: ctry_cd)
    end

    zipcd = params[:zipcd].to_s.strip.upcase
    if zipcd.present?
      scope = scope.where("zipcd LIKE ?", "%#{zipcd}%")
    end

    zipaddr = params[:zipaddr].to_s.strip
    if zipaddr.present?
      scope = scope.where("zipaddr LIKE ?", "%#{zipaddr}%")
    end

    mapped_key_map = {}
    if regn_cd.present?
      StdRegionZipMapping.where(regn_cd: regn_cd).pluck(:ctry_cd, :zipcd, :seq_no).each do |key_tuple|
        key = build_zip_key(*key_tuple)
        mapped_key_map[key] = true
      end
    end

    rows = scope.map do |zip|
      key = build_zip_key(zip.ctry_cd, zip.zipcd, zip.seq_no)
      if mapped_key_map[key]
        nil
      else
        zip_json(zip)
      end
    end.compact

    render json: rows
  end

  def save_mappings
    regn_cd = save_mapping_params[:regn_cd].to_s.strip.upcase
    corp_cd = normalized_corp_cd
    persist_selected_corp!(corp_cd)

    if regn_cd.blank?
      render json: { success: false, errors: [ "권역코드는 필수입니다." ] }, status: :unprocessable_entity
      return
    end

    if region_out_of_corp_scope?(regn_cd: regn_cd, corp_cd: corp_cd)
      render json: { success: false, errors: [ "선택한 법인에 속한 권역만 저장할 수 있습니다." ] }, status: :unprocessable_entity
      return
    end

    result = { inserted: 0, deleted: 0 }
    errors = []

    ActiveRecord::Base.transaction do
      deleted_count = StdRegionZipMapping.where(regn_cd: regn_cd).delete_all
      result[:deleted] = deleted_count

      Array(save_mapping_params[:rows]).each_with_index do |attrs, index|
        mapping = StdRegionZipMapping.new(
          regn_cd: regn_cd,
          ctry_cd: attrs[:ctry_cd],
          zipcd: attrs[:zipcd],
          seq_no: attrs[:seq_no],
          sort_seq: attrs[:sort_seq].presence || (index + 1)
        )

        if mapping.save
          result[:inserted] += 1
        else
          errors.concat(mapping.errors.full_messages)
        end
      end

      if errors.any?
        raise ActiveRecord::Rollback
      end
    end

    if errors.any?
      render json: { success: false, errors: errors.uniq }, status: :unprocessable_entity
    else
      render json: { success: true, message: "권역별 우편번호 매핑이 저장되었습니다.", data: result }
    end
  end

  private
    def menu_code_for_permission
      "STD_REGION_ZIP"
    end

    def save_mapping_params
      params.permit(
        :corp_cd,
        :regn_cd,
        rows: [ :ctry_cd, :zipcd, :seq_no, :sort_seq ]
      )
    end

    def normalized_corp_cd
      params[:corp_cd].to_s.strip.upcase
    end

    def persist_selected_corp!(corp_cd)
      if corp_cd.blank?
        return
      end

      session[:std_region_zip_selected_corp_cd] = corp_cd
    end

    def region_out_of_corp_scope?(regn_cd:, corp_cd:)
      if corp_cd.blank?
        return false
      end

      region = StdRegion.find_by(regn_cd: regn_cd)
      if region.nil?
        return true
      end

      region.corp_cd.to_s.strip.upcase != corp_cd
    end

    def resolve_default_corporation
      from_session = session[:std_region_zip_selected_corp_cd].to_s.strip.upcase
      if from_session.present?
        row = find_active_corporation(from_session)
        if row
          return row
        end
      end

      fallback_code = StdRegion.where(use_yn_cd: "Y").order(:corp_cd).limit(1).pick(:corp_cd).to_s.strip.upcase
      if fallback_code.present?
        row = find_active_corporation(fallback_code)
        if row
          return row
        end
      end

      StdCorporation.where(use_yn_cd: "Y").order(:corp_cd).first || StdCorporation.order(:corp_cd).first
    rescue ActiveRecord::StatementInvalid
      nil
    end

    def find_active_corporation(corp_cd)
      code = corp_cd.to_s.strip.upcase
      if code.blank?
        return nil
      end

      StdCorporation.where(use_yn_cd: "Y").find_by(corp_cd: code) || StdCorporation.find_by(corp_cd: code)
    rescue ActiveRecord::StatementInvalid
      nil
    end

    def build_zip_key(ctry_cd, zipcd, seq_no)
      "#{ctry_cd}::#{zipcd}::#{seq_no}"
    end

    def mapping_json(mapping, zip)
      {
        id: build_zip_key(mapping.ctry_cd, mapping.zipcd, mapping.seq_no),
        regn_cd: mapping.regn_cd,
        sort_seq: mapping.sort_seq,
        ctry_cd: mapping.ctry_cd,
        zipcd: mapping.zipcd,
        seq_no: mapping.seq_no,
        zipaddr: zip&.zipaddr,
        sido: zip&.sido,
        sgng: zip&.sgng,
        eupdiv: zip&.eupdiv
      }
    end

    def zip_json(zip)
      {
        id: build_zip_key(zip.ctry_cd, zip.zipcd, zip.seq_no),
        ctry_cd: zip.ctry_cd,
        zipcd: zip.zipcd,
        seq_no: zip.seq_no,
        zipaddr: zip.zipaddr,
        sido: zip.sido,
        sgng: zip.sgng,
        eupdiv: zip.eupdiv
      }
    end
end
