class System::CodeDetailsController < System::BaseController
  def index
    if code_header.nil?
      render json: []
      return
    end

    render json: code_header.details.ordered.map { |detail| detail_json(detail) }
  end

  def create
    detail = code_header!.details.new(code_detail_params.except(:code))
    detail.code = code_header!.code

    if detail.save
      render json: { success: true, message: "상세코드가 추가되었습니다.", code_detail: detail_json(detail) }
    else
      render json: { success: false, errors: detail.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    detail = find_detail
    attrs = code_detail_params.to_h
    attrs.delete("code")
    attrs.delete("detail_code")

    if detail.update(attrs)
      render json: { success: true, message: "상세코드가 수정되었습니다.", code_detail: detail_json(detail) }
    else
      render json: { success: false, errors: detail.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    detail = find_detail
    detail.destroy
    render json: { success: true, message: "상세코드가 삭제되었습니다." }
  end

  def batch_save
    operations = batch_save_params
    result = { inserted: 0, updated: 0, deleted: 0 }
    errors = []

    ActiveRecord::Base.transaction do
      Array(operations[:rowsToInsert]).each do |attrs|
        next if attrs[:detail_code].to_s.strip.blank? && attrs[:detail_code_name].to_s.strip.blank?

        detail = code_header!.details.new(attrs.permit(:detail_code, :detail_code_name, :short_name, :ref_code, :sort_order, :use_yn))
        detail.code = code_header!.code
        if detail.save
          result[:inserted] += 1
        else
          errors.concat(detail.errors.full_messages)
        end
      end

      Array(operations[:rowsToUpdate]).each do |attrs|
        detail_code = attrs[:detail_code].to_s
        detail = code_header!.details.find_by(detail_code: detail_code)
        if detail.nil?
          errors << "상세코드를 찾을 수 없습니다: #{detail_code}"
          next
        end

        update_attrs = attrs.permit(:detail_code_name, :short_name, :ref_code, :sort_order, :use_yn)
        if detail.update(update_attrs)
          result[:updated] += 1
        else
          errors.concat(detail.errors.full_messages)
        end
      end

      Array(operations[:rowsToDelete]).each do |detail_code|
        detail = code_header!.details.find_by(detail_code: detail_code.to_s)
        next if detail.nil?

        detail.destroy
        result[:deleted] += 1
      end

      raise ActiveRecord::Rollback if errors.any?
    end

    if errors.any?
      render json: { success: false, errors: errors.uniq }, status: :unprocessable_entity
    else
      render json: { success: true, message: "상세코드 저장이 완료되었습니다.", data: result }
    end
  end

  private
    def code_header
      @code_header ||= AdmCodeHeader.find_by(code: params[:code_id])
    end

    def code_header!
      header = code_header
      if header.nil?
        raise ActiveRecord::RecordNotFound, "code not found: #{params[:code_id]}"
      end

      header
    end

    def find_detail
      code_header!.details.find_by!(detail_code: params[:detail_code])
    end

    def code_detail_params
      params.require(:code_detail).permit(:code, :detail_code, :detail_code_name, :short_name, :ref_code, :sort_order, :use_yn)
    end

    def batch_save_params
      params.permit(
        rowsToDelete: [],
        rowsToInsert: [ :detail_code, :detail_code_name, :short_name, :ref_code, :sort_order, :use_yn ],
        rowsToUpdate: [ :detail_code, :detail_code_name, :short_name, :ref_code, :sort_order, :use_yn ]
      )
    end

    def detail_json(detail)
      {
        id: detail.detail_code,
        code: detail.code,
        detail_code: detail.detail_code,
        detail_code_name: detail.detail_code_name,
        short_name: detail.short_name,
        ref_code: detail.ref_code,
        sort_order: detail.sort_order,
        use_yn: detail.use_yn,
        update_by: detail.update_by,
        update_time: detail.update_time,
        create_by: detail.create_by,
        create_time: detail.create_time
      }
    end
end
