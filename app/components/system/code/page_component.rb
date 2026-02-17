class System::Code::PageComponent < System::BasePageComponent
  def initialize(query_params:, selected_code:)
    super(query_params: query_params)
    @selected_code = selected_code.presence
  end

  private
    attr_reader :selected_code

    def collection_path(**) = helpers.system_code_index_path(**)
    def member_path(id, **) = helpers.system_code_path(id, **)

    def detail_collection_path(code_id, **) = helpers.system_code_details_path(code_id, **)

    def detail_grid_url
      return nil if selected_code.blank?

      detail_collection_path(selected_code, format: :json)
    end

    def master_batch_save_url
      helpers.batch_save_system_code_index_path
    end

    def detail_batch_save_url_template
      "/system/code/:code/details/batch_save"
    end

    def selected_code_label
      selected_code.present? ? "선택 코드: #{selected_code}" : "코드를 먼저 선택하세요."
    end

    def search_fields
      [
        { field: "code", type: "input", label: "코드", placeholder: "코드 검색.." },
        { field: "code_name", type: "input", label: "코드명", placeholder: "코드명 검색.." },
        { field: "detail_code", type: "input", label: "상세코드", placeholder: "상세코드 검색.." },
        { field: "detail_code_name", type: "input", label: "상세코드명", placeholder: "상세코드명 검색.." },
        {
          field: "use_yn",
          type: "select",
          label: "사용여부",
          options: [
            { label: "전체", value: "" },
            { label: "사용", value: "Y" },
            { label: "미사용", value: "N" }
          ],
          include_blank: false
        }
      ]
    end

    def master_columns
      [
        { field: "code", headerName: "코드", minWidth: 130, editable: true },
        { field: "code_name", headerName: "코드명", minWidth: 180, editable: true },
        {
          field: "use_yn",
          headerName: "사용여부",
          maxWidth: 100,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: %w[Y N] },
          cellRenderer: "codeUseYnCellRenderer"
        },
        { field: "update_by", headerName: "수정자", minWidth: 100, editable: false },
        { field: "update_time", headerName: "수정일시", minWidth: 170, formatter: "datetime", editable: false },
        { field: "create_by", headerName: "생성자", minWidth: 100, editable: false },
        { field: "create_time", headerName: "생성일시", minWidth: 170, formatter: "datetime", editable: false }
      ]
    end

    def detail_columns
      [
        { field: "detail_code", headerName: "상세코드", minWidth: 130, editable: true },
        { field: "detail_code_name", headerName: "상세코드명", minWidth: 180, editable: true },
        { field: "short_name", headerName: "단축명", minWidth: 120, editable: true },
        { field: "ref_code", headerName: "참조코드", minWidth: 120, editable: true },
        { field: "sort_order", headerName: "정렬순서", maxWidth: 110, editable: true, cellEditor: "agNumberCellEditor", type: "numericColumn" },
        {
          field: "use_yn",
          headerName: "사용여부",
          maxWidth: 100,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: %w[Y N] },
          cellRenderer: "codeUseYnCellRenderer"
        },
        { field: "update_by", headerName: "수정자", minWidth: 100, editable: false },
        { field: "update_time", headerName: "수정일시", minWidth: 170, formatter: "datetime", editable: false },
        { field: "create_by", headerName: "생성자", minWidth: 100, editable: false },
        { field: "create_time", headerName: "생성일시", minWidth: 170, formatter: "datetime", editable: false }
      ]
    end
end
