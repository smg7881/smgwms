class Om::CustomerSystemConfigsController < Om::BaseController
  KEY_FIELDS = %i[setup_unit_cd cust_cd lclas_cd mclas_cd sclas_cd setup_sctn_cd].freeze
  MERGE_KEY_FIELDS = %i[lclas_cd mclas_cd sclas_cd setup_sctn_cd].freeze

  def index
    @search_form = build_search_form

    respond_to do |format|
      format.html
      format.json do
        rows = if merge_customer_mode?
          merged_customer_rows(search_cust_cd)
        else
          customer_system_configs_scope.to_a.map { |row| row_hash_from_record(row) }
        end

        name_map = customer_name_map_from_codes(rows.map { |row| row[:cust_cd] })
        render json: rows.map { |row| row_json_from_hash(row, name_map) }
      end
    end
  end

  def batch_save
    operations = batch_save_params
    result = { inserted: 0, updated: 0, deleted: 0 }
    errors = []

    ActiveRecord::Base.transaction do
      Array(operations[:rowsToInsert]).each do |attrs|
        if attrs[:lclas_cd].to_s.strip.blank? && attrs[:module_nm].to_s.strip.blank?
          next
        end

        row = OmCustomerSystemConfig.new(config_params_from_row(attrs))
        if row.save
          result[:inserted] += 1
        else
          errors.concat(row.errors.full_messages)
        end
      end

      Array(operations[:rowsToUpdate]).each do |attrs|
        update_attrs = config_params_from_row(attrs)
        key_attrs = key_attrs_from_hash(update_attrs)
        if key_attrs.nil?
          errors << "수정 키가 올바르지 않습니다."
          next
        end

        row = OmCustomerSystemConfig.find_by(key_attrs)
        if row.present?
          if row.update(update_attrs)
            result[:updated] += 1
          else
            errors.concat(row.errors.full_messages)
          end
        else
          upsert_row = OmCustomerSystemConfig.new(update_attrs)
          if upsert_row.save
            result[:inserted] += 1
          else
            errors.concat(upsert_row.errors.full_messages)
          end
        end
      end

      Array(operations[:rowsToDelete]).each do |delete_key|
        row = nil

        delete_key_attrs = delete_key_attrs_from_value(delete_key)
        if delete_key_attrs.present?
          row = OmCustomerSystemConfig.find_by(delete_key_attrs)
        else
          row = OmCustomerSystemConfig.find_by(id: delete_key)
        end

        if row.nil?
          next
        end

        if row.update(use_yn: "N")
          result[:deleted] += 1
        else
          errors.concat(row.errors.full_messages.presence || [ "delete failed: #{delete_key.inspect}" ])
        end
      end

      if errors.any?
        raise ActiveRecord::Rollback
      end
    end

    if errors.any?
      render json: { success: false, errors: errors.uniq }, status: :unprocessable_entity
    else
      render json: { success: true, message: "고객별 시스템 설정이 저장되었습니다.", data: result }
    end
  end

  private
    def menu_code_for_permission
      "OM_CUST_SYS_CONF"
    end

    def build_search_form
      form = Om::CustomerSystemConfigSearchForm.new(search_params.to_h)
      if form.cust_cd.present?
        form.cust_nm = customer_name_for(form.cust_cd)
      end
      form
    end

    def search_params
      params.fetch(:q, {}).permit(
        :setup_unit_cd,
        :cust_cd,
        :lclas_cd,
        :mclas_cd,
        :sclas_cd,
        :setup_sctn_cd,
        :module_nm,
        :use_yn
      )
    end

    def merge_customer_mode?
      if search_setup_unit_cd == "CUSTOMER" && search_cust_cd.present?
        return true
      end

      false
    end

    def customer_system_configs_scope
      scope = OmCustomerSystemConfig.ordered

      if search_setup_unit_cd.present?
        scope = scope.where(setup_unit_cd: search_setup_unit_cd)
      end
      if search_cust_cd.present?
        scope = scope.where(cust_cd: search_cust_cd)
      end

      scope = apply_common_code_filters(scope)
      scope = apply_module_filter(scope)
      scope = apply_use_yn_filter(scope)
      scope
    end

    # CUSTOMER 조회에서만 실행:
    # system rows + customer rows를 merge key(l/m/s/setup_sctn) 기준으로 outer join 형태로 합침.
    # customer override가 있으면 customer row를 우선한다.
    def merged_customer_rows(cust_cd)
      system_scope = OmCustomerSystemConfig.where(setup_unit_cd: "SYSTEM")
      customer_scope = OmCustomerSystemConfig.where(setup_unit_cd: "CUSTOMER", cust_cd: cust_cd)

      system_scope = apply_common_code_filters(system_scope)
      customer_scope = apply_common_code_filters(customer_scope)

      merged = {}

      system_scope.find_each do |system_row|
        virtual_row = build_virtual_customer_row(system_row, cust_cd)
        merged[merge_key_for_hash(virtual_row)] = virtual_row
      end

      customer_scope.find_each do |customer_row|
        row_hash = row_hash_from_record(customer_row)
        merged[merge_key_for_hash(row_hash)] = row_hash
      end

      rows = merged.values
      rows = apply_module_filter_to_rows(rows)
      rows = apply_use_yn_filter_to_rows(rows)
      rows.sort_by do |row|
        [
          row[:lclas_cd].to_s,
          row[:mclas_cd].to_s,
          row[:sclas_cd].to_s,
          row[:setup_sctn_cd].to_s
        ]
      end
    end

    def apply_common_code_filters(scope)
      if search_lclas_cd.present?
        scope = scope.where(lclas_cd: search_lclas_cd)
      end
      if search_mclas_cd.present?
        scope = scope.where(mclas_cd: search_mclas_cd)
      end
      if search_sclas_cd.present?
        scope = scope.where(sclas_cd: search_sclas_cd)
      end
      if search_setup_sctn_cd.present?
        scope = scope.where(setup_sctn_cd: search_setup_sctn_cd)
      end
      scope
    end

    def apply_module_filter(scope)
      if search_module_nm.present?
        scope = scope.where("module_nm LIKE ?", "%#{search_module_nm}%")
      end
      scope
    end

    def apply_use_yn_filter(scope)
      if search_use_yn.present?
        scope = scope.where(use_yn: search_use_yn)
      end
      scope
    end

    def apply_module_filter_to_rows(rows)
      if search_module_nm.blank?
        return rows
      end

      keyword = search_module_nm.upcase
      rows.select do |row|
        row[:module_nm].to_s.upcase.include?(keyword)
      end
    end

    def apply_use_yn_filter_to_rows(rows)
      if search_use_yn.blank?
        return rows
      end

      rows.select do |row|
        row[:use_yn].to_s.upcase == search_use_yn
      end
    end

    def batch_save_params
      permitted = params.permit(
        rowsToInsert: [
          :setup_unit_cd, :cust_cd, :lclas_cd, :mclas_cd, :sclas_cd,
          :setup_sctn_cd, :module_nm, :setup_value, :use_yn
        ],
        rowsToUpdate: [
          :setup_unit_cd, :cust_cd, :lclas_cd, :mclas_cd, :sclas_cd,
          :setup_sctn_cd, :module_nm, :setup_value, :use_yn
        ]
      )

      # rowsToDelete accepts both:
      # - legacy scalar ids: [1, 2]
      # - composite keys: [{ setup_unit_cd: ..., cust_cd: ..., ... }]
      permitted[:rowsToDelete] = params[:rowsToDelete]
      permitted
    end

    def config_params_from_row(row)
      row.permit(
        *KEY_FIELDS,
        :module_nm,
        :setup_value,
        :use_yn
      ).to_h.symbolize_keys
    end

    def key_attrs_from_hash(attrs)
      normalize_key_hash(attrs.slice(*KEY_FIELDS))
    end

    def delete_key_attrs_from_value(delete_key)
      if delete_key.is_a?(ActionController::Parameters)
        return normalize_key_hash(delete_key.permit(*KEY_FIELDS).to_h.symbolize_keys)
      end

      if delete_key.is_a?(Hash)
        raw = delete_key.slice(*KEY_FIELDS.map(&:to_s), *KEY_FIELDS).to_h.symbolize_keys
        return normalize_key_hash(raw)
      end

      nil
    end

    def normalize_key_hash(raw)
      key_hash = {
        setup_unit_cd: raw[:setup_unit_cd].to_s.strip.upcase,
        cust_cd: raw[:cust_cd].to_s.strip.upcase,
        lclas_cd: raw[:lclas_cd].to_s.strip.upcase,
        mclas_cd: raw[:mclas_cd].to_s.strip.upcase,
        sclas_cd: raw[:sclas_cd].to_s.strip.upcase,
        setup_sctn_cd: raw[:setup_sctn_cd].to_s.strip.upcase
      }

      if key_hash[:setup_unit_cd] == "SYSTEM"
        key_hash[:cust_cd] = ""
      end

      required_fields = %i[setup_unit_cd lclas_cd mclas_cd sclas_cd setup_sctn_cd]
      if key_hash[:setup_unit_cd] == "CUSTOMER"
        required_fields = required_fields + [ :cust_cd ]
      end

      if required_fields.any? { |field| key_hash[field].blank? }
        return nil
      end

      key_hash
    end

    def row_hash_from_record(row)
      {
        id: row.id,
        setup_unit_cd: row.setup_unit_cd,
        cust_cd: row.cust_cd,
        cust_nm: nil,
        lclas_cd: row.lclas_cd,
        mclas_cd: row.mclas_cd,
        sclas_cd: row.sclas_cd,
        setup_sctn_cd: row.setup_sctn_cd,
        module_nm: row.module_nm,
        setup_value: row.setup_value,
        use_yn: row.use_yn,
        create_by: row.create_by,
        create_time: row.create_time,
        update_by: row.update_by,
        update_time: row.update_time,
        from_system_default: false
      }
    end

    def build_virtual_customer_row(system_row, cust_cd)
      base = row_hash_from_record(system_row)
      base.merge(
        id: nil,
        setup_unit_cd: "CUSTOMER",
        cust_cd: cust_cd,
        create_by: nil,
        create_time: nil,
        update_by: nil,
        update_time: nil,
        from_system_default: true
      )
    end

    def merge_key_for_hash(row)
      MERGE_KEY_FIELDS.map { |field| row[field].to_s.upcase }.join("::")
    end

    def row_json_from_hash(row, name_map)
      cust_code = row[:cust_cd].to_s.upcase
      resolved_name = row[:cust_nm].to_s.strip
      if resolved_name.blank?
        resolved_name = name_map[cust_code].to_s
      end

      row.merge(cust_nm: resolved_name.presence)
    end

    def customer_name_map_from_codes(codes)
      normalized_codes = Array(codes).map { |code| code.to_s.upcase }.reject(&:blank?).uniq
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

    def customer_name_for(cust_cd)
      if !defined?(StdBzacMst) || !StdBzacMst.table_exists?
        return cust_cd
      end

      StdBzacMst.find_by(bzac_cd: cust_cd.to_s.strip.upcase)&.bzac_nm.to_s.presence || cust_cd
    rescue ActiveRecord::StatementInvalid
      cust_cd
    end

    def search_setup_unit_cd
      search_params[:setup_unit_cd].to_s.strip.upcase.presence
    end

    def search_cust_cd
      search_params[:cust_cd].to_s.strip.upcase.presence
    end

    def search_lclas_cd
      search_params[:lclas_cd].to_s.strip.upcase.presence
    end

    def search_mclas_cd
      search_params[:mclas_cd].to_s.strip.upcase.presence
    end

    def search_sclas_cd
      search_params[:sclas_cd].to_s.strip.upcase.presence
    end

    def search_setup_sctn_cd
      search_params[:setup_sctn_cd].to_s.strip.upcase.presence
    end

    def search_module_nm
      search_params[:module_nm].to_s.strip.presence
    end

    def search_use_yn
      search_params[:use_yn].to_s.strip.upcase.presence
    end
end
