class Std::WorkRoutingStep::PageComponent < Std::BasePageComponent
  def initialize(query_params:, selected_work_routing:)
    super(query_params: query_params)
    @selected_work_routing = selected_work_routing.presence
  end

  private
    attr_reader :selected_work_routing

    def collection_path(**) = helpers.std_work_routing_steps_path(**)
    def member_path(_id, **) = helpers.std_work_routing_steps_path(**)

    def detail_collection_path(work_routing_id, **) = helpers.std_work_routing_step_details_path(work_routing_id, **)

    def detail_grid_url
      return nil if selected_work_routing.blank?

      detail_collection_path(selected_work_routing, format: :json)
    end

    def master_batch_save_url
      helpers.batch_save_std_work_routing_steps_path
    end

    def detail_batch_save_url_template
      "/std/work_routing_steps/:id/details/batch_save"
    end

    def selected_work_routing_label
      if selected_work_routing.present?
        "선택 작업경로: #{selected_work_routing}"
      else
        "작업경로를 먼저 선택하세요."
      end
    end

    def work_type1_map_json
      build_upper_code_map_json("10")
    end

    def work_type2_map_json
      build_upper_code_map_json("11")
    end

    def work_step_level2_map_json
      build_upper_code_map_json("08")
    end

    def search_fields
      [
        { field: "wrk_rt_cd", type: "input", label: "작업경로코드", placeholder: "코드 검색.." },
        { field: "wrk_rt_nm", type: "input", label: "작업경로명", placeholder: "작업경로명 검색.." },
        {
          field: "use_yn_cd",
          type: "select",
          label: "사용여부",
          options: common_code_options("CMM_USE_YN", include_all: true),
          include_blank: false
        }
      ]
    end

    def master_columns
      [
        {
          field: "__row_status",
          headerName: "상태",
          width: 68,
          minWidth: 68,
          maxWidth: 68,
          editable: false,
          sortable: false,
          filter: false,
          resizable: false,
          cellStyle: { textAlign: "center" },
          cellRenderer: "rowStatusCellRenderer"
        },
        { field: "wrk_rt_cd", headerName: "작업경로코드", minWidth: 130, editable: true },
        { field: "wrk_rt_nm", headerName: "작업경로명", minWidth: 190, editable: true },
        {
          field: "hwajong_cd",
          headerName: "화종",
          minWidth: 130,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("09") },
          formatter: "codeLabel",
          context: { codeMap: common_code_map("09") }
        },
        {
          field: "wrk_type1_cd",
          headerName: "작업유형1",
          minWidth: 140,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("10") },
          formatter: "codeLabel",
          context: { codeMap: common_code_map("10") }
        },
        {
          field: "wrk_type2_cd",
          headerName: "작업유형2",
          minWidth: 140,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("11") },
          formatter: "codeLabel",
          context: { codeMap: common_code_map("11") }
        },
        {
          field: "use_yn_cd",
          headerName: "사용여부",
          maxWidth: 95,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("CMM_USE_YN") },
          cellRenderer: "createStatusBadge", cellRendererParams: { trueLabel: "Y" }
        },
        { field: "rmk_cd", headerName: "비고", minWidth: 200, editable: true },
        { field: "update_by", headerName: "수정자", minWidth: 100, editable: false },
        { field: "update_time", headerName: "수정일시", minWidth: 170, formatter: "datetime", editable: false },
        { field: "create_by", headerName: "생성자", minWidth: 100, editable: false },
        { field: "create_time", headerName: "생성일시", minWidth: 170, formatter: "datetime", editable: false }
      ]
    end

    def detail_columns
      [
        {
          field: "__row_status",
          headerName: "상태",
          width: 68,
          minWidth: 68,
          maxWidth: 68,
          editable: false,
          sortable: false,
          filter: false,
          resizable: false,
          cellStyle: { textAlign: "center" },
          cellRenderer: "rowStatusCellRenderer"
        },
        { field: "seq_no", headerName: "순서", maxWidth: 100, editable: true, cellEditor: "agNumberCellEditor", type: "numericColumn" },
        {
          field: "work_step_cd",
          headerName: "작업단계코드",
          minWidth: 140,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("181") },
          formatter: "codeLabel",
          context: { codeMap: common_code_map("181") }
        },
        {
          field: "work_step_level1_cd",
          headerName: "작업단계Level1",
          minWidth: 160,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("07") },
          formatter: "codeLabel",
          context: { codeMap: common_code_map("07") }
        },
        {
          field: "work_step_level2_cd",
          headerName: "작업단계Level2",
          minWidth: 160,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("08") },
          formatter: "codeLabel",
          context: { codeMap: common_code_map("08") }
        },
        {
          field: "use_yn_cd",
          headerName: "사용여부",
          maxWidth: 95,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("CMM_USE_YN") },
          cellRenderer: "createStatusBadge", cellRendererParams: { trueLabel: "Y" }
        },
        { field: "rmk_cd", headerName: "비고", minWidth: 180, editable: true },
        { field: "update_by", headerName: "수정자", minWidth: 100, editable: false },
        { field: "update_time", headerName: "수정일시", minWidth: 170, formatter: "datetime", editable: false },
        { field: "create_by", headerName: "생성자", minWidth: 100, editable: false },
        { field: "create_time", headerName: "생성일시", minWidth: 170, formatter: "datetime", editable: false }
      ]
    end

    def build_upper_code_map_json(code)
      rows = AdmCodeDetail.active.where(code: code).where.not(upper_detail_code: [ nil, "" ]).ordered
      map = rows.group_by(&:upper_detail_code).transform_values do |group_rows|
        group_rows.map(&:detail_code)
      end
      map.to_json
    end
end
