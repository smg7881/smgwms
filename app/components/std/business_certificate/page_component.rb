class Std::BusinessCertificate::PageComponent < Std::BasePageComponent
  private
    def collection_path(**) = helpers.std_business_certificates_path(**)
    def member_path(id, **) = helpers.std_business_certificate_path(id, **)
    def client_defaults_url = helpers.client_defaults_std_business_certificates_path

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
        { field: "bzac_cd", headerName: "거래처코드", minWidth: 120 },
        { field: "bzac_nm", headerName: "거래처명", minWidth: 160 },
        { field: "compreg_slip", headerName: "사업자등록번호", minWidth: 140 },
        {
          field: "bizman_yn_cd",
          headerName: "사업자구분",
          minWidth: 120
        },
        { field: "store_nm_cd", headerName: "상호명", minWidth: 160 },
        { field: "rptr_nm_cd", headerName: "대표자명", minWidth: 140 },
        { field: "attached_file_nm", headerName: "첨부파일", minWidth: 180 },
        {
          field: "use_yn_cd",
          headerName: "사용여부",
          maxWidth: 90,
          cellRenderer: "createStatusBadge", cellRendererParams: { trueLabel: "Y" }
        },
        { field: "update_by", headerName: "수정자", minWidth: 100 },
        { field: "update_time", headerName: "수정일시", minWidth: 160, formatter: "datetime" },
        {
          field: "actions",
          headerName: "작업항목",
          minWidth: 110,
          maxWidth: 110,
          filter: false,
          sortable: false,
          cellClass: "ag-cell-actions",
          cellRenderer: "actionCellRenderer",
          cellRendererParams: { actions: [
            { type: "edit", eventName: "std-business-certificate-crud:edit", dataKeys: { id: "id||bzac_cd" } },
            { type: "delete", eventName: "std-business-certificate-crud:delete", dataKeys: { id: "id||bzac_cd", bzacNm: "bzac_nm||bzac_cd" } }
          ] }
        }
      ]
    end

    def form_fields
      [
        {
          field: "bzac_lookup",
          type: "popup",
          label: "거래처",
          popup_type: "client",
          code_field: "bzac_cd",
          required: true,
          target: "fieldBzacCd",
          placeholder: "거래처를 선택하세요."
        },
        {
          field: "compreg_slip",
          type: "input",
          label: "사업자등록번호",
          required: true,
          maxlength: 30,
          target: "fieldCompregSlip",
          help: "숫자 10자리 또는 하이픈(-) 포함 형식으로 입력하세요."
        },
        {
          field: "bizman_yn_cd",
          type: "select",
          label: "사업자구분",
          required: true,
          include_blank: true,
          options: common_code_options("STD_BIZMAN_YN"),
          target: "fieldBizmanYnCd"
        },
        { field: "store_nm_cd", type: "input", label: "상호명", required: true, maxlength: 200, target: "fieldStoreNmCd" },
        { field: "rptr_nm_cd", type: "input", label: "대표자명", required: true, maxlength: 120, target: "fieldRptrNmCd" },
        { field: "corp_reg_no_cd", type: "input", label: "법인등록번호", maxlength: 50, target: "fieldCorpRegNoCd" },
        { field: "bizcond_cd", type: "input", label: "업태", maxlength: 120, target: "fieldBizcondCd" },
        { field: "indstype_cd", type: "input", label: "업종", maxlength: 120, target: "fieldIndstypeCd" },
        {
          field: "dup_bzac_yn_cd",
          type: "radio",
          label: "중복거래처여부",
          value: "N",
          options: common_code_radio_options("CMM_USE_YN"),
          target: "fieldDupBzacYnCd"
        },
        {
          field: "zip_lookup",
          type: "popup",
          label: "우편번호",
          popup_type: "zipcode",
          code_field: "zip_cd",
          target: "fieldZipCd",
          placeholder: "우편번호를 선택하세요."
        },
        { field: "zipaddr_cd", type: "input", label: "주소", span: "24", maxlength: 300, target: "fieldZipaddrCd" },
        { field: "dtl_addr_cd", type: "input", label: "상세주소", span: "24", maxlength: 300, target: "fieldDtlAddrCd" },
        { field: "clbiz_ymd", type: "date_picker", label: "폐업일자", target: "fieldClbizYmd" },
        {
          field: "use_yn_cd",
          type: "radio",
          label: "사용여부",
          value: "Y",
          options: common_code_radio_options("CMM_USE_YN"),
          target: "fieldUseYnCd"
        },
        { field: "rmk", type: "textarea", label: "비고", rows: 4, colspan: 2, span: "24", maxlength: 1000, target: "fieldRmk" },
        {
          field: "attachments",
          type: "multi_file",
          span: "24",
          label: "첨부파일",
          multiple: true,
          max_files: 5,
          max_size_mb: 30,
          target: "fieldAttachments",
          existing_target: "existingFiles",
          selected_target: "selectedFiles"
        },
        { field: "create_by", type: "input", label: "등록자", readonly: true, target: "fieldCreateBy" },
        { field: "create_time", type: "input", label: "등록일시", readonly: true, target: "fieldCreateTime" },
        { field: "update_by", type: "input", label: "수정자", readonly: true, target: "fieldUpdateBy" },
        { field: "update_time", type: "input", label: "수정일시", readonly: true, target: "fieldUpdateTime" }
      ]
    end

end
