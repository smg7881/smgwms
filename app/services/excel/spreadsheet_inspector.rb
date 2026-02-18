module Excel
  class SpreadsheetInspector
    Result = Struct.new(:headers, :data_row_count, keyword_init: true)

    def initialize(file_path:, extension:)
      @file_path = file_path
      @extension = extension
    end

    def call
      spreadsheet = Roo::Spreadsheet.open(file_path, extension: extension.to_sym)
      headers = normalized_row(spreadsheet.row(1))
      data_row_count = [ spreadsheet.last_row.to_i - 1, 0 ].max
      Result.new(headers: headers, data_row_count: data_row_count)
    end

    private
      attr_reader :file_path, :extension

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
