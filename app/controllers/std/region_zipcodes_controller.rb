class Std::RegionZipcodesController < Std::BaseController
  def index
  end

  def mapped_zipcodes
    regn_cd = params[:regn_cd].to_s.strip.upcase
    if regn_cd.blank?
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
    if regn_cd.blank?
      render json: { success: false, errors: [ "권역코드는 필수입니다." ] }, status: :unprocessable_entity
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
        :regn_cd,
        rows: [ :ctry_cd, :zipcd, :seq_no, :sort_seq ]
      )
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
