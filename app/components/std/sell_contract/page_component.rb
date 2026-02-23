class Std::SellContract::PageComponent < Std::BasePageComponent
  def initialize(query_params:, selected_contract:)
    super(query_params: query_params)
    @selected_contract = selected_contract.presence
  end

  private
    attr_reader :selected_contract

    def collection_path(**) = helpers.std_sell_contracts_path(**)
    def member_path(id, **) = helpers.std_sell_contract_path(id, **)

    def master_batch_save_url
      helpers.batch_save_std_sell_contracts_path
    end

    def settlement_list_url_template
      "/std/sell_contracts/:id/settlements.json"
    end

    def settlement_batch_url_template
      "/std/sell_contracts/:id/batch_save_settlements"
    end

    def change_history_list_url_template
      "/std/sell_contracts/:id/change_histories.json"
    end

    def selected_contract_label
      if selected_contract.present?
        "선택 매출계약: #{selected_contract}"
      else
        "매출계약을 먼저 선택하세요."
      end
    end

    def search_fields
      [
        { field: "corp_cd", type: "input", label: "법인코드", placeholder: "법인코드 검색" },
        { field: "bzac_cd", type: "input", label: "거래처코드", placeholder: "거래처코드 검색" },
        { field: "bzac_nm", type: "input", label: "거래처명", placeholder: "거래처명 검색" },
        {
          field: "ctrt_sctn_cd",
          type: "select",
          label: "계약구분",
          options: common_code_options("STD_SELL_CTRT_SCTN", include_all: true, all_label: "전체"),
          include_blank: false
        },
        { field: "sell_ctrt_no", type: "input", label: "매출계약번호", placeholder: "매출계약번호 검색" },
        { field: "inq_prid_from", type: "date_picker", label: "조회시작일" },
        { field: "inq_prid_to", type: "date_picker", label: "조회종료일" },
        {
          field: "use_yn_cd",
          type: "select",
          label: "사용여부",
          options: common_code_options("CMM_USE_YN", include_all: true, all_label: "전체"),
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
        { field: "sell_ctrt_no", headerName: "매출계약번호", minWidth: 140, editable: false },
        { field: "sell_ctrt_nm", headerName: "매출계약명", minWidth: 180, editable: false },
        { field: "corp_cd", headerName: "법인코드", minWidth: 100, editable: false },
        { field: "bzac_cd", headerName: "거래처코드", minWidth: 120, editable: false },
        { field: "bzac_nm", headerName: "거래처명", minWidth: 170, editable: false },
        { field: "bizman_no", headerName: "사업자번호", minWidth: 130, editable: false },
        { field: "ctrt_sctn_cd", headerName: "계약구분", minWidth: 110, editable: false },
        { field: "ctrt_kind_cd", headerName: "계약종류", minWidth: 110, editable: false },
        { field: "ctrt_amt", headerName: "계약금액", minWidth: 130, editable: false, type: "numericColumn" },
        { field: "ctrt_strt_day", headerName: "계약시작일", minWidth: 120, formatter: "date", editable: false },
        { field: "ctrt_end_day", headerName: "계약종료일", minWidth: 120, formatter: "date", editable: false },
        {
          field: "use_yn_cd",
          headerName: "사용여부",
          maxWidth: 95,
          editable: false,
          cellRenderer: "codeUseYnCellRenderer"
        },
        { field: "update_by", headerName: "수정자", minWidth: 95, editable: false },
        { field: "update_time", headerName: "수정일시", minWidth: 160, formatter: "datetime", editable: false }
      ]
    end

    def settlement_columns
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
        { field: "seq_no", headerName: "순번", maxWidth: 90, editable: true, cellEditor: "agNumberCellEditor" },
        { field: "fnc_or_cd", headerName: "금융기관코드", minWidth: 130, editable: true },
        { field: "fnc_or_nm", headerName: "금융기관명", minWidth: 170, editable: true },
        { field: "acnt_no_cd", headerName: "계좌번호", minWidth: 150, editable: true },
        { field: "dpstr_nm", headerName: "예금주명", minWidth: 130, editable: true },
        {
          field: "mon_cd",
          headerName: "통화코드",
          minWidth: 100,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("STD_MON_CODE") }
        },
        { field: "aply_fnc_or_cd", headerName: "환산적용기관코드", minWidth: 150, editable: true },
        { field: "aply_fnc_or_nm", headerName: "환산적용기관명", minWidth: 170, editable: true },
        {
          field: "anno_dgrcnt",
          headerName: "고시차수",
          minWidth: 100,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("STD_ANNO_DGRCNT") }
        },
        { field: "exrt_aply_std_cd", headerName: "환산적용기준", minWidth: 130, editable: true },
        { field: "prvs_cyfd_amt", headerName: "전월이월분", minWidth: 120, editable: true, type: "numericColumn" },
        {
          field: "main_bank_yn_cd",
          headerName: "주거래은행",
          maxWidth: 100,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("CMM_USE_YN") },
          cellRenderer: "codeUseYnCellRenderer"
        },
        { field: "exca_ofcr_cd", headerName: "정산담당자코드", minWidth: 140, editable: true },
        { field: "exca_ofcr_nm", headerName: "정산담당자명", minWidth: 140, editable: true },
        {
          field: "use_yn_cd",
          headerName: "사용여부",
          maxWidth: 100,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("CMM_USE_YN") },
          cellRenderer: "codeUseYnCellRenderer"
        },
        { field: "remk", headerName: "비고", minWidth: 200, editable: true }
      ]
    end

    def change_history_columns
      [
        { field: "seq_no", headerName: "순번", maxWidth: 90, editable: false },
        { field: "chg_tbl_nm", headerName: "변경테이블", minWidth: 180, editable: false },
        { field: "chg_col_nm", headerName: "변경항목", minWidth: 180, editable: false },
        { field: "chg_bef_conts", headerName: "변경전내용", minWidth: 240, editable: false },
        { field: "chg_aft_conts", headerName: "변경후내용", minWidth: 240, editable: false },
        { field: "regr_cd", headerName: "등록자", minWidth: 110, editable: false },
        { field: "chg_date", headerName: "변경일시", minWidth: 170, formatter: "datetime", editable: false }
      ]
    end

    def detail_form_model
      @detail_form_model ||= StdSellContract.new
    end

    def detail_form_data
      {
        action: "submit->resource-form#submit submit->sell-contract-grid#preventDetailSubmit"
      }
    end

    def basic_form_fields
      [
        { field: "sell_ctrt_no", type: "input", label: "매출계약번호", readonly: true, target: "detailField" },
        { field: "sell_ctrt_nm", type: "input", label: "매출계약명", required: true, maxlength: 200, target: "detailField" },
        { field: "corp_cd", type: "input", label: "법인코드", maxlength: 20, target: "detailField" },
        { field: "bzac_cd", type: "input", label: "거래처코드", required: true, maxlength: 20, target: "detailField" },
        { field: "bizman_no", type: "input", label: "사업자번호", required: true, maxlength: 20, inputmode: "numeric", target: "detailField" },
        {
          field: "ctrt_sctn_cd",
          type: "select",
          label: "계약구분",
          required: true,
          options: common_code_options("STD_SELL_CTRT_SCTN"),
          target: "detailField"
        },
        {
          field: "ctrt_kind_cd",
          type: "select",
          label: "계약종류",
          required: true,
          options: common_code_options("STD_SELL_CTRT_KIND"),
          target: "detailField"
        },
        { field: "bef_ctrt_no", type: "input", label: "기존계약번호", maxlength: 30, target: "detailField" },
        { field: "ctrt_dept_cd", type: "input", label: "계약부서코드", maxlength: 50, target: "detailField" },
        { field: "ctrt_dept_nm", type: "input", label: "계약부서명", maxlength: 100, target: "detailField" },
        { field: "ord_recp_poss_ymd", type: "date_picker", label: "오더접수가능일", target: "detailField" },
        { field: "strt_ctrt_ymd", type: "date_picker", label: "최초계약일자", target: "detailField" },
        { field: "ctrt_strt_day", type: "date_picker", label: "계약시작일", required: true, target: "detailField" },
        { field: "ctrt_end_day", type: "date_picker", label: "계약종료일", required: true, target: "detailField" },
        { field: "ctrt_exten_ymd", type: "date_picker", label: "계약연장일자", target: "detailField" },
        { field: "ctrt_expi_noti_ymd", type: "date_picker", label: "계약만료통보일자", target: "detailField" },
        { field: "ctrt_cnctr_ymd", type: "date_picker", label: "계약해지일자", target: "detailField" },
        {
          field: "ctrt_cnctr_reason_cd",
          type: "select",
          label: "계약해지사유코드",
          options: common_code_options("STD_CTRT_CNCTR_REASON"),
          target: "detailField"
        },
        {
          field: "indgrp_cd",
          type: "select",
          label: "산업군",
          options: common_code_options("STD_INDGRP"),
          target: "detailField"
        },
        {
          field: "loan_limt_over_yn_cd",
          type: "select",
          label: "여신한도초과여부",
          options: common_code_options("CMM_USE_YN"),
          target: "detailField"
        },
        { field: "ctrt_amt", type: "input", label: "계약금액", inputmode: "decimal", target: "detailField" },
        {
          field: "vat_sctn_cd",
          type: "select",
          label: "부가세구분",
          options: common_code_options("STD_VAT_SCTN"),
          target: "detailField"
        },
        {
          field: "apv_mthd_cd",
          type: "select",
          label: "결제방법",
          options: common_code_options("STD_APV_MTHD"),
          target: "detailField"
        },
        {
          field: "apv_type_cd",
          type: "select",
          label: "결제유형",
          options: common_code_options("STD_APV_TYPE"),
          target: "detailField"
        },
        {
          field: "bilg_mthd_cd",
          type: "select",
          label: "청구방법",
          options: common_code_options("STD_BILG_MTHD"),
          target: "detailField"
        },
        {
          field: "dcsn_yn_cd",
          type: "select",
          label: "확정여부",
          options: common_code_options("CMM_USE_YN"),
          target: "detailField"
        },
        {
          field: "use_yn_cd",
          type: "select",
          label: "사용여부",
          options: common_code_options("CMM_USE_YN"),
          target: "detailField"
        }
      ]
    end

    def additional_form_fields
      [
        { field: "ctrt_amt_chg_reason", type: "textarea", label: "계약금액변경사유", rows: 2, target: "detailField" },
        { field: "main_rsbt_clause", type: "textarea", label: "주요책임조항", rows: 2, target: "detailField" },
        { field: "re_ctrt_cond", type: "textarea", label: "재계약조건", rows: 2, target: "detailField" },
        { field: "ctrt_cnctr_cond", type: "textarea", label: "계약해지조건", rows: 2, target: "detailField" },
        { field: "ctrt_cnctr_dtl_reason", type: "textarea", label: "계약해지상세사유", rows: 2, target: "detailField" },
        { field: "sell_bnfit_amt", type: "input", label: "매출이익액", inputmode: "decimal", target: "detailField" },
        { field: "sell_bnfit_rt", type: "input", label: "매출이익률(%)", inputmode: "decimal", target: "detailField" },
        { field: "contrbtn_bnfit_amt", type: "input", label: "공헌이익액", inputmode: "decimal", target: "detailField" },
        { field: "contrbtn_bnfit_rt", type: "input", label: "공헌이익률(%)", inputmode: "decimal", target: "detailField" },
        { field: "remk", type: "textarea", label: "비고", rows: 3, colspan: 2, target: "detailField" }
      ]
    end
end
