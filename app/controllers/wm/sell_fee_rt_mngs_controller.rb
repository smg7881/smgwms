class Wm::SellFeeRtMngsController < Wm::BaseController
  def index
    @selected_fee_rt_no = params[:selected_fee_rt_no].to_s.strip.presence

    respond_to do |format|
      format.html
      format.json { render json: records_scope.map { |record| record_json(record) } }
    end
  end

  def batch_save
    master_operations = master_batch_save_params
    detail_operations = detail_batch_save_params
    result = {
      master: { inserted: 0, updated: 0, deleted: 0 },
      detail: { inserted: 0, updated: 0, deleted: 0 }
    }
    errors = []
    inserted_master_key_by_temp_id = {}
    deleted_master_keys = []
    selected_master_key = nil

    ActiveRecord::Base.transaction do
      process_master_inserts(master_operations[:rowsToInsert], result[:master], errors, inserted_master_key_by_temp_id)
      process_master_updates(master_operations[:rowsToUpdate], result[:master], errors)
      process_master_deletes(master_operations[:rowsToDelete], result[:master], errors, deleted_master_keys)

      selected_master_key = resolve_detail_master_key(
        detail_operations: detail_operations,
        inserted_master_key_by_temp_id: inserted_master_key_by_temp_id,
        deleted_master_keys: deleted_master_keys,
        errors: errors
      )

      validate_new_master_requires_detail(
        inserted_master_key_by_temp_id: inserted_master_key_by_temp_id,
        detail_operations: detail_operations,
        errors: errors
      )

      process_detail_operations(
        master_key: selected_master_key,
        detail_operations: detail_operations,
        result: result[:detail],
        errors: errors
      )

      if errors.any?
        raise ActiveRecord::Rollback
      end
    end

    if errors.any?
      render json: { success: false, errors: errors.uniq }, status: :unprocessable_entity
    else
      render json: {
        success: true,
        message: "매출요율 저장이 완료되었습니다.",
        data: result,
        selected_master_key: selected_master_key
      }
    end
  end

  private
    def menu_code_for_permission
      "WM_SELL_FEE_RT_MNG"
    end

    def search_params
      params.fetch(:q, {}).permit(:work_pl_cd, :ctrt_cprtco_cd, :sell_buy_attr_cd, :use_yn, :aply_date_from, :aply_date_to)
    end

    def records_scope
      scope = Wm::SellFeeRtMng.ordered

      if search_params[:work_pl_cd].present?
        scope = scope.where(work_pl_cd: normalize_code(search_params[:work_pl_cd]))
      end
      if search_params[:ctrt_cprtco_cd].present?
        scope = scope.where(ctrt_cprtco_cd: normalize_code(search_params[:ctrt_cprtco_cd]))
      end
      if search_params[:sell_buy_attr_cd].present?
        scope = scope.where(sell_buy_attr_cd: normalize_code(search_params[:sell_buy_attr_cd]))
      end
      if search_params[:use_yn].present?
        scope = scope.where(use_yn: normalize_use_yn(search_params[:use_yn]))
      end

      if search_params[:aply_date_from].present? && search_params[:aply_date_to].present?
        from_date = normalize_ymd(search_params[:aply_date_from])
        to_date = normalize_ymd(search_params[:aply_date_to])
        detail_table = Wm::SellFeeRtMngDtl.table_name
        scope = scope.joins(:details).where(
          "(#{detail_table}.aply_strt_ymd <= ? AND #{detail_table}.aply_end_ymd >= ?) OR (#{detail_table}.aply_strt_ymd >= ? AND #{detail_table}.aply_strt_ymd <= ?)",
          to_date, from_date, from_date, to_date
        ).distinct
      end

      scope
    end

    def master_batch_save_params
      params.permit(
        rowsToDelete: [],
        rowsToInsert: [
          :client_temp_id, :corp_cd, :work_pl_cd, :ctrt_cprtco_cd, :sell_buy_attr_cd,
          :sell_dept_cd, :sell_item_type, :sell_item_cd, :sell_unit_clas_cd, :sell_unit_cd,
          :use_yn, :auto_yn, :rmk
        ],
        rowsToUpdate: [
          :wrhs_exca_fee_rt_no, :work_pl_cd, :ctrt_cprtco_cd, :sell_buy_attr_cd,
          :sell_dept_cd, :sell_item_type, :sell_item_cd, :sell_unit_clas_cd, :sell_unit_cd,
          :use_yn, :auto_yn, :rmk
        ]
      )
    end

    def detail_batch_save_params
      raw = params[:detailOperations]
      if raw.respond_to?(:permit)
        raw.permit(
          :master_key,
          :master_client_temp_id,
          rowsToDelete: [],
          rowsToInsert: [ :dcsn_yn, :aply_strt_ymd, :aply_end_ymd, :aply_uprice, :cur_cd, :std_work_qty, :aply_strt_qty, :aply_end_qty, :rmk ],
          rowsToUpdate: [ :lineno, :dcsn_yn, :aply_strt_ymd, :aply_end_ymd, :aply_uprice, :cur_cd, :std_work_qty, :aply_strt_qty, :aply_end_qty, :rmk ]
        )
      else
        ActionController::Parameters.new.permit
      end
    end

    def process_master_inserts(rows, result, errors, inserted_master_key_by_temp_id)
      Array(rows).each do |attrs|
        if attrs[:work_pl_cd].to_s.strip.blank? && attrs[:ctrt_cprtco_cd].to_s.strip.blank?
          next
        end

        record = Wm::SellFeeRtMng.new(master_insert_attrs(attrs))
        record.wrhs_exca_fee_rt_no = generate_fee_rt_no
        record.corp_cd = resolve_corp_cd(attrs)

        if record.save
          result[:inserted] += 1
          temp_id = attrs[:client_temp_id].to_s.strip
          if temp_id.present?
            inserted_master_key_by_temp_id[temp_id] = record.wrhs_exca_fee_rt_no
          end
        else
          errors.concat(record.errors.full_messages)
        end
      end
    end

    def process_master_updates(rows, result, errors)
      Array(rows).each do |attrs|
        master_key = normalize_code(attrs[:wrhs_exca_fee_rt_no])
        record = Wm::SellFeeRtMng.find_by(wrhs_exca_fee_rt_no: master_key)

        if record.nil?
          errors << "창고정산요율번호를 찾을 수 없습니다: #{master_key}"
        else
          if record.update(master_update_attrs(attrs))
            result[:updated] += 1
          else
            errors.concat(record.errors.full_messages)
          end
        end
      end
    end

    def process_master_deletes(rows, result, errors, deleted_master_keys)
      Array(rows).each do |raw_key|
        master_key = normalize_code(raw_key)
        record = Wm::SellFeeRtMng.find_by(wrhs_exca_fee_rt_no: master_key)
        if record.nil?
          next
        end

        if record.destroy
          result[:deleted] += 1
          deleted_master_keys << master_key
        else
          errors.concat(record.errors.full_messages.presence || [ "매출요율 삭제에 실패했습니다: #{master_key}" ])
        end
      end
    end

    def resolve_detail_master_key(detail_operations:, inserted_master_key_by_temp_id:, deleted_master_keys:, errors:)
      has_detail_changes = detail_operations_changed?(detail_operations)
      if !has_detail_changes
        return nil
      end

      master_key = normalize_code(detail_operations[:master_key])
      if master_key.present?
        if deleted_master_keys.include?(master_key)
          errors << "삭제된 매출요율은 상세를 저장할 수 없습니다."
          return nil
        end

        if Wm::SellFeeRtMng.exists?(wrhs_exca_fee_rt_no: master_key)
          return master_key
        end
      end

      temp_id = detail_operations[:master_client_temp_id].to_s.strip
      if temp_id.present?
        mapped_key = inserted_master_key_by_temp_id[temp_id]
        if mapped_key.present?
          return mapped_key
        end
      end

      errors << "상세 저장 대상 매출요율을 찾을 수 없습니다."
      nil
    end

    def validate_new_master_requires_detail(inserted_master_key_by_temp_id:, detail_operations:, errors:)
      if inserted_master_key_by_temp_id.any? && !detail_insert_exists?(detail_operations)
        errors << "요율상세를 등록하시기 바랍니다."
      end
    end

    def process_detail_operations(master_key:, detail_operations:, result:, errors:)
      if !detail_operations_changed?(detail_operations)
        return
      end

      if master_key.blank?
        errors << "상세 저장 대상 매출요율이 없습니다."
        return
      end

      master = Wm::SellFeeRtMng.find_by(wrhs_exca_fee_rt_no: master_key)
      if master.nil?
        errors << "요율마스터를 찾을 수 없습니다: #{master_key}"
        return
      end

      process_detail_inserts(master, detail_operations[:rowsToInsert], result, errors)
      process_detail_updates(master, detail_operations[:rowsToUpdate], result, errors)
      process_detail_deletes(master, detail_operations[:rowsToDelete], result, errors)
    end

    def process_detail_inserts(master, rows, result, errors)
      Array(rows).each do |attrs|
        if attrs[:aply_strt_ymd].to_s.strip.blank? && attrs[:aply_end_ymd].to_s.strip.blank?
          next
        end

        record = master.details.new(detail_insert_attrs(attrs))
        record.wrhs_exca_fee_rt_no = master.wrhs_exca_fee_rt_no
        record.lineno = next_detail_lineno(master)
        if record.save
          result[:inserted] += 1
        else
          errors.concat(record.errors.full_messages)
        end
      end
    end

    def process_detail_updates(master, rows, result, errors)
      Array(rows).each do |attrs|
        lineno = attrs[:lineno].to_i
        record = master.details.find_by(lineno: lineno)

        if record.nil?
          errors << "라인번호를 찾을 수 없습니다: #{lineno}"
        else
          if record.update(detail_update_attrs(attrs))
            result[:updated] += 1
          else
            errors.concat(record.errors.full_messages)
          end
        end
      end
    end

    def process_detail_deletes(master, rows, result, errors)
      Array(rows).each do |raw_lineno|
        lineno = raw_lineno.to_i
        record = master.details.find_by(lineno: lineno)
        if record.nil?
          next
        end

        if record.destroy
          result[:deleted] += 1
        else
          errors.concat(record.errors.full_messages.presence || [ "요율상세 삭제에 실패했습니다: #{lineno}" ])
        end
      end
    end

    def master_insert_attrs(attrs)
      attrs.permit(
        :work_pl_cd, :ctrt_cprtco_cd, :sell_buy_attr_cd, :sell_dept_cd,
        :sell_item_type, :sell_item_cd, :sell_unit_clas_cd, :sell_unit_cd,
        :use_yn, :auto_yn, :rmk
      )
    end

    def master_update_attrs(attrs)
      attrs.permit(
        :work_pl_cd, :ctrt_cprtco_cd, :sell_buy_attr_cd, :sell_dept_cd,
        :sell_item_type, :sell_item_cd, :sell_unit_clas_cd, :sell_unit_cd,
        :use_yn, :auto_yn, :rmk
      )
    end

    def detail_insert_attrs(attrs)
      permitted = attrs.permit(
        :dcsn_yn, :aply_strt_ymd, :aply_end_ymd, :aply_uprice,
        :cur_cd, :std_work_qty, :aply_strt_qty, :aply_end_qty, :rmk
      )
      normalize_detail_dates!(permitted)
      permitted
    end

    def detail_update_attrs(attrs)
      permitted = attrs.permit(
        :dcsn_yn, :aply_strt_ymd, :aply_end_ymd, :aply_uprice,
        :cur_cd, :std_work_qty, :aply_strt_qty, :aply_end_qty, :rmk
      )
      normalize_detail_dates!(permitted)
      permitted
    end

    def normalize_detail_dates!(attrs)
      attrs[:aply_strt_ymd] = normalize_ymd(attrs[:aply_strt_ymd])
      attrs[:aply_end_ymd] = normalize_ymd(attrs[:aply_end_ymd])
    end

    def next_detail_lineno(master)
      max_lineno = master.details.maximum(:lineno)
      if max_lineno
        max_lineno + 1
      else
        1
      end
    end

    def detail_operations_changed?(detail_operations)
      rows_to_insert = Array(detail_operations[:rowsToInsert])
      rows_to_update = Array(detail_operations[:rowsToUpdate])
      rows_to_delete = Array(detail_operations[:rowsToDelete])
      rows_to_insert.any? || rows_to_update.any? || rows_to_delete.any?
    end

    def detail_insert_exists?(detail_operations)
      Array(detail_operations[:rowsToInsert]).any?
    end

    def resolve_corp_cd(attrs)
      requested = normalize_code(attrs[:corp_cd])
      if requested.present?
        return requested
      end

      if defined?(StdCorporation) && StdCorporation.table_exists?
        active_corp = StdCorporation.where(use_yn_cd: "Y").order(:corp_cd).limit(1).pick(:corp_cd)
        if active_corp.present?
          return normalize_code(active_corp)
        end

        any_corp = StdCorporation.order(:corp_cd).limit(1).pick(:corp_cd)
        if any_corp.present?
          return normalize_code(any_corp)
        end
      end

      "DEFAULT"
    rescue ActiveRecord::StatementInvalid
      "DEFAULT"
    end

    def normalize_ymd(value)
      value.to_s.gsub(/[^0-9]/, "").first(8)
    end

    def normalize_code(value)
      value.to_s.strip.upcase
    end

    def normalize_use_yn(value)
      normalized = value.to_s.strip.upcase
      if normalized == "N"
        "N"
      else
        "Y"
      end
    end

    def generate_fee_rt_no
      "S#{Time.current.strftime('%Y%m%d%H%M%S')}#{rand(100..999)}"
    end

    def workplace_name(code)
      lookup_name(workplace_name_map, code)
    end

    def client_name(code)
      lookup_name(client_name_map, code)
    end

    def sellbuy_attr_name(code)
      lookup_name(sellbuy_attr_name_map, code)
    end

    def dept_name(code)
      lookup_name(dept_name_map, code)
    end

    def good_name(code)
      lookup_name(good_name_map, code)
    end

    def lookup_name(map, code)
      normalized_code = normalize_code(code)
      map[normalized_code]
    end

    def workplace_name_map
      @workplace_name_map ||= begin
        if defined?(StdWorkplace) && StdWorkplace.table_exists?
          StdWorkplace.where(use_yn_cd: "Y").pluck(:workpl_cd, :workpl_nm).to_h { |cd, nm| [normalize_code(cd), nm.to_s.strip] }
        else
          {}
        end
      rescue ActiveRecord::StatementInvalid
        {}
      end
    end

    def client_name_map
      @client_name_map ||= begin
        if defined?(StdBzacMst) && StdBzacMst.table_exists?
          StdBzacMst.where(use_yn_cd: "Y").pluck(:bzac_cd, :bzac_nm).to_h { |cd, nm| [normalize_code(cd), nm.to_s.strip] }
        else
          {}
        end
      rescue ActiveRecord::StatementInvalid
        {}
      end
    end

    def sellbuy_attr_name_map
      @sellbuy_attr_name_map ||= begin
        if defined?(StdSellbuyAttribute) && StdSellbuyAttribute.table_exists?
          StdSellbuyAttribute.where(use_yn_cd: "Y").pluck(:sellbuy_attr_cd, :sellbuy_attr_nm).to_h { |cd, nm| [normalize_code(cd), nm.to_s.strip] }
        else
          {}
        end
      rescue ActiveRecord::StatementInvalid
        {}
      end
    end

    def dept_name_map
      @dept_name_map ||= begin
        if defined?(AdmDept) && AdmDept.table_exists?
          AdmDept.where(use_yn: "Y").pluck(:dept_code, :dept_nm).to_h { |cd, nm| [normalize_code(cd), nm.to_s.strip] }
        else
          {}
        end
      rescue ActiveRecord::StatementInvalid
        {}
      end
    end

    def good_name_map
      @good_name_map ||= begin
        if defined?(StdGood) && StdGood.table_exists?
          StdGood.where(use_yn_cd: "Y").pluck(:goods_cd, :goods_nm).to_h { |cd, nm| [normalize_code(cd), nm.to_s.strip] }
        else
          {}
        end
      rescue ActiveRecord::StatementInvalid
        {}
      end
    end

    def record_json(record)
      {
        id: record.wrhs_exca_fee_rt_no,
        wrhs_exca_fee_rt_no: record.wrhs_exca_fee_rt_no,
        corp_cd: record.corp_cd,
        work_pl_cd: record.work_pl_cd,
        work_pl_nm: workplace_name(record.work_pl_cd),
        sell_buy_sctn_cd: record.sell_buy_sctn_cd,
        ctrt_cprtco_cd: record.ctrt_cprtco_cd,
        ctrt_cprtco_nm: client_name(record.ctrt_cprtco_cd),
        sell_buy_attr_cd: record.sell_buy_attr_cd,
        sell_buy_attr_nm: sellbuy_attr_name(record.sell_buy_attr_cd),
        sell_dept_cd: record.sell_dept_cd,
        sell_dept_nm: dept_name(record.sell_dept_cd),
        sell_item_type: record.sell_item_type,
        sell_item_cd: record.sell_item_cd,
        sell_item_nm: good_name(record.sell_item_cd),
        sell_unit_clas_cd: record.sell_unit_clas_cd,
        sell_unit_cd: record.sell_unit_cd,
        use_yn: record.use_yn,
        auto_yn: record.auto_yn,
        rmk: record.rmk,
        update_by: record.update_by,
        update_time: record.update_time,
        create_by: record.create_by,
        create_time: record.create_time
      }
    end
end
