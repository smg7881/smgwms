class System::NoticeController < System::BaseController
  def index
    @notices = filtered_notices_scope

    respond_to do |format|
      format.html
      format.json { render json: @notices.map { |notice| notice_json(notice) } }
    end
  end

  def show
    notice = find_notice
    render json: notice_json(notice, include_attachments: true)
  end

  def create
    notice = AdmNotice.new(notice_params_without_attachments)

    if notice.save
      attach_files(notice, uploaded_attachments)
      render json: { success: true, message: "추가되었습니다.", notice: notice_json(notice, include_attachments: true) }
    else
      render json: { success: false, errors: notice.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    notice = find_notice

    if notice.update(notice_params_without_attachments)
      purge_files(notice, removed_attachment_ids)
      attach_files(notice, uploaded_attachments)
      render json: { success: true, message: "수정되었습니다.", notice: notice_json(notice, include_attachments: true) }
    else
      render json: { success: false, errors: notice.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    notice = find_notice
    notice.destroy
    render json: { success: true, message: "삭제되었습니다." }
  end

  def bulk_destroy
    ids = Array(params[:ids]).map { |id| id.to_i }.uniq

    if ids.empty?
      render json: { success: false, errors: [ "삭제할 공지사항을 선택해주세요." ] }, status: :unprocessable_entity
      return
    end

    deleted_count = AdmNotice.where(id: ids).destroy_all.size
    render json: { success: true, message: "#{deleted_count}건 삭제되었습니다." }
  end

  private
    def filtered_notices_scope
      scope = AdmNotice.ordered

      if search_params[:category_code].present?
        scope = scope.where(category_code: search_params[:category_code].to_s.strip.upcase)
      end
      if search_params[:title].present?
        scope = scope.where("title LIKE ?", "%#{search_params[:title]}%")
      end
      if search_params[:is_published].present?
        scope = scope.where(is_published: search_params[:is_published].to_s.strip.upcase)
      end

      scope
    end

    def search_params
      params.fetch(:q, {}).permit(:category_code, :title, :is_published)
    end

    def notice_params
      params.require(:notice).permit(
        :category_code,
        :title,
        :content,
        :is_top_fixed,
        :is_published,
        :start_date,
        :end_date,
        attachments: [],
        remove_attachment_ids: []
      )
    end

    def notice_params_without_attachments
      notice_params.except(:attachments, :remove_attachment_ids)
    end

    def uploaded_attachments
      Array(notice_params[:attachments]).reject(&:blank?)
    end

    def removed_attachment_ids
      Array(notice_params[:remove_attachment_ids]).map(&:to_i).select(&:positive?).uniq
    end

    def attach_files(notice, files)
      if files.any?
        notice.attachments.attach(files)
      end
    end

    def purge_files(notice, attachment_ids)
      return if attachment_ids.empty?

      notice.attachments.attachments.where(id: attachment_ids).find_each do |attachment|
        attachment.purge
      end
    end

    def find_notice
      AdmNotice.find(params[:id])
    end

    def notice_json(notice, include_attachments: false)
      json = {
        id: notice.id,
        category_code: notice.category_code,
        title: notice.title,
        content: notice.content,
        is_top_fixed: notice.is_top_fixed,
        is_published: notice.is_published,
        start_date: notice.start_date,
        end_date: notice.end_date,
        view_count: notice.view_count,
        create_by: notice.create_by,
        create_time: notice.create_time,
        update_by: notice.update_by,
        update_time: notice.update_time
      }

      if include_attachments
        json[:attachments] = notice.attachments.map do |file|
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
