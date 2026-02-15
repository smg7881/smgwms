class System::Dept::PageComponent < ApplicationComponent
  def initialize(query_params:)
    @query_params = query_params
  end

  private
    attr_reader :query_params

    def create_url
      helpers.system_dept_index_path
    end

    def update_url
      helpers.system_dept_path(":id")
    end

    def delete_url
      helpers.system_dept_path(":id")
    end

    def grid_url
      helpers.system_dept_index_path(format: :json, q: query_params["q"])
    end

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
end
