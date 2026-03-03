class Std::BusinessCertificatesController < Std::BaseController
  def index
    respond_to do |format|
      format.html
      format.json { render json: certificates_scope.map { |row| certificate_json(row) } }
    end
  end

  def show
    row = find_certificate
    render json: certificate_json(row, include_attachments: true)
  end

  def client_defaults
    bzac_cd = params[:bzac_cd].to_s.strip.upcase
    if bzac_cd.blank?
      render json: { success: false, errors: [ "거래처코드는 필수입니다." ] }, status: :bad_request
      return
    end

    client = StdBzacMst.find_by(bzac_cd: bzac_cd)
    if client.nil?
      render json: { success: false, errors: [ "거래처를 찾을 수 없습니다: #{bzac_cd}" ] }, status: :not_found
      return
    end

    render json: { success: true, defaults: certificate_defaults_from_client(client) }
  end

  def create
    row = StdBusinessCertificate.new(certificate_params_without_attachments)
    apply_client_name_if_blank(row)

    if row.save
      attach_files(row, uploaded_attachments)
      sync_attached_file_name(row, clear_if_empty: true)
      render json: { success: true, message: "사업자등록증 정보가 등록되었습니다.", certificate: certificate_json(row, include_attachments: true) }
    else
      render json: { success: false, errors: row.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    row = find_certificate
    update_attrs = certificate_params_without_attachments.to_h
    update_attrs.delete("bzac_cd")
    row.assign_attributes(update_attrs)
    apply_client_name_if_blank(row)

    if row.save
      purge_files(row, removed_attachment_ids)
      attach_files(row, uploaded_attachments)
      sync_attached_file_name(row, clear_if_empty: attachments_changed?)
      render json: { success: true, message: "사업자등록증 정보가 수정되었습니다.", certificate: certificate_json(row, include_attachments: true) }
    else
      render json: { success: false, errors: row.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    row = find_certificate

    if row.update(use_yn_cd: "N")
      render json: { success: true, message: "사업자등록증 정보가 비활성화되었습니다." }
    else
      render json: { success: false, errors: row.errors.full_messages.presence || [ "사업자등록증 비활성화에 실패했습니다." ] }, status: :unprocessable_entity
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
          errors << "사업자등록증 정보를 찾을 수 없습니다: #{bzac_cd}"
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
          errors.concat(row.errors.full_messages.presence || [ "사업자등록증 비활성화에 실패했습니다: #{bzac_cd}" ])
        end
      end

      if errors.any?
        raise ActiveRecord::Rollback
      end
    end

    if errors.any?
      render json: { success: false, errors: errors.uniq }, status: :unprocessable_entity
    else
      render json: { success: true, message: "사업자등록증 정보가 저장되었습니다.", data: result }
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

    def certificate_params
      merged_params = {}
      if params[:std_business_certificate].present?
        merged_params.merge!(params[:std_business_certificate].to_unsafe_h)
      end
      if params[:business_certificate].present?
        merged_params.merge!(params[:business_certificate].to_unsafe_h)
      end

      ActionController::Parameters.new(merged_params).permit(
        :bzac_cd, :bzac_nm, :compreg_slip, :bizman_yn_cd, :store_nm_cd, :rptr_nm_cd,
        :corp_reg_no_cd, :bizcond_cd, :indstype_cd, :dup_bzac_yn_cd, :zip_cd, :zipaddr_cd,
        :dtl_addr_cd, :rmk, :clbiz_ymd, :attached_file_nm, :use_yn_cd,
        attachments: [],
        remove_attachment_ids: []
      )
    end

    def certificate_params_without_attachments
      certificate_params.except(:attachments, :remove_attachment_ids)
    end

    def uploaded_attachments
      Array(certificate_params[:attachments]).reject(&:blank?)
    end

    def removed_attachment_ids
      Array(certificate_params[:remove_attachment_ids]).map(&:to_i).select(&:positive?).uniq
    end

    def attachments_changed?
      if uploaded_attachments.any?
        true
      elsif removed_attachment_ids.any?
        true
      else
        false
      end
    end

    def attach_files(row, files)
      if files.any?
        row.attachments.attach(files)
      end
    end

    def purge_files(row, attachment_ids)
      if attachment_ids.empty?
        return
      end

      row.attachments.attachments.where(id: attachment_ids).find_each do |attachment|
        attachment.purge
      end
    end

    def sync_attached_file_name(row, clear_if_empty: false)
      row.refresh_attached_file_name!(clear_if_empty: clear_if_empty)
    end

    def find_certificate
      StdBusinessCertificate.find_by!(bzac_cd: params[:id].to_s.strip.upcase)
    end

    def apply_client_name_if_blank(row)
      if row.bzac_nm.blank? && row.bzac_cd.present?
        client = StdBzacMst.find_by(bzac_cd: row.bzac_cd)
        row.bzac_nm = client&.bzac_nm
      end
    end

    def certificate_defaults_from_client(client)
      {
        bzac_cd: client.bzac_cd,
        bzac_nm: client.bzac_nm,
        compreg_slip: client.bizman_no,
        bizman_yn_cd: "BUSINESS",
        store_nm_cd: client.bzac_nm,
        rptr_nm_cd: nil,
        corp_reg_no_cd: nil,
        bizcond_cd: nil,
        indstype_cd: nil,
        dup_bzac_yn_cd: "N",
        zip_cd: client.zip_cd,
        zipaddr_cd: client.addr_cd,
        dtl_addr_cd: client.addr_dtl_cd,
        use_yn_cd: client.use_yn_cd
      }
    end

    def certificate_params_from_row(row)
      row.permit(
        :bzac_cd, :bzac_nm, :compreg_slip, :bizman_yn_cd, :store_nm_cd, :rptr_nm_cd,
        :corp_reg_no_cd, :bizcond_cd, :indstype_cd, :dup_bzac_yn_cd, :zip_cd, :zipaddr_cd,
        :dtl_addr_cd, :rmk, :clbiz_ymd, :attached_file_nm, :use_yn_cd
      ).to_h.symbolize_keys
    end

    def certificate_json(row, include_attachments: false)
      json = {
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

      if include_attachments
        json[:attachments] = row.attachments.map do |file|
          {
            id: file.id,
            filename: file.filename.to_s,
            byte_size: file.byte_size,
            content_type: file.content_type,
            url: Rails.application.routes.url_helpers.rails_blob_path(file, only_path: true)
          }
        end
      end

      json
    end
end
