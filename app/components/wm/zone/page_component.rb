class Wm::Zone::PageComponent < Wm::BasePageComponent
  private
    def collection_path(**) = helpers.wm_zone_index_path(**)
    def member_path(_id, **) = helpers.wm_zone_index_path(**)

    def zones_url
      helpers.zones_wm_zone_index_path(format: :json)
    end

    def batch_save_url
      helpers.batch_save_wm_zone_index_path
    end

    def search_fields
      [
        {
          field: "workpl_cd",
          type: "select",
          label: "작업장",
          options: workplace_search_options,
          include_blank: false
        },
        {
          field: "area_cd",
          type: "select",
          label: "구역",
          options: area_search_options,
          include_blank: false
        },
        { field: "zone_cd", type: "input", label: "Zone", placeholder: "Zone 코드/명 검색.." },
        {
          field: "use_yn",
          type: "select",
          label: "사용여부",
          options: common_code_options("CMM_USE_YN", include_all: true),
          include_blank: false
        }
      ]
    end

    def area_columns
      [
        { field: "workpl_nm", headerName: "작업장명", minWidth: 120 },
        { field: "area_cd", headerName: "구역코드", minWidth: 110 },
        { field: "area_nm", headerName: "구역명", minWidth: 150 }
      ]
    end

    def zone_columns
      [
        {
          field: "__row_status",
          headerName: "상태",
          width: 68,
          minWidth: 68,
          maxWidth: 68,
          editable: false,
          sortable: false,
          filter: false,
          resizable: false,
          cellStyle: { textAlign: "center" },
          cellRenderer: "rowStatusCellRenderer"
        },
        { field: "workpl_cd", headerName: "작업장코드", minWidth: 130, editable: false, hide: true },
        { field: "area_cd", headerName: "구역코드", minWidth: 110, editable: false, hide: true },
        { field: "zone_cd", headerName: "ZONE코드", minWidth: 130, editable: true },
        { field: "zone_nm", headerName: "ZONE명", minWidth: 170, editable: true },
        { field: "zone_desc", headerName: "설명", minWidth: 220, editable: true },
        {
          field: "use_yn",
          headerName: "사용여부",
          maxWidth: 110,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("CMM_USE_YN") },
          cellRenderer: "createStatusBadge", cellRendererParams: { trueLabel: "Y" }
        },
        { field: "update_by", headerName: "수정자", minWidth: 100, editable: false },
        { field: "update_time", headerName: "수정일시", minWidth: 170, formatter: "datetime", editable: false }
      ]
    end

    def workplace_search_options
      workplace_records.map do |workplace|
        {
          label: "#{workplace.workpl_cd} - #{workplace.workpl_nm}",
          value: workplace.workpl_cd
        }
      end
    end

    def area_search_options
      options = [ { label: "전체", value: "" } ]
      return options if selected_workpl_cd.blank?

      options + WmArea.where(workpl_cd: selected_workpl_cd).ordered.map do |area|
        {
          label: "#{area.area_cd} - #{area.area_nm}",
          value: area.area_cd
        }
      end
    end

    def selected_workpl_cd
      @selected_workpl_cd ||= begin
        value = query_params.dig("q", "workpl_cd").to_s.strip.upcase
        value.presence || workplace_records.first&.workpl_cd
      end
    end

    def workplace_records
      @workplace_records ||= WmWorkplace.where(use_yn: "Y").ordered.to_a
    end
end
