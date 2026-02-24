class System::CodeController < System::BaseController
  def index
    @selected_code = params[:selected_code].presence

    respond_to do |format|
      format.html
      format.json { render json: headers_scope.map { |header| header_json(header) } }
    end
  end

  def create
    header = AdmCodeHeader.new(code_header_params)
    if header.save
      render json: { success: true, message: "코드가 추가되었습니다.", code_header: header_json(header) }
    else
      render json: { success: false, errors: header.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    header = find_header
    attrs = code_header_params.to_h
    attrs.delete("code")

    if header.update(attrs)
      render json: { success: true, message: "코드가 수정되었습니다.", code_header: header_json(header) }
    else
      render json: { success: false, errors: header.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    header = find_header

    if header.destroy
      render json: { success: true, message: "코드가 삭제되었습니다." }
    else
      render json: { success: false, errors: header.errors.full_messages.presence || [ "삭제에 실패했습니다." ] }, status: :unprocessable_entity
    end
  end

  def batch_save
    operations = batch_save_params
    result = { inserted: 0, updated: 0, deleted: 0 }
    errors = []

    ActiveRecord::Base.transaction do
      Array(operations[:rowsToInsert]).each do |attrs|
        next if attrs[:code].to_s.strip.blank? && attrs[:code_name].to_s.strip.blank?

        header = AdmCodeHeader.new(attrs.permit(:code, :code_name, :sys_sctn_cd, :rmk, :use_yn))
        if header.save
          result[:inserted] += 1
        else
          errors.concat(header.errors.full_messages)
        end
      end

      Array(operations[:rowsToUpdate]).each do |attrs|
        code = attrs[:code].to_s
        header = AdmCodeHeader.find_by(code: code)
        if header.nil?
          errors << "코드를 찾을 수 없습니다: #{code}"
          next
        end

        update_attrs = attrs.permit(:code_name, :sys_sctn_cd, :rmk, :use_yn)
        if header.update(update_attrs)
          result[:updated] += 1
        else
          errors.concat(header.errors.full_messages)
        end
      end

      Array(operations[:rowsToDelete]).each do |code|
        header = AdmCodeHeader.find_by(code: code.to_s)
        next if header.nil?

        AdmCodeDetail.where(code: header.code).delete_all

        if header.destroy
          result[:deleted] += 1
        else
          errors.concat(header.errors.full_messages.presence || [ "코드 삭제에 실패했습니다: #{code}" ])
        end
      end

      raise ActiveRecord::Rollback if errors.any?
    end

    if errors.any?
      render json: { success: false, errors: errors.uniq }, status: :unprocessable_entity
    else
      render json: { success: true, message: "코드 저장이 완료되었습니다.", data: result }
    end
  end

  private
    def find_header
      AdmCodeHeader.find_by!(code: params[:id])
    end

    def search_params
      params.fetch(:q, {}).permit(:code, :code_name, :detail_code, :detail_code_name, :use_yn)
    end

    def headers_scope
      scope = AdmCodeHeader.ordered
      if search_params[:code].present?
        scope = scope.where("code LIKE ?", "%#{search_params[:code]}%")
      end
      if search_params[:code_name].present?
        scope = scope.where("code_name LIKE ?", "%#{search_params[:code_name]}%")
      end
      if search_params[:use_yn].present?
        scope = scope.where(use_yn: search_params[:use_yn])
      end

      if search_params[:detail_code].present? || search_params[:detail_code_name].present?
        scope = scope.joins(:details)
        if search_params[:detail_code].present?
          scope = scope.where("adm_code_details.detail_code LIKE ?", "%#{search_params[:detail_code]}%")
        end
        if search_params[:detail_code_name].present?
          scope = scope.where("adm_code_details.detail_code_name LIKE ?", "%#{search_params[:detail_code_name]}%")
        end
        scope = scope.distinct
      end

      scope
    end

    def code_header_params
      params.require(:code_header).permit(:code, :code_name, :sys_sctn_cd, :rmk, :use_yn)
    end

    def batch_save_params
      params.permit(
        rowsToDelete: [],
        rowsToInsert: [ :code, :code_name, :sys_sctn_cd, :rmk, :use_yn ],
        rowsToUpdate: [ :code, :code_name, :sys_sctn_cd, :rmk, :use_yn ]
      )
    end

    def header_json(header)
      {
        id: header.code,
        code: header.code,
        code_name: header.code_name,
        sys_sctn_cd: header.sys_sctn_cd,
        rmk: header.rmk,
        use_yn: header.use_yn,
        update_by: header.update_by,
        update_time: header.update_time,
        create_by: header.create_by,
        create_time: header.create_time
      }
    end
end
