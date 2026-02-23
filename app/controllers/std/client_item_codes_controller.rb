class Std::ClientItemCodesController < Std::BaseController
  def index
    respond_to do |format|
      format.html
      format.json do
        rows = client_item_code_scope.to_a
        bzac_name_by_code = bzac_name_map(rows)
        goods_name_by_code = goods_name_map(rows)
        render json: rows.map { |row| client_item_code_json(row, bzac_name_by_code, goods_name_by_code) }
      end
    end
  end

  def create
    row = StdClientItemCode.new(client_item_code_params)

    if row.save
      render json: { success: true, message: "거래처별아이템코드가 등록되었습니다.", client_item_code: client_item_code_json(row) }
    else
      render json: { success: false, errors: row.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    row = find_client_item_code
    if row.nil?
      render json: { success: false, errors: [ "거래처별아이템코드를 찾을 수 없습니다: #{params[:id]}" ] }, status: :not_found
      return
    end

    if row.update(client_item_code_params)
      render json: { success: true, message: "거래처별아이템코드가 수정되었습니다.", client_item_code: client_item_code_json(row) }
    else
      render json: { success: false, errors: row.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    row = find_client_item_code
    if row.nil?
      render json: { success: false, errors: [ "거래처별아이템코드를 찾을 수 없습니다: #{params[:id]}" ] }, status: :not_found
      return
    end

    if row.update(use_yn_cd: "N")
      render json: { success: true, message: "거래처별아이템코드가 삭제되었습니다." }
    else
      render json: { success: false, errors: row.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private
    def menu_code_for_permission
      "STD_CLIENT_ITEM"
    end

    def search_params
      params.fetch(:q, {}).permit(:bzac_cd, :item_cd, :item_nm, :use_yn_cd)
    end

    def client_item_code_scope
      scope = StdClientItemCode.ordered

      if search_bzac_cd.present?
        scope = scope.where(bzac_cd: search_bzac_cd)
      end
      if search_item_cd.present?
        scope = scope.where("item_cd LIKE ?", "%#{search_item_cd}%")
      end
      if search_item_nm.present?
        scope = scope.where("item_nm LIKE ?", "%#{search_item_nm}%")
      end
      if search_use_yn_cd.present?
        scope = scope.where(use_yn_cd: search_use_yn_cd)
      end

      scope
    end

    def search_bzac_cd
      search_params[:bzac_cd].to_s.strip.upcase.presence
    end

    def search_item_cd
      search_params[:item_cd].to_s.strip.upcase.presence
    end

    def search_item_nm
      search_params[:item_nm].to_s.strip.presence
    end

    def search_use_yn_cd
      search_params[:use_yn_cd].to_s.strip.upcase.presence
    end

    def client_item_code_params
      params.require(:client_item_code).permit(
        :item_cd, :item_nm, :bzac_cd, :goodsnm_cd,
        :danger_yn_cd, :png_yn_cd, :mstair_lading_yn_cd, :if_yn_cd,
        :wgt_unit_cd, :qty_unit_cd, :tmpt_unit_cd, :vol_unit_cd, :basis_unit_cd, :len_unit_cd,
        :pckg_qty, :tot_wgt_kg, :net_wgt_kg,
        :vessel_tmpt_c, :vessel_width_m, :vessel_vert_m, :vessel_hght_m, :vessel_vol_cbm,
        :use_yn_cd, :prod_nm_cd, :regr_nm_cd, :reg_date, :mdfr_nm_cd, :chgdt
      )
    end

    def find_client_item_code
      StdClientItemCode.find_by(id: params[:id].to_i)
    end

    def bzac_name_map(rows)
      codes = rows.map(&:bzac_cd).compact_blank.uniq
      if codes.empty? || !defined?(StdBzacMst) || !StdBzacMst.table_exists?
        {}
      else
        StdBzacMst.where(bzac_cd: codes).pluck(:bzac_cd, :bzac_nm).to_h
      end
    end

    def goods_name_map(rows)
      codes = rows.map(&:goodsnm_cd).compact_blank.uniq
      if codes.empty? || !defined?(StdGood) || !StdGood.table_exists?
        {}
      else
        StdGood.where(goods_cd: codes).pluck(:goods_cd, :goods_nm).to_h
      end
    end

    def client_item_code_json(row, bzac_name_by_code = nil, goods_name_by_code = nil)
      bzac_names = bzac_name_by_code || {}
      goods_names = goods_name_by_code || {}
      bzac_cd = row.bzac_cd.to_s.upcase
      goodsnm_cd = row.goodsnm_cd.to_s.upcase

      {
        id: row.id,
        item_cd: row.item_cd,
        item_nm: row.item_nm,
        bzac_cd: bzac_cd,
        bzac_nm: bzac_names[bzac_cd].to_s.presence,
        goodsnm_cd: goodsnm_cd,
        goodsnm_nm: goods_names[goodsnm_cd].to_s.presence,
        danger_yn_cd: row.danger_yn_cd,
        png_yn_cd: row.png_yn_cd,
        mstair_lading_yn_cd: row.mstair_lading_yn_cd,
        if_yn_cd: row.if_yn_cd,
        wgt_unit_cd: row.wgt_unit_cd,
        qty_unit_cd: row.qty_unit_cd,
        tmpt_unit_cd: row.tmpt_unit_cd,
        vol_unit_cd: row.vol_unit_cd,
        basis_unit_cd: row.basis_unit_cd,
        len_unit_cd: row.len_unit_cd,
        pckg_qty: row.pckg_qty,
        tot_wgt_kg: row.tot_wgt_kg,
        net_wgt_kg: row.net_wgt_kg,
        vessel_tmpt_c: row.vessel_tmpt_c,
        vessel_width_m: row.vessel_width_m,
        vessel_vert_m: row.vessel_vert_m,
        vessel_hght_m: row.vessel_hght_m,
        vessel_vol_cbm: row.vessel_vol_cbm,
        use_yn_cd: row.use_yn_cd,
        prod_nm_cd: row.prod_nm_cd,
        regr_nm_cd: row.regr_nm_cd,
        reg_date: row.reg_date,
        mdfr_nm_cd: row.mdfr_nm_cd,
        chgdt: row.chgdt,
        create_by: row.create_by,
        create_time: row.create_time,
        update_by: row.update_by,
        update_time: row.update_time
      }
    end
end
