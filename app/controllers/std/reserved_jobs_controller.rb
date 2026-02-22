class Std::ReservedJobsController < Std::BaseController
  def index
    respond_to do |format|
      format.html
      format.json { render json: reserved_jobs_scope.map { |row| reserved_job_json(row) } }
    end
  end

  def batch_save
    operations = batch_save_params
    result = { inserted: 0, updated: 0, deleted: 0 }
    errors = []

    ActiveRecord::Base.transaction do
      Array(operations[:rowsToInsert]).each do |attrs|
        if attrs[:rsv_work_nm_cd].to_s.strip.blank?
          next
        end

        row = StdReservedJob.new(reserved_job_params_from_row(attrs))
        if row.rel_menu_nm.blank? && row.rel_menu_cd.present?
          row.rel_menu_nm = AdmMenu.find_by(menu_cd: row.rel_menu_cd)&.menu_nm
        end

        if row.save
          result[:inserted] += 1
        else
          errors.concat(row.errors.full_messages)
        end
      end

      Array(operations[:rowsToUpdate]).each do |attrs|
        rsv_work_no = attrs[:rsv_work_no].to_s.strip.upcase
        row = StdReservedJob.find_by(rsv_work_no: rsv_work_no)
        if row.nil?
          errors << "예약작업 정보를 찾을 수 없습니다: #{rsv_work_no}"
          next
        end

        update_attrs = reserved_job_params_from_row(attrs)
        update_attrs.delete(:rsv_work_no)
        if row.update(update_attrs)
          result[:updated] += 1
        else
          errors.concat(row.errors.full_messages)
        end
      end

      Array(operations[:rowsToDelete]).each do |rsv_work_no|
        row = StdReservedJob.find_by(rsv_work_no: rsv_work_no.to_s.strip.upcase)
        if row.nil?
          next
        end

        if row.update(use_yn_cd: "N")
          result[:deleted] += 1
        else
          errors.concat(row.errors.full_messages.presence || [ "예약작업 비활성화에 실패했습니다: #{rsv_work_no}" ])
        end
      end

      if errors.any?
        raise ActiveRecord::Rollback
      end
    end

    if errors.any?
      render json: { success: false, errors: errors.uniq }, status: :unprocessable_entity
    else
      render json: { success: true, message: "예약작업 정보가 저장되었습니다.", data: result }
    end
  end

  private
    def menu_code_for_permission
      "STD_RESERVED_JOB"
    end

    def search_params
      params.fetch(:q, {}).permit(:sys_sctn_cd, :rsv_work_nm_cd, :use_yn_cd)
    end

    def reserved_jobs_scope
      scope = StdReservedJob.ordered
      if search_sys_sctn_cd.present?
        scope = scope.where(sys_sctn_cd: search_sys_sctn_cd)
      end
      if search_rsv_work_nm_cd.present?
        scope = scope.where("rsv_work_nm_cd LIKE ?", "%#{search_rsv_work_nm_cd}%")
      end
      if search_use_yn_cd.present?
        scope = scope.where(use_yn_cd: search_use_yn_cd)
      end
      scope
    end

    def search_sys_sctn_cd
      search_params[:sys_sctn_cd].to_s.strip.upcase.presence
    end

    def search_rsv_work_nm_cd
      search_params[:rsv_work_nm_cd].to_s.strip.presence
    end

    def search_use_yn_cd
      search_params[:use_yn_cd].to_s.strip.upcase.presence
    end

    def batch_save_params
      params.permit(
        rowsToDelete: [],
        rowsToInsert: [
          :sys_sctn_cd, :rsv_work_no, :rel_menu_cd, :rel_menu_nm, :rsv_work_nm_cd, :rsv_work_desc_cd,
          :rel_pgm_cd, :rel_pgm_nm, :pgm_sctn_cd, :rsv_work_cycle_cd, :hms_unit_min, :rmk_cd, :use_yn_cd
        ],
        rowsToUpdate: [
          :sys_sctn_cd, :rsv_work_no, :rel_menu_cd, :rel_menu_nm, :rsv_work_nm_cd, :rsv_work_desc_cd,
          :rel_pgm_cd, :rel_pgm_nm, :pgm_sctn_cd, :rsv_work_cycle_cd, :hms_unit_min, :rmk_cd, :use_yn_cd
        ]
      )
    end

    def reserved_job_params_from_row(row)
      row.permit(
        :sys_sctn_cd, :rsv_work_no, :rel_menu_cd, :rel_menu_nm, :rsv_work_nm_cd, :rsv_work_desc_cd,
        :rel_pgm_cd, :rel_pgm_nm, :pgm_sctn_cd, :rsv_work_cycle_cd, :hms_unit_min, :rmk_cd, :use_yn_cd
      ).to_h.symbolize_keys
    end

    def reserved_job_json(row)
      {
        id: row.rsv_work_no,
        sys_sctn_cd: row.sys_sctn_cd,
        rsv_work_no: row.rsv_work_no,
        rel_menu_cd: row.rel_menu_cd,
        rel_menu_nm: row.rel_menu_nm,
        rsv_work_nm_cd: row.rsv_work_nm_cd,
        rsv_work_desc_cd: row.rsv_work_desc_cd,
        rel_pgm_cd: row.rel_pgm_cd,
        rel_pgm_nm: row.rel_pgm_nm,
        pgm_sctn_cd: row.pgm_sctn_cd,
        rsv_work_cycle_cd: row.rsv_work_cycle_cd,
        hms_unit_min: row.hms_unit_min,
        rmk_cd: row.rmk_cd,
        use_yn_cd: row.use_yn_cd,
        create_by: row.create_by,
        create_time: row.create_time,
        update_by: row.update_by,
        update_time: row.update_time
      }
    end
end
