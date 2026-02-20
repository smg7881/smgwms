module Excel
  class SpreadsheetInspector
    Result = Struct.new(:headers, :data_row_count, keyword_init: true)

    def initialize(file_path:, extension:)
      @file_path = file_path
      @extension = extension
    end

    def call
      with_prepared_file_path do |prepared_file_path|
        spreadsheet = Roo::Spreadsheet.open(prepared_file_path, extension: extension.to_sym)
        headers = normalized_row(spreadsheet.row(1))
        data_row_count = [ spreadsheet.last_row.to_i - 1, 0 ].max
        Result.new(headers: headers, data_row_count: data_row_count)
      end
    end

    private
      attr_reader :file_path, :extension

      def with_prepared_file_path
        if csv_extension?
          Tempfile.create([ "excel-inspector-normalized", ".csv" ]) do |tempfile|
            tempfile.binmode
            tempfile.write(normalized_csv_content)
            tempfile.flush
            yield tempfile.path
          end
        else
          yield file_path
        end
      end

      def csv_extension?
        extension.to_s.delete(".").downcase == "csv"
      end

      def normalized_csv_content
        File.binread(file_path).gsub(/\r\n?/, "\n")
      end

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
  end
end
