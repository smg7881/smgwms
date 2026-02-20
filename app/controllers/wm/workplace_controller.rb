class Wm::WorkplaceController < Wm::BaseController
  def index
    respond_to do |format|
      format.html
      format.json { render json: workplaces_scope.map { |workplace| workplace_json(workplace) } }
    end
  end

  def batch_save
    operations = batch_save_params
    result = { inserted: 0, updated: 0, deleted: 0 }
    errors = []

    ActiveRecord::Base.transaction do
      Array(operations[:rowsToInsert]).each do |attrs|
        if attrs[:workpl_cd].to_s.strip.blank? && attrs[:workpl_nm].to_s.strip.blank?
          next
        end

        workplace = WmWorkplace.new(workplace_params_from_row(attrs))
        if workplace.save
          result[:inserted] += 1
        else
          errors.concat(workplace.errors.full_messages)
        end
      end

      Array(operations[:rowsToUpdate]).each do |attrs|
        workpl_cd = attrs[:workpl_cd].to_s.strip.upcase
        workplace = WmWorkplace.find_by(workpl_cd: workpl_cd)

        if workplace.nil?
          errors << "작업장코드를 찾을 수 없습니다: #{workpl_cd}"
          next
        end

        update_attrs = workplace_params_from_row(attrs)
        update_attrs.delete(:workpl_cd)

        if workplace.update(update_attrs)
          result[:updated] += 1
        else
          errors.concat(workplace.errors.full_messages)
        end
      end

      Array(operations[:rowsToDelete]).each do |workpl_cd|
        workplace = WmWorkplace.find_by(workpl_cd: workpl_cd.to_s.strip.upcase)
        if workplace.nil?
          next
        end

        if workplace.destroy
          result[:deleted] += 1
        else
          errors.concat(workplace.errors.full_messages.presence || [ "작업장 삭제에 실패했습니다: #{workpl_cd}" ])
        end
      end

      if errors.any?
        raise ActiveRecord::Rollback
      end
    end

    if errors.any?
      render json: { success: false, errors: errors.uniq }, status: :unprocessable_entity
    else
      render json: { success: true, message: "작업장 데이터가 저장되었습니다.", data: result }
    end
  end

  private
    def menu_code_for_permission
      "WM_WORKPLACE"
    end

    def search_params
      params.fetch(:q, {}).permit(:workpl, :workpl_type, :workplType, :use_yn, :useYn)
    end

    def workplaces_scope
      scope = WmWorkplace.ordered

      if search_workpl.present?
        keyword = "%#{search_workpl}%"
        scope = scope.where("workpl_cd LIKE ? OR workpl_nm LIKE ?", keyword, keyword)
      end
      if search_workpl_type.present?
        scope = scope.where(workpl_type: search_workpl_type)
      end
      if search_use_yn.present?
        scope = scope.where(use_yn: search_use_yn)
      end

      scope
    end

    def search_workpl
      search_params[:workpl].to_s.strip.upcase.presence
    end

    def search_workpl_type
      value = search_params[:workpl_type].presence || search_params[:workplType].presence
      value.to_s.strip.upcase.presence
    end

    def search_use_yn
      value = search_params[:use_yn].presence || search_params[:useYn].presence
      value.to_s.strip.upcase.presence
    end

    def batch_save_params
      params.permit(
        rowsToDelete: [],
        rowsToInsert: [
          :workpl_cd, :workpl_nm, :workpl_type, :client_cd, :prop_cd,
          :nation_cd, :zip_cd, :addr, :addr_dtl, :tel_no, :fax_no,
          :remk, :use_yn
        ],
        rowsToUpdate: [
          :workpl_cd, :workpl_nm, :workpl_type, :client_cd, :prop_cd,
          :nation_cd, :zip_cd, :addr, :addr_dtl, :tel_no, :fax_no,
          :remk, :use_yn
        ]
      )
    end

    def workplace_params_from_row(row)
      row.permit(
        :workpl_cd, :workpl_nm, :workpl_type, :client_cd, :prop_cd,
        :nation_cd, :zip_cd, :addr, :addr_dtl, :tel_no, :fax_no,
        :remk, :use_yn
      ).to_h.symbolize_keys
    end

    def workplace_json(workplace)
      {
        id: workplace.workpl_cd,
        workpl_cd: workplace.workpl_cd,
        workpl_nm: workplace.workpl_nm,
        workpl_type: workplace.workpl_type,
        client_cd: workplace.client_cd,
        prop_cd: workplace.prop_cd,
        nation_cd: workplace.nation_cd,
        zip_cd: workplace.zip_cd,
        addr: workplace.addr,
        addr_dtl: workplace.addr_dtl,
        tel_no: workplace.tel_no,
        fax_no: workplace.fax_no,
        remk: workplace.remk,
        use_yn: workplace.use_yn,
        create_by: workplace.create_by,
        create_time: workplace.create_time,
        update_by: workplace.update_by,
        update_time: workplace.update_time
      }
    end
end
