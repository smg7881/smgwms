require "csv"

module Excel
  class ImportProcessor
    Result = Struct.new(
      :total_rows,
      :success_rows,
      :failed_rows,
      :error_messages,
      keyword_init: true
    )

    def initialize(handler:, file_path:, extension:, task:)
      @handler = handler
      @file_path = file_path
      @extension = extension
      @task = task
    end

    def call
      spreadsheet = Roo::Spreadsheet.open(file_path, extension: extension.to_sym)
      header_row = normalized_row(spreadsheet.row(1))
      expected_headers = handler.headers
      if header_row != expected_headers
        raise HeaderMismatchError.new(expected_headers:, actual_headers: header_row)
      end

      total_rows = 0
      success_rows = 0
      error_rows = []

      if spreadsheet.last_row.to_i >= 2
        (2..spreadsheet.last_row).each do |row_number|
          row = spreadsheet.row(row_number)
          next if blank_row?(row)

          total_rows += 1
          row_hash = Hash[expected_headers.zip(row)]

          begin
            handler.import_row!(row_hash)
            success_rows += 1
          rescue StandardError => e
            error_rows << build_error_row(row_number, e.message, row_hash)
          end
        end
      end

      failed_rows = error_rows.size
      attach_error_report(error_rows) if failed_rows.positive?

      Result.new(
        total_rows: total_rows,
        success_rows: success_rows,
        failed_rows: failed_rows,
        error_messages: error_rows.map { |row| row[:error_message] }
      )
    end

    private
      attr_reader :handler, :file_path, :extension, :task

      def normalized_row(row)
        row.map.with_index do |value, index|
          text = value.to_s.strip
          if index == 0
            text.sub(/\A\uFEFF/, "")
          else
            text
          end
        end
      end

      def blank_row?(row)
        row.all? { |cell| cell.blank? }
      end

      def build_error_row(row_number, message, row_hash)
        {
          row_number: row_number,
          error_message: message,
          row_data: row_hash.to_json
        }
      end

      def attach_error_report(error_rows)
        io = StringIO.new(build_error_report_csv(error_rows))
        task.error_report.attach(
          io: io,
          filename: "excel-import-errors-#{task.id}-#{Time.current.to_i}.csv",
          content_type: "text/csv"
        )
      end

      def build_error_report_csv(error_rows)
        CSV.generate(headers: true) do |csv|
          csv << [ "row_number", "error_message", "row_data" ]
          error_rows.each do |error_row|
            csv << [ error_row[:row_number], error_row[:error_message], error_row[:row_data] ]
          end
        end
      end

      class HeaderMismatchError < StandardError
        attr_reader :expected_headers, :actual_headers

        def initialize(expected_headers:, actual_headers:)
          @expected_headers = expected_headers
          @actual_headers = actual_headers
          super("헤더가 템플릿과 일치하지 않습니다.")
        end
      end
  end
end
