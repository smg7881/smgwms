class System::Dept::FormModalComponent < ApplicationComponent
  private
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
