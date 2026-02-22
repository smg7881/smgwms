class Std::ApprovalHistory::PageComponent < Std::BasePageComponent
  private
    def collection_path(**) = helpers.std_approval_histories_path(**)
    def member_path(_id, **) = helpers.std_approval_histories_path(**)

    def request_action_url
      helpers.request_action_std_approval_histories_path
    end

    def approve_action_url
      helpers.approve_action_std_approval_histories_path
    end

    def current_user_code
      Current.user&.user_id_code.to_s.strip.upcase
    end

    def search_fields
      [
        { field: "corp_nm", type: "popup", label: "법인", popup_type: "corp", code_field: "corp_cd", placeholder: "법인 선택" },
        {
          field: "apv_stat_cd",
          type: "select",
          label: "결재상태",
          options: common_code_options("STD_APV_STATUS", include_all: true, all_label: "전체"),
          include_blank: false
        },
        { field: "apv_reqr_nm", type: "popup", label: "요청자", popup_type: "user", code_field: "apv_reqr", placeholder: "요청자 선택" },
        { field: "asmt_apver_nm", type: "popup", label: "결재자", popup_type: "user", code_field: "asmt_apver", placeholder: "결재자 선택" },
        { field: "menu_nm", type: "popup", label: "메뉴명", popup_type: "menu", code_field: "menu_cd", placeholder: "메뉴 선택" }
      ]
    end

    def status_options_for_modal
      common_code_options("STD_APV_STATUS")
    end

    def columns
      [
        { field: "apv_req_no", headerName: "결재요청번호", minWidth: 145 },
        { field: "menu_nm", headerName: "메뉴명", minWidth: 150 },
        { field: "apv_req_ymd", headerName: "결재요청일자", minWidth: 165, formatter: "datetime" },
        { field: "apv_reqr", headerName: "결재요청자", minWidth: 110 },
        { field: "apv_stat_cd", headerName: "결재상태", minWidth: 100 },
        { field: "asmt_apver", headerName: "담당결재자", minWidth: 120 },
        { field: "apv_apv_ymd", headerName: "결재승인일자", minWidth: 165, formatter: "datetime" },
        { field: "apv_req_conts", headerName: "결재요청내용", minWidth: 220 },
        { field: "apv_opi", headerName: "결재의견", minWidth: 180 },
        { field: "update_by", headerName: "수정자", minWidth: 95 },
        { field: "update_time", headerName: "수정일시", minWidth: 165, formatter: "datetime" }
      ]
    end
end
