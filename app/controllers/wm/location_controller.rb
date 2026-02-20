class Wm::LocationController < Wm::BaseController
  def index
    if request.format.html? && should_redirect_to_default_query?
      redirect_to wm_location_index_path(q: default_query_params)
      return
    end

    respond_to do |format|
      format.html
      format.json { render json: locations_scope.map { |location| location_json(location) } }
    end
  end

  def areas
    workpl_cd = params[:workpl_cd].to_s.strip.upcase
    if workpl_cd.blank?
      render json: []
      return
    end

    rows = WmArea.where(workpl_cd: workpl_cd, use_yn: "Y").ordered.map do |area|
      {
        area_cd: area.area_cd,
        area_nm: area.area_nm
      }
    end

    render json: rows
  end

  def zones
    workpl_cd = params[:workpl_cd].to_s.strip.upcase
    area_cd = params[:area_cd].to_s.strip.upcase
    if workpl_cd.blank? || area_cd.blank?
      render json: []
      return
    end

    scope = WmZone.where(workpl_cd: workpl_cd, area_cd: area_cd).ordered
    filter_use_yn = params[:use_yn].to_s.strip.upcase.presence || "Y"
    scope = scope.where(use_yn: filter_use_yn)

    rows = scope.map do |zone|
      {
        zone_cd: zone.zone_cd,
        zone_nm: zone.zone_nm,
        use_yn: zone.use_yn
      }
    end

    render json: rows
  end

  def batch_save
    operations = batch_save_params
    result = { inserted: 0, updated: 0, deleted: 0 }
    errors = []

    ActiveRecord::Base.transaction do
      Array(operations[:rowsToInsert]).each do |attrs|
        if attrs[:loc_cd].to_s.strip.blank? && attrs[:loc_nm].to_s.strip.blank?
          next
        end

        location = WmLocation.new(location_params_from_row(attrs))
        if location.save
          result[:inserted] += 1
        else
          errors.concat(location.errors.full_messages)
        end
      end

      Array(operations[:rowsToUpdate]).each do |attrs|
        workpl_cd = attrs[:workpl_cd].to_s.strip.upcase
        area_cd = attrs[:area_cd].to_s.strip.upcase
        zone_cd = attrs[:zone_cd].to_s.strip.upcase
        loc_cd = attrs[:loc_cd].to_s.strip.upcase
        location = WmLocation.find_by(workpl_cd: workpl_cd, area_cd: area_cd, zone_cd: zone_cd, loc_cd: loc_cd)

        if location.nil?
          errors << "로케이션코드를 찾을 수 없습니다: #{workpl_cd}/#{area_cd}/#{zone_cd}/#{loc_cd}"
          next
        end

        update_attrs = location_params_from_row(attrs)
        update_attrs.delete(:workpl_cd)
        update_attrs.delete(:area_cd)
        update_attrs.delete(:zone_cd)
        update_attrs.delete(:loc_cd)

        if location.update(update_attrs)
          result[:updated] += 1
        else
          errors.concat(location.errors.full_messages)
        end
      end

      Array(operations[:rowsToDelete]).each do |key|
        workpl_cd, area_cd, zone_cd, loc_cd = extract_delete_key(key)
        next if workpl_cd.blank? || area_cd.blank? || zone_cd.blank? || loc_cd.blank?

        location = WmLocation.find_by(workpl_cd: workpl_cd, area_cd: area_cd, zone_cd: zone_cd, loc_cd: loc_cd)
        next if location.nil?

        if location.has_stock == "Y"
          errors << "재고가 있는 로케이션은 삭제할 수 없습니다: #{workpl_cd}/#{area_cd}/#{zone_cd}/#{loc_cd}"
          next
        end

        if location.destroy
          result[:deleted] += 1
        else
          errors.concat(location.errors.full_messages.presence || [ "로케이션 삭제에 실패했습니다: #{workpl_cd}/#{area_cd}/#{zone_cd}/#{loc_cd}" ])
        end
      end

      if errors.any?
        raise ActiveRecord::Rollback
      end
    end

    if errors.any?
      render json: { success: false, errors: errors.uniq }, status: :unprocessable_entity
    else
      render json: { success: true, message: "로케이션 데이터가 저장되었습니다.", data: result }
    end
  end

  private
    def menu_code_for_permission
      "WM_LOCATION"
    end

    def search_params
      params.fetch(:q, {}).permit(
        :workpl_cd, :workplCd,
        :area_cd, :areaCd,
        :zone_cd, :zoneCd,
        :loc_cd, :locCd,
        :loc_class_cd, :locClassCd,
        :use_yn, :useYn
      )
    end

    def locations_scope
      scope = WmLocation.ordered

      if search_workpl_cd.present?
        scope = scope.where(workpl_cd: search_workpl_cd)
      else
        scope = scope.none
      end

      if search_area_cd.present?
        scope = scope.where(area_cd: search_area_cd)
      end

      if search_zone_cd.present?
        scope = scope.where(zone_cd: search_zone_cd)
      end

      if search_loc_keyword.present?
        keyword = "%#{search_loc_keyword}%"
        scope = scope.where("loc_cd LIKE ? OR loc_nm LIKE ?", keyword, keyword)
      end

      if search_loc_class_cd.present?
        scope = scope.where(loc_class_cd: search_loc_class_cd)
      end

      if search_use_yn.present?
        scope = scope.where(use_yn: search_use_yn)
      end

      scope
    end

    def search_workpl_cd
      value = search_params[:workpl_cd].presence || search_params[:workplCd].presence
      value.to_s.strip.upcase.presence
    end

    def search_area_cd
      value = search_params[:area_cd].presence || search_params[:areaCd].presence
      value.to_s.strip.upcase.presence
    end

    def search_zone_cd
      value = search_params[:zone_cd].presence || search_params[:zoneCd].presence
      value.to_s.strip.upcase.presence
    end

    def search_loc_keyword
      value = search_params[:loc_cd].presence || search_params[:locCd].presence
      value.to_s.strip.presence
    end

    def search_loc_class_cd
      value = search_params[:loc_class_cd].presence || search_params[:locClassCd].presence
      value.to_s.strip.upcase.presence
    end

    def search_use_yn
      value = search_params[:use_yn].presence || search_params[:useYn].presence
      value.to_s.strip.upcase.presence
    end

    def default_zone
      @default_zone ||= WmZone.where(use_yn: "Y").ordered.limit(1).first
    end

    def should_redirect_to_default_query?
      params[:q].blank? && default_zone.present?
    end

    def default_query_params
      {
        workpl_cd: default_zone.workpl_cd,
        area_cd: default_zone.area_cd,
        zone_cd: default_zone.zone_cd,
        use_yn: "Y"
      }
    end

    def batch_save_params
      params.permit(
        rowsToDelete: [ :workpl_cd, :area_cd, :zone_cd, :loc_cd ],
        rowsToInsert: [
          :workpl_cd, :area_cd, :zone_cd, :loc_cd, :loc_nm,
          :loc_class_cd, :loc_type_cd,
          :width_len, :vert_len, :height_len, :max_weight, :max_cbm,
          :has_stock, :use_yn
        ],
        rowsToUpdate: [
          :workpl_cd, :area_cd, :zone_cd, :loc_cd, :loc_nm,
          :loc_class_cd, :loc_type_cd,
          :width_len, :vert_len, :height_len, :max_weight, :max_cbm,
          :has_stock, :use_yn
        ]
      )
    end

    def location_params_from_row(row)
      row.permit(
        :workpl_cd, :area_cd, :zone_cd, :loc_cd, :loc_nm,
        :loc_class_cd, :loc_type_cd,
        :width_len, :vert_len, :height_len, :max_weight, :max_cbm,
        :has_stock, :use_yn
      ).to_h.symbolize_keys
    end

    def extract_delete_key(key)
      return [ nil, nil, nil, nil ] if key.blank?

      params = key.respond_to?(:permit) ? key.permit(:workpl_cd, :area_cd, :zone_cd, :loc_cd) : key
      hash = params.to_h
      [
        hash["workpl_cd"].to_s.strip.upcase.presence,
        hash["area_cd"].to_s.strip.upcase.presence,
        hash["zone_cd"].to_s.strip.upcase.presence,
        hash["loc_cd"].to_s.strip.upcase.presence
      ]
    end

    def location_json(location)
      {
        id: "#{location.workpl_cd}_#{location.area_cd}_#{location.zone_cd}_#{location.loc_cd}",
        workpl_cd: location.workpl_cd,
        area_cd: location.area_cd,
        zone_cd: location.zone_cd,
        loc_cd: location.loc_cd,
        loc_nm: location.loc_nm,
        loc_class_cd: location.loc_class_cd,
        loc_type_cd: location.loc_type_cd,
        width_len: location.width_len,
        vert_len: location.vert_len,
        height_len: location.height_len,
        max_weight: location.max_weight,
        max_cbm: location.max_cbm,
        has_stock: location.has_stock,
        use_yn: location.use_yn,
        create_by: location.create_by,
        create_time: location.create_time,
        update_by: location.update_by,
        update_time: location.update_time
      }
    end
end
