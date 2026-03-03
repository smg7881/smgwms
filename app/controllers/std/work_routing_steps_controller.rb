class Std::WorkRoutingStepsController < Std::BaseController
  def index
    @selected_work_routing = params[:selected_work_routing].presence

    respond_to do |format|
      format.html
      format.json { render json: work_routing_scope.map { |row| work_routing_json(row) } }
    end
  end

  def batch_save
    operations = batch_save_params
    result = { inserted: 0, updated: 0, deleted: 0 }
    errors = []

    ActiveRecord::Base.transaction do
      process_inserts(operations[:rowsToInsert], result, errors)
      process_updates(operations[:rowsToUpdate], result, errors)
      process_deletes(operations[:rowsToDelete], result, errors)

      if errors.any?
        raise ActiveRecord::Rollback
      end
    end

    if errors.any?
      render json: { success: false, errors: errors.uniq }, status: :unprocessable_entity
    else
      render json: { success: true, message: "기준작업경로 정보가 저장되었습니다.", data: result }
    end
  end

  private
    def menu_code_for_permission
      "STD_WRK_RTING_STEP"
    end

    def search_params
      params.fetch(:q, {}).permit(:wrk_rt_cd, :wrk_rt_nm, :use_yn_cd)
    end

    def work_routing_scope
      scope = StdWorkRouting.ordered
      if search_wrt_rt_cd.present?
        scope = scope.where("wrk_rt_cd LIKE ?", "%#{search_wrt_rt_cd}%")
      end
      if search_wrt_rt_nm.present?
        scope = scope.where("wrk_rt_nm LIKE ?", "%#{search_wrt_rt_nm}%")
      end
      if search_use_yn_cd.present?
        scope = scope.where(use_yn_cd: search_use_yn_cd)
      end
      scope
    end

    def search_wrt_rt_cd
      search_params[:wrk_rt_cd].to_s.strip.upcase.presence
    end

    def search_wrt_rt_nm
      search_params[:wrk_rt_nm].to_s.strip.presence
    end

    def search_use_yn_cd
      search_params[:use_yn_cd].to_s.strip.upcase.presence
    end

    def batch_save_params
      params.permit(
        rowsToDelete: [],
        rowsToInsert: [ :wrk_rt_cd, :wrk_rt_nm, :hwajong_cd, :wrk_type1_cd, :wrk_type2_cd, :use_yn_cd, :rmk_cd ],
        rowsToUpdate: [ :wrk_rt_cd, :wrk_rt_nm, :hwajong_cd, :wrk_type1_cd, :wrk_type2_cd, :use_yn_cd, :rmk_cd ]
      )
    end

    def work_routing_params_from_row(row)
      row.permit(
        :wrk_rt_cd, :wrk_rt_nm, :hwajong_cd, :wrk_type1_cd, :wrk_type2_cd, :use_yn_cd, :rmk_cd
      ).to_h.symbolize_keys
    end

    def process_inserts(rows, result, errors)
      Array(rows).each do |attrs|
        if attrs[:wrk_rt_cd].to_s.strip.blank? && attrs[:wrk_rt_nm].to_s.strip.blank?
          next
        end

        row = StdWorkRouting.new(work_routing_params_from_row(attrs))
        if row.save
          result[:inserted] += 1
        else
          errors.concat(row.errors.full_messages)
        end
      end
    end

    def process_updates(rows, result, errors)
      Array(rows).each do |attrs|
        wrk_rt_cd = attrs[:wrk_rt_cd].to_s.strip.upcase
        row = StdWorkRouting.find_by(wrk_rt_cd: wrk_rt_cd)
        if row.nil?
          errors << "기준작업경로 정보를 찾을 수 없습니다: #{wrk_rt_cd}"
          next
        end

        update_attrs = work_routing_params_from_row(attrs)
        update_attrs.delete(:wrk_rt_cd)
        if row.update(update_attrs)
          result[:updated] += 1
        else
          errors.concat(row.errors.full_messages)
        end
      end
    end

    def process_deletes(rows, result, errors)
      Array(rows).each do |wrk_rt_cd|
        normalized_code = wrk_rt_cd.to_s.strip.upcase
        row = StdWorkRouting.find_by(wrk_rt_cd: normalized_code)
        if row.nil?
          next
        end

        if row.update(use_yn_cd: "N")
          inactivate_steps(row, errors)
          result[:deleted] += 1
        else
          errors.concat(row.errors.full_messages.presence || [ "기준작업경로 비활성화에 실패했습니다: #{normalized_code}" ])
        end
      end
    end

    def inactivate_steps(work_routing, errors)
      work_routing.steps.where(use_yn_cd: "Y").ordered.each do |step|
        if !step.update(use_yn_cd: "N")
          errors.concat(step.errors.full_messages)
        end
      end
    end

    def work_routing_json(row)
      {
        id: row.wrk_rt_cd,
        wrk_rt_cd: row.wrk_rt_cd,
        wrk_rt_nm: row.wrk_rt_nm,
        hwajong_cd: row.hwajong_cd,
        wrk_type1_cd: row.wrk_type1_cd,
        wrk_type2_cd: row.wrk_type2_cd,
        use_yn_cd: row.use_yn_cd,
        rmk_cd: row.rmk_cd,
        create_by: row.create_by,
        create_time: row.create_time,
        update_by: row.update_by,
        update_time: row.update_time
      }
    end
end
