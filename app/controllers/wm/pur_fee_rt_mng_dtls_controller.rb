class Wm::PurFeeRtMngDtlsController < System::BaseController
  before_action :set_master

  def index
    respond_to do |format|
      format.json { render json: records_scope.map { |record| record_json(record) } }
    end
  end

  def batch_save
    operations = batch_save_params
    result = { inserted: 0, updated: 0, deleted: 0 }
    errors = []

    ActiveRecord::Base.transaction do
      Array(operations[:rowsToInsert]).each do |attrs|
        record = @master.details.build(attrs.permit(:dcsn_yn, :aply_strt_ymd, :aply_end_ymd, :aply_uprice, :cur_cd, :std_work_qty, :aply_strt_qty, :aply_end_qty, :rmk))
        record.lineno = generate_lineno

        if record.save
          result[:inserted] += 1
        else
          errors.concat(record.errors.full_messages)
        end
      end

      Array(operations[:rowsToUpdate]).each do |attrs|
        record = @master.details.find_by(lineno: attrs[:lineno])
        if record.nil?
          errors << "라인번호를 찾을 수 없습니다: #{attrs[:lineno]}"
          next
        end

        if record.update(attrs.permit(:dcsn_yn, :aply_strt_ymd, :aply_end_ymd, :aply_uprice, :cur_cd, :std_work_qty, :aply_strt_qty, :aply_end_qty, :rmk))
          result[:updated] += 1
        else
          errors.concat(record.errors.full_messages)
        end
      end

      Array(operations[:rowsToDelete]).each do |lineno|
        record = @master.details.find_by(lineno: lineno)
        next if record.nil?

        if record.destroy
          result[:deleted] += 1
        else
          errors.concat(record.errors.full_messages.presence || [ "요율 삭제에 실패했습니다: #{lineno}" ])
        end
      end

      raise ActiveRecord::Rollback if errors.any?
    end

    if errors.any?
      render json: { success: false, errors: errors.uniq }, status: :unprocessable_entity
    else
      render json: { success: true, message: "요율상세 저장이 완료되었습니다.", data: result }
    end
  end

  private
    def set_master
      @master = Wm::PurFeeRtMng.find_by(wrhs_exca_fee_rt_no: params[:pur_fee_rt_mng_id])
      unless @master
        render json: { success: false, errors: [ "요율마스터를 찾을 수 없습니다." ] }, status: :not_found
      end
    end

    def records_scope
      @master.details.order(:lineno)
    end

    def batch_save_params
      params.permit(
        rowsToDelete: [],
        rowsToInsert: [ :dcsn_yn, :aply_strt_ymd, :aply_end_ymd, :aply_uprice, :cur_cd, :std_work_qty, :aply_strt_qty, :aply_end_qty, :rmk ],
        rowsToUpdate: [ :lineno, :dcsn_yn, :aply_strt_ymd, :aply_end_ymd, :aply_uprice, :cur_cd, :std_work_qty, :aply_strt_qty, :aply_end_qty, :rmk ]
      )
    end

    def record_json(record)
      {
        id: record.lineno,
        wrhs_exca_fee_rt_no: record.wrhs_exca_fee_rt_no,
        lineno: record.lineno,
        dcsn_yn: record.dcsn_yn,
        aply_strt_ymd: record.aply_strt_ymd,
        aply_end_ymd: record.aply_end_ymd,
        aply_uprice: record.aply_uprice,
        cur_cd: record.cur_cd,
        std_work_qty: record.std_work_qty,
        aply_strt_qty: record.aply_strt_qty,
        aply_end_qty: record.aply_end_qty,
        rmk: record.rmk,
        update_by: record.update_by,
        update_time: record.update_time,
        create_by: record.create_by,
        create_time: record.create_time
      }
    end

    def generate_lineno
      max_lineno = @master.details.maximum(:lineno) || 0
      max_lineno + 1
    end
end
