class Wm::SellFeeRtMngDtlsController < Wm::BaseController
  before_action :set_master

  def index
    render json: records_scope.map { |record| record_json(record) }
  end

  private
    def menu_code_for_permission
      "WM_SELL_FEE_RT_MNG"
    end

    def set_master
      master_key = params[:sell_fee_rt_mng_id].to_s.strip.upcase
      @master = Wm::SellFeeRtMng.find_by(wrhs_exca_fee_rt_no: master_key)
      if @master.nil?
        render json: { success: false, errors: ["요율마스터를 찾을 수 없습니다."] }, status: :not_found
        return
      end
    end

    def records_scope
      @master.details.order(:lineno)
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
end
