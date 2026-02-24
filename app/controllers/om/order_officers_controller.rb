class Om::OrderOfficersController < Om::BaseController
  def index
    @search_form = build_search_form

    respond_to do |format|
      format.html
      format.json do
        rows = order_officers_scope.to_a
        dept_name_map = dept_name_map_from_codes(rows.map(&:ord_chrg_dept_cd))
        customer_name_map = customer_name_map_from_codes(rows.map(&:cust_cd))
        officer_info_map = officer_info_map_from_codes(rows.map(&:ofcr_cd))

        render json: rows.map { |row| row_json(row, dept_name_map, customer_name_map, officer_info_map) }
      end
    end
  end

  def batch_save
    operations = batch_save_params
    result = { inserted: 0, updated: 0, deleted: 0 }
    errors = []

    ActiveRecord::Base.transaction do
      Array(operations[:rowsToInsert]).each do |attrs|
        if insert_row_blank?(attrs)
          next
        end

        row = OmOrderOfficer.new(order_officer_params_from_row(attrs))
        if row.save
          result[:inserted] += 1
        else
          errors.concat(row.errors.full_messages)
        end
      end

      Array(operations[:rowsToUpdate]).each do |attrs|
        id = attrs[:id].to_s.strip
        normalized_params = order_officer_params_from_row(attrs)

        if id.present?
          row = OmOrderOfficer.find_by(id: id)
          if row.present?
            if row.update(normalized_params)
              result[:updated] += 1
            else
              errors.concat(row.errors.full_messages)
            end
          else
            upsert_row = OmOrderOfficer.new(normalized_params)
            if upsert_row.save
              result[:inserted] += 1
            else
              errors.concat(upsert_row.errors.full_messages)
            end
          end
        else
          upsert_row = OmOrderOfficer.new(normalized_params)
          if upsert_row.save
            result[:inserted] += 1
          else
            errors.concat(upsert_row.errors.full_messages)
          end
        end
      end

      Array(operations[:rowsToDelete]).each do |delete_key|
        row = row_from_delete_key(delete_key)
        if row.nil?
          next
        end

        if row.update(use_yn: "N")
          result[:deleted] += 1
        else
          errors.concat(row.errors.full_messages.presence || [ "오더담당자 삭제에 실패했습니다: #{delete_key}" ])
        end
      end

      if errors.any?
        raise ActiveRecord::Rollback
      end
    end

    if errors.any?
      render json: { success: false, errors: errors.uniq }, status: :unprocessable_entity
    else
      render json: { success: true, message: "오더담당자 정보가 저장되었습니다.", data: result }
    end
  end

  private
    def menu_code_for_permission
      "OM_ORD_OFCR"
    end

    def build_search_form
      form = Om::OrderOfficerSearchForm.new(search_params.to_h)
      if form.dept_cd.present?
        form.dept_nm = dept_name_for(form.dept_cd)
      end
      if form.cust_cd.present?
        form.cust_nm = customer_name_for(form.cust_cd)
      end
      if form.ofcr_cd.present?
        form.ofcr_nm = officer_name_for(form.ofcr_cd)
      end
      form
    end

    def search_params
      params.fetch(:q, {}).permit(:dept_cd, :cust_cd, :exp_imp_dom_sctn_cd, :ofcr_cd)
    end

    def order_officers_scope
      scope = OmOrderOfficer.ordered.where(use_yn: "Y")
      if search_dept_cd.present?
        scope = scope.where(ord_chrg_dept_cd: search_dept_cd)
      end
      if search_cust_cd.present?
        scope = scope.where(cust_cd: search_cust_cd)
      end
      if search_exp_imp_dom_sctn_cd.present?
        scope = scope.where(exp_imp_dom_sctn_cd: search_exp_imp_dom_sctn_cd)
      end
      if search_ofcr_cd.present?
        scope = scope.where(ofcr_cd: search_ofcr_cd)
      end
      scope
    end

    def search_dept_cd
      search_params[:dept_cd].to_s.strip.upcase.presence
    end

    def search_cust_cd
      search_params[:cust_cd].to_s.strip.upcase.presence
    end

    def search_exp_imp_dom_sctn_cd
      search_params[:exp_imp_dom_sctn_cd].to_s.strip.upcase.presence
    end

    def search_ofcr_cd
      search_params[:ofcr_cd].to_s.strip.upcase.presence
    end

    def batch_save_params
      params.permit(
        rowsToDelete: [],
        rowsToInsert: [
          :id, :ord_chrg_dept_cd, :ord_chrg_dept_nm, :cust_cd, :cust_nm,
          :exp_imp_dom_sctn_cd, :ofcr_cd, :ofcr_nm, :tel_no, :mbp_no, :use_yn
        ],
        rowsToUpdate: [
          :id, :ord_chrg_dept_cd, :ord_chrg_dept_nm, :cust_cd, :cust_nm,
          :exp_imp_dom_sctn_cd, :ofcr_cd, :ofcr_nm, :tel_no, :mbp_no, :use_yn
        ]
      )
    end

    def insert_row_blank?(attrs)
      attrs[:ord_chrg_dept_cd].to_s.strip.blank? &&
        attrs[:cust_cd].to_s.strip.blank? &&
        attrs[:ofcr_cd].to_s.strip.blank?
    end

    def row_from_delete_key(delete_key)
      if delete_key.is_a?(ActionController::Parameters)
        return OmOrderOfficer.find_by(id: delete_key[:id].to_s.strip.presence)
      end

      if delete_key.is_a?(Hash)
        return OmOrderOfficer.find_by(id: delete_key[:id].to_s.strip.presence || delete_key["id"].to_s.strip.presence)
      end

      OmOrderOfficer.find_by(id: delete_key.to_s.strip.presence)
    end

    def order_officer_params_from_row(row)
      params_hash = row.permit(
        :ord_chrg_dept_cd, :ord_chrg_dept_nm, :cust_cd, :cust_nm,
        :exp_imp_dom_sctn_cd, :ofcr_cd, :ofcr_nm, :tel_no, :mbp_no, :use_yn
      ).to_h.symbolize_keys

      dept_cd = params_hash[:ord_chrg_dept_cd].to_s.strip.upcase
      cust_cd = params_hash[:cust_cd].to_s.strip.upcase
      ofcr_cd = params_hash[:ofcr_cd].to_s.strip.upcase

      if params_hash[:ord_chrg_dept_nm].to_s.strip.blank? && dept_cd.present?
        params_hash[:ord_chrg_dept_nm] = dept_name_for(dept_cd)
      end
      if params_hash[:cust_nm].to_s.strip.blank? && cust_cd.present?
        params_hash[:cust_nm] = customer_name_for(cust_cd)
      end
      if params_hash[:ofcr_nm].to_s.strip.blank? && ofcr_cd.present?
        params_hash[:ofcr_nm] = officer_name_for(ofcr_cd)
      end

      normalized_phone = if ofcr_cd.present?
        officer_phone_for(ofcr_cd)
      else
        ""
      end
      if params_hash[:tel_no].to_s.strip.blank? && normalized_phone.present?
        params_hash[:tel_no] = normalized_phone
      end
      if params_hash[:mbp_no].to_s.strip.blank? && normalized_phone.present?
        params_hash[:mbp_no] = normalized_phone
      end

      if params_hash[:use_yn].to_s.strip.blank?
        params_hash[:use_yn] = "Y"
      end

      params_hash
    end

    def row_json(row, dept_name_map, customer_name_map, officer_info_map)
      dept_code = row.ord_chrg_dept_cd.to_s.upcase
      cust_code = row.cust_cd.to_s.upcase
      officer_code = row.ofcr_cd.to_s.upcase
      officer_info = officer_info_map[officer_code] || {}

      {
        id: row.id,
        ord_chrg_dept_cd: dept_code,
        ord_chrg_dept_nm: row.ord_chrg_dept_nm.to_s.presence || dept_name_map[dept_code].to_s.presence,
        cust_cd: cust_code,
        cust_nm: row.cust_nm.to_s.presence || customer_name_map[cust_code].to_s.presence,
        exp_imp_dom_sctn_cd: row.exp_imp_dom_sctn_cd,
        ofcr_cd: officer_code,
        ofcr_nm: row.ofcr_nm.to_s.presence || officer_info[:name].to_s.presence,
        tel_no: row.tel_no.to_s.presence || officer_info[:phone].to_s.presence,
        mbp_no: row.mbp_no.to_s.presence || officer_info[:mobile_phone].to_s.presence || officer_info[:phone].to_s.presence,
        use_yn: row.use_yn,
        create_by: row.create_by,
        create_time: row.create_time,
        update_by: row.update_by,
        update_time: row.update_time
      }
    end

    def dept_name_map_from_codes(codes)
      normalized_codes = Array(codes).map { |code| code.to_s.strip.upcase }.reject(&:blank?).uniq
      if normalized_codes.empty?
        return {}
      end
      if !defined?(AdmDept) || !AdmDept.table_exists?
        return {}
      end

      AdmDept.where(dept_code: normalized_codes).pluck(:dept_code, :dept_nm).to_h do |code, name|
        [ code.to_s.upcase, name.to_s.strip ]
      end
    rescue ActiveRecord::StatementInvalid
      {}
    end

    def customer_name_map_from_codes(codes)
      normalized_codes = Array(codes).map { |code| code.to_s.strip.upcase }.reject(&:blank?).uniq
      if normalized_codes.empty?
        return {}
      end
      if !defined?(StdBzacMst) || !StdBzacMst.table_exists?
        return {}
      end

      StdBzacMst.where(bzac_cd: normalized_codes).pluck(:bzac_cd, :bzac_nm).to_h do |code, name|
        [ code.to_s.upcase, name.to_s.strip ]
      end
    rescue ActiveRecord::StatementInvalid
      {}
    end

    def officer_info_map_from_codes(codes)
      normalized_codes = Array(codes).map { |code| code.to_s.strip.upcase }.reject(&:blank?).uniq
      if normalized_codes.empty?
        return {}
      end
      if !defined?(User) || !User.table_exists?
        return {}
      end

      User.where(user_id_code: normalized_codes).pluck(:user_id_code, :user_nm, :phone).to_h do |code, name, phone|
        normalized_phone = phone.to_s.strip
        [
          code.to_s.upcase,
          {
            name: name.to_s.strip,
            phone: normalized_phone.presence,
            mobile_phone: normalized_phone.presence
          }
        ]
      end
    rescue ActiveRecord::StatementInvalid
      {}
    end

    def dept_name_for(dept_cd)
      if !defined?(AdmDept) || !AdmDept.table_exists?
        return dept_cd
      end

      AdmDept.find_by(dept_code: dept_cd.to_s.strip.upcase)&.dept_nm.to_s.presence || dept_cd
    rescue ActiveRecord::StatementInvalid
      dept_cd
    end

    def customer_name_for(cust_cd)
      if !defined?(StdBzacMst) || !StdBzacMst.table_exists?
        return cust_cd
      end

      StdBzacMst.find_by(bzac_cd: cust_cd.to_s.strip.upcase)&.bzac_nm.to_s.presence || cust_cd
    rescue ActiveRecord::StatementInvalid
      cust_cd
    end

    def officer_name_for(ofcr_cd)
      if !defined?(User) || !User.table_exists?
        return ofcr_cd
      end

      User.find_by(user_id_code: ofcr_cd.to_s.strip.upcase)&.user_nm.to_s.presence || ofcr_cd
    rescue ActiveRecord::StatementInvalid
      ofcr_cd
    end

    def officer_phone_for(ofcr_cd)
      if !defined?(User) || !User.table_exists?
        return ""
      end

      User.find_by(user_id_code: ofcr_cd.to_s.strip.upcase)&.phone.to_s.strip
    rescue ActiveRecord::StatementInvalid
      ""
    end
end
