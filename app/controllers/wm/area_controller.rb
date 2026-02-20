class Wm::AreaController < Wm::BaseController
  def index
    respond_to do |format|
      format.html
      format.json { render json: area_rows_json }
    end
  end

  def batch_save
    operations = batch_save_params
    result = { inserted: 0, updated: 0, deleted: 0 }
    errors = []

    ActiveRecord::Base.transaction do
      Array(operations[:rowsToInsert]).each do |attrs|
        if attrs[:workpl_cd].to_s.strip.blank? && attrs[:area_cd].to_s.strip.blank? && attrs[:area_nm].to_s.strip.blank?
          next
        end

        area = WmArea.new(area_params_from_row(attrs))
        if area.save
          result[:inserted] += 1
        else
          errors.concat(area.errors.full_messages)
        end
      end

      Array(operations[:rowsToUpdate]).each do |attrs|
        workpl_cd = attrs[:workpl_cd].to_s.strip.upcase
        area_cd = attrs[:area_cd].to_s.strip.upcase
        area = WmArea.find_by(workpl_cd: workpl_cd, area_cd: area_cd)

        if area.nil?
          errors << "구역코드를 찾을 수 없습니다: #{workpl_cd}/#{area_cd}"
          next
        end

        update_attrs = area_params_from_row(attrs)
        update_attrs.delete(:workpl_cd)
        update_attrs.delete(:area_cd)

        if area.update(update_attrs)
          result[:updated] += 1
        else
          errors.concat(area.errors.full_messages)
        end
      end

      Array(operations[:rowsToDelete]).each do |key|
        workpl_cd, area_cd = extract_delete_key(key)
        next if workpl_cd.blank? || area_cd.blank?

        area = WmArea.find_by(workpl_cd: workpl_cd, area_cd: area_cd)
        next if area.nil?

        if area.destroy
          result[:deleted] += 1
        else
          errors.concat(area.errors.full_messages.presence || [ "구역 삭제에 실패했습니다: #{workpl_cd}/#{area_cd}" ])
        end
      end

      if errors.any?
        raise ActiveRecord::Rollback
      end
    end

    if errors.any?
      render json: { success: false, errors: errors.uniq }, status: :unprocessable_entity
    else
      render json: { success: true, message: "구역 데이터가 저장되었습니다.", data: result }
    end
  end

  private
    def menu_code_for_permission
      "WM_AREA"
    end

    def search_params
      params.fetch(:q, {}).permit(:workpl_cd, :workplCd, :area_nm, :areaNm, :use_yn, :useYn)
    end

    def areas_scope
      scope = WmArea.ordered

      if search_workpl_cd.present?
        scope = scope.where(workpl_cd: search_workpl_cd)
      end
      if search_area_nm.present?
        keyword = "%#{search_area_nm}%"
        scope = scope.where("area_nm LIKE ?", keyword)
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

    def search_area_nm
      value = search_params[:area_nm].presence || search_params[:areaNm].presence
      value.to_s.strip.presence
    end

    def search_use_yn
      value = search_params[:use_yn].presence || search_params[:useYn].presence
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
          area_desc: area.area_desc,
          use_yn: area.use_yn,
          create_by: area.create_by,
          create_time: area.create_time,
          update_by: area.update_by,
          update_time: area.update_time
        }
      end
    end

    def workplace_name_map(rows)
      codes = rows.map(&:workpl_cd).uniq
      return {} if codes.empty?

      WmWorkplace.where(workpl_cd: codes).pluck(:workpl_cd, :workpl_nm).to_h
    end

    def batch_save_params
      params.permit(
        rowsToDelete: [ :workpl_cd, :area_cd ],
        rowsToInsert: [ :workpl_cd, :area_cd, :area_nm, :area_desc, :use_yn ],
        rowsToUpdate: [ :workpl_cd, :area_cd, :area_nm, :area_desc, :use_yn ]
      )
    end

    def area_params_from_row(row)
      row.permit(:workpl_cd, :area_cd, :area_nm, :area_desc, :use_yn).to_h.symbolize_keys
    end

    def extract_delete_key(key)
      return [ nil, nil ] if key.blank?

      params = key.respond_to?(:permit) ? key.permit(:workpl_cd, :area_cd) : key
      hash = params.to_h
      [
        hash["workpl_cd"].to_s.strip.upcase.presence,
        hash["area_cd"].to_s.strip.upcase.presence
      ]
    end
end
