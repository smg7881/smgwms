class Om::PreOrderFileUploadsController < Om::BaseController
  def index
    @form = Om::PreOrderFileUploadForm.new
  end

  def preview
    result = upload_service.preview
    render json: result
  rescue ActionController::ParameterMissing
    render json: { success: false, message: "업로드 파일을 선택해주세요.", can_save: false }, status: :unprocessable_entity
  end

  def validate_rows
    result = upload_service.validate_rows
    render json: result
  rescue ActionController::ParameterMissing
    render json: { success: false, message: "업로드 파일을 선택해주세요.", can_save: false }, status: :unprocessable_entity
  end

  def save
    result = upload_service.save
    if result[:success]
      render json: result
    else
      render json: result, status: :unprocessable_entity
    end
  rescue ActionController::ParameterMissing
    render json: { success: false, message: "업로드 파일을 선택해주세요.", can_save: false }, status: :unprocessable_entity
  rescue ActiveRecord::RecordInvalid => e
    render json: { success: false, message: e.record.errors.full_messages.join(", "), can_save: false }, status: :unprocessable_entity
  end

  def download_template
    package = Axlsx::Package.new
    workbook = package.workbook
    workbook.add_worksheet(name: "pre_order_upload") do |sheet|
      sheet.add_row(Om::PreOrderFileUploadService::TEMPLATE_HEADERS)
      sheet.add_row(template_sample_row)
    end

    send_data(
      package.to_stream.read,
      filename: "OM_beforeORDERregister.xlsx",
      type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      disposition: "attachment"
    )
  end

  private
    def menu_code_for_permission
      "OM_PRE_ORD_FILE_UL"
    end

    def upload_service
      Om::PreOrderFileUploadService.new(file: upload_file_param, actor: current_actor)
    end

    def upload_file_param
      permitted = params.fetch(:q, {}).permit(:upload_file)
      upload_file = permitted[:upload_file]
      if upload_file.blank?
        raise ActionController::ParameterMissing, :upload_file
      end

      upload_file
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

    def template_sample_row
      [
        "BEF202602240001", "PO202602240001", "C0000001", "CO202602240001",
        "C0000001", "C0000001", "홍길동", "02-1111-2222",
        "PRE_ORDER", "N", "N", "NORMAL", "BZ000001",
        "DPT0001", "WORKPLACE", "04524", "2026-02-24", "2026-02-26",
        "ARV0001", "WORKPLACE", "06234", "1",
        "ITEM0001", "샘플품목", "100", "EA", "1200", "KG", "8.5", "M3"
      ]
    end
end
