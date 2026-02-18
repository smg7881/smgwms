class ExcelImportJob < ApplicationJob
  queue_as :default

  def perform(task_id)
    task = ExcelImportTask.find(task_id)
    handler = Excel::HandlerRegistry.fetch(task.resource_key)

    task.update!(status: "processing", started_at: Time.current, error_summary: nil)

    Tempfile.create([ "excel-import-task-#{task.id}", source_extension(task) ]) do |file|
      file.binmode
      file.write(task.source_file.download)
      file.flush

      result = Excel::ImportProcessor.new(
        handler: handler,
        file_path: file.path,
        extension: source_extension(task).delete("."),
        task: task
      ).call

      finalize_task!(task, result)
    end
  rescue Excel::ImportProcessor::HeaderMismatchError => e
    task.update!(
      status: "failed",
      completed_at: Time.current,
      error_summary: "헤더 불일치: expected=#{e.expected_headers.join(', ')} actual=#{e.actual_headers.join(', ')}"
    )
  rescue StandardError => e
    task.update!(status: "failed", completed_at: Time.current, error_summary: e.message)
    raise
  end

  private
    def finalize_task!(task, result)
      status = if result.failed_rows.positive?
        "completed_with_errors"
      else
        "completed"
      end

      task.update!(
        status: status,
        total_rows: result.total_rows,
        success_rows: result.success_rows,
        failed_rows: result.failed_rows,
        completed_at: Time.current,
        error_summary: result.error_messages.first(10).join(" | ")
      )
    end

    def source_extension(task)
      extension = File.extname(task.source_filename.to_s)
      if extension.present?
        extension
      else
        ".xlsx"
      end
    end
end
