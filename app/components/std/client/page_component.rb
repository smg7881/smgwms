class Std::Client::PageComponent < Std::BasePageComponent
  def initialize(query_params:, selected_client:)
    super(query_params: query_params)
    @selected_client = selected_client.presence
  end

  private
    attr_reader :selected_client

    def collection_path(**) = helpers.std_clients_path(**)
    def member_path(id, **) = helpers.std_client_path(id, **)

    def master_batch_save_url
      helpers.batch_save_std_clients_path
    end

    def selected_client_label
      if selected_client.present?
        "선택 거래처: #{selected_client}"
      else
        "거래처를 먼저 선택하세요."
      end
    end

    def contact_list_url_template
      "/std/clients/:id/contacts.json"
    end

    def contact_batch_url_template
      "/std/clients/:id/batch_save_contacts"
    end

    def workplace_list_url_template
      "/std/clients/:id/workplaces.json"
    end

    def workplace_batch_url_template
      "/std/clients/:id/batch_save_workplaces"
    end

    def section_map_json
      rows = AdmCodeDetail.active.where(code: "STD_BZAC_SCTN").where.not(upper_detail_code: [ nil, "" ]).ordered
      map = rows.group_by(&:upper_detail_code).transform_values do |group_rows|
        group_rows.map { |r| { label: r.detail_code_name, value: r.detail_code } }
      end
      map.to_json
    end

    def search_fields
      [
        { field: "bzac_cd", type: "input", label: "거래처코드", placeholder: "거래처코드 검색.." },
        { field: "bzac_nm", type: "input", label: "거래처명", placeholder: "거래처명 검색.." },
        {
          field: "mngt_corp_nm",
          type: "popup",
          label: "관리법인",
          popup_type: "corp",
          code_field: "mngt_corp_cd",
          placeholder: "관리법인 선택"
        },
        {
          field: "bzac_sctn_grp_cd",
          type: "select",
          label: "거래처구분그룹",
          options: common_code_options("STD_BZAC_SCTN_GRP", include_all: true),
          include_blank: false
        },
        {
          field: "bzac_sctn_cd",
          type: "select",
          label: "거래처구분",
          options: common_code_options("STD_BZAC_SCTN", include_all: true),
          include_blank: false
        },
        { field: "bizman_no", type: "input", label: "사업자번호", placeholder: "숫자 10자리" },
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
        { field: "bzac_cd", headerName: "거래처코드", minWidth: 110, editable: false },
        { field: "bzac_nm", headerName: "거래처명", minWidth: 180, editable: false },
        {
          field: "bzac_sctn_grp_cd",
          headerName: "거래처구분그룹",
          minWidth: 140,
          editable: false,
          formatter: "codeLabel",
          context: { codeMap: common_code_map("STD_BZAC_SCTN_GRP") }
        },
        {
          field: "bzac_sctn_cd",
          headerName: "거래처구분",
          minWidth: 130,
          editable: false,
          formatter: "codeLabel",
          context: { codeMap: common_code_map("STD_BZAC_SCTN") }
        },
        { field: "bizman_no", headerName: "사업자번호", minWidth: 120, editable: false },
        { field: "rpt_sales_emp_cd", headerName: "대표영업사원", minWidth: 120, editable: false },
        { field: "mngt_corp_cd", headerName: "관리법인", minWidth: 120, editable: false },
        { field: "ctry_cd", headerName: "국가", maxWidth: 90, editable: false },
        {
          field: "use_yn_cd",
          headerName: "사용여부",
          maxWidth: 95,
          editable: false,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("CMM_USE_YN") },
          cellRenderer: "createStatusBadge", cellRendererParams: { trueLabel: "Y" }
        },
        { field: "update_by", headerName: "수정자", minWidth: 95, editable: false },
        { field: "update_time", headerName: "수정일시", minWidth: 160, formatter: "datetime", editable: false }
      ]
    end

    def contact_columns
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
        { field: "seq_cd", headerName: "순번", maxWidth: 90, editable: true, cellEditor: "agNumberCellEditor" },
        { field: "nm_cd", headerName: "담당자명", minWidth: 140, editable: true },
        { field: "ofic_telno_cd", headerName: "전화번호", minWidth: 120, editable: true },
        { field: "mbp_no_cd", headerName: "휴대전화", minWidth: 120, editable: true },
        { field: "email_cd", headerName: "이메일", minWidth: 190, editable: true },
        {
          field: "rpt_yn_cd",
          headerName: "대표여부",
          maxWidth: 100,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("CMM_USE_YN") },
          cellRenderer: "createStatusBadge", cellRendererParams: { trueLabel: "Y" }
        },
        {
          field: "use_yn_cd",
          headerName: "사용여부",
          maxWidth: 100,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("CMM_USE_YN") },
          cellRenderer: "createStatusBadge", cellRendererParams: { trueLabel: "Y" }
        }
      ]
    end

    def workplace_columns
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
        { field: "seq_cd", headerName: "순번", maxWidth: 90, editable: true, cellEditor: "agNumberCellEditor" },
        { field: "workpl_nm_cd", headerName: "작업장명", minWidth: 180, editable: true },
        { field: "workpl_sctn_cd", headerName: "작업장구분", minWidth: 140, editable: true },
        { field: "ofcr_cd", headerName: "담당자코드", minWidth: 120, editable: true },
        {
          field: "use_yn_cd",
          headerName: "사용여부",
          maxWidth: 100,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("CMM_USE_YN") },
          cellRenderer: "createStatusBadge", cellRendererParams: { trueLabel: "Y" }
        }
      ]
    end

    def detail_form_model
      @detail_form_model ||= StdBzacMst.new
    end

    def detail_form_data
      {
        action: "submit->resource-form#submit submit->client-grid#preventDetailSubmit"
      }
    end

    def basic_form_fields
      [
        { field: "bzac_cd", type: "input", label: "거래처코드", readonly: true, target: "detailField" },
        { field: "bzac_nm", type: "input", label: "거래처명", required: true, maxlength: 100, target: "detailField" },
        {
          field: "mngt_corp_nm",
          type: "popup",
          label: "관리법인",
          required: true,
          popup_type: "corp",
          code_field: "mngt_corp_cd",
          placeholder: "관리법인 선택",
          target: "detailField"
        },
        { field: "bizman_no", type: "input", label: "사업자번호", required: true, maxlength: 10, inputmode: "numeric", target: "detailField" },
        {
          field: "bzac_sctn_grp_cd",
          type: "select",
          label: "거래처구분그룹",
          required: true,
          options: common_code_options("STD_BZAC_SCTN_GRP"),
          target: "detailField detailGroupField"
        },
        {
          field: "bzac_sctn_cd",
          type: "select",
          label: "거래처구분",
          required: true,
          options: common_code_options("STD_BZAC_SCTN"),
          target: "detailField detailSectionField"
        },
        {
          field: "bzac_kind_cd",
          type: "select",
          label: "거래처종류",
          required: true,
          options: common_code_options("STD_BZAC_KIND"),
          target: "detailField"
        },
        {
          field: "ctry_cd",
          type: "select",
          label: "국가",
          required: true,
          options: common_code_options("STD_NATION"),
          target: "detailField"
        },
        {
          field: "upper_bzac_nm",
          type: "popup",
          label: "상위거래처",
          popup_type: "client",
          code_field: "upper_bzac_cd",
          placeholder: "상위거래처 선택",
          target: "detailField"
        },
        { field: "rpt_bzac_cd", type: "input", label: "대표거래처", maxlength: 20, target: "detailField" },
        { field: "rpt_sales_emp_cd", type: "input", label: "대표영업사원", required: true, maxlength: 20, target: "detailField" },
        { field: "rpt_sales_emp_nm", type: "input", label: "대표영업사원명", maxlength: 100, target: "detailField" },
        {
          field: "zip_nm",
          type: "popup",
          label: "우편번호",
          popup_type: "zipcode",
          code_field: "zip_cd",
          placeholder: "우편번호 선택",
          target: "detailField"
        },
        { field: "addr_cd", type: "input", label: "주소", maxlength: 255, target: "detailField" },
        { field: "addr_dtl_cd", type: "input", label: "상세주소", maxlength: 255, target: "detailField" },
        { field: "aply_strt_day_cd", type: "date_picker", label: "적용시작일", required: true, target: "detailField" },
        { field: "aply_end_day_cd", type: "date_picker", label: "적용종료일", target: "detailField" },
        {
          field: "use_yn_cd",
          type: "select",
          label: "사용여부",
          required: true,
          options: common_code_options("CMM_USE_YN"),
          target: "detailField"
        }
      ]
    end

    def use_yn_options_for_form
      common_code_options("CMM_USE_YN")
    end

    def additional_form_fields
      [
        { field: "if_yn_cd", type: "select", label: "IF 여부", options: use_yn_options_for_form, target: "detailField" },
        { field: "branch_yn_cd", type: "select", label: "지점여부", options: use_yn_options_for_form, target: "detailField" },
        { field: "sell_bzac_yn_cd", type: "select", label: "매출여부", options: use_yn_options_for_form, target: "detailField" },
        { field: "pur_bzac_yn_cd", type: "select", label: "매입여부", options: use_yn_options_for_form, target: "detailField" },
        { field: "tpl_logis_yn_cd", type: "select", label: "삼자물류여부", options: use_yn_options_for_form, target: "detailField" },
        { field: "elec_taxbill_yn_cd", type: "select", label: "전자세금계산서", options: use_yn_options_for_form, target: "detailField" },
        { field: "bilg_bzac_cd", type: "input", label: "청구거래처", maxlength: 20, target: "detailField" },
        {
          field: "fnc_or_nm",
          type: "popup",
          label: "금융기관",
          popup_type: "financial_institution",
          code_field: "fnc_or_cd",
          placeholder: "금융기관 선택",
          target: "detailField"
        },
        { field: "acnt_no_cd", type: "input", label: "계좌번호", maxlength: 50, target: "detailField" },
        { field: "remk", type: "textarea", label: "비고", rows: 3, colspan: 3, maxlength: 500, target: "detailField" }
      ]
    end
end
