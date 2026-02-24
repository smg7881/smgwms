# 고객 오더 담당자 관리 화면을 렌더링하기 위한 뷰 컴포넌트
# 검색 조건 폼 설정과 그리드(ag-Grid) 설정(컬럼 정보, 라우팅 등)을 관리합니다.
class Om::CustomerOrderOfficer::PageComponent < Om::BasePageComponent
  # 공통코드(OM_EXP_IMP_DOM_SCTN) 조회가 불가능할 때 사용할 기본(Fallback) 옵션 리스트
  FALLBACK_EXP_IMP_DOM_OPTIONS = [
    { label: "수출", value: "EXPORT" },
    { label: "수입", value: "IMPORT" },
    { label: "내수", value: "DOMESTIC" }
  ].freeze

  # 컴포넌트 초기화
  # @param query_params [Hash] URL의 쿼리 파라미터
  # @param search_form [Object] 화면 상단의 검색 폼 객체
  def initialize(query_params:, search_form:)
    super(query_params: query_params)
    @search_form = search_form
  end

  private
    attr_reader :search_form

    # 목록 조회용 API URL 반환
    def collection_path(**) = helpers.om_customer_order_officers_path(**)
    # 단건 조회용 API URL 반환
    def member_path(_id, **) = helpers.om_customer_order_officers_path(**)

    # 그리드 데이터의 일괄 저장(추가/수정/삭제)을 위한 API 엔드포인트 URL 반환
    def batch_save_url
      helpers.batch_save_om_customer_order_officers_path
    end

    # 상단 검색 폼에 렌더링될 필드 속성 목록을 반환
    # (부서조회 팝업, 고객조회 팝업, 콤보박스, 텍스트입력 등 4개 필드로 구성)
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
          field: "cust_ofcr_nm",
          type: "input",
          label: "담당자",
          placeholder: "담당자명 검색"
        }
      ]
    end

    # ag-Grid에 렌더링될 각 컬럼의 속성을 반환
    # (팝업 연동 에디터, 셀렉트박스 에디터, 수정 가능 여부, 너비 등을 세부 정의)
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
          minWidth: 140,
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
        { field: "cust_ofcr_nm", headerName: "고객담당자명", minWidth: 140, editable: true },
        { field: "cust_ofcr_tel_no", headerName: "고객담당자전화번호", minWidth: 170, editable: true },
        { field: "update_by", headerName: "수정자", minWidth: 100, editable: false },
        { field: "update_time", headerName: "수정일시", minWidth: 160, formatter: "datetime", editable: false }
      ]
    end

    # 그리드 내 [수출입내수구분] 셀렉트박스(에디터)에서 선택 가능한 값(value)들만의 배열 반환
    def exp_imp_dom_values
      exp_imp_dom_options(include_all: false).map { |option| option[:value] }
    end

    # "수출입내수구분" 항목에 맵핑할 `{ label: "", value: "" }` 구조의 옵션 배열을 반환
    # @param include_all [Boolean] "전체" 항목 추가 여부
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
