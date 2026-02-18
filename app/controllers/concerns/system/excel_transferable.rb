module System
  module ExcelTransferable
    extend ActiveSupport::Concern

    IMPORT_SYNC_THRESHOLD = 10_000

    def excel_template
      handler = excel_handler
      payload = Excel::WorkbookBuilder.new(
        headers: handler.headers,
        rows: [],
        sheet_name: handler.sheet_name
      ).to_stream

      send_data(
        payload,
        filename: "#{handler.filename_prefix}-template-#{Date.current}.xlsx",
        type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      )
    end

    def excel_export
      handler = excel_handler
      rows = handler.export_rows(excel_export_scope)
      payload = Excel::WorkbookBuilder.new(
        headers: handler.headers,
        rows: rows,
        sheet_name: handler.sheet_name
      ).to_stream

      send_data(
        payload,
        filename: "#{handler.filename_prefix}-#{Date.current}.xlsx",
        type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      )
    end

    def excel_import
      validation = Excel::UploadValidator.new(params[:file]).call
      unless validation.valid
        redirect_to excel_redirect_path, alert: validation.errors.join(" ")
        return
      end

      task = create_import_task!(params[:file])
      inspector = build_inspector(params[:file], validation.extension)
      inspected = inspector.call

      expected_headers = excel_handler.headers
      if inspected.headers != expected_headers
        task.update!(
          status: "failed",
          completed_at: Time.current,
          error_summary: "헤더 불일치: expected=#{expected_headers.join(', ')} actual=#{inspected.headers.join(', ')}"
        )
        redirect_to excel_redirect_path, alert: "업로드 실패: 헤더가 템플릿과 일치하지 않습니다."
        return
      end

      if inspected.data_row_count > IMPORT_SYNC_THRESHOLD
        task.update!(status: "queued")
        ExcelImportJob.perform_later(task.id)
        redirect_to excel_redirect_path, notice: "대용량 파일(#{inspected.data_row_count}건) 업로드가 접수되었습니다. 백그라운드에서 처리합니다."
      else
        process_sync_import!(task, validation.extension)
      end
    end

    private
      def excel_handler
        Excel::HandlerRegistry.fetch(excel_resource_key)
      end

      def create_import_task!(file)
        task = ExcelImportTask.new(
          resource_key: excel_resource_key.to_s,
          status: "processing",
          source_filename: file.original_filename,
          source_byte_size: file.size,
          requested_by: Current.user
        )
        task.save!

        file.tempfile.rewind
        task.source_file.attach(
          io: file.tempfile,
          filename: file.original_filename,
          content_type: file.content_type
        )
        task
      end

      def build_inspector(file, extension)
        file.tempfile.rewind
        Excel::SpreadsheetInspector.new(file_path: file.tempfile.path, extension: extension)
      end

      def process_sync_import!(task, extension)
        result = nil
        task.source_file.open do |file|
          result = Excel::ImportProcessor.new(
            handler: excel_handler,
            file_path: file.path,
            extension: extension,
            task: task
          ).call
        end

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

        if task.failed_rows.positive?
          notice = "업로드 완료(일부 실패): 성공 #{task.success_rows}건, 실패 #{task.failed_rows}건"
        else
          notice = "업로드 완료: #{task.success_rows}건"
        end

        redirect_to excel_redirect_path, notice: notice
      rescue Excel::ImportProcessor::HeaderMismatchError
        task.update!(status: "failed", completed_at: Time.current, error_summary: "헤더 불일치")
        redirect_to excel_redirect_path, alert: "업로드 실패: 헤더가 템플릿과 일치하지 않습니다."
      rescue StandardError => e
        task.update!(status: "failed", completed_at: Time.current, error_summary: e.message)
        redirect_to excel_redirect_path, alert: "업로드 실패: #{e.message}"
      end

      def excel_redirect_path
        request.referer.presence || url_for(action: :index)
      end

      def excel_resource_key
        raise NotImplementedError, "하위 클래스에서 excel_resource_key를 구현해야 합니다."
      end

      def excel_export_scope
        raise NotImplementedError, "하위 클래스에서 excel_export_scope를 구현해야 합니다."
      end
  end
end
