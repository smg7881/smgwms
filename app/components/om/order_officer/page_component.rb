class Om::OrderOfficer::PageComponent < Om::BasePageComponent
  FALLBACK_EXP_IMP_DOM_OPTIONS = [
    { label: "수출", value: "EXPORT" },
    { label: "수입", value: "IMPORT" },
    { label: "내수", value: "DOMESTIC" }
  ].freeze

  def initialize(query_params:, search_form:)
    super(query_params: query_params)
    @search_form = search_form
  end

  private
    attr_reader :search_form

    def collection_path(**) = helpers.om_order_officers_path(**)
    def member_path(_id, **) = helpers.om_order_officers_path(**)

    def batch_save_url
      helpers.batch_save_om_order_officers_path
    end

    def search_fields
      [
        {
          field: "dept_nm",
          type: "popup",
          label: "부서",
          popup_type: "dept",
          code_field: "dept_cd",
          value: search_form.dept_nm,
          placeholder: "부서 선택",
          display_width: "220px",
          code_width: "120px"
        },
        {
          field: "cust_nm",
          type: "popup",
          label: "고객",
          popup_type: "client",
          code_field: "cust_cd",
          value: search_form.cust_nm,
          placeholder: "고객 선택",
          display_width: "220px",
          code_width: "120px"
        },
        {
          field: "exp_imp_dom_sctn_cd",
          type: "select",
          label: "수출입내수구분",
          options: exp_imp_dom_options(include_all: true),
          include_blank: false
        },
        {
          field: "ofcr_nm",
          type: "popup",
          label: "담당자",
          popup_type: "user",
          code_field: "ofcr_cd",
          value: search_form.ofcr_nm,
          placeholder: "담당자 선택",
          display_width: "220px",
          code_width: "120px"
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
        { field: "id", headerName: "ID", hide: true, editable: false, sortable: false, filter: false },
        {
          field: "ord_chrg_dept_cd",
          headerName: "오더담당부서코드",
          minWidth: 160,
          editable: true,
          lookup_popup_type: "dept",
          lookup_code_field: "ord_chrg_dept_cd",
          lookup_name_field: "ord_chrg_dept_nm",
          lookup_popup_title: "부서 조회"
        },
        { field: "ord_chrg_dept_nm", headerName: "오더담당부서명", minWidth: 170, editable: false },
        {
          field: "cust_cd",
          headerName: "고객코드",
          minWidth: 120,
          editable: true,
          lookup_popup_type: "client",
          lookup_code_field: "cust_cd",
          lookup_name_field: "cust_nm",
          lookup_popup_title: "고객 조회"
        },
        { field: "cust_nm", headerName: "고객명", minWidth: 160, editable: false },
        {
          field: "exp_imp_dom_sctn_cd",
          headerName: "수출입내수구분",
          minWidth: 140,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: exp_imp_dom_values }
        },
        {
          field: "ofcr_cd",
          headerName: "담당자아이디",
          minWidth: 140,
          editable: true,
          lookup_popup_type: "user",
          lookup_code_field: "ofcr_cd",
          lookup_name_field: "ofcr_nm",
          lookup_popup_title: "담당자 조회"
        },
        { field: "ofcr_nm", headerName: "담당자명", minWidth: 140, editable: false },
        { field: "tel_no", headerName: "전화번호", minWidth: 150, editable: false },
        { field: "mbp_no", headerName: "휴대전화번호", minWidth: 170, editable: false },
        { field: "update_by", headerName: "수정자", minWidth: 100, editable: false },
        { field: "update_time", headerName: "수정일시", minWidth: 160, formatter: "datetime", editable: false }
      ]
    end

    def exp_imp_dom_values
      exp_imp_dom_options(include_all: false).map { |option| option[:value] }
    end

    def exp_imp_dom_options(include_all:)
      options = common_code_options("OM_EXP_IMP_DOM_SCTN", include_all: include_all, all_label: "전체")
      has_real_options = options.any? { |option| option[:value].to_s.present? }
      if has_real_options
        return options
      end

      if include_all
        [ { label: "전체", value: "" } ] + FALLBACK_EXP_IMP_DOM_OPTIONS
      else
        FALLBACK_EXP_IMP_DOM_OPTIONS
      end
    end
end
