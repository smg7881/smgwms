module Excel
  class WorkbookBuilder
    def initialize(headers:, rows:, sheet_name:)
      @headers = headers
      @rows = rows
      @sheet_name = sheet_name
    end

    def to_stream
      package = Axlsx::Package.new
      package.workbook.add_worksheet(name: sheet_name) do |sheet|
        sheet.add_row(headers)
        rows.each do |row|
          sheet.add_row(row)
        end
      end
      package.to_stream.read
    end

    private
      attr_reader :headers, :rows, :sheet_name
  end
end
