class Std::WorkStepsController < Std::BaseController
  def index
    respond_to do |format|
      format.html
      format.json { render json: work_steps_scope.map { |row| work_step_json(row) } }
    end
  end

  def create
    row = StdWorkStep.new(work_step_params)

    if row.save
      render json: { success: true, message: "작업단계가 등록되었습니다.", work_step: work_step_json(row) }
    else
      render json: { success: false, errors: row.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    row = find_work_step
    if row.nil?
      render json: { success: false, errors: [ "작업단계를 찾을 수 없습니다: #{params[:id]}" ] }, status: :not_found
      return
    end

    update_attrs = work_step_params.to_h
    update_attrs.delete("work_step_cd")

    if row.update(update_attrs)
      render json: { success: true, message: "작업단계가 수정되었습니다.", work_step: work_step_json(row) }
    else
      render json: { success: false, errors: row.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    row = find_work_step
    if row.nil?
      render json: { success: false, errors: [ "작업단계를 찾을 수 없습니다: #{params[:id]}" ] }, status: :not_found
      return
    end

    if row.update(use_yn_cd: "N")
      render json: { success: true, message: "작업단계가 비활성화되었습니다." }
    else
      render json: { success: false, errors: row.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private
    def menu_code_for_permission
      "STD_WORK_STEP"
    end

    def search_params
      params.fetch(:q, {}).permit(:work_step_cd, :work_step_nm, :use_yn_cd)
    end

    def work_steps_scope
      scope = StdWorkStep.ordered
      if search_work_step_cd.present?
        scope = scope.where("work_step_cd LIKE ?", "%#{search_work_step_cd}%")
      end
      if search_work_step_nm.present?
        scope = scope.where("work_step_nm LIKE ?", "%#{search_work_step_nm}%")
      end
      if search_use_yn_cd.present?
        scope = scope.where(use_yn_cd: search_use_yn_cd)
      end
      scope
    end

    def search_work_step_cd
      search_params[:work_step_cd].to_s.strip.upcase.presence
    end

    def search_work_step_nm
      search_params[:work_step_nm].to_s.strip.presence
    end

    def search_use_yn_cd
      search_params[:use_yn_cd].to_s.strip.upcase.presence
    end

    def work_step_params
      params.require(:work_step).permit(
        :work_step_cd, :work_step_nm, :work_step_level1_cd, :work_step_level2_cd,
        :sort_seq, :conts_cd, :rmk_cd, :use_yn_cd
      )
    end

    def find_work_step
      StdWorkStep.find_by(work_step_cd: params[:id].to_s.strip.upcase)
    end

    def work_step_json(row)
      {
        id: row.work_step_cd,
        work_step_cd: row.work_step_cd,
        work_step_nm: row.work_step_nm,
        work_step_level1_cd: row.work_step_level1_cd,
        work_step_level2_cd: row.work_step_level2_cd,
        sort_seq: row.sort_seq,
        conts_cd: row.conts_cd,
        rmk_cd: row.rmk_cd,
        use_yn_cd: row.use_yn_cd,
        create_by: row.create_by,
        create_time: row.create_time,
        update_by: row.update_by,
        update_time: row.update_time
      }
    end
end
