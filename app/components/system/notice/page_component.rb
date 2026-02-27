class System::Notice::PageComponent < System::BasePageComponent
  private
    def collection_path(**) = helpers.system_notice_index_path(**)
    def member_path(id, **) = helpers.system_notice_path(id, **)

    def bulk_delete_url
      helpers.bulk_destroy_system_notice_index_path
    end

    def search_fields
      [
        {
          field: "category_code",
          type: "select",
          label: "분류",
          options: common_code_options("NOTICE_CATEGORY", include_all: true),
          include_blank: false
        },
        { field: "title", type: "input", label: "제목", placeholder: "제목 검색..." },
        {
          field: "is_published",
          type: "select",
          label: "게시여부",
          options: common_code_options("CMM_USE_YN", include_all: true),
          include_blank: false
        }
      ]
    end

    def columns
      [
        { field: "category_code", headerName: "분류", minWidth: 130, maxWidth: 150 },
        { field: "is_top_fixed", headerName: "상단고정", minWidth: 90, maxWidth: 110, cellRenderer: "createStatusBadge", cellRendererParams: { trueLabel: "공지", falseLabel: "일반", trueColor: "#d03050", falseColor: "#8b949e", fontSize: "12px" } },
        { field: "title", headerName: "제목", minWidth: 280, cellRenderer: "noticeTitleCellRenderer" },
        { field: "is_published", headerName: "게시여부", minWidth: 100, maxWidth: 120, cellRenderer: "createStatusBadge", cellRendererParams: { trueLabel: "게시", falseLabel: "미게시", falseColor: "#d08700" } },
        { field: "create_time", headerName: "등록일시", minWidth: 160, formatter: "datetime" },
        { field: "view_count", headerName: "조회수", minWidth: 90, maxWidth: 100 },
        { field: "create_by", headerName: "등록자", minWidth: 100, maxWidth: 130 },
        { field: "actions", headerName: "작업", minWidth: 110, maxWidth: 110, filter: false, sortable: false, cellClass: "ag-cell-actions",
          cellRenderer: "actionCellRenderer",
          cellRendererParams: { actions: [
            { type: "edit",   eventName: "notice-crud:edit",   dataKeys: { id: "id" } },
            { type: "delete", eventName: "notice-crud:delete", dataKeys: { id: "id", title: "title" } }
          ] }
        }
      ]
    end

    def form_fields
      [
        {
          field: "category_code",
          type: "select",
          span: "24",
          label: "분류",
          required: true,
          include_blank: true,
          options: common_code_options("NOTICE_CATEGORY"),
          target: "fieldCategoryCode"
        },
        { field: "title", type: "input", span: "24", label: "제목", required: true, maxlength: 200, target: "fieldTitle" },
        {
          field: "is_top_fixed",
          type: "radio",
          label: "상단고정",
          options: [
            { label: "고정", value: "Y" },
            { label: "일반", value: "N" }
          ],
          target: "fieldIsTopFixed"
        },
        {
          field: "is_published",
          type: "radio",
          label: "게시여부",
          options: [
            { label: "게시", value: "Y" },
            { label: "미게시", value: "N" }
          ],
          target: "fieldIsPublished"
        },
        { field: "start_date", type: "date_picker", label: "게시 시작일", target: "fieldStartDate" },
        { field: "end_date", type: "date_picker", label: "게시 종료일", target: "fieldEndDate" },
        {
          field: "content",
          type: "rich_textarea",
          label: "내용",
          required: true,
          rows: 10,
          colspan: 2,
          target: "fieldContent",
          disable_file_attachments: true
        },
        {
          field: "attachments",
          type: "multi_file",
          span: "24",
          label: "첨부파일",
          multiple: true,
          max_files: 5,
          max_size_mb: 50,
          target: "fieldAttachments",
          existing_target: "existingFiles",
          selected_target: "selectedFiles"
        }
      ]
    end
end
