class Wm::PurFeeRtMngsController < System::BaseController
  def index
    respond_to do |format|
      format.html
      format.json { render json: records_scope.map { |record| record_json(record) } }
    end
  end

  def batch_save
    operations = batch_save_params
    result = { inserted: 0, updated: 0, deleted: 0 }
    errors = []

    ActiveRecord::Base.transaction do
      Array(operations[:rowsToInsert]).each do |attrs|
        if attrs[:work_pl_cd].to_s.strip.blank? && attrs[:ctrt_cprtco_cd].to_s.strip.blank?
          next
        end

        record = Wm::PurFeeRtMng.new(attrs.permit(:work_pl_cd, :ctrt_cprtco_cd, :sell_buy_attr_cd, :pur_dept_cd, :pur_item_type, :pur_item_cd, :pur_unit_clas_cd, :pur_unit_cd, :use_yn, :auto_yn, :rmk))
        record.wrhs_exca_fee_rt_no = generate_fee_rt_no

        if record.save
          result[:inserted] += 1
        else
          errors.concat(record.errors.full_messages)
        end
      end

      Array(operations[:rowsToUpdate]).each do |attrs|
        record = Wm::PurFeeRtMng.find_by(wrhs_exca_fee_rt_no: attrs[:wrhs_exca_fee_rt_no].to_s)
        if record.nil?
          errors << "창고정산요율번호를 찾을 수 없습니다: #{attrs[:wrhs_exca_fee_rt_no]}"
          next
        end

        if record.update(attrs.permit(:work_pl_cd, :ctrt_cprtco_cd, :sell_buy_attr_cd, :pur_dept_cd, :pur_item_type, :pur_item_cd, :pur_unit_clas_cd, :pur_unit_cd, :use_yn, :auto_yn, :rmk))
          result[:updated] += 1
        else
          errors.concat(record.errors.full_messages)
        end
      end

      Array(operations[:rowsToDelete]).each do |fee_rt_no|
        record = Wm::PurFeeRtMng.find_by(wrhs_exca_fee_rt_no: fee_rt_no.to_s)
        next if record.nil?

        if record.destroy
          result[:deleted] += 1
        else
          errors.concat(record.errors.full_messages.presence || [ "매입요율 삭제에 실패했습니다: #{fee_rt_no}" ])
        end
      end

      raise ActiveRecord::Rollback if errors.any?
    end

    if errors.any?
      render json: { success: false, errors: errors.uniq }, status: :unprocessable_entity
    else
      render json: { success: true, message: "매입요율 저장이 완료되었습니다.", data: result }
    end
  end

  private
    def search_params
      params.fetch(:q, {}).permit(:work_pl_cd, :ctrt_cprtco_cd, :sell_buy_attr_cd, :use_yn, :aply_date_from, :aply_date_to)
    end

    def records_scope
      scope = Wm::PurFeeRtMng.ordered

      if search_params[:work_pl_cd].present?
        scope = scope.where(work_pl_cd: search_params[:work_pl_cd])
      end
      if search_params[:ctrt_cprtco_cd].present?
        scope = scope.where(ctrt_cprtco_cd: search_params[:ctrt_cprtco_cd])
      end
      if search_params[:sell_buy_attr_cd].present?
        scope = scope.where(sell_buy_attr_cd: search_params[:sell_buy_attr_cd])
      end
      if search_params[:use_yn].present?
        scope = scope.where(use_yn: search_params[:use_yn])
      end

      # 매입요율상세 기간 조인 검색
      if search_params[:aply_date_from].present? && search_params[:aply_date_to].present?
        from_date = search_params[:aply_date_from].delete("-")
        to_date = search_params[:aply_date_to].delete("-")
        scope = scope.joins(:details).where(
          "(tb_wm06002.aply_strt_ymd <= ? AND tb_wm06002.aply_end_ymd >= ?) OR (tb_wm06002.aply_strt_ymd >= ? AND tb_wm06002.aply_strt_ymd <= ?)",
          to_date, from_date, from_date, to_date
        ).distinct
      end

      scope
    end

    def batch_save_params
      params.permit(
        rowsToDelete: [],
        rowsToInsert: [ :work_pl_cd, :ctrt_cprtco_cd, :sell_buy_attr_cd, :pur_dept_cd, :pur_item_type, :pur_item_cd, :pur_unit_clas_cd, :pur_unit_cd, :use_yn, :auto_yn, :rmk ],
        rowsToUpdate: [ :wrhs_exca_fee_rt_no, :work_pl_cd, :ctrt_cprtco_cd, :sell_buy_attr_cd, :pur_dept_cd, :pur_item_type, :pur_item_cd, :pur_unit_clas_cd, :pur_unit_cd, :use_yn, :auto_yn, :rmk ]
      )
    end

    def record_json(record)
      {
        id: record.wrhs_exca_fee_rt_no,
        wrhs_exca_fee_rt_no: record.wrhs_exca_fee_rt_no,
        corp_cd: record.corp_cd,
         work_pl_cd: record.work_pl_cd,
        sell_buy_sctn_cd: record.sell_buy_sctn_cd,
        ctrt_cprtco_cd: record.ctrt_cprtco_cd,
        sell_buy_attr_cd: record.sell_buy_attr_cd,
        pur_dept_cd: record.pur_dept_cd,
        pur_item_type: record.pur_item_type,
        pur_item_cd: record.pur_item_cd,
        pur_unit_clas_cd: record.pur_unit_clas_cd,
        pur_unit_cd: record.pur_unit_cd,
        use_yn: record.use_yn,
        auto_yn: record.auto_yn,
        rmk: record.rmk,
        update_by: record.update_by,
        update_time: record.update_time,
        create_by: record.create_by,
        create_time: record.create_time
      }
    end

    def generate_fee_rt_no
      # PRD 명세: SQ_TB_WM06001_FEE_RT_NO (여기선 임시로 시간 기반 생성)
      "P" + Time.current.strftime("%Y%m%d%H%M%S") + rand(100..999).to_s
    end
end
