class Ui::AgGridComponent < ApplicationComponent
  ALLOWED_COLUMN_KEYS = %i[
    field headerName
    flex minWidth maxWidth width
    filter sortable resizable editable
    pinned hide cellStyle cellClass
    type cellEditor cellEditorParams
    formatter
    cellRenderer cellRendererParams
    lookup_popup_type lookup_popup_url lookup_code_field lookup_name_field lookup_popup_title
  ].freeze

  def initialize(columns:, url: nil, row_data: nil, pagination: true,
                 page_size: 20, height: "500px", row_selection: nil,
                 server_pagination: false, grid_id: nil, **html_options)
    @columns = columns
    @url = url
    @row_data = row_data
    @pagination = pagination
    @page_size = page_size
    @height = height
    @row_selection = row_selection
    @server_pagination = server_pagination
    @grid_id = grid_id
    @html_options = html_options
  end

  private
    attr_reader :columns, :url, :row_data, :pagination,
                :page_size, :height, :row_selection, :server_pagination,
                :grid_id, :html_options

    def safe_columns
      @safe_columns ||= sanitize_column_defs(columns)
    end

    def stimulus_data
      data = {
        controller: "ag-grid",
        "ag-grid-columns-value" => safe_columns.to_json,
        "ag-grid-pagination-value" => pagination,
        "ag-grid-page-size-value" => page_size,
        "ag-grid-height-value" => height
      }
      data["ag-grid-url-value"] = url if url.present?
      data["ag-grid-row-data-value"] = row_data.to_json if row_data.present?
      data["ag-grid-row-selection-value"] = row_selection if row_selection.present?
      data["ag-grid-server-pagination-value"] = server_pagination if server_pagination
      data["ag-grid-grid-id-value"] = grid_id if grid_id.present?
      data
    end

    def wrapper_attrs
      opts = html_options.dup
      custom_data = opts.delete(:data) || {}
      opts.merge(data: custom_data.merge(stimulus_data))
    end

    def sanitize_column_defs(cols)
      cols.map do |col|
        col = col.symbolize_keys
        sanitized = col.slice(*ALLOWED_COLUMN_KEYS)
        rejected = col.keys - ALLOWED_COLUMN_KEYS
        if rejected.any?
          Rails.logger.warn(
            "[AgGridComponent] 허용되지 않는 columnDef 키 제거: #{rejected.join(', ')} " \
            "(field: #{col[:field]})"
          )
        end
        sanitized
      end
    end
end
