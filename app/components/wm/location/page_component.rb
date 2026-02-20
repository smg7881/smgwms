class Wm::Location::PageComponent < Wm::BasePageComponent
  LOCATION_CLASS_OPTIONS = [
    { label: "전체", value: "" },
    { label: "STORAGE", value: "STORAGE" },
    { label: "PICKING", value: "PICKING" },
    { label: "MOVE", value: "MOVE" }
  ].freeze

  LOCATION_CLASS_VALUES = %w[STORAGE PICKING MOVE].freeze
  LOCATION_TYPE_VALUES = %w[NORMAL RACK FLOOR].freeze

  private
    def collection_path(**) = helpers.wm_location_index_path(**)
    def member_path(_id, **) = helpers.wm_location_index_path(**)

    def areas_url
      helpers.areas_wm_location_index_path(format: :json)
    end

    def zones_url
      helpers.zones_wm_location_index_path(format: :json)
    end

    def batch_save_url
      helpers.batch_save_wm_location_index_path
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
          label: "AREA",
          options: area_search_options
        },
        {
          field: "zone_cd",
          type: "select",
          label: "ZONE",
          options: zone_search_options
        },
        { field: "loc_cd", type: "input", label: "로케이션", placeholder: "로케이션코드/명 검색.." },
        {
          field: "loc_class_cd",
          type: "select",
          label: "구분",
          options: LOCATION_CLASS_OPTIONS
        },
        {
          field: "use_yn",
          type: "select",
          label: "사용여부",
          options: common_code_options("CMM_USE_YN", include_all: true),
          include_blank: false
        }
      ]
    end

    def columns
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
        { field: "workpl_cd", headerName: "작업장코드", minWidth: 120, editable: false },
        { field: "area_cd", headerName: "AREA코드", minWidth: 110, editable: false },
        { field: "zone_cd", headerName: "ZONE코드", minWidth: 110, editable: false },
        { field: "loc_cd", headerName: "로케이션코드", minWidth: 130, editable: true },
        { field: "loc_nm", headerName: "로케이션명", minWidth: 170, editable: true },
        {
          field: "loc_class_cd",
          headerName: "구분",
          minWidth: 120,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: LOCATION_CLASS_VALUES }
        },
        {
          field: "loc_type_cd",
          headerName: "유형",
          minWidth: 120,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: LOCATION_TYPE_VALUES }
        },
        { field: "width_len", headerName: "가로", minWidth: 90, editable: true, cellEditor: "agNumberCellEditor" },
        { field: "vert_len", headerName: "세로", minWidth: 90, editable: true, cellEditor: "agNumberCellEditor" },
        { field: "height_len", headerName: "높이", minWidth: 90, editable: true, cellEditor: "agNumberCellEditor" },
        { field: "max_weight", headerName: "최대중량", minWidth: 100, editable: true, cellEditor: "agNumberCellEditor" },
        { field: "max_cbm", headerName: "최대부피", minWidth: 100, editable: true, cellEditor: "agNumberCellEditor" },
        {
          field: "use_yn",
          headerName: "사용여부",
          maxWidth: 110,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("CMM_USE_YN") },
          cellRenderer: "codeUseYnCellRenderer"
        },
        {
          field: "has_stock",
          headerName: "재고",
          maxWidth: 90,
          editable: false,
          cellRenderer: "stockYnCellRenderer"
        },
        { field: "update_by", headerName: "수정자", minWidth: 100, editable: false },
        { field: "update_time", headerName: "수정일시", minWidth: 170, formatter: "datetime", editable: false },
        { field: "create_by", headerName: "생성자", minWidth: 100, editable: false },
        { field: "create_time", headerName: "생성일시", minWidth: 170, formatter: "datetime", editable: false }
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

      options + WmArea.where(workpl_cd: selected_workpl_cd, use_yn: "Y").ordered.map do |area|
        {
          label: "#{area.area_cd} - #{area.area_nm}",
          value: area.area_cd
        }
      end
    end

    def zone_search_options
      options = [ { label: "전체", value: "" } ]
      return options if selected_workpl_cd.blank? || selected_area_cd.blank?

      options + WmZone.where(workpl_cd: selected_workpl_cd, area_cd: selected_area_cd, use_yn: "Y").ordered.map do |zone|
        {
          label: "#{zone.zone_cd} - #{zone.zone_nm}",
          value: zone.zone_cd
        }
      end
    end

    def selected_workpl_cd
      @selected_workpl_cd ||= begin
        value = query_params.dig("q", "workpl_cd").to_s.strip.upcase
        value.presence || workplace_records.first&.workpl_cd
      end
    end

    def selected_area_cd
      @selected_area_cd ||= query_params.dig("q", "area_cd").to_s.strip.upcase.presence
    end

    def workplace_records
      @workplace_records ||= WmWorkplace.where(use_yn: "Y").ordered.to_a
    end
end
