class Std::SellbuyAttributesController < Std::BaseController
  def index
    respond_to do |format|
      format.html
      format.json do
        rows = sellbuy_attributes_scope.to_a
        upper_name_by_code = upper_name_map(rows)
        render json: rows.map { |row| sellbuy_attribute_json(row, upper_name_by_code) }
      end
    end
  end

  def create
    row = StdSellbuyAttribute.new(sellbuy_attribute_params)

    if row.save
      render json: { success: true, message: "매출입항목이 등록되었습니다.", sellbuy_attribute: sellbuy_attribute_json(row) }
    else
      render json: { success: false, errors: row.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    row = find_sellbuy_attribute
    if row.nil?
      render json: { success: false, errors: [ "매출입항목코드를 찾을 수 없습니다: #{params[:id]}" ] }, status: :not_found
      return
    end

    update_attrs = sellbuy_attribute_params.to_h
    update_attrs.delete("sellbuy_attr_cd")
    if row.update(update_attrs)
      render json: { success: true, message: "매출입항목이 수정되었습니다.", sellbuy_attribute: sellbuy_attribute_json(row) }
    else
      render json: { success: false, errors: row.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    row = find_sellbuy_attribute
    if row.nil?
      render json: { success: false, errors: [ "매출입항목코드를 찾을 수 없습니다: #{params[:id]}" ] }, status: :not_found
      return
    end

    if row.update(use_yn_cd: "N")
      render json: { success: true, message: "매출입항목이 삭제되었습니다." }
    else
      render json: { success: false, errors: row.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private
    def menu_code_for_permission
      "STD_SELLBUY_ATTR"
    end

    def search_params
      params.fetch(:q, {}).permit(:corp_cd, :sellbuy_sctn_cd, :sellbuy_attr_cd, :sellbuy_attr_nm, :use_yn_cd)
    end

    def sellbuy_attributes_scope
      scope = StdSellbuyAttribute.ordered

      if search_corp_cd.present?
        scope = scope.where(corp_cd: search_corp_cd)
      end
      if search_sellbuy_sctn_cd.present?
        scope = scope.where(sellbuy_sctn_cd: search_sellbuy_sctn_cd)
      end
      if search_sellbuy_attr_cd.present?
        scope = scope.where("sellbuy_attr_cd LIKE ?", "%#{search_sellbuy_attr_cd}%")
      end
      if search_sellbuy_attr_nm.present?
        keyword = "%#{search_sellbuy_attr_nm}%"
        scope = scope.where(
          "sellbuy_attr_nm LIKE ? OR sellbuy_attr_eng_nm LIKE ? OR rdtn_nm LIKE ?",
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

    def search_corp_cd
      search_params[:corp_cd].to_s.strip.upcase.presence
    end

    def search_sellbuy_sctn_cd
      search_params[:sellbuy_sctn_cd].to_s.strip.upcase.presence
    end

    def search_sellbuy_attr_cd
      search_params[:sellbuy_attr_cd].to_s.strip.upcase.presence
    end

    def search_sellbuy_attr_nm
      search_params[:sellbuy_attr_nm].to_s.strip.presence
    end

    def search_use_yn_cd
      search_params[:use_yn_cd].to_s.strip.upcase.presence
    end

    def sellbuy_attribute_params
      params.require(:sellbuy_attribute).permit(
        :corp_cd, :sellbuy_sctn_cd, :sellbuy_attr_cd, :sellbuy_attr_nm, :rdtn_nm, :sellbuy_attr_eng_nm,
        :upper_sellbuy_attr_cd, :sell_yn_cd, :pur_yn_cd, :tran_yn_cd, :fis_air_yn_cd, :strg_yn_cd,
        :cgwrk_yn_cd, :fis_shpng_yn_cd, :dc_extr_yn_cd, :tax_payfor_yn_cd, :lumpsum_yn_cd,
        :dcnct_reg_pms_yn_cd, :sell_dr_acct_cd, :sell_cr_acct_cd, :pur_dr_acct_cd, :pur_cr_acct_cd,
        :sys_sctn_cd, :ndcsn_sell_cr_acct_cd, :ndcsn_cost_dr_acct_cd, :rmk_cd, :use_yn_cd
      )
    end

    def find_sellbuy_attribute
      StdSellbuyAttribute.find_by(sellbuy_attr_cd: params[:id].to_s.strip.upcase)
    end

    def upper_name_map(rows)
      upper_codes = rows.map(&:upper_sellbuy_attr_cd).compact_blank.uniq
      if upper_codes.empty?
        {}
      else
        StdSellbuyAttribute.where(sellbuy_attr_cd: upper_codes).pluck(:sellbuy_attr_cd, :sellbuy_attr_nm).to_h
      end
    end

    def sellbuy_attribute_json(row, upper_name_by_code = nil)
      upper_names = upper_name_by_code || {}
      upper_code = row.upper_sellbuy_attr_cd.to_s.upcase.presence

      {
        id: row.sellbuy_attr_cd,
        corp_cd: row.corp_cd,
        sellbuy_sctn_cd: row.sellbuy_sctn_cd,
        sellbuy_attr_cd: row.sellbuy_attr_cd,
        sellbuy_attr_nm: row.sellbuy_attr_nm,
        rdtn_nm: row.rdtn_nm,
        sellbuy_attr_eng_nm: row.sellbuy_attr_eng_nm,
        upper_sellbuy_attr_cd: upper_code,
        upper_sellbuy_attr_nm: upper_names[upper_code].to_s.presence,
        sell_yn_cd: row.sell_yn_cd,
        pur_yn_cd: row.pur_yn_cd,
        tran_yn_cd: row.tran_yn_cd,
        fis_air_yn_cd: row.fis_air_yn_cd,
        strg_yn_cd: row.strg_yn_cd,
        cgwrk_yn_cd: row.cgwrk_yn_cd,
        fis_shpng_yn_cd: row.fis_shpng_yn_cd,
        dc_extr_yn_cd: row.dc_extr_yn_cd,
        tax_payfor_yn_cd: row.tax_payfor_yn_cd,
        lumpsum_yn_cd: row.lumpsum_yn_cd,
        dcnct_reg_pms_yn_cd: row.dcnct_reg_pms_yn_cd,
        sell_dr_acct_cd: row.sell_dr_acct_cd,
        sell_cr_acct_cd: row.sell_cr_acct_cd,
        pur_dr_acct_cd: row.pur_dr_acct_cd,
        pur_cr_acct_cd: row.pur_cr_acct_cd,
        sys_sctn_cd: row.sys_sctn_cd,
        ndcsn_sell_cr_acct_cd: row.ndcsn_sell_cr_acct_cd,
        ndcsn_cost_dr_acct_cd: row.ndcsn_cost_dr_acct_cd,
        rmk_cd: row.rmk_cd,
        use_yn_cd: row.use_yn_cd,
        create_by: row.create_by,
        create_time: row.create_time,
        update_by: row.update_by,
        update_time: row.update_time
      }
    end
end
