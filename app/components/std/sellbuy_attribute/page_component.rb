class Std::SellbuyAttribute::PageComponent < Std::BasePageComponent
  private
    def collection_path(**) = helpers.std_sellbuy_attributes_path(**)
    def member_path(id, **) = helpers.std_sellbuy_attribute_path(id, **)

    def search_fields
      [
        { field: "corp_nm", type: "popup", label: "법인", popup_type: "corp", code_field: "corp_cd", placeholder: "법인 선택" },
        {
          field: "sellbuy_sctn_cd",
          type: "select",
          label: "매출입구분",
          options: common_code_options("STD_SELLBUY_SCTN", include_all: true, all_label: "전체"),
          include_blank: false
        },
        { field: "sellbuy_attr_nm", type: "input", label: "매출입항목명", placeholder: "매출입항목명 입력" },
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
        {
          field: "sellbuy_sctn_cd",
          headerName: "매출입구분",
          minWidth: 110,
          refData: common_code_map("STD_SELLBUY_SCTN")
        },
        { field: "sellbuy_attr_cd", headerName: "매출입항목코드", minWidth: 130 },
        { field: "sellbuy_attr_nm", headerName: "매출입항목명", minWidth: 180 },
        { field: "rdtn_nm", headerName: "단축명", minWidth: 120 },
        { field: "sellbuy_attr_eng_nm", headerName: "매출입항목영문명", minWidth: 180 },
        { field: "upper_sellbuy_attr_cd", headerName: "상위매출입항목코드", minWidth: 140 },
        { field: "upper_sellbuy_attr_nm", headerName: "상위매출입항목명", minWidth: 150 },
        { field: "tran_yn_cd", headerName: "운송여부", maxWidth: 90, cellRenderer: "codeUseYnCellRenderer" },
        { field: "strg_yn_cd", headerName: "보관여부", maxWidth: 90, cellRenderer: "codeUseYnCellRenderer" },
        { field: "use_yn_cd", headerName: "사용여부", maxWidth: 90, cellRenderer: "codeUseYnCellRenderer" },
        { field: "update_by", headerName: "수정자", minWidth: 90 },
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
            { type: "edit",   eventName: "std-sellbuy-attribute-crud:edit",   dataKeys: { sellbuyAttrData: nil } },
            { type: "delete", eventName: "std-sellbuy-attribute-crud:delete", dataKeys: { id: "id||sellbuy_attr_cd", sellbuyAttrNm: "sellbuy_attr_nm||sellbuy_attr_cd" } }
          ] }
        }
      ]
    end

    def form_fields
      [
        {
          field: "corp_cd",
          type: "input",
          label: "법인",
          required: true,
          readonly: true,
          target: "fieldCorpCd",
          placeholder: "법인코드"
        },
        {
          field: "sellbuy_attr_cd",
          type: "input",
          label: "매출입항목코드",
          readonly: true,
          target: "fieldSellbuyAttrCd",
          placeholder: "자동채번"
        },
        {
          field: "sellbuy_attr_nm",
          type: "input",
          label: "매출입항목명",
          required: true,
          maxlength: 150,
          target: "fieldSellbuyAttrNm"
        },
        {
          field: "rdtn_nm",
          type: "input",
          label: "단축명",
          required: true,
          maxlength: 120,
          target: "fieldRdtnNm"
        },
        { field: "sell_yn_cd", type: "select", label: "매출여부", options: yn_options, include_blank: false, target: "fieldSellYnCd" },
        {
          field: "sellbuy_attr_eng_nm",
          type: "input",
          label: "매출입항목영문명",
          required: true,
          maxlength: 150,
          target: "fieldSellbuyAttrEngNm"
        },
        { field: "pur_yn_cd", type: "select", label: "매입여부", options: yn_options, include_blank: false, target: "fieldPurYnCd" },
        { field: "tran_yn_cd", type: "select", label: "운송여부", options: yn_options, include_blank: false, target: "fieldTranYnCd" },
        { field: "fis_air_yn_cd", type: "select", label: "국제물류항공여부", options: yn_options, include_blank: false, target: "fieldFisAirYnCd" },
        { field: "strg_yn_cd", type: "select", label: "보관여부", options: yn_options, include_blank: false, target: "fieldStrgYnCd" },
        { field: "cgwrk_yn_cd", type: "select", label: "하역여부", options: yn_options, include_blank: false, target: "fieldCgwrkYnCd" },
        { field: "fis_shpng_yn_cd", type: "select", label: "국제물류해운여부", options: yn_options, include_blank: false, target: "fieldFisShpngYnCd" },
        { field: "dc_extr_yn_cd", type: "select", label: "할인할증여부", options: yn_options, include_blank: false, target: "fieldDcExtrYnCd" },
        { field: "tax_payfor_yn_cd", type: "select", label: "세금대납여부", options: yn_options, include_blank: false, target: "fieldTaxPayforYnCd" },
        { field: "sell_dr_acct_cd", type: "input", label: "매출차변계정", maxlength: 30, target: "fieldSellDrAcctCd" },
        {
          field: "upper_sellbuy_attr_lookup",
          type: "popup",
          label: "상위매출입항목코드",
          popup_type: "sellbuy_attr",
          code_field: "upper_sellbuy_attr_cd",
          target: "fieldUpperSellbuyAttrCd",
          placeholder: "상위매출입항목 선택"
        },
        {
          field: "upper_sellbuy_attr_nm",
          type: "input",
          label: "매출입항목명",
          disabled: true,
          target: "fieldUpperSellbuyAttrNm"
        },
        { field: "sell_cr_acct_cd", type: "input", label: "매출대변계정", maxlength: 30, target: "fieldSellCrAcctCd" },
        { field: "pur_dr_acct_cd", type: "input", label: "매입차변계정", maxlength: 30, target: "fieldPurDrAcctCd" },
        { field: "pur_cr_acct_cd", type: "input", label: "매입대변계정", maxlength: 30, target: "fieldPurCrAcctCd" },
        {
          field: "sys_sctn_cd",
          type: "select",
          label: "시스템구분코드",
          options: common_code_options("STD_SYS_SCTN", include_all: true, all_label: "전체"),
          include_blank: false,
          target: "fieldSysSctnCd"
        },
        { field: "ndcsn_sell_cr_acct_cd", type: "input", label: "미확정매출대변계정", maxlength: 30, target: "fieldNdcsnSellCrAcctCd" },
        { field: "dcnct_reg_pms_yn_cd", type: "select", label: "미연계등록허용여부", options: yn_options, include_blank: false, target: "fieldDcnctRegPmsYnCd" },
        { field: "lumpsum_yn_cd", type: "select", label: "LUMPSUM 여부", options: yn_options, include_blank: false, target: "fieldLumpsumYnCd" },
        { field: "ndcsn_cost_dr_acct_cd", type: "input", label: "미확정원가차변계정", maxlength: 30, target: "fieldNdcsnCostDrAcctCd" },
        { field: "use_yn_cd", type: "select", label: "사용여부", options: yn_options, include_blank: false, target: "fieldUseYnCd" },
        { field: "rmk_cd", type: "textarea", label: "비고", rows: 3, span: "24", maxlength: 500, target: "fieldRmkCd" },
        {
          field: "create_by",
          type: "input",
          label: "등록자",
          disabled: true,
          target: "fieldCreateBy"
        },
        {
          field: "update_by",
          type: "input",
          label: "수정자",
          disabled: true,
          target: "fieldUpdateBy"
        },
        {
          field: "create_time",
          type: "input",
          label: "등록일시",
          disabled: true,
          target: "fieldCreateTime"
        },
        {
          field: "update_time",
          type: "input",
          label: "수정일시",
          disabled: true,
          target: "fieldUpdateTime"
        }
      ]
    end

    def yn_options
      common_code_options("CMM_USE_YN")
    end
end
