# app/components/wm/pur_fee_rt_mngs/page_component.rb
class Wm::PurFeeRtMngs::PageComponent < System::BasePageComponent
  def initialize(query_params:, selected_fee_rt_no: nil)
    super(query_params: query_params)
    @selected_fee_rt_no = selected_fee_rt_no.presence
  end

  private
    attr_reader :selected_fee_rt_no

    def collection_path(**) = helpers.wm_pur_fee_rt_mngs_path(**)
    def member_path(id, **) = helpers.wm_pur_fee_rt_mng_path(id, **)

    def detail_grid_url
      return nil if selected_fee_rt_no.blank?
      helpers.wm_pur_fee_rt_mng_details_path(selected_fee_rt_no, format: :json)
    end

    def master_batch_save_url
      helpers.batch_save_wm_pur_fee_rt_mngs_path
    end

    def detail_batch_save_url_template
      "/wm/pur_fee_rt_mngs/:pur_fee_rt_mng_id/details/batch_save"
    end

    def selected_master_label
      selected_fee_rt_no.present? ? "선택 정산요율: #{selected_fee_rt_no}" : "요율을 먼저 선택하세요."
    end

    def search_fields
      [
        { field: "work_pl_cd", type: "popup", label: "작업장", popup_type: "workplace", code_field: "work_pl_cd", name_field: "work_pl_nm", placeholder: "작업장 선택" },
        { field: "ctrt_cprtco_cd", type: "popup", label: "계약협력사", popup_type: "partner", code_field: "ctrt_cprtco_cd", name_field: "ctrt_cprtco_nm", placeholder: "협력사 선택" },
        { field: "sell_buy_attr_cd", type: "popup", label: "매입항목", popup_type: "item", code_field: "sell_buy_attr_cd", name_field: "sell_buy_attr_nm", placeholder: "항목 선택" },
        {
          field: "use_yn",
          type: "select",
          label: "사용여부",
          options: common_code_options("CMM_USE_YN", include_all: true),
          include_blank: false,
          value: "Y"
        },
        { field: "aply_date", type: "date_range", label: "적용일자", start_field: "aply_date_from", end_field: "aply_date_to", value: [ Time.current.beginning_of_year.strftime("%Y-%m-%d"), Time.current.strftime("%Y-%m-%d") ] }
      ]
    end

    def master_columns
      [
        {
          field: "__row_status",
          headerName: "상태",
          width: 68, minWidth: 68, maxWidth: 68,
          editable: false, sortable: false, filter: false, resizable: false,
          cellStyle: { textAlign: "center" },
          cellRenderer: "rowStatusCellRenderer"
        },
        { field: "work_pl_cd", headerName: "작업장", minWidth: 130, editable: false },
        { field: "ctrt_cprtco_cd", headerName: "계약협력사", minWidth: 150, editable: false },
        { field: "sell_buy_attr_cd", headerName: "매입항목", minWidth: 130, editable: false },
        { field: "pur_dept_cd", headerName: "매입부서", minWidth: 130, editable: false },
        { field: "pur_item_type", headerName: "매입아이템유형", minWidth: 150, editable: true, cellEditor: "agSelectCellEditor", cellEditorParams: { values: common_code_values("69") }, cellRenderer: "createStatusBadge", cellRendererParams: { trueLabel: "Y" } },
        { field: "pur_item_cd", headerName: "매입아이템", minWidth: 130, editable: true },
        { field: "pur_unit_clas_cd", headerName: "매입단위분류", minWidth: 130, editable: true, cellEditor: "agSelectCellEditor", cellEditorParams: { values: common_code_values("20") }, cellRenderer: "createStatusBadge", cellRendererParams: { trueLabel: "Y" } },
        { field: "pur_unit_cd", headerName: "매입단위", minWidth: 130, editable: true },
        {
          field: "use_yn",
          headerName: "사용여부",
          maxWidth: 100,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("CMM_USE_YN") },
          cellRenderer: "createStatusBadge", cellRendererParams: { trueLabel: "Y" }
        },
        {
          field: "auto_yn",
          headerName: "자동여부",
          maxWidth: 100,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("CMM_USE_YN") },
          cellRenderer: "createStatusBadge", cellRendererParams: { trueLabel: "Y" }
        },
        { field: "rmk", headerName: "비고", minWidth: 200, editable: true },
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
          width: 68, minWidth: 68, maxWidth: 68,
          editable: false, sortable: false, filter: false, resizable: false,
          cellStyle: { textAlign: "center" },
          cellRenderer: "rowStatusCellRenderer"
        },
        { field: "lineno", headerName: "라인번호", minWidth: 100, editable: false },
        {
          field: "dcsn_yn",
          headerName: "확정여부",
          maxWidth: 100,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("CMM_USE_YN") },
          cellRenderer: "createStatusBadge", cellRendererParams: { trueLabel: "Y" }
        },
        { field: "aply_strt_ymd", headerName: "적용시작일자", minWidth: 150, editable: true },
        { field: "aply_end_ymd", headerName: "적용종료일자", minWidth: 150, editable: true },
        { field: "aply_uprice", headerName: "적용단가", minWidth: 120, editable: true, type: "numericColumn" },
        { field: "cur_cd", headerName: "통화코드", minWidth: 100, editable: true, cellEditor: "agSelectCellEditor", cellEditorParams: { values: common_code_values("27") }, cellRenderer: "createStatusBadge", cellRendererParams: { trueLabel: "Y" } },
        { field: "std_work_qty", headerName: "기준작업물량", minWidth: 130, editable: true, type: "numericColumn" },
        { field: "aply_strt_qty", headerName: "적용시작물량", minWidth: 130, editable: true, type: "numericColumn" },
        { field: "aply_end_qty", headerName: "적용종료물량", minWidth: 130, editable: true, type: "numericColumn" },
        { field: "rmk", headerName: "비고", minWidth: 200, editable: true },
        { field: "update_by", headerName: "수정자", minWidth: 100, editable: false },
        { field: "update_time", headerName: "수정일시", minWidth: 170, formatter: "datetime", editable: false }
      ]
    end
end
