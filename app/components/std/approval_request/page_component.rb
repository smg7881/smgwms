class Std::ApprovalRequest::PageComponent < Std::BasePageComponent
  private
    def collection_path(**) = helpers.std_approval_requests_path(**)
    def member_path(_id, **) = helpers.std_approval_requests_path(**)

    def batch_save_url
      helpers.batch_save_std_approval_requests_path
    end

    def request_action_url
      helpers.request_action_std_approval_requests_path
    end

    def approve_action_url
      helpers.approve_action_std_approval_requests_path
    end

    def search_fields
      [
        { field: "corp_nm", type: "popup", label: "법인", popup_type: "corp", code_field: "corp_cd", placeholder: "법인 선택" },
        { field: "menu_nm", type: "popup", label: "메뉴", popup_type: "menu", code_field: "menu_cd", placeholder: "메뉴 선택" },
        {
          field: "apv_stat_cd",
          type: "select",
          label: "결재상태",
          options: common_code_options("STD_APV_STATUS", include_all: true, all_label: "전체"),
          include_blank: false
        },
        { field: "apv_reqr_nm", type: "popup", label: "요청자", popup_type: "user", code_field: "apv_reqr", placeholder: "요청자 선택" },
        { field: "asmt_apver_nm", type: "popup", label: "결재자", popup_type: "user", code_field: "asmt_apver", placeholder: "결재자 선택" }
      ]
    end

    def columns
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
        { field: "apv_req_no", headerName: "결재요청번호", minWidth: 140, editable: true },
        { field: "corp_cd", headerName: "법인코드", minWidth: 100, editable: true },
        { field: "menu_cd", headerName: "메뉴코드", minWidth: 105, editable: true },
        { field: "menu_nm", headerName: "메뉴명", minWidth: 140, editable: true },
        { field: "apv_reqr", headerName: "요청자", minWidth: 100, editable: true },
        { field: "asmt_apver", headerName: "지정결재자", minWidth: 120, editable: true },
        { field: "apver_chg", headerName: "결재자변경", minWidth: 120, editable: true },
        { field: "apv_req_conts", headerName: "결재요청내용", minWidth: 220, editable: true },
        {
          field: "apv_stat_cd",
          headerName: "결재상태",
          minWidth: 110,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("STD_APV_STATUS") }
        },
        {
          field: "apv_type_cd",
          headerName: "결재유형",
          minWidth: 110,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("STD_APV_TYPE") }
        },
        { field: "apv_req_ymd", headerName: "결재요청일자", minWidth: 165, editable: true, formatter: "datetime" },
        { field: "apv_opi", headerName: "결재의견", minWidth: 180, editable: true },
        { field: "apv_apv_ymd", headerName: "결재승인일자", minWidth: 165, editable: true, formatter: "datetime" },
        {
          field: "use_yn",
          headerName: "사용여부",
          maxWidth: 95,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("CMM_USE_YN") },
          cellRenderer: "codeUseYnCellRenderer"
        }
      ]
    end
end
