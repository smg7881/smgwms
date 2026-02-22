class Std::InterfaceInfosController < Std::BaseController
  def index
    respond_to do |format|
      format.html
      format.json { render json: interface_infos_scope.map { |row| interface_info_json(row) } }
    end
  end

  def batch_save
    operations = batch_save_params
    result = { inserted: 0, updated: 0, deleted: 0 }
    errors = []

    ActiveRecord::Base.transaction do
      Array(operations[:rowsToInsert]).each do |attrs|
        if attrs[:if_nm_cd].to_s.strip.blank?
          next
        end

        row = StdInterfaceInfo.new(interface_info_params_from_row(attrs))
        if row.save
          result[:inserted] += 1
        else
          errors.concat(row.errors.full_messages)
        end
      end

      Array(operations[:rowsToUpdate]).each do |attrs|
        if_cd = attrs[:if_cd].to_s.strip.upcase
        row = StdInterfaceInfo.find_by(if_cd: if_cd)
        if row.nil?
          errors << "Interface row not found: #{if_cd}"
          next
        end

        update_attrs = interface_info_params_from_row(attrs)
        update_attrs.delete(:if_cd)
        if row.update(update_attrs)
          result[:updated] += 1
        else
          errors.concat(row.errors.full_messages)
        end
      end

      Array(operations[:rowsToDelete]).each do |if_cd|
        row = StdInterfaceInfo.find_by(if_cd: if_cd.to_s.strip.upcase)
        if row.nil?
          next
        end

        if row.update(use_yn_cd: "N")
          result[:deleted] += 1
        else
          errors.concat(row.errors.full_messages.presence || [ "Interface row deactivation failed: #{if_cd}" ])
        end
      end

      if errors.any?
        raise ActiveRecord::Rollback
      end
    end

    if errors.any?
      render json: { success: false, errors: errors.uniq }, status: :unprocessable_entity
    else
      render json: { success: true, message: "Interface data saved.", data: result }
    end
  end

  private
    def menu_code_for_permission
      "STD_INTERFACE_INFO"
    end

    def search_params
      params.fetch(:q, {}).permit(:corp_cd, :if_sctn_cd, :if_nm_cd, :use_yn_cd)
    end

    def interface_infos_scope
      scope = StdInterfaceInfo.ordered
      if search_corp_cd.present?
        scope = scope.where(corp_cd: search_corp_cd)
      end
      if search_if_sctn_cd.present?
        scope = scope.where(if_sctn_cd: search_if_sctn_cd)
      end
      if search_if_nm_cd.present?
        scope = scope.where("if_nm_cd LIKE ?", "%#{search_if_nm_cd}%")
      end
      if search_use_yn_cd.present?
        scope = scope.where(use_yn_cd: search_use_yn_cd)
      end
      scope
    end

    def search_corp_cd
      search_params[:corp_cd].to_s.strip.upcase.presence
    end

    def search_if_sctn_cd
      search_params[:if_sctn_cd].to_s.strip.upcase.presence
    end

    def search_if_nm_cd
      search_params[:if_nm_cd].to_s.strip.presence
    end

    def search_use_yn_cd
      search_params[:use_yn_cd].to_s.strip.upcase.presence
    end

    def batch_save_params
      params.permit(
        rowsToDelete: [],
        rowsToInsert: [
          :corp_cd, :if_cd, :if_meth_cd, :if_sctn_cd, :if_nm_cd, :send_sys_cd, :rcv_sys_cd,
          :rcv_sctn_cd, :use_yn_cd, :if_bzac_cd, :bzac_nm, :bzac_sys_nm_cd, :if_desc_cd
        ],
        rowsToUpdate: [
          :corp_cd, :if_cd, :if_meth_cd, :if_sctn_cd, :if_nm_cd, :send_sys_cd, :rcv_sys_cd,
          :rcv_sctn_cd, :use_yn_cd, :if_bzac_cd, :bzac_nm, :bzac_sys_nm_cd, :if_desc_cd
        ]
      )
    end

    def interface_info_params_from_row(row)
      row.permit(
        :corp_cd, :if_cd, :if_meth_cd, :if_sctn_cd, :if_nm_cd, :send_sys_cd, :rcv_sys_cd,
        :rcv_sctn_cd, :use_yn_cd, :if_bzac_cd, :bzac_nm, :bzac_sys_nm_cd, :if_desc_cd
      ).to_h.symbolize_keys
    end

    def interface_info_json(row)
      {
        id: row.if_cd,
        corp_cd: row.corp_cd,
        if_cd: row.if_cd,
        if_meth_cd: row.if_meth_cd,
        if_sctn_cd: row.if_sctn_cd,
        if_nm_cd: row.if_nm_cd,
        send_sys_cd: row.send_sys_cd,
        rcv_sys_cd: row.rcv_sys_cd,
        rcv_sctn_cd: row.rcv_sctn_cd,
        use_yn_cd: row.use_yn_cd,
        if_bzac_cd: row.if_bzac_cd,
        bzac_nm: row.bzac_nm,
        bzac_sys_nm_cd: row.bzac_sys_nm_cd,
        if_desc_cd: row.if_desc_cd,
        create_by: row.create_by,
        create_time: row.create_time,
        update_by: row.update_by,
        update_time: row.update_time
      }
    end
end
