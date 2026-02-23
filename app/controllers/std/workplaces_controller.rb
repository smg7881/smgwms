class Std::WorkplacesController < Std::BaseController
  def index
    respond_to do |format|
      format.html
      format.json { render json: workplaces_scope.map { |row| workplace_json(row) } }
    end
  end

  def create
    row = StdWorkplace.new(workplace_params)

    if row.save
      render json: { success: true, message: "작업장이 등록되었습니다.", workplace: workplace_json(row) }
    else
      render json: { success: false, errors: row.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    row = find_workplace
    if row.nil?
      render json: { success: false, errors: [ "작업장코드를 찾을 수 없습니다: #{params[:id]}" ] }, status: :not_found
      return
    end

    update_attrs = workplace_params.to_h
    update_attrs.delete("workpl_cd")

    if row.update(update_attrs)
      render json: { success: true, message: "작업장이 수정되었습니다.", workplace: workplace_json(row) }
    else
      render json: { success: false, errors: row.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    row = find_workplace
    if row.nil?
      render json: { success: false, errors: [ "작업장코드를 찾을 수 없습니다: #{params[:id]}" ] }, status: :not_found
      return
    end

    if row.update(use_yn_cd: "N")
      render json: { success: true, message: "작업장이 비활성화되었습니다." }
    else
      render json: { success: false, errors: row.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def batch_save
    operations = batch_save_params
    result = { inserted: 0, updated: 0, deleted: 0 }
    errors = []

    ActiveRecord::Base.transaction do
      Array(operations[:rowsToInsert]).each do |attrs|
        if attrs[:workpl_nm].to_s.strip.blank?
          next
        end

        row = StdWorkplace.new(workplace_params_from_row(attrs))
        if row.save
          result[:inserted] += 1
        else
          errors.concat(row.errors.full_messages)
        end
      end

      Array(operations[:rowsToUpdate]).each do |attrs|
        workpl_cd = attrs[:workpl_cd].to_s.strip.upcase
        row = StdWorkplace.find_by(workpl_cd: workpl_cd)
        if row.nil?
          errors << "작업장코드를 찾을 수 없습니다: #{workpl_cd}"
          next
        end

        update_attrs = workplace_params_from_row(attrs)
        update_attrs.delete(:workpl_cd)
        if row.update(update_attrs)
          result[:updated] += 1
        else
          errors.concat(row.errors.full_messages)
        end
      end

      Array(operations[:rowsToDelete]).each do |workpl_cd|
        row = StdWorkplace.find_by(workpl_cd: workpl_cd.to_s.strip.upcase)
        if row.nil?
          next
        end

        if row.update(use_yn_cd: "N")
          result[:deleted] += 1
        else
          errors.concat(row.errors.full_messages.presence || [ "작업장 비활성화에 실패했습니다: #{workpl_cd}" ])
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
      "STD_WORKPLACE"
    end

    def search_params
      params.fetch(:q, {}).permit(
        :corp_cd, :workpl, :workpl_cd, :workpl_nm,
        :workpl_sctn_cd, :use_yn_cd
      )
    end

    def workplaces_scope
      scope = StdWorkplace.ordered
      if search_corp_cd.present?
        scope = scope.where(corp_cd: search_corp_cd)
      end

      if search_workpl.present?
        keyword = "%#{search_workpl}%"
        scope = scope.where("workpl_cd LIKE ? OR workpl_nm LIKE ?", keyword, keyword)
      else
        if search_workpl_cd.present?
          scope = scope.where("workpl_cd LIKE ?", "%#{search_workpl_cd}%")
        end
        if search_workpl_nm.present?
          scope = scope.where("workpl_nm LIKE ?", "%#{search_workpl_nm}%")
        end
      end

      if search_workpl_sctn_cd.present?
        scope = scope.where(workpl_sctn_cd: search_workpl_sctn_cd)
      end
      if search_use_yn_cd.present?
        scope = scope.where(use_yn_cd: search_use_yn_cd)
      end
      scope
    end

    def search_corp_cd
      search_params[:corp_cd].to_s.strip.upcase.presence
    end

    def search_workpl
      search_params[:workpl].to_s.strip.upcase.presence
    end

    def search_workpl_cd
      search_params[:workpl_cd].to_s.strip.upcase.presence
    end

    def search_workpl_nm
      search_params[:workpl_nm].to_s.strip.presence
    end

    def search_workpl_sctn_cd
      search_params[:workpl_sctn_cd].to_s.strip.upcase.presence
    end

    def search_use_yn_cd
      search_params[:use_yn_cd].to_s.strip.upcase.presence
    end

    def batch_save_params
      params.permit(
        rowsToDelete: [],
        rowsToInsert: [
          :corp_cd, :workpl_cd, :upper_workpl_cd, :dept_cd, :workpl_nm, :workpl_sctn_cd,
          :capa_spec_unit_cd, :max_capa, :adpt_capa, :dimem_spec_unit_cd, :dimem, :wm_yn_cd,
          :bzac_cd, :ctry_cd, :zip_cd, :addr_cd, :dtl_addr_cd, :use_yn_cd, :remk_cd
        ],
        rowsToUpdate: [
          :corp_cd, :workpl_cd, :upper_workpl_cd, :dept_cd, :workpl_nm, :workpl_sctn_cd,
          :capa_spec_unit_cd, :max_capa, :adpt_capa, :dimem_spec_unit_cd, :dimem, :wm_yn_cd,
          :bzac_cd, :ctry_cd, :zip_cd, :addr_cd, :dtl_addr_cd, :use_yn_cd, :remk_cd
        ]
      )
    end

    def workplace_params
      params.require(:workplace).permit(
        :corp_cd, :workpl_cd, :upper_workpl_cd, :dept_cd, :workpl_nm, :workpl_sctn_cd,
        :capa_spec_unit_cd, :max_capa, :adpt_capa, :dimem_spec_unit_cd, :dimem, :wm_yn_cd,
        :bzac_cd, :ctry_cd, :zip_cd, :addr_cd, :dtl_addr_cd, :use_yn_cd, :remk_cd
      )
    end

    def workplace_params_from_row(row)
      row.permit(
        :corp_cd, :workpl_cd, :upper_workpl_cd, :dept_cd, :workpl_nm, :workpl_sctn_cd,
        :capa_spec_unit_cd, :max_capa, :adpt_capa, :dimem_spec_unit_cd, :dimem, :wm_yn_cd,
        :bzac_cd, :ctry_cd, :zip_cd, :addr_cd, :dtl_addr_cd, :use_yn_cd, :remk_cd
      ).to_h.symbolize_keys
    end

    def find_workplace
      StdWorkplace.find_by(workpl_cd: params[:id].to_s.strip.upcase)
    end

    def workplace_json(row)
      {
        id: row.workpl_cd,
        corp_cd: row.corp_cd,
        workpl_cd: row.workpl_cd,
        upper_workpl_cd: row.upper_workpl_cd,
        dept_cd: row.dept_cd,
        workpl_nm: row.workpl_nm,
        workpl_sctn_cd: row.workpl_sctn_cd,
        capa_spec_unit_cd: row.capa_spec_unit_cd,
        max_capa: row.max_capa,
        adpt_capa: row.adpt_capa,
        dimem_spec_unit_cd: row.dimem_spec_unit_cd,
        dimem: row.dimem,
        wm_yn_cd: row.wm_yn_cd,
        bzac_cd: row.bzac_cd,
        ctry_cd: row.ctry_cd,
        zip_cd: row.zip_cd,
        addr_cd: row.addr_cd,
        dtl_addr_cd: row.dtl_addr_cd,
        use_yn_cd: row.use_yn_cd,
        remk_cd: row.remk_cd,
        create_by: row.create_by,
        create_time: row.create_time,
        update_by: row.update_by,
        update_time: row.update_time
      }
    end
end
