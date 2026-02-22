class Std::BusinessCertificate::PageComponent < Std::BasePageComponent
  private
    def collection_path(**) = helpers.std_business_certificates_path(**)
    def member_path(_id, **) = helpers.std_business_certificates_path(**)

    def batch_save_url
      helpers.batch_save_std_business_certificates_path
    end

    def search_fields
      [
        { field: "bzac_cd", type: "input", label: "거래처코드", placeholder: "코드 검색" },
        { field: "bzac_nm", type: "popup", label: "거래처", popup_type: "client", code_field: "bzac_cd", placeholder: "거래처 선택" },
        {
          field: "use_yn_cd",
          type: "select",
          label: "사용여부",
          options: common_code_options("CMM_USE_YN", include_all: true, all_label: "전체"),
          include_blank: false
        }
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
        { field: "bzac_cd", headerName: "거래처코드", minWidth: 110, editable: true },
        { field: "bzac_nm", headerName: "거래처명", minWidth: 160, editable: true },
        { field: "compreg_slip", headerName: "사업자등록번호", minWidth: 130, editable: true },
        {
          field: "bizman_yn_cd",
          headerName: "사업자구분",
          minWidth: 120,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("STD_BIZMAN_YN") }
        },
        { field: "store_nm_cd", headerName: "상호명", minWidth: 150, editable: true },
        { field: "rptr_nm_cd", headerName: "대표자명", minWidth: 130, editable: true },
        { field: "corp_reg_no_cd", headerName: "법인등록번호", minWidth: 130, editable: true },
        { field: "bizcond_cd", headerName: "업태", minWidth: 140, editable: true },
        { field: "indstype_cd", headerName: "종목", minWidth: 140, editable: true },
        {
          field: "dup_bzac_yn_cd",
          headerName: "중복거래처여부",
          maxWidth: 100,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("CMM_USE_YN") },
          cellRenderer: "codeUseYnCellRenderer"
        },
        { field: "zip_cd", headerName: "우편번호", maxWidth: 100, editable: true },
        { field: "zipaddr_cd", headerName: "주소", minWidth: 180, editable: true },
        { field: "dtl_addr_cd", headerName: "상세주소", minWidth: 180, editable: true },
        { field: "clbiz_ymd", headerName: "폐업일자", minWidth: 120, editable: true },
        { field: "attached_file_nm", headerName: "첨부파일", minWidth: 140, editable: true },
        { field: "rmk", headerName: "비고", minWidth: 200, editable: true },
        {
          field: "use_yn_cd",
          headerName: "사용여부",
          maxWidth: 90,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("CMM_USE_YN") },
          cellRenderer: "codeUseYnCellRenderer"
        },
        { field: "update_by", headerName: "수정자", minWidth: 100, editable: false },
        { field: "update_time", headerName: "수정일시", minWidth: 160, formatter: "datetime", editable: false }
      ]
    end
end
