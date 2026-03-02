class System::CodeDetailsController < System::BaseController
  def index
    header = code_header
    if header.nil?
      render json: []
    else
      render json: header.details.ordered.map { |detail| detail_json(detail) }
    end
  end

  def create
    header = code_header!
    detail = header.details.new(code_detail_params.except(:code))
    detail.code = header.code

    if detail.save
      render_success(message: "상세코드가 추가되었습니다.", payload: { code_detail: detail_json(detail) })
    else
      render_failure(errors: detail.errors.full_messages)
    end
  end

  def update
    detail = find_detail
    attrs = code_detail_params.to_h
    attrs.delete("code")
    attrs.delete("detail_code")

    if detail.update(attrs)
      render_success(message: "상세코드가 수정되었습니다.", payload: { code_detail: detail_json(detail) })
    else
      render_failure(errors: detail.errors.full_messages)
    end
  end

  def destroy
    detail = find_detail
    if detail.destroy
      render_success(message: "상세코드가 삭제되었습니다.")
    else
      render_failure(errors: detail.errors.full_messages.presence || [ "상세코드 삭제에 실패했습니다." ])
    end
  end

  def batch_save
    operations = batch_save_params
    header = code_header!
    result = { inserted: 0, updated: 0, deleted: 0 }
    errors = []

    ActiveRecord::Base.transaction do
      process_detail_inserts(header, operations[:rowsToInsert], result, errors)
      process_detail_updates(header, operations[:rowsToUpdate], result, errors)
      process_detail_deletes(header, operations[:rowsToDelete], result, errors)

      raise ActiveRecord::Rollback if errors.any?
    end

    if errors.any?
      render_failure(errors: errors.uniq)
    else
      render_success(message: "상세코드 저장이 완료되었습니다.", payload: { data: result })
    end
  end

  private
    def code_header
      code = normalized_code_param(:code_id)
      @code_header ||= AdmCodeHeader.find_by(code: code)
    end

    def code_header!
      header = code_header
      if header.nil?
        raise ActiveRecord::RecordNotFound, "code not found: #{normalized_code_param(:code_id)}"
      end

      header
    end

    def find_detail
      code_header!.details.find_by!(detail_code: normalized_code_param(:detail_code))
    end

    def code_detail_params
      params.require(:code_detail).permit(:code, :detail_code, :detail_code_name, :short_name, :upper_code, :upper_detail_code, :rmk, :attr1, :attr2, :attr3, :attr4, :attr5, :sort_order, :use_yn)
    end

    def batch_save_params
      params.permit(
        rowsToDelete: [],
        rowsToInsert: [ :detail_code, :detail_code_name, :short_name, :upper_code, :upper_detail_code, :rmk, :attr1, :attr2, :attr3, :attr4, :attr5, :sort_order, :use_yn ],
        rowsToUpdate: [ :detail_code, :detail_code_name, :short_name, :upper_code, :upper_detail_code, :rmk, :attr1, :attr2, :attr3, :attr4, :attr5, :sort_order, :use_yn ]
      )
    end

    def process_detail_inserts(header, rows, result, errors)
      Array(rows).each do |attrs|
        if attrs[:detail_code].to_s.strip.blank? && attrs[:detail_code_name].to_s.strip.blank?
          next
        end

        detail = header.details.new(detail_insert_attrs(attrs))
        detail.code = header.code
        if detail.save
          result[:inserted] += 1
        else
          errors.concat(detail.errors.full_messages)
        end
      end
    end

    def process_detail_updates(header, rows, result, errors)
      Array(rows).each do |attrs|
        detail_code = normalized_code(attrs[:detail_code])
        detail = header.details.find_by(detail_code: detail_code)
        if detail.nil?
          errors << "상세코드를 찾을 수 없습니다: #{detail_code}"
          next
        end

        if detail.update(detail_update_attrs(attrs))
          result[:updated] += 1
        else
          errors.concat(detail.errors.full_messages)
        end
      end
    end

    def process_detail_deletes(header, rows, result, _errors)
      Array(rows).each do |detail_code|
        normalized = normalized_code(detail_code)
        detail = header.details.find_by(detail_code: normalized)
        next if detail.nil?

        detail.destroy
        result[:deleted] += 1
      end
    end

    def detail_insert_attrs(attrs)
      attrs.permit(:detail_code, :detail_code_name, :short_name, :upper_code, :upper_detail_code, :rmk, :attr1, :attr2, :attr3, :attr4, :attr5, :sort_order, :use_yn)
    end

    def detail_update_attrs(attrs)
      attrs.permit(:detail_code_name, :short_name, :upper_code, :upper_detail_code, :rmk, :attr1, :attr2, :attr3, :attr4, :attr5, :sort_order, :use_yn)
    end

    def detail_json(detail)
      {
        id: detail.detail_code,
        code: detail.code,
        detail_code: detail.detail_code,
        detail_code_name: detail.detail_code_name,
        short_name: detail.short_name,
        upper_code: detail.upper_code,
        upper_detail_code: detail.upper_detail_code,
        rmk: detail.rmk,
        attr1: detail.attr1,
        attr2: detail.attr2,
        attr3: detail.attr3,
        attr4: detail.attr4,
        attr5: detail.attr5,
        sort_order: detail.sort_order,
        use_yn: detail.use_yn,
        update_by: detail.update_by,
        update_time: detail.update_time,
        create_by: detail.create_by,
        create_time: detail.create_time
      }
    end
end
