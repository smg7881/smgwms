class Std::BusinessCertificatesController < Std::BaseController
  def index
    respond_to do |format|
      format.html
      format.json { render json: certificates_scope.map { |row| certificate_json(row) } }
    end
  end

  def batch_save
    operations = batch_save_params
    result = { inserted: 0, updated: 0, deleted: 0 }
    errors = []

    ActiveRecord::Base.transaction do
      Array(operations[:rowsToInsert]).each do |attrs|
        if attrs[:compreg_slip].to_s.strip.blank?
          next
        end

        row = StdBusinessCertificate.new(certificate_params_from_row(attrs))
        if row.bzac_nm.blank? && row.bzac_cd.present?
          client = StdBzacMst.find_by(bzac_cd: row.bzac_cd)
          row.bzac_nm = client&.bzac_nm
        end

        if row.save
          result[:inserted] += 1
        else
          errors.concat(row.errors.full_messages)
        end
      end

      Array(operations[:rowsToUpdate]).each do |attrs|
        bzac_cd = attrs[:bzac_cd].to_s.strip.upcase
        row = StdBusinessCertificate.find_by(bzac_cd: bzac_cd)
        if row.nil?
          errors << "Business certificate not found: #{bzac_cd}"
          next
        end

        update_attrs = certificate_params_from_row(attrs)
        update_attrs.delete(:bzac_cd)
        if row.update(update_attrs)
          result[:updated] += 1
        else
          errors.concat(row.errors.full_messages)
        end
      end

      Array(operations[:rowsToDelete]).each do |bzac_cd|
        row = StdBusinessCertificate.find_by(bzac_cd: bzac_cd.to_s.strip.upcase)
        if row.nil?
          next
        end

        if row.update(use_yn_cd: "N")
          result[:deleted] += 1
        else
          errors.concat(row.errors.full_messages.presence || [ "Business certificate deactivation failed: #{bzac_cd}" ])
        end
      end

      if errors.any?
        raise ActiveRecord::Rollback
      end
    end

    if errors.any?
      render json: { success: false, errors: errors.uniq }, status: :unprocessable_entity
    else
      render json: { success: true, message: "Business certificate data saved.", data: result }
    end
  end

  private
    def menu_code_for_permission
      "STD_BIZ_CERT"
    end

    def search_params
      params.fetch(:q, {}).permit(:bzac_cd, :bzac_nm, :compreg_slip, :use_yn_cd)
    end

    def certificates_scope
      scope = StdBusinessCertificate.ordered
      if search_bzac_cd.present?
        scope = scope.where("bzac_cd LIKE ?", "%#{search_bzac_cd}%")
      end
      if search_bzac_nm.present?
        scope = scope.where("bzac_nm LIKE ?", "%#{search_bzac_nm}%")
      end
      if search_compreg_slip.present?
        scope = scope.where("compreg_slip LIKE ?", "%#{search_compreg_slip}%")
      end
      if search_use_yn_cd.present?
        scope = scope.where(use_yn_cd: search_use_yn_cd)
      end
      scope
    end

    def search_bzac_cd
      search_params[:bzac_cd].to_s.strip.upcase.presence
    end

    def search_bzac_nm
      search_params[:bzac_nm].to_s.strip.presence
    end

    def search_compreg_slip
      search_params[:compreg_slip].to_s.gsub(/[^0-9]/, "").presence
    end

    def search_use_yn_cd
      search_params[:use_yn_cd].to_s.strip.upcase.presence
    end

    def batch_save_params
      params.permit(
        rowsToDelete: [],
        rowsToInsert: [
          :bzac_cd, :bzac_nm, :compreg_slip, :bizman_yn_cd, :store_nm_cd, :rptr_nm_cd,
          :corp_reg_no_cd, :bizcond_cd, :indstype_cd, :dup_bzac_yn_cd, :zip_cd, :zipaddr_cd,
          :dtl_addr_cd, :rmk, :clbiz_ymd, :attached_file_nm, :use_yn_cd
        ],
        rowsToUpdate: [
          :bzac_cd, :bzac_nm, :compreg_slip, :bizman_yn_cd, :store_nm_cd, :rptr_nm_cd,
          :corp_reg_no_cd, :bizcond_cd, :indstype_cd, :dup_bzac_yn_cd, :zip_cd, :zipaddr_cd,
          :dtl_addr_cd, :rmk, :clbiz_ymd, :attached_file_nm, :use_yn_cd
        ]
      )
    end

    def certificate_params_from_row(row)
      row.permit(
        :bzac_cd, :bzac_nm, :compreg_slip, :bizman_yn_cd, :store_nm_cd, :rptr_nm_cd,
        :corp_reg_no_cd, :bizcond_cd, :indstype_cd, :dup_bzac_yn_cd, :zip_cd, :zipaddr_cd,
        :dtl_addr_cd, :rmk, :clbiz_ymd, :attached_file_nm, :use_yn_cd
      ).to_h.symbolize_keys
    end

    def certificate_json(row)
      {
        id: row.bzac_cd,
        bzac_cd: row.bzac_cd,
        bzac_nm: row.bzac_nm,
        compreg_slip: row.compreg_slip,
        bizman_yn_cd: row.bizman_yn_cd,
        store_nm_cd: row.store_nm_cd,
        rptr_nm_cd: row.rptr_nm_cd,
        corp_reg_no_cd: row.corp_reg_no_cd,
        bizcond_cd: row.bizcond_cd,
        indstype_cd: row.indstype_cd,
        dup_bzac_yn_cd: row.dup_bzac_yn_cd,
        zip_cd: row.zip_cd,
        zipaddr_cd: row.zipaddr_cd,
        dtl_addr_cd: row.dtl_addr_cd,
        rmk: row.rmk,
        clbiz_ymd: row.clbiz_ymd,
        attached_file_nm: row.attached_file_nm,
        use_yn_cd: row.use_yn_cd,
        create_by: row.create_by,
        create_time: row.create_time,
        update_by: row.update_by,
        update_time: row.update_time
      }
    end
end
