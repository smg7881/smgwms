class System::Users::FormModalComponent < ApplicationComponent
  private
    def fields
      [
        { field: "photo", type: "photo", label: "사진", span: "12", colspan: 2, rowspan: 2, target: "fieldPhoto" },
        { field: "user_id_code", type: "input", label: "사번", required: true, maxlength: 16, target: "fieldUserIdCode" },
        { field: "user_nm", type: "input", label: "사원명", required: true, maxlength: 20, target: "fieldUserNm" },
        { field: "email_address", type: "input", label: "이메일", maxlength: 100, target: "fieldEmailAddress" },
        { field: "password", type: "input", label: "비밀번호", input_type: "password", maxlength: 72, autocomplete: "off", target: "fieldPassword" },
        { field: "dept_cd", type: "input", label: "부서코드", maxlength: 20, target: "fieldDeptCd" },
        { field: "dept_nm", type: "input", label: "부서명", maxlength: 50, target: "fieldDeptNm" },
        {
          field: "role_cd",
          type: "select",
          label: "권한",
          include_blank: true,
          options: [
            { label: "관리자", value: "ADMIN" },
            { label: "일반사용자", value: "USER" },
            { label: "뷰어", value: "VIEWER" }
          ],
          target: "fieldRoleCd"
        },
        {
          field: "position_cd",
          type: "select",
          label: "직급",
          include_blank: true,
          options: [
            { label: "사원", value: "STAFF" },
            { label: "주임", value: "SENIOR" },
            { label: "대리", value: "ASSISTANT_MGR" },
            { label: "과장", value: "MANAGER" },
            { label: "차장", value: "DEPUTY_GM" },
            { label: "부장", value: "GENERAL_MGR" }
          ],
          target: "fieldPositionCd"
        },
        {
          field: "job_title_cd",
          type: "select",
          label: "직책",
          include_blank: true,
          options: [
            { label: "담당", value: "MEMBER" },
            { label: "팀장", value: "TEAM_LEAD" },
            { label: "파트장", value: "PART_LEAD" }
          ],
          target: "fieldJobTitleCd"
        },
        {
          field: "work_status",
          type: "select",
          label: "재직상태",
          include_blank: false,
          options: [
            { label: "재직", value: "ACTIVE" },
            { label: "퇴사", value: "RESIGNED" }
          ],
          target: "fieldWorkStatus"
        },
        { field: "hire_date", type: "date_picker", label: "입사일", required: true, target: "fieldHireDate" },
        { field: "resign_date", type: "date_picker", label: "퇴사일", target: "fieldResignDate" },
        { field: "phone", type: "input", label: "연락처", placeholder: "010-0000-0000", maxlength: 13, target: "fieldPhone" },
        { field: "address", type: "input", label: "주소", maxlength: 200, target: "fieldAddress" },
        { field: "detail_address", type: "input", label: "상세주소", maxlength: 200, target: "fieldDetailAddress" }
      ]
    end
end
