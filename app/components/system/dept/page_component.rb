class System::Dept::PageComponent < System::BasePageComponent
  private
    def collection_path(**) = helpers.system_dept_index_path(**)
    def member_path(id, **) = helpers.system_dept_path(id, **)

    def search_fields
      [
        { field: "dept_code", type: "input", label: "부서코드", placeholder: "부서코드를 입력하세요" },
        { field: "dept_nm", type: "input", label: "부서명", placeholder: "부서명을 입력하세요" },
        {
          field: "use_yn",
          type: "select",
          label: "사용여부",
          options: [
            { label: "전체", value: "" },
            { label: "사용", value: "Y" },
            { label: "미사용", value: "N" }
          ],
          include_blank: false
        }
      ]
    end

    def columns
      [
        { field: "dept_nm", headerName: "부서명", minWidth: 240, cellRenderer: "deptTreeCellRenderer" },
        { field: "dept_code", headerName: "부서코드", minWidth: 120 },
        { field: "parent_dept_code", headerName: "상위부서코드", minWidth: 140 },
        { field: "dept_type", headerName: "부서유형", minWidth: 110 },
        { field: "dept_order", headerName: "부서순서", maxWidth: 110 },
        { field: "use_yn", headerName: "사용여부", maxWidth: 100, cellRenderer: "deptUseYnCellRenderer" },
        { field: "update_by", headerName: "수정자", minWidth: 100 },
        { field: "update_time", headerName: "수정일시", minWidth: 170, formatter: "datetime" },
        { field: "create_by", headerName: "생성자", minWidth: 100 },
        { field: "create_time", headerName: "생성일시", minWidth: 170, formatter: "datetime" },
        { field: "actions", headerName: "작업", minWidth: 140, maxWidth: 140, filter: false, sortable: false, cellClass: "ag-cell-actions", cellRenderer: "deptActionCellRenderer" }
      ]
    end

    def form_fields
      [
        { field: "dept_code", type: "input", label: "부서코드", required: true, maxlength: 50, target: "fieldDeptCode" },
        { field: "dept_nm", type: "input", label: "부서명", required: true, maxlength: 100, target: "fieldDeptNm" },
        { field: "parent_dept_code", type: "input", label: "상위 부서코드", readonly: true, maxlength: 50, target: "fieldParentDeptCode" },
        {
          field: "dept_type",
          type: "select",
          label: "부서유형",
          include_blank: true,
          options: [
            { label: "본부", value: "HQ" },
            { label: "실", value: "OFFICE" },
            { label: "팀", value: "TEAM" },
            { label: "파트", value: "PART" }
          ],
          target: "fieldDeptType"
        },
        { field: "dept_order", type: "number", label: "부서순서", value: 0, min: 0, target: "fieldDeptOrder" },
        {
          field: "use_yn",
          type: "radio",
          label: "사용여부",
          value: "Y",
          options: [
            { label: "사용", value: "Y" },
            { label: "미사용", value: "N" }
          ]
        },
        { field: "description", type: "textarea", label: "설명", rows: 4, colspan: 2, maxlength: 500, target: "fieldDescription" }
      ]
    end
end
