class System::LoginHistory::PageComponent < System::BasePageComponent
  private
    def collection_path(**) = helpers.system_login_histories_path(**)
    def member_path(_id, **) = "#"

    def search_fields
      [
        { field: "user_id_code", type: "input", label: "사번", placeholder: "사번 검색.." },
        { field: "start_date", type: "date_picker", label: "시작일시", date_type: "datetime" },
        { field: "end_date", type: "date_picker", label: "종료일시", date_type: "datetime" },
        { field: "login_success", type: "select", label: "결과",
          options: [ { value: "", label: "전체" }, { value: "true", label: "성공" }, { value: "false", label: "실패" } ] }
      ]
    end

    def columns
      [
        { field: "id", headerName: "ID", minWidth: 80, maxWidth: 90, pinned: "left" },
        { field: "user_id_code", headerName: "사번", minWidth: 120, maxWidth: 150 },
        { field: "user_nm", headerName: "사원명", minWidth: 100, maxWidth: 130 },
        { field: "login_time", headerName: "로그인 시간", minWidth: 170, formatter: "datetime" },
        { field: "login_success", headerName: "결과", minWidth: 90, maxWidth: 100,
          cellRenderer: "loginSuccessCellRenderer" },
        { field: "ip_address", headerName: "IP 주소", minWidth: 130, maxWidth: 160 },
        { field: "browser", headerName: "브라우저", minWidth: 150 },
        { field: "os", headerName: "OS", minWidth: 150 },
        { field: "failure_reason", headerName: "실패 사유", minWidth: 200 }
      ]
    end
end
