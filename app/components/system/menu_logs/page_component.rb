class System::MenuLogs::PageComponent < System::BasePageComponent
  private
    def collection_path(**) = helpers.system_menu_logs_path(**)
    def member_path(id, **) = "#{helpers.system_menu_logs_path}/#{id}"

    def search_fields
      [
        { field: "user_id", type: "input", label: "사용자 ID", placeholder: "사용자 ID 검색.." },
        { field: "user_name", type: "input", label: "사용자명", placeholder: "사용자명 검색.." },
        { field: "menu_id", type: "input", label: "메뉴 ID", placeholder: "메뉴 ID 검색.." },
        { field: "menu_name", type: "input", label: "메뉴명", placeholder: "메뉴명 검색.." },
        { field: "ip_address", type: "input", label: "IP 주소", placeholder: "IP 주소 검색.." },
        { field: "access_time_from", type: "date_picker", label: "접속 시작일시", date_type: "datetime" },
        { field: "access_time_to", type: "date_picker", label: "접속 종료일시", date_type: "datetime" }
      ]
    end

    def columns
      [
        { field: "id", headerName: "로그 ID", minWidth: 100, maxWidth: 110, pinned: "left" },
        { field: "user_id", headerName: "사용자 ID", minWidth: 120, maxWidth: 150 },
        { field: "user_name", headerName: "사용자명", minWidth: 120, maxWidth: 150 },
        { field: "menu_id", headerName: "메뉴 ID", minWidth: 130, maxWidth: 180 },
        { field: "menu_name", headerName: "메뉴명", minWidth: 180 },
        { field: "menu_path", headerName: "메뉴 경로", minWidth: 220, formatter: "truncate" },
        { field: "access_time", headerName: "접속 시간", minWidth: 170, formatter: "datetime" },
        { field: "ip_address", headerName: "IP 주소", minWidth: 130, maxWidth: 160 },
        { field: "user_agent", headerName: "User Agent", minWidth: 260, formatter: "truncate" },
        { field: "session_id", headerName: "세션 ID", minWidth: 150, maxWidth: 220 },
        { field: "referrer", headerName: "이전 페이지", minWidth: 220, formatter: "truncate" }
      ]
    end
end
