class Std::GoodsController < Std::BaseController
  def index
    respond_to do |format|
      format.html
      format.json { render json: goods_scope.map { |row| good_json(row) } }
    end
  end

  def batch_save
    operations = batch_save_params
    result = { inserted: 0, updated: 0, deleted: 0 }
    errors = []

    ActiveRecord::Base.transaction do
      Array(operations[:rowsToInsert]).each do |attrs|
        if attrs[:goods_nm].to_s.strip.blank?
          next
        end

        row = StdGood.new(good_params_from_row(attrs))
        if row.save
          result[:inserted] += 1
        else
          errors.concat(row.errors.full_messages)
        end
      end

      Array(operations[:rowsToUpdate]).each do |attrs|
        goods_cd = attrs[:goods_cd].to_s.strip.upcase
        row = StdGood.find_by(goods_cd: goods_cd)
        if row.nil?
          errors << "품명 정보를 찾을 수 없습니다: #{goods_cd}"
          next
        end

        update_attrs = good_params_from_row(attrs)
        update_attrs.delete(:goods_cd)
        if row.update(update_attrs)
          result[:updated] += 1
        else
          errors.concat(row.errors.full_messages)
        end
      end

      Array(operations[:rowsToDelete]).each do |goods_cd|
        row = StdGood.find_by(goods_cd: goods_cd.to_s.strip.upcase)
        if row.nil?
          next
        end

        if row.update(use_yn_cd: "N")
          result[:deleted] += 1
        else
          errors.concat(row.errors.full_messages.presence || [ "품명 비활성화에 실패했습니다: #{goods_cd}" ])
        end
      end

      if errors.any?
        raise ActiveRecord::Rollback
      end
    end

    if errors.any?
      render json: { success: false, errors: errors.uniq }, status: :unprocessable_entity
    else
      render json: { success: true, message: "품명 정보가 저장되었습니다.", data: result }
    end
  end

  private
    def menu_code_for_permission
      "STD_GOODS"
    end

    def search_params
      params.fetch(:q, {}).permit(:goods_cd, :goods_nm, :use_yn_cd)
    end

    def goods_scope
      scope = StdGood.ordered
      if search_goods_cd.present?
        scope = scope.where("goods_cd LIKE ?", "%#{search_goods_cd}%")
      end
      if search_goods_nm.present?
        scope = scope.where("goods_nm LIKE ?", "%#{search_goods_nm}%")
      end
      if search_use_yn_cd.present?
        scope = scope.where(use_yn_cd: search_use_yn_cd)
      end
      scope
    end

    def search_goods_cd
      search_params[:goods_cd].to_s.strip.upcase.presence
    end

    def search_goods_nm
      search_params[:goods_nm].to_s.strip.presence
    end

    def search_use_yn_cd
      search_params[:use_yn_cd].to_s.strip.upcase.presence
    end

    def batch_save_params
      params.permit(
        rowsToDelete: [],
        rowsToInsert: [ :goods_cd, :goods_nm, :hatae_cd, :item_grp_cd, :item_cd, :hwajong_cd, :hwajong_grp_cd, :rmk_cd, :use_yn_cd ],
        rowsToUpdate: [ :goods_cd, :goods_nm, :hatae_cd, :item_grp_cd, :item_cd, :hwajong_cd, :hwajong_grp_cd, :rmk_cd, :use_yn_cd ]
      )
    end

    def good_params_from_row(row)
      row.permit(
        :goods_cd, :goods_nm, :hatae_cd, :item_grp_cd, :item_cd, :hwajong_cd, :hwajong_grp_cd, :rmk_cd, :use_yn_cd
      ).to_h.symbolize_keys
    end

    def good_json(row)
      {
        id: row.goods_cd,
        goods_cd: row.goods_cd,
        goods_nm: row.goods_nm,
        hatae_cd: row.hatae_cd,
        item_grp_cd: row.item_grp_cd,
        item_cd: row.item_cd,
        hwajong_cd: row.hwajong_cd,
        hwajong_grp_cd: row.hwajong_grp_cd,
        rmk_cd: row.rmk_cd,
        use_yn_cd: row.use_yn_cd,
        create_by: row.create_by,
        create_time: row.create_time,
        update_by: row.update_by,
        update_time: row.update_time
      }
    end
end
