class Std::Workplace::PageComponent < Std::BasePageComponent
  private
    def collection_path(**) = helpers.std_workplaces_path(**)
    def member_path(id, **) = helpers.std_workplace_path(id, **)

    def search_fields
      [
        { field: "corp_nm", type: "popup", label: "법인", popup_type: "corp", code_field: "corp_cd", placeholder: "법인 선택" },
        { field: "workpl", type: "input", label: "작업장", placeholder: "작업장코드/명을 입력하세요." },
        {
          field: "workpl_sctn_cd",
          type: "select",
          label: "작업장구분",
          options: common_code_options("STD_WORKPL_SCTN", include_all: true, all_label: "전체"),
          include_blank: false
        },
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
        { field: "corp_cd", headerName: "법인코드", minWidth: 110 },
        { field: "workpl_cd", headerName: "작업장코드", minWidth: 120 },
        { field: "workpl_nm", headerName: "작업장명", minWidth: 170 },
        { field: "workpl_sctn_cd", headerName: "작업장구분", minWidth: 120 },
        { field: "dept_cd", headerName: "부서코드", minWidth: 110 },
        { field: "upper_workpl_cd", headerName: "상위작업장", minWidth: 120 },
        {
          field: "wm_yn_cd",
          headerName: "창고관리",
          maxWidth: 100,
          cellRenderer: "createStatusBadge", cellRendererParams: { trueLabel: "Y" }
        },
        {
          field: "use_yn_cd",
          headerName: "사용여부",
          maxWidth: 95,
          cellRenderer: "createStatusBadge", cellRendererParams: { trueLabel: "Y" }
        },
        { field: "update_by", headerName: "수정자", minWidth: 95 },
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
            { type: "edit",   eventName: "std-workplace-crud:edit",   dataKeys: { workplaceData: nil } },
            { type: "delete", eventName: "std-workplace-crud:delete", dataKeys: { id: "id||workpl_cd", workplNm: "workpl_nm||workpl_cd" } }
          ] }
        }
      ]
    end

    def form_fields
      [
        {
          field: "corp_lookup",
          type: "popup",
          label: "법인",
          popup_type: "corp",
          code_field: "corp_cd",
          required: true,
          target: "fieldCorpCd",
          placeholder: "법인을 선택하세요."
        },
        { field: "workpl_cd", type: "input", label: "작업장코드", required: true, maxlength: 20, target: "fieldWorkplCd" },
        { field: "workpl_nm", type: "input", label: "작업장명", required: true, maxlength: 120, target: "fieldWorkplNm" },
        {
          field: "upper_workpl_lookup",
          type: "popup",
          label: "상위작업장",
          popup_type: "workplace",
          code_field: "upper_workpl_cd",
          target: "fieldUpperWorkplCd",
          placeholder: "상위작업장을 선택하세요."
        },
        {
          field: "dept_lookup",
          type: "popup",
          label: "부서",
          popup_type: "dept",
          code_field: "dept_cd",
          required: true,
          target: "fieldDeptCd",
          placeholder: "부서를 선택하세요."
        },
        {
          field: "workpl_sctn_cd",
          type: "select",
          label: "작업장구분",
          required: true,
          include_blank: true,
          options: common_code_options("STD_WORKPL_SCTN"),
          target: "fieldWorkplSctnCd"
        },
        {
          field: "capa_spec_unit_cd",
          type: "select",
          label: "용량단위",
          include_blank: true,
          options: common_code_options("STD_CAPA_UNIT"),
          target: "fieldCapaSpecUnitCd"
        },
        { field: "max_capa", type: "number", label: "최대용량", step: "0.001", target: "fieldMaxCapa" },
        { field: "adpt_capa", type: "number", label: "적정용량", step: "0.001", target: "fieldAdptCapa" },
        {
          field: "dimem_spec_unit_cd",
          type: "select",
          label: "면적단위",
          include_blank: true,
          options: common_code_options("STD_DIMEM_UNIT"),
          target: "fieldDimemSpecUnitCd"
        },
        { field: "dimem", type: "number", label: "면적", step: "0.001", target: "fieldDimem" },
        {
          field: "bzac_lookup",
          type: "popup",
          label: "거래처",
          popup_type: "client",
          code_field: "bzac_cd",
          target: "fieldBzacCd",
          placeholder: "거래처를 선택하세요."
        },
        {
          field: "ctry_lookup",
          type: "popup",
          label: "국가",
          popup_type: "country",
          code_field: "ctry_cd",
          target: "fieldCtryCd",
          placeholder: "국가를 선택하세요."
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
        { field: "addr_cd", type: "input", label: "주소", maxlength: 300, span: "24", target: "fieldAddrCd" },
        { field: "dtl_addr_cd", type: "input", label: "상세주소", maxlength: 300, span: "24", target: "fieldDtlAddrCd" },
        {
          field: "wm_yn_cd",
          type: "radio",
          label: "창고관리여부",
          value: "N",
          options: yn_radio_options
        },
        {
          field: "use_yn_cd",
          type: "radio",
          label: "사용여부",
          value: "Y",
          options: yn_radio_options
        },
        { field: "remk_cd", type: "textarea", label: "설명", rows: 4, colspan: 2, span: "24", maxlength: 1000, target: "fieldRemkCd" }
      ]
    end

    def yn_radio_options
      [
        { label: "사용", value: "Y" },
        { label: "미사용", value: "N" }
      ]
    end
end
