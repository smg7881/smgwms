class Std::WorkStep::PageComponent < Std::BasePageComponent
  private
    def collection_path(**) = helpers.std_work_steps_path(**)
    def member_path(id, **) = helpers.std_work_step_path(id, **)

    def search_fields
      [
        { field: "work_step_cd", type: "input", label: "작업단계코드", placeholder: "작업단계코드를 입력하세요." },
        { field: "work_step_nm", type: "input", label: "작업단계명", placeholder: "작업단계명을 입력하세요." },
        {
          field: "use_yn_cd",
          type: "select",
          label: "사용여부",
          options: common_code_options("CMM_USE_YN", include_all: true, all_label: "전체"),
          include_blank: false
        }
      ]
    end

    def columns
      [
        { field: "work_step_cd", headerName: "작업단계코드", minWidth: 130 },
        { field: "work_step_nm", headerName: "작업단계명", minWidth: 180 },
        {
          field: "work_step_level1_cd",
          headerName: "작업단계Level1",
          minWidth: 160,
          formatter: "codeLabel",
          context: { codeMap: common_code_map("07") }
        },
        {
          field: "work_step_level2_cd",
          headerName: "작업단계Level2",
          minWidth: 160,
          formatter: "codeLabel",
          context: { codeMap: common_code_map("08") }
        },
        { field: "sort_seq", headerName: "정렬순서", maxWidth: 100, type: "numericColumn" },
        {
          field: "use_yn_cd",
          headerName: "사용여부",
          maxWidth: 95,
          cellRenderer: "createStatusBadge", cellRendererParams: { trueLabel: "Y" }
        },
        { field: "rmk_cd", headerName: "비고", minWidth: 180 },
        { field: "update_by", headerName: "수정자", minWidth: 95 },
        { field: "update_time", headerName: "수정일시", minWidth: 160, formatter: "datetime" },
        { field: "create_by", headerName: "생성자", minWidth: 95 },
        { field: "create_time", headerName: "생성일시", minWidth: 160, formatter: "datetime" },
        {
          field: "actions",
          headerName: "작업",
          minWidth: 110,
          maxWidth: 110,
          filter: false,
          sortable: false,
          cellClass: "ag-cell-actions",
          cellRenderer: "actionCellRenderer",
          cellRendererParams: { actions: [
            { type: "edit", eventName: "std-work-step-crud:edit", dataKeys: { workStepData: nil } },
            { type: "delete", eventName: "std-work-step-crud:delete", dataKeys: { id: "id||work_step_cd", workStepNm: "work_step_nm||work_step_cd" } }
          ] }
        }
      ]
    end

    def form_fields
      [
        { field: "work_step_cd", type: "input", label: "작업단계코드", required: true, maxlength: 30, target: "fieldWorkStepCd" },
        { field: "work_step_nm", type: "input", label: "작업단계명", required: true, maxlength: 150, target: "fieldWorkStepNm" },
        {
          field: "work_step_level1_cd",
          type: "select",
          label: "작업단계Level1",
          required: true,
          include_blank: true,
          options: common_code_options("07"),
          target: "fieldWorkStepLevel1Cd"
        },
        {
          field: "work_step_level2_cd",
          type: "select",
          label: "작업단계Level2",
          required: true,
          include_blank: true,
          options: work_step_level2_options,
          depends_on: "work_step_level1_cd",
          depends_filter: "work_step_level1_cd",
          target: "fieldWorkStepLevel2Cd"
        },
        {
          field: "use_yn_cd",
          type: "radio",
          label: "사용여부",
          value: "Y",
          options: common_code_radio_options("CMM_USE_YN")
        },
        { field: "sort_seq", type: "number", label: "정렬순서", value: 0, min: 0, target: "fieldSortSeq" },
        { field: "conts_cd", type: "textarea", label: "내용", rows: 3, colspan: 2, maxlength: 2000, target: "fieldContsCd" },
        { field: "rmk_cd", type: "textarea", label: "비고", rows: 3, colspan: 2, maxlength: 500, target: "fieldRmkCd" }
      ]
    end

    def work_step_level2_options
      AdmCodeDetail.active.where(code: "08").ordered.map do |row|
        {
          label: row.detail_code_name,
          value: row.detail_code,
          work_step_level1_cd: row.upper_detail_code.to_s.strip.upcase
        }
      end
    end
end
