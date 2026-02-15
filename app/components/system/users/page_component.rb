class System::Users::PageComponent < ApplicationComponent
  def initialize(query_params:)
    @query_params = query_params
  end

  private
    attr_reader :query_params

    def create_url
      helpers.system_users_path
    end

    def update_url
      helpers.system_user_path(":id")
    end

    def delete_url
      helpers.system_user_path(":id")
    end

    def check_id_url
      helpers.check_id_system_users_path
    end

    def grid_url
      helpers.system_users_path(format: :json, q: query_params["q"])
    end

    def search_fields
      [
        { field: "dept_nm", type: "input", label: "부서명", placeholder: "부서명 검색..." },
        { field: "user_nm", type: "input", label: "사원명", placeholder: "사원명 검색..." },
        {
          field: "work_status",
          type: "select",
          label: "재직상태",
          options: [
            { label: "전체", value: "" },
            { label: "재직", value: "ACTIVE" },
            { label: "퇴사", value: "RESIGNED" }
          ],
          include_blank: false
        }
      ]
    end

    def columns
      [
        { field: "user_id_code", headerName: "사번", minWidth: 120 },
        { field: "user_nm", headerName: "사원명", minWidth: 120 },
        { field: "dept_nm", headerName: "부서", minWidth: 150 },
        { field: "phone", headerName: "연락처", minWidth: 130 },
        { field: "work_status", headerName: "재직상태", maxWidth: 100, cellRenderer: "workStatusCellRenderer" },
        { field: "hire_date", headerName: "입사일", minWidth: 120, formatter: "date" },
        { field: "resign_date", headerName: "퇴사일", minWidth: 120, formatter: "date" },
        { field: "email_address", headerName: "이메일", minWidth: 200 },
        { field: "address", headerName: "주소", minWidth: 200 },
        { field: "actions", headerName: "작업", minWidth: 120, maxWidth: 120, filter: false, sortable: false, cellClass: "ag-cell-actions", cellRenderer: "userActionCellRenderer" }
      ]
    end
end
