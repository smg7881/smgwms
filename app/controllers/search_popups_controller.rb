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
            ctry_cd: row[:ctry_cd],
            ctry_nm: row[:ctry_nm],
            biz_no: row[:biz_no],
            fnc_or_cd: row[:fnc_or_cd],
            fnc_or_nm: row[:fnc_or_nm],
            fnc_or_eng_nm: row[:fnc_or_eng_nm],
            use_yn: row[:use_yn],
            phone: row[:phone],
            mobile_phone: row[:mobile_phone],
            upper_corp_cd: row[:upper_corp_cd],
            upper_corp_nm: row[:upper_corp_nm],
            sellbuy_attr_cd: row[:sellbuy_attr_cd],
            sellbuy_attr_nm: row[:sellbuy_attr_nm],
            sellbuy_attr_eng_nm: row[:sellbuy_attr_eng_nm],
            rdtn_nm: row[:rdtn_nm],
            upper_sellbuy_attr_cd: row[:upper_sellbuy_attr_cd],
            upper_sellbuy_attr_nm: row[:upper_sellbuy_attr_nm],
            tran_yn: row[:tran_yn],
            strg_yn: row[:strg_yn]
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
      params.fetch(:search_popup_form, {}).permit(
        :display, :code, :corp_cd, :corp_nm, :use_yn,
        :ctry_cd, :fnc_or_cd, :fnc_or_nm,
        :sellbuy_attr_cd, :sellbuy_attr_nm, :tran_yn, :strg_yn
      )
    end

    def corp_popup?
      @type == "corp"
    end

    def financial_org_popup?
      %w[financial_institution fin_org financial_org fnc_or].include?(@type)
    end

    def sellbuy_attr_popup?
      %w[sellbuy_attr sellbuyattribute sell_buy_attr].include?(@type)
    end

    def normalized_use_yn(value)
      normalized = value.to_s.strip.upcase
      if %w[Y N].include?(normalized)
        normalized
      else
        "Y"
      end
    end

    def normalized_optional_yn(value)
      normalized = value.to_s.strip.upcase
      if %w[Y N].include?(normalized)
        normalized
      else
        nil
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
          corp_cd: popup_corp_cd,
          corp_nm: popup_form_params[:corp_nm].to_s.strip.presence || params[:q].to_s.strip,
          use_yn: normalized_use_yn(popup_form_params[:use_yn])
        )
      elsif financial_org_popup?
        SearchPopupForm.new(
          ctry_cd: popup_form_params[:ctry_cd].to_s.strip.upcase.presence || params[:ctry_cd].to_s.strip.upcase.presence,
          fnc_or_cd: popup_form_params[:fnc_or_cd].to_s.strip.upcase.presence,
          fnc_or_nm: popup_form_params[:fnc_or_nm].to_s.strip.presence || params[:q].to_s.strip,
          use_yn: normalized_use_yn(popup_form_params[:use_yn])
        )
      elsif sellbuy_attr_popup?
        SearchPopupForm.new(
          corp_cd: popup_corp_cd,
          corp_nm: popup_form_params[:corp_nm].to_s.strip.presence,
          sellbuy_attr_cd: popup_form_params[:sellbuy_attr_cd].to_s.strip.upcase.presence,
          sellbuy_attr_nm: popup_form_params[:sellbuy_attr_nm].to_s.strip.presence || params[:q].to_s.strip.presence,
          use_yn: normalized_use_yn(popup_form_params[:use_yn]),
          tran_yn: normalized_optional_yn(popup_form_params[:tran_yn]),
          strg_yn: normalized_optional_yn(popup_form_params[:strg_yn])
        )
      else
        SearchPopupForm.new(
          display: lookup_keyword,
          code: popup_form_params[:code].to_s.strip.upcase,
          corp_cd: popup_corp_cd
        )
      end
    end

    def popup_corp_cd
      value = popup_form_params[:corp_cd].presence || params[:corp_cd].presence
      value.to_s.strip.upcase
    end

    def lookup_rows(type)
      if type == "corp"
        corp_rows
      elsif financial_org_popup?
        financial_org_rows
      elsif sellbuy_attr_popup?
        sellbuy_attr_rows
      else
        generic_rows(type)
      end
    end

    def generic_rows(type)
      rows = case type
      when "dept", "department"
        dept_rows
      when "region", "regn"
        region_rows
      when "good", "goods", "item"
        good_rows
      when "country", "ctry"
        country_rows
      when "client", "bzac"
        client_rows
      when "zipcode", "zipcd", "zip"
        zipcode_rows
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

    # PRD: 국가 + 금융기관코드 + 금융기관명 + 사용여부(Y/N, 기본 Y) 조회 조건
    #      그리드: 국가/금융기관코드/금융기관명/금융기관영문명
    def financial_org_rows
      return [] unless defined?(StdFinancialInstitution) && StdFinancialInstitution.table_exists?

      scope = StdFinancialInstitution.ordered
      if @popup_form.ctry_cd.present?
        scope = scope.where(ctry_cd: @popup_form.ctry_cd)
      end
      if @popup_form.fnc_or_cd.present?
        scope = scope.where("fnc_or_cd LIKE ?", "%#{@popup_form.fnc_or_cd}%")
      end
      if @popup_form.fnc_or_nm.present?
        scope = scope.where(
          "fnc_or_cd LIKE ? OR fnc_or_nm LIKE ? OR fnc_or_eng_nm LIKE ?",
          "%#{@popup_form.fnc_or_nm}%",
          "%#{@popup_form.fnc_or_nm}%",
          "%#{@popup_form.fnc_or_nm}%"
        )
      end
      if @popup_form.use_yn.present?
        scope = scope.where(use_yn_cd: @popup_form.use_yn)
      end

      scope.limit(200).map do |row|
        fnc_or_cd = row.fnc_or_cd.to_s.upcase
        fnc_or_nm = row.fnc_or_nm.to_s.strip
        {
          code: fnc_or_cd,
          name: fnc_or_nm,
          display: fnc_or_nm,
          fnc_or_cd: fnc_or_cd,
          fnc_or_nm: fnc_or_nm,
          fnc_or_eng_nm: row.fnc_or_eng_nm.to_s.strip,
          ctry_cd: row.ctry_cd.to_s.upcase.presence,
          ctry_nm: row.ctry_nm.to_s.strip.presence,
          ctry: row.ctry_nm.to_s.strip.presence || row.ctry_cd.to_s.upcase,
          use_yn: row.use_yn_cd.to_s.upcase
        }.compact
      end
    rescue ActiveRecord::StatementInvalid
      []
    end

    def region_rows
      return [] unless defined?(StdRegion) && StdRegion.table_exists?

      scope = StdRegion.where(use_yn_cd: "Y")
      if @popup_form.corp_cd.present?
        scope = scope.where(corp_cd: @popup_form.corp_cd)
      end

      scope.ordered.filter_map do |row|
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
        code = row.user_id_code.to_s.strip.upcase
        if code.blank?
          next
        end

        name = row.user_nm.to_s.strip.presence || code
        phone = row.phone.to_s.strip
        {
          code: code,
          name: name,
          display: name,
          phone: phone.presence,
          mobile_phone: phone.presence
        }.compact
      end
    rescue ActiveRecord::StatementInvalid
      []
    end

    def dept_rows
      return [] unless defined?(AdmDept) && AdmDept.table_exists?

      AdmDept.where(use_yn: "Y").ordered.filter_map do |row|
        build_generic_row(code: row.dept_code, name: row.dept_nm)
      end
    rescue ActiveRecord::StatementInvalid
      []
    end

    def zipcode_rows
      return [] unless defined?(StdZipCode) && StdZipCode.table_exists?

      StdZipCode.active.ordered.filter_map do |row|
        label = row.zipaddr.to_s.strip.presence || row.zipcd.to_s.strip
        build_generic_row(code: row.zipcd, name: label)
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

    def good_rows
      return [] unless defined?(StdGood) && StdGood.table_exists?

      StdGood.where(use_yn_cd: "Y").ordered.filter_map do |row|
        build_generic_row(code: row.goods_cd, name: row.goods_nm)
      end
    rescue ActiveRecord::StatementInvalid
      []
    end

    # PRD: 매출입항목 선택팝업
    #      조회조건: 매출입항목코드/명, 사용여부(Y 기본), 법인, 운송여부, 보관여부
    #      그리드: 매출입항목코드/명/영문명/단축명/상위코드/상위명
    def sellbuy_attr_rows
      return [] unless defined?(StdSellbuyAttribute) && StdSellbuyAttribute.table_exists?

      scope = StdSellbuyAttribute.ordered
      if @popup_form.corp_cd.present?
        scope = scope.where(corp_cd: @popup_form.corp_cd)
      end
      if @popup_form.sellbuy_attr_cd.present?
        scope = scope.where("sellbuy_attr_cd LIKE ?", "%#{@popup_form.sellbuy_attr_cd}%")
      end
      if @popup_form.sellbuy_attr_nm.present?
        keyword = "%#{@popup_form.sellbuy_attr_nm}%"
        scope = scope.where(
          "sellbuy_attr_cd LIKE ? OR sellbuy_attr_nm LIKE ? OR sellbuy_attr_eng_nm LIKE ? OR rdtn_nm LIKE ?",
          keyword,
          keyword,
          keyword,
          keyword
        )
      end
      if @popup_form.use_yn.present?
        scope = scope.where(use_yn_cd: @popup_form.use_yn)
      end
      if @popup_form.tran_yn.present?
        scope = scope.where(tran_yn_cd: @popup_form.tran_yn)
      end
      if @popup_form.strg_yn.present?
        scope = scope.where(strg_yn_cd: @popup_form.strg_yn)
      end

      rows = scope.limit(200).to_a
      return [] if rows.empty?

      upper_codes = rows.map(&:upper_sellbuy_attr_cd).compact_blank.uniq
      upper_name_by_code = if upper_codes.empty?
        {}
      else
        StdSellbuyAttribute.where(sellbuy_attr_cd: upper_codes).pluck(:sellbuy_attr_cd, :sellbuy_attr_nm).to_h
      end

      rows.map do |row|
        code = row.sellbuy_attr_cd.to_s.upcase
        name = row.sellbuy_attr_nm.to_s.strip
        upper_code = row.upper_sellbuy_attr_cd.to_s.upcase.presence

        {
          code: code,
          name: name,
          display: name,
          corp_cd: row.corp_cd.to_s.upcase,
          sellbuy_attr_cd: code,
          sellbuy_attr_nm: name,
          sellbuy_attr_eng_nm: row.sellbuy_attr_eng_nm.to_s.strip,
          rdtn_nm: row.rdtn_nm.to_s.strip,
          upper_sellbuy_attr_cd: upper_code,
          upper_sellbuy_attr_nm: upper_name_by_code[upper_code].to_s.presence,
          tran_yn: row.tran_yn_cd.to_s.upcase,
          strg_yn: row.strg_yn_cd.to_s.upcase,
          use_yn: row.use_yn_cd.to_s.upcase
        }.compact
      end
    rescue ActiveRecord::StatementInvalid
      []
    end
end
