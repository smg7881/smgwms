class Std::CorporationsController < Std::BaseController
  def index
    respond_to do |format|
      format.html
      format.json { render json: corporations_scope.map { |row| corporation_json(row) } }
    end
  end

  def country_infos
    corporation = find_corporation
    rows = corporation.country_rows.ordered.map { |row| country_json(row) }
    render json: rows
  end

  def batch_save
    operations = batch_save_params
    result = { inserted: 0, updated: 0, deleted: 0 }
    errors = []

    ActiveRecord::Base.transaction do
      Array(operations[:rowsToInsert]).each do |attrs|
        if attrs[:corp_nm].to_s.strip.blank?
          next
        end

        row = StdCorporation.new(corporation_params_from_row(attrs))
        if row.save
          result[:inserted] += 1
        else
          errors.concat(row.errors.full_messages)
        end
      end

      Array(operations[:rowsToUpdate]).each do |attrs|
        corp_cd = attrs[:corp_cd].to_s.strip.upcase
        row = StdCorporation.find_by(corp_cd: corp_cd)
        if row.nil?
          errors << "법인 정보를 찾을 수 없습니다: #{corp_cd}"
          next
        end

        update_attrs = corporation_params_from_row(attrs)
        update_attrs.delete(:corp_cd)
        row.assign_attributes(update_attrs)
        tracked_changes = row.changes_to_save.except("update_by", "update_time")

        if row.save
          save_histories!(corp_cd: row.corp_cd, source_kind: "MASTER", source_key: row.corp_cd, tracked_changes: tracked_changes)
          result[:updated] += 1
        else
          errors.concat(row.errors.full_messages)
        end
      end

      Array(operations[:rowsToDelete]).each do |corp_cd|
        normalized_code = corp_cd.to_s.strip.upcase
        row = StdCorporation.find_by(corp_cd: normalized_code)
        if row.nil?
          next
        end

        before_use_yn = row.use_yn_cd
        if row.update(use_yn_cd: "N")
          if before_use_yn != "N"
            save_histories!(
              corp_cd: row.corp_cd,
              source_kind: "MASTER",
              source_key: row.corp_cd,
              tracked_changes: { "use_yn_cd" => [ before_use_yn, "N" ] }
            )
          end
          result[:deleted] += 1
        else
          errors.concat(row.errors.full_messages.presence || [ "법인 비활성화에 실패했습니다: #{normalized_code}" ])
        end
      end

      if errors.any?
        raise ActiveRecord::Rollback
      end
    end

    if errors.any?
      render json: { success: false, errors: errors.uniq }, status: :unprocessable_entity
    else
      render json: { success: true, message: "법인 정보가 저장되었습니다.", data: result }
    end
  end

  def batch_save_country_infos
    corporation = find_corporation
    operations = country_batch_save_params
    result = { inserted: 0, updated: 0, deleted: 0 }
    errors = []

    ActiveRecord::Base.transaction do
      Array(operations[:rowsToInsert]).each do |attrs|
        if attrs[:ctry_cd].to_s.strip.blank?
          next
        end

        row = StdCorporationCountry.new(
          country_params_from_row(attrs).merge(corp_cd: corporation.corp_cd)
        )
        if row.save
          result[:inserted] += 1
        else
          errors.concat(row.errors.full_messages)
        end
      end

      Array(operations[:rowsToUpdate]).each do |attrs|
        row = StdCorporationCountry.find_by(corp_cd: corporation.corp_cd, seq: attrs[:seq].to_i)
        if row.nil?
          errors << "법인 국가 정보를 찾을 수 없습니다: #{corporation.corp_cd}/#{attrs[:seq]}"
          next
        end

        update_attrs = country_params_from_row(attrs)
        update_attrs.delete(:seq)
        row.assign_attributes(update_attrs)
        tracked_changes = row.changes_to_save.except("update_by", "update_time")

        if row.save
          save_histories!(
            corp_cd: corporation.corp_cd,
            source_kind: "COUNTRY",
            source_key: row.seq.to_s,
            tracked_changes: tracked_changes
          )
          result[:updated] += 1
        else
          errors.concat(row.errors.full_messages)
        end
      end

      Array(operations[:rowsToDelete]).each do |seq|
        row = StdCorporationCountry.find_by(corp_cd: corporation.corp_cd, seq: seq.to_i)
        if row.nil?
          next
        end

        before_use_yn = row.use_yn_cd
        if row.update(use_yn_cd: "N")
          if before_use_yn != "N"
            save_histories!(
              corp_cd: corporation.corp_cd,
              source_kind: "COUNTRY",
              source_key: row.seq.to_s,
              tracked_changes: { "use_yn_cd" => [ before_use_yn, "N" ] }
            )
          end
          result[:deleted] += 1
        else
          errors.concat(row.errors.full_messages.presence || [ "법인 국가 정보 비활성화에 실패했습니다: #{corporation.corp_cd}/#{seq}" ])
        end
      end

      active_rep_count = StdCorporationCountry.where(corp_cd: corporation.corp_cd, rpt_yn_cd: "Y", use_yn_cd: "Y").count
      if active_rep_count > 1
        errors << "법인별 대표 국가는 1개만 설정할 수 있습니다."
      end

      if errors.any?
        raise ActiveRecord::Rollback
      end
    end

    if errors.any?
      render json: { success: false, errors: errors.uniq }, status: :unprocessable_entity
    else
      render json: { success: true, message: "법인 국가 정보가 저장되었습니다.", data: result }
    end
  end

  private
    def menu_code_for_permission
      "STD_CORPORATION"
    end

    def find_corporation
      corp_cd = params[:id].to_s.strip.upcase
      StdCorporation.find_by!(corp_cd: corp_cd)
    end

    def search_params
      params.fetch(:q, {}).permit(:corp_cd, :corp_nm, :use_yn_cd)
    end

    def corporations_scope
      scope = StdCorporation.ordered
      if search_corp_cd.present?
        scope = scope.where("corp_cd LIKE ?", "%#{search_corp_cd}%")
      end
      if search_corp_nm.present?
        scope = scope.where("corp_nm LIKE ?", "%#{search_corp_nm}%")
      end
      if search_use_yn_cd.present?
        scope = scope.where(use_yn_cd: search_use_yn_cd)
      end
      scope
    end

    def search_corp_cd
      search_params[:corp_cd].to_s.strip.upcase.presence
    end

    def search_corp_nm
      search_params[:corp_nm].to_s.strip.presence
    end

    def search_use_yn_cd
      search_params[:use_yn_cd].to_s.strip.upcase.presence
    end

    def batch_save_params
      params.permit(
        rowsToDelete: [],
        rowsToInsert: [ :corp_cd, :corp_nm, :indstype_cd, :bizcond_cd, :rptr_nm_cd, :compreg_slip_cd, :upper_corp_cd, :zip_cd, :addr_cd, :dtl_addr_cd, :vat_sctn_cd, :use_yn_cd ],
        rowsToUpdate: [ :corp_cd, :corp_nm, :indstype_cd, :bizcond_cd, :rptr_nm_cd, :compreg_slip_cd, :upper_corp_cd, :zip_cd, :addr_cd, :dtl_addr_cd, :vat_sctn_cd, :use_yn_cd ]
      )
    end

    def country_batch_save_params
      params.permit(
        rowsToDelete: [],
        rowsToInsert: [ :seq, :ctry_cd, :aply_mon_unit_cd, :timezone_cd, :std_time, :summer_time, :sys_lang_slc, :vat_rt, :rpt_yn_cd, :use_yn_cd ],
        rowsToUpdate: [ :seq, :ctry_cd, :aply_mon_unit_cd, :timezone_cd, :std_time, :summer_time, :sys_lang_slc, :vat_rt, :rpt_yn_cd, :use_yn_cd ]
      )
    end

    def corporation_params_from_row(row)
      row.permit(
        :corp_cd, :corp_nm, :indstype_cd, :bizcond_cd, :rptr_nm_cd, :compreg_slip_cd, :upper_corp_cd, :zip_cd, :addr_cd, :dtl_addr_cd, :vat_sctn_cd, :use_yn_cd
      ).to_h.symbolize_keys
    end

    def country_params_from_row(row)
      row.permit(
        :seq, :ctry_cd, :aply_mon_unit_cd, :timezone_cd, :std_time, :summer_time, :sys_lang_slc, :vat_rt, :rpt_yn_cd, :use_yn_cd
      ).to_h.symbolize_keys
    end

    def corporation_json(row)
      {
        id: row.corp_cd,
        corp_cd: row.corp_cd,
        corp_nm: row.corp_nm,
        indstype_cd: row.indstype_cd,
        bizcond_cd: row.bizcond_cd,
        rptr_nm_cd: row.rptr_nm_cd,
        compreg_slip_cd: row.compreg_slip_cd,
        upper_corp_cd: row.upper_corp_cd,
        zip_cd: row.zip_cd,
        addr_cd: row.addr_cd,
        dtl_addr_cd: row.dtl_addr_cd,
        vat_sctn_cd: row.vat_sctn_cd,
        use_yn_cd: row.use_yn_cd,
        create_by: row.create_by,
        create_time: row.create_time,
        update_by: row.update_by,
        update_time: row.update_time
      }
    end

    def country_json(row)
      {
        id: "#{row.corp_cd}_#{row.seq}",
        seq: row.seq,
        ctry_cd: row.ctry_cd,
        aply_mon_unit_cd: row.aply_mon_unit_cd,
        timezone_cd: row.timezone_cd,
        std_time: row.std_time,
        summer_time: row.summer_time,
        sys_lang_slc: row.sys_lang_slc,
        vat_rt: row.vat_rt,
        rpt_yn_cd: row.rpt_yn_cd,
        use_yn_cd: row.use_yn_cd,
        create_by: row.create_by,
        create_time: row.create_time,
        update_by: row.update_by,
        update_time: row.update_time
      }
    end

    def save_histories!(corp_cd:, source_kind:, source_key:, tracked_changes:)
      if tracked_changes.blank?
        return
      end

      seq = StdCorporationHistory.next_hist_seq_for(corp_cd)
      now = Time.current
      actor = current_actor

      tracked_changes.each do |column_name, values|
        old_value, new_value = values
        StdCorporationHistory.create!(
          corp_cd: corp_cd,
          hist_seq: seq,
          source_kind: source_kind,
          source_key: source_key,
          changed_col_nm: column_name,
          before_value: old_value.to_s,
          after_value: new_value.to_s,
          changed_by: actor,
          changed_at: now
        )
        seq += 1
      end
    end

    def current_actor
      if Current.user&.user_id_code.present?
        Current.user.user_id_code
      elsif Current.user&.email_address.present?
        Current.user.email_address
      else
        "system"
      end
    end
end
