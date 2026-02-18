class System::ExcelImportTasksController < System::BaseController
  def index
    @tasks = filtered_scope.limit(200)
  end

  def error_report
    task = ExcelImportTask.find(params[:id])
    unless task.error_report.attached?
      redirect_to system_excel_import_tasks_path, alert: "오류 리포트 파일이 없습니다."
      return
    end

    send_data(
      task.error_report.download,
      filename: task.error_report.filename.to_s,
      type: "text/csv"
    )
  end

  private
    def filtered_scope
      scope = ExcelImportTask.recent_first.includes(:requested_by)
      if filter_params[:resource_key].present?
        scope = scope.where(resource_key: filter_params[:resource_key])
      end
      if filter_params[:status].present?
        scope = scope.where(status: filter_params[:status])
      end
      scope
    end

    def filter_params
      params.fetch(:q, {}).permit(:resource_key, :status)
    end
end
