class Wm::ZoneController < Wm::BaseController
  def index
    if request.format.html? && should_redirect_to_default_query?
      redirect_to wm_zone_index_path(q: default_query_params)
      return
    end

    respond_to do |format|
      format.html
      format.json { render json: area_rows_json }
    end
  end

  def zones
    workpl_cd = params[:workpl_cd].to_s.strip.upcase
    area_cd = params[:area_cd].to_s.strip.upcase
    if workpl_cd.blank? || area_cd.blank?
      render json: []
      return
    end

    render json: zone_rows_json(workpl_cd, area_cd)
  end

  def batch_save
    operations = batch_save_params
    result = { inserted: 0, updated: 0, deleted: 0 }
    errors = []

    ActiveRecord::Base.transaction do
      Array(operations[:rowsToInsert]).each do |attrs|
        if attrs[:workpl_cd].to_s.strip.blank? && attrs[:area_cd].to_s.strip.blank? && attrs[:zone_cd].to_s.strip.blank?
          next
        end

        zone = WmZone.new(zone_params_from_row(attrs))
        if zone.save
          result[:inserted] += 1
        else
          errors.concat(zone.errors.full_messages)
        end
      end

      Array(operations[:rowsToUpdate]).each do |attrs|
        workpl_cd = attrs[:workpl_cd].to_s.strip.upcase
        area_cd = attrs[:area_cd].to_s.strip.upcase
        zone_cd = attrs[:zone_cd].to_s.strip.upcase
        zone = WmZone.find_by(workpl_cd: workpl_cd, area_cd: area_cd, zone_cd: zone_cd)

        if zone.nil?
          errors << "보관존코드를 찾을 수 없습니다: #{workpl_cd}/#{area_cd}/#{zone_cd}"
          next
        end

        update_attrs = zone_params_from_row(attrs)
        update_attrs.delete(:workpl_cd)
        update_attrs.delete(:area_cd)
        update_attrs.delete(:zone_cd)

        if zone.update(update_attrs)
          result[:updated] += 1
        else
          errors.concat(zone.errors.full_messages)
        end
      end

      Array(operations[:rowsToDelete]).each do |key|
        workpl_cd, area_cd, zone_cd = extract_delete_key(key)
        next if workpl_cd.blank? || area_cd.blank? || zone_cd.blank?

        zone = WmZone.find_by(workpl_cd: workpl_cd, area_cd: area_cd, zone_cd: zone_cd)
        next if zone.nil?

        if zone.destroy
          result[:deleted] += 1
        else
          errors.concat(zone.errors.full_messages.presence || [ "보관존 삭제에 실패했습니다: #{workpl_cd}/#{area_cd}/#{zone_cd}" ])
        end
      end

      if errors.any?
        raise ActiveRecord::Rollback
      end
    end

    if errors.any?
      render json: { success: false, errors: errors.uniq }, status: :unprocessable_entity
    else
      render json: { success: true, message: "보관존 데이터가 저장되었습니다.", data: result }
    end
  end

  private
    def menu_code_for_permission
      "WM_ZONE"
    end

    def search_params
      params.fetch(:q, {}).permit(:workpl_cd, :workplCd, :area_cd, :areaCd, :zone_cd, :zoneCd, :use_yn, :useYn)
    end

    def areas_scope
      scope = WmArea.ordered

      if search_workpl_cd.present?
        scope = scope.where(workpl_cd: search_workpl_cd)
      else
        scope = scope.none
      end

      if search_area_cd.present?
        scope = scope.where(area_cd: search_area_cd)
      end

      if search_use_yn.present?
        scope = scope.where(use_yn: search_use_yn)
      end

      scope
    end

    def zone_scope(workpl_cd, area_cd)
      scope = WmZone.ordered.where(workpl_cd: workpl_cd, area_cd: area_cd)

      if search_zone_keyword.present?
        keyword = "%#{search_zone_keyword}%"
        scope = scope.where("zone_cd LIKE ? OR zone_nm LIKE ?", keyword, keyword)
      end

      if search_use_yn.present?
        scope = scope.where(use_yn: search_use_yn)
      end

      scope
    end

    def search_workpl_cd
      value = search_params[:workpl_cd].presence || search_params[:workplCd].presence || params[:workpl_cd].presence || params[:workplCd].presence
      value.to_s.strip.upcase.presence
    end

    def search_area_cd
      value = search_params[:area_cd].presence || search_params[:areaCd].presence || params[:area_cd].presence || params[:areaCd].presence
      value.to_s.strip.upcase.presence
    end

    def search_zone_keyword
      value = search_params[:zone_cd].presence || search_params[:zoneCd].presence || params[:zone_cd].presence || params[:zoneCd].presence
      value.to_s.strip.presence
    end

    def search_use_yn
      value = search_params[:use_yn].presence || search_params[:useYn].presence || params[:use_yn].presence || params[:useYn].presence
      value.to_s.strip.upcase.presence
    end

    def area_rows_json
      rows = areas_scope.to_a
      workplace_names = workplace_name_map(rows)

      rows.map do |area|
        {
          id: "#{area.workpl_cd}_#{area.area_cd}",
          workpl_cd: area.workpl_cd,
          workpl_nm: workplace_names[area.workpl_cd],
          area_cd: area.area_cd,
          area_nm: area.area_nm,
          use_yn: area.use_yn
        }
      end
    end

    def zone_rows_json(workpl_cd, area_cd)
      zone_scope(workpl_cd, area_cd).map do |zone|
        {
          id: "#{zone.workpl_cd}_#{zone.area_cd}_#{zone.zone_cd}",
          workpl_cd: zone.workpl_cd,
          area_cd: zone.area_cd,
          zone_cd: zone.zone_cd,
          zone_nm: zone.zone_nm,
          zone_desc: zone.zone_desc,
          use_yn: zone.use_yn,
          update_by: zone.update_by,
          update_time: zone.update_time
        }
      end
    end

    def workplace_name_map(rows)
      codes = rows.map(&:workpl_cd).uniq
      return {} if codes.empty?

      WmWorkplace.where(workpl_cd: codes).pluck(:workpl_cd, :workpl_nm).to_h
    end

    def should_redirect_to_default_query?
      params[:q].blank? && default_workpl_cd.present?
    end

    def default_query_params
      {
        workpl_cd: default_workpl_cd,
        use_yn: "Y"
      }
    end

    def default_workpl_cd
      @default_workpl_cd ||= WmWorkplace.where(use_yn: "Y").ordered.limit(1).pick(:workpl_cd)
    end

    def batch_save_params
      params.permit(
        rowsToDelete: [ :workpl_cd, :area_cd, :zone_cd ],
        rowsToInsert: [ :workpl_cd, :area_cd, :zone_cd, :zone_nm, :zone_desc, :use_yn ],
        rowsToUpdate: [ :workpl_cd, :area_cd, :zone_cd, :zone_nm, :zone_desc, :use_yn ]
      )
    end

    def zone_params_from_row(row)
      row.permit(:workpl_cd, :area_cd, :zone_cd, :zone_nm, :zone_desc, :use_yn).to_h.symbolize_keys
    end

    def extract_delete_key(key)
      return [ nil, nil, nil ] if key.blank?

      params = key.respond_to?(:permit) ? key.permit(:workpl_cd, :area_cd, :zone_cd) : key
      hash = params.to_h
      [
        hash["workpl_cd"].to_s.strip.upcase.presence,
        hash["area_cd"].to_s.strip.upcase.presence,
        hash["zone_cd"].to_s.strip.upcase.presence
      ]
    end
end
