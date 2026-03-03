class Std::WorkRoutingStepDetailsController < Std::BaseController
  def index
    work_routing = find_work_routing
    if work_routing.nil?
      render json: []
    else
      render json: work_routing.steps.ordered.map { |row| detail_json(row) }
    end
  end

  def batch_save
    operations = batch_save_params
    work_routing = find_work_routing!
    result = { inserted: 0, updated: 0, deleted: 0 }
    errors = []

    ActiveRecord::Base.transaction do
      process_inserts(work_routing, operations[:rowsToInsert], result, errors)
      process_updates(work_routing, operations[:rowsToUpdate], result, errors)
      process_deletes(work_routing, operations[:rowsToDelete], result, errors)

      if errors.any?
        raise ActiveRecord::Rollback
      end
    end

    if errors.any?
      render json: { success: false, errors: errors.uniq }, status: :unprocessable_entity
    else
      render json: { success: true, message: "작업경로별 작업단계 정보가 저장되었습니다.", data: result }
    end
  end

  private
    def menu_code_for_permission
      "STD_WRK_RTING_STEP"
    end

    def find_work_routing
      wrk_rt_cd = params[:work_routing_step_id].to_s.strip.upcase
      StdWorkRouting.find_by(wrk_rt_cd: wrk_rt_cd)
    end

    def find_work_routing!
      work_routing = find_work_routing
      if work_routing.nil?
        raise ActiveRecord::RecordNotFound, "work_routing not found: #{params[:work_routing_step_id]}"
      end

      work_routing
    end

    def batch_save_params
      params.permit(
        rowsToDelete: [],
        rowsToInsert: [ :seq_no, :work_step_cd, :work_step_level1_cd, :work_step_level2_cd, :use_yn_cd, :rmk_cd ],
        rowsToUpdate: [ :seq_no, :work_step_cd, :work_step_level1_cd, :work_step_level2_cd, :use_yn_cd, :rmk_cd ]
      )
    end

    def detail_insert_attrs(row)
      row.permit(:seq_no, :work_step_cd, :work_step_level1_cd, :work_step_level2_cd, :use_yn_cd, :rmk_cd).to_h.symbolize_keys
    end

    def detail_update_attrs(row)
      row.permit(:work_step_cd, :work_step_level1_cd, :work_step_level2_cd, :use_yn_cd, :rmk_cd).to_h.symbolize_keys
    end

    def process_inserts(work_routing, rows, result, errors)
      Array(rows).each do |attrs|
        if attrs[:work_step_cd].to_s.strip.blank? && attrs[:work_step_level1_cd].to_s.strip.blank?
          next
        end

        row = work_routing.steps.new(detail_insert_attrs(attrs))
        row.wrk_rt_cd = work_routing.wrk_rt_cd
        if row.save
          result[:inserted] += 1
        else
          errors.concat(row.errors.full_messages)
        end
      end
    end

    def process_updates(work_routing, rows, result, errors)
      Array(rows).each do |attrs|
        seq_no = attrs[:seq_no].to_i
        row = work_routing.steps.find_by(seq_no: seq_no)
        if row.nil?
          errors << "작업단계 정보를 찾을 수 없습니다: #{work_routing.wrk_rt_cd}/#{attrs[:seq_no]}"
          next
        end

        if row.update(detail_update_attrs(attrs))
          result[:updated] += 1
        else
          errors.concat(row.errors.full_messages)
        end
      end
    end

    def process_deletes(work_routing, rows, result, errors)
      Array(rows).each do |seq_no|
        row = work_routing.steps.find_by(seq_no: seq_no.to_i)
        if row.nil?
          next
        end

        if row.update(use_yn_cd: "N")
          result[:deleted] += 1
        else
          errors.concat(row.errors.full_messages.presence || [ "작업단계 비활성화에 실패했습니다: #{work_routing.wrk_rt_cd}/#{seq_no}" ])
        end
      end
    end

    def detail_json(row)
      {
        id: "#{row.wrk_rt_cd}_#{row.seq_no}",
        wrk_rt_cd: row.wrk_rt_cd,
        seq_no: row.seq_no,
        work_step_cd: row.work_step_cd,
        work_step_level1_cd: row.work_step_level1_cd,
        work_step_level2_cd: row.work_step_level2_cd,
        use_yn_cd: row.use_yn_cd,
        rmk_cd: row.rmk_cd,
        create_by: row.create_by,
        create_time: row.create_time,
        update_by: row.update_by,
        update_time: row.update_time
      }
    end
end
