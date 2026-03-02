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
      render_success(message: "코드가 추가되었습니다.", payload: { code_header: header_json(header) })
    else
      render_failure(errors: header.errors.full_messages)
    end
  end

  def update
    header = find_header
    attrs = code_header_params.to_h
    attrs.delete("code")

    if header.update(attrs)
      render_success(message: "코드가 수정되었습니다.", payload: { code_header: header_json(header) })
    else
      render_failure(errors: header.errors.full_messages)
    end
  end

  def destroy
    header = find_header

    if destroy_header_with_details(header)
      render_success(message: "코드가 삭제되었습니다.")
    else
      render_failure(errors: header.errors.full_messages.presence || [ "삭제에 실패했습니다." ])
    end
  end

  def batch_save
    operations = batch_save_params
    result = { inserted: 0, updated: 0, deleted: 0 }
    errors = []

    ActiveRecord::Base.transaction do
      process_header_inserts(operations[:rowsToInsert], result, errors)
      process_header_updates(operations[:rowsToUpdate], result, errors)
      process_header_deletes(operations[:rowsToDelete], result, errors)

      raise ActiveRecord::Rollback if errors.any?
    end

    if errors.any?
      render_failure(errors: errors.uniq)
    else
      render_success(message: "코드 저장이 완료되었습니다.", payload: { data: result })
    end
  end

  private
    def find_header
      AdmCodeHeader.find_by!(code: normalized_code_param(:id))
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
        scope = scope.where(use_yn: normalized_code(search_params[:use_yn]))
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

    def process_header_inserts(rows, result, errors)
      Array(rows).each do |attrs|
        if attrs[:code].to_s.strip.blank? && attrs[:code_name].to_s.strip.blank?
          next
        end

        header = AdmCodeHeader.new(header_insert_attrs(attrs))
        if header.save
          result[:inserted] += 1
        else
          errors.concat(header.errors.full_messages)
        end
      end
    end

    def process_header_updates(rows, result, errors)
      Array(rows).each do |attrs|
        code = normalized_code(attrs[:code])
        header = AdmCodeHeader.find_by(code: code)
        if header.nil?
          errors << "코드를 찾을 수 없습니다: #{code}"
          next
        end

        if header.update(header_update_attrs(attrs))
          result[:updated] += 1
        else
          errors.concat(header.errors.full_messages)
        end
      end
    end

    def process_header_deletes(rows, result, errors)
      Array(rows).each do |code|
        normalized = normalized_code(code)
        header = AdmCodeHeader.find_by(code: normalized)
        next if header.nil?

        if destroy_header_with_details(header)
          result[:deleted] += 1
        else
          errors.concat(header.errors.full_messages.presence || [ "코드 삭제에 실패했습니다: #{normalized}" ])
        end
      end
    end

    def header_insert_attrs(attrs)
      attrs.permit(:code, :code_name, :sys_sctn_cd, :rmk, :use_yn)
    end

    def header_update_attrs(attrs)
      attrs.permit(:code_name, :sys_sctn_cd, :rmk, :use_yn)
    end

    def destroy_header_with_details(header)
      destroyed = false

      ActiveRecord::Base.transaction do
        AdmCodeDetail.where(code: header.code).delete_all
        destroyed = header.destroy
        raise ActiveRecord::Rollback unless destroyed
      end

      destroyed
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
