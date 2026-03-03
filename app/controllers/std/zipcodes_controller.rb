class Std::ZipcodesController < Std::BaseController
  def index
    respond_to do |format|
      format.html
      format.json do
        rows = zipcode_scope.to_a
        ctry_name_by_code = country_name_map(rows)
        render json: rows.map { |row| zipcode_json(row, ctry_name_by_code) }
      end
    end
  end

  def create
    row = StdZipCode.new(zipcode_params)

    if row.save
      render json: { success: true, message: "우편번호가 등록되었습니다.", zipcode: zipcode_json(row) }
    else
      render json: { success: false, errors: row.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    row = find_zipcode
    if row.nil?
      render json: { success: false, errors: [ "우편번호를 찾을 수 없습니다: #{params[:id]}" ] }, status: :not_found
      return
    end

    update_attrs = zipcode_params.to_h
    update_attrs.delete("ctry_cd")
    update_attrs.delete("zipcd")
    update_attrs.delete("seq_no")

    if row.update(update_attrs)
      render json: { success: true, message: "우편번호가 수정되었습니다.", zipcode: zipcode_json(row) }
    else
      render json: { success: false, errors: row.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    row = find_zipcode
    if row.nil?
      render json: { success: false, errors: [ "우편번호를 찾을 수 없습니다: #{params[:id]}" ] }, status: :not_found
      return
    end

    if row.update(use_yn_cd: "N")
      render json: { success: true, message: "우편번호가 삭제되었습니다." }
    else
      render json: { success: false, errors: row.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private
    def menu_code_for_permission
      "STD_ZIP_CODE"
    end

    def search_params
      params.fetch(:q, {}).permit(:ctry_cd, :zipcd, :zipaddr, :use_yn_cd)
    end

    def zipcode_scope
      scope = StdZipCode.ordered

      if search_ctry_cd.present?
        scope = scope.where(ctry_cd: search_ctry_cd)
      end
      if search_zipcd.present?
        scope = scope.where("zipcd LIKE ?", "%#{search_zipcd}%")
      end
      if search_zipaddr.present?
        keyword = "%#{search_zipaddr}%"
        scope = scope.where(
          "zipaddr LIKE ? OR sido LIKE ? OR sgng LIKE ? OR eupdiv LIKE ?",
          keyword,
          keyword,
          keyword,
          keyword
        )
      end
      if search_use_yn_cd.present?
        scope = scope.where(use_yn_cd: search_use_yn_cd)
      end

      scope
    end

    def search_ctry_cd
      search_params[:ctry_cd].to_s.strip.upcase.presence
    end

    def search_zipcd
      search_params[:zipcd].to_s.strip.upcase.presence
    end

    def search_zipaddr
      search_params[:zipaddr].to_s.strip.presence
    end

    def search_use_yn_cd
      search_params[:use_yn_cd].to_s.strip.upcase.presence
    end

    def zipcode_params
      params.require(:zipcode).permit(
        :ctry_cd, :zipcd, :seq_no,
        :zipaddr, :sido, :sgng, :eupdiv,
        :addr_ri, :iland_san, :san_houseno, :apt_bild_nm,
        :strt_houseno_wek, :strt_houseno_mnst, :end_houseno_wek, :end_houseno_mnst,
        :dong_rng_strt, :dong_houseno_end, :chg_ymd,
        :use_yn_cd
      )
    end

    def find_zipcode
      StdZipCode.find_by(id: params[:id].to_i)
    end

    def country_name_map(rows)
      country_codes = rows.map(&:ctry_cd).compact_blank.uniq
      if country_codes.empty? || !defined?(StdCountry) || !StdCountry.table_exists?
        {}
      else
        StdCountry.where(ctry_cd: country_codes).pluck(:ctry_cd, :ctry_nm).to_h
      end
    rescue ActiveRecord::StatementInvalid
      {}
    end

    def zipcode_json(row, ctry_name_by_code = nil)
      country_names = ctry_name_by_code || {}
      ctry_cd = row.ctry_cd.to_s.strip.upcase

      {
        id: row.id,
        ctry_cd: ctry_cd,
        ctry_nm: country_names[ctry_cd].to_s.presence,
        zipcd: row.zipcd,
        seq_no: row.seq_no,
        zipaddr: row.zipaddr,
        sido: row.sido,
        sgng: row.sgng,
        eupdiv: row.eupdiv,
        addr_ri: row.addr_ri,
        iland_san: row.iland_san,
        san_houseno: row.san_houseno,
        apt_bild_nm: row.apt_bild_nm,
        strt_houseno_wek: row.strt_houseno_wek,
        strt_houseno_mnst: row.strt_houseno_mnst,
        end_houseno_wek: row.end_houseno_wek,
        end_houseno_mnst: row.end_houseno_mnst,
        dong_rng_strt: row.dong_rng_strt,
        dong_houseno_end: row.dong_houseno_end,
        chg_ymd: row.chg_ymd,
        use_yn_cd: row.use_yn_cd,
        create_by: row.create_by,
        create_time: row.create_time,
        update_by: row.update_by,
        update_time: row.update_time
      }
    end
end
