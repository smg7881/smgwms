class SearchPopupsController < ApplicationController
  def show
    @type = params[:type].to_s.strip.downcase
    @frame = params[:frame].presence || "search_popup_frame"
    @popup_form = build_popup_form
    @rows = lookup_rows(@type)

    respond_to do |format|
      format.json do
        render json: @rows.map do |row|
          {
            code: row[:code],
            name: row[:name],
            display: row[:display],
            corp_cd: row[:corp_cd],
            corp_nm: row[:corp_nm],
            ctry: row[:ctry],
            biz_no: row[:biz_no],
            upper_corp_cd: row[:upper_corp_cd],
            upper_corp_nm: row[:upper_corp_nm]
          }.compact
        end
      end
      format.html { render layout: popup_layout? }
    end
  end

  private
    def popup_layout?
      if params[:popup].present?
        "popup"
      elsif turbo_frame_request? || params[:frame].present?
        false
      else
        "application"
      end
    end

    def popup_form_params
      params.fetch(:search_popup_form, {}).permit(:display, :code, :corp_cd, :corp_nm, :use_yn)
    end

    def corp_popup?
      @type == "corp"
    end

    def normalized_use_yn(value)
      normalized = value.to_s.strip.upcase
      if %w[Y N].include?(normalized)
        normalized
      else
        "Y"
      end
    end

    def lookup_keyword
      direct = params[:q].to_s.strip
      if direct.present?
        direct
      else
        popup_form_params[:display].to_s.strip
      end
    end

    def build_popup_form
      if corp_popup?
        SearchPopupForm.new(
          corp_cd: popup_form_params[:corp_cd].to_s.strip.upcase,
          corp_nm: popup_form_params[:corp_nm].to_s.strip.presence || params[:q].to_s.strip,
          use_yn: normalized_use_yn(popup_form_params[:use_yn])
        )
      else
        SearchPopupForm.new(
          display: lookup_keyword,
          code: popup_form_params[:code].to_s.strip.upcase
        )
      end
    end

    def lookup_rows(type)
      if type == "corp"
        corp_rows
      else
        generic_rows(type)
      end
    end

    def generic_rows(type)
      rows = case type
      when "region", "regn"
        region_rows
      when "country", "ctry"
        country_rows
      when "client", "bzac"
        client_rows
      when "menu"
        menu_rows
      when "user"
        user_rows
      when "workplace"
        workplace_rows
      else
        []
      end

      keyword = lookup_keyword
      return rows.first(200) if keyword.blank?

      up_keyword = keyword.upcase
      rows.select do |row|
        row[:code].to_s.upcase.include?(up_keyword) ||
          row[:name].to_s.upcase.include?(up_keyword) ||
          row[:display].to_s.upcase.include?(up_keyword)
      end.first(200)
    end

    def build_generic_row(code:, name:)
      normalized_code = code.to_s.strip.upcase
      normalized_name = name.to_s.strip
      return nil if normalized_code.blank?

      resolved_name = normalized_name.presence || normalized_code
      {
        code: normalized_code,
        name: resolved_name,
        display: resolved_name
      }
    end

    # PRD: 법인코드 + 법인명 + 사용여부(Y/N, 기본 Y) 조회 조건
    #      그리드: 법인코드/법인명/국가/사업자등록번호
    def corp_rows
      return [] unless defined?(StdCorporation) && StdCorporation.table_exists?

      scope = StdCorporation.ordered
      if @popup_form.corp_cd.present?
        scope = scope.where("corp_cd LIKE ?", "%#{@popup_form.corp_cd}%")
      end
      if @popup_form.corp_nm.present?
        scope = scope.where("corp_nm LIKE ?", "%#{@popup_form.corp_nm}%")
      end
      if @popup_form.use_yn.present?
        scope = scope.where(use_yn_cd: @popup_form.use_yn)
      end

      corporations = scope.limit(200).to_a
      return [] if corporations.empty?

      corp_codes = corporations.map(&:corp_cd)

      country_rows = []
      if defined?(StdCorporationCountry) && StdCorporationCountry.table_exists?
        country_rows = StdCorporationCountry
          .where(corp_cd: corp_codes, use_yn_cd: "Y")
          .order(Arel.sql("CASE WHEN rpt_yn_cd = 'Y' THEN 0 ELSE 1 END"), :seq)
      end
      country_by_corp = {}
      country_rows.each do |country|
        country_by_corp[country.corp_cd] ||= country.ctry_cd.to_s.upcase
      end

      upper_codes = corporations.map(&:upper_corp_cd).compact_blank.uniq
      upper_name_by_code = if upper_codes.empty?
        {}
      else
        StdCorporation.where(corp_cd: upper_codes).pluck(:corp_cd, :corp_nm).to_h
      end

      corporations.map do |corp|
        corp_cd = corp.corp_cd.to_s.upcase
        corp_nm = corp.corp_nm.to_s.strip

        {
          code: corp_cd,
          name: corp_nm,
          display: corp_nm,
          corp_cd: corp_cd,
          corp_nm: corp_nm,
          ctry: country_by_corp[corp_cd].to_s,
          biz_no: corp.compreg_slip_cd.to_s,
          upper_corp_cd: corp.upper_corp_cd.to_s.upcase.presence,
          upper_corp_nm: upper_name_by_code[corp.upper_corp_cd.to_s.upcase]
        }.compact
      end
    rescue ActiveRecord::StatementInvalid
      []
    end

    def region_rows
      return [] unless defined?(StdRegion) && StdRegion.table_exists?

      StdRegion.where(use_yn_cd: "Y").ordered.filter_map do |row|
        build_generic_row(code: row.regn_cd, name: row.regn_nm_cd)
      end
    rescue ActiveRecord::StatementInvalid
      []
    end

    def country_rows
      return [] unless defined?(StdCountry) && StdCountry.table_exists?

      StdCountry.where(use_yn_cd: "Y").ordered.filter_map do |row|
        build_generic_row(code: row.ctry_cd, name: row.ctry_nm)
      end
    rescue ActiveRecord::StatementInvalid
      []
    end

    def client_rows
      return [] unless defined?(StdBzacMst) && StdBzacMst.table_exists?

      StdBzacMst.where(use_yn_cd: "Y").ordered.filter_map do |row|
        build_generic_row(code: row.bzac_cd, name: row.bzac_nm)
      end
    rescue ActiveRecord::StatementInvalid
      []
    end

    def menu_rows
      return [] unless defined?(AdmMenu) && AdmMenu.table_exists?

      AdmMenu.active.where(menu_type: "MENU").ordered.filter_map do |row|
        build_generic_row(code: row.menu_cd, name: row.menu_nm)
      end
    rescue ActiveRecord::StatementInvalid
      []
    end

    def user_rows
      return [] unless defined?(User) && User.table_exists?

      User.ordered.filter_map do |row|
        build_generic_row(code: row.user_id_code, name: row.user_nm)
      end
    rescue ActiveRecord::StatementInvalid
      []
    end

    def workplace_rows
      return [] unless defined?(StdWorkplace) && StdWorkplace.table_exists?

      StdWorkplace.where(use_yn_cd: "Y").ordered.filter_map do |row|
        build_generic_row(code: row.workpl_cd, name: row.workpl_nm)
      end
    rescue ActiveRecord::StatementInvalid
      []
    end
end
