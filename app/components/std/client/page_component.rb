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

    def section_list_url
      helpers.sections_std_clients_path(format: :json)
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
      map = {}
      section_group_code_values.each do |group_code|
        map[group_code] = section_option_items(group_code)
      end
      map.to_json
    end

    def search_fields
      [
        { field: "bzac_cd", type: "input", label: "거래처코드", placeholder: "거래처코드 검색.." },
        { field: "bzac_nm", type: "input", label: "거래처명", placeholder: "거래처명 검색.." },
        { field: "mngt_corp_cd", type: "input", label: "관리법인", placeholder: "관리법인 코드.." },
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
          options: section_options,
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
        { field: "bzac_nm", headerName: "거래처명", minWidth: 180, editable: true },
        {
          field: "bzac_sctn_grp_cd",
          headerName: "거래처구분그룹",
          minWidth: 140,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: section_group_code_values }
        },
        {
          field: "bzac_sctn_cd",
          headerName: "거래처구분",
          minWidth: 130,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: section_code_values }
        },
        { field: "bizman_no", headerName: "사업자번호", minWidth: 120, editable: true },
        { field: "rpt_sales_emp_cd", headerName: "대표영업사원", minWidth: 120, editable: true },
        { field: "mngt_corp_cd", headerName: "관리법인", minWidth: 120, editable: true },
        { field: "ctry_cd", headerName: "국가", maxWidth: 90, editable: true },
        {
          field: "use_yn_cd",
          headerName: "사용여부",
          maxWidth: 95,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("CMM_USE_YN") },
          cellRenderer: "codeUseYnCellRenderer"
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
          cellRenderer: "codeUseYnCellRenderer"
        },
        {
          field: "use_yn_cd",
          headerName: "사용여부",
          maxWidth: 100,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("CMM_USE_YN") },
          cellRenderer: "codeUseYnCellRenderer"
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
          cellRenderer: "codeUseYnCellRenderer"
        }
      ]
    end

    def section_group_options_for_form
      common_code_options("STD_BZAC_SCTN_GRP")
    end

    def section_options_for_form
      section_option_items(nil)
    end

    def section_code_values
      common_code_values("STD_BZAC_SCTN")
    end

    def section_group_code_values
      common_code_values("STD_BZAC_SCTN_GRP")
    end

    def kind_options_for_form
      common_code_options("STD_BZAC_KIND")
    end

    def nation_options_for_form
      common_code_options("STD_NATION")
    end

    def use_yn_options_for_form
      common_code_options("CMM_USE_YN")
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
        { field: "mngt_corp_cd", type: "input", label: "관리법인", required: true, maxlength: 20, target: "detailField" },
        { field: "bizman_no", type: "input", label: "사업자번호", required: true, maxlength: 10, inputmode: "numeric", target: "detailField" },
        {
          field: "bzac_sctn_grp_cd",
          type: "select",
          label: "거래처구분그룹",
          required: true,
          options: section_group_options_for_form,
          target: "detailField detailGroupField"
        },
        {
          field: "bzac_sctn_cd",
          type: "select",
          label: "거래처구분",
          required: true,
          options: section_options_for_form,
          target: "detailField detailSectionField"
        },
        {
          field: "bzac_kind_cd",
          type: "select",
          label: "거래처종류",
          required: true,
          options: kind_options_for_form,
          target: "detailField"
        },
        {
          field: "ctry_cd",
          type: "select",
          label: "국가",
          required: true,
          options: nation_options_for_form,
          target: "detailField"
        },
        { field: "upper_bzac_cd", type: "input", label: "상위거래처", maxlength: 20, target: "detailField" },
        { field: "rpt_bzac_cd", type: "input", label: "대표거래처", maxlength: 20, target: "detailField" },
        { field: "rpt_sales_emp_cd", type: "input", label: "대표영업사원", required: true, maxlength: 20, target: "detailField" },
        { field: "rpt_sales_emp_nm", type: "input", label: "대표영업사원명", maxlength: 100, target: "detailField" },
        { field: "zip_cd", type: "input", label: "우편번호", maxlength: 20, target: "detailField" },
        { field: "addr_cd", type: "input", label: "주소", maxlength: 255, target: "detailField" },
        { field: "addr_dtl_cd", type: "input", label: "상세주소", maxlength: 255, target: "detailField" },
        { field: "aply_strt_day_cd", type: "date_picker", label: "적용시작일", required: true, target: "detailField" },
        { field: "aply_end_day_cd", type: "date_picker", label: "적용종료일", target: "detailField" },
        {
          field: "use_yn_cd",
          type: "select",
          label: "사용여부",
          required: true,
          options: use_yn_options_for_form,
          target: "detailField"
        }
      ]
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
        { field: "remk", type: "textarea", label: "비고", rows: 3, colspan: 2, maxlength: 500, target: "detailField" }
      ]
    end

    def section_option_items(group_code)
      scope = AdmCodeDetail.active.where(code: "STD_BZAC_SCTN").ordered
      if group_code.present?
        scope = scope.where(upper_detail_code: group_code)
      end

      scope.map do |row|
        {
          label: row.detail_code_name,
          value: row.detail_code
        }
      end
    end

    def section_options
      options = [ { label: "전체", value: "" } ]
      scope = AdmCodeDetail.active.where(code: "STD_BZAC_SCTN").ordered
      if selected_section_group.present?
        scope = scope.where(upper_detail_code: selected_section_group)
      end
      options + scope.map { |row| { label: row.detail_code_name, value: row.detail_code } }
    end

    def selected_section_group
      @selected_section_group ||= begin
        value = query_params.dig("q", "bzac_sctn_grp_cd").to_s.strip.upcase
        value.presence
      end
    end
end
