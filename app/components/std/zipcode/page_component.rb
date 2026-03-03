class Std::Zipcode::PageComponent < Std::BasePageComponent
  private
    def collection_path(**) = helpers.std_zipcodes_path(**)
    def member_path(id, **) = helpers.std_zipcode_path(id, **)

    def search_fields
      [
        {
          field: "ctry_nm",
          type: "popup",
          label: "국가",
          popup_type: "country",
          code_field: "ctry_cd",
          placeholder: "국가 선택"
        },
        { field: "zipcd", type: "input", label: "우편번호", placeholder: "우편번호 입력" },
        { field: "zipaddr", type: "input", label: "우편주소", placeholder: "우편주소/시도/시군구/읍면동" },
        {
          field: "use_yn_cd",
          type: "select",
          label: "사용여부",
          options: common_code_options(use_yn_code, include_all: true, all_label: "전체"),
          include_blank: false
        }
      ]
    end

    def columns
      [
        { field: "ctry_cd", headerName: "국가코드", maxWidth: 100 },
        { field: "ctry_nm", headerName: "국가명", minWidth: 120 },
        { field: "zipcd", headerName: "우편번호", minWidth: 120 },
        { field: "seq_no", headerName: "일련번호", maxWidth: 100, type: "numericColumn" },
        { field: "zipaddr", headerName: "우편주소", minWidth: 260 },
        { field: "sido", headerName: "시도", minWidth: 120 },
        { field: "sgng", headerName: "시군구", minWidth: 120 },
        { field: "eupdiv", headerName: "읍면동", minWidth: 120 },
        { field: "use_yn_cd", headerName: "사용여부", maxWidth: 90, cellRenderer: "createStatusBadge", cellRendererParams: { trueLabel: "Y" } },
        { field: "update_by", headerName: "수정자", minWidth: 100 },
        { field: "update_time", headerName: "수정일시", minWidth: 160, formatter: "datetime" },
        {
          field: "actions",
          headerName: "작업항목",
          minWidth: 110,
          maxWidth: 110,
          filter: false,
          sortable: false,
          cellClass: "ag-cell-actions",
          cellRenderer: "actionCellRenderer",
          cellRendererParams: { actions: [
            { type: "edit",   eventName: "std-zipcode-crud:edit",   dataKeys: { zipcodeData: nil } },
            { type: "delete", eventName: "std-zipcode-crud:delete", dataKeys: { id: "id", zipCodeLabel: "zipcd||id" } }
          ] }
        }
      ]
    end

    def form_fields
      [
        {
          field: "ctry_lookup",
          type: "popup",
          label: "국가",
          popup_type: "country",
          code_field: "ctry_cd",
          required: true,
          target: "fieldCtryCd",
          placeholder: "국가 선택"
        },
        {
          field: "zipcd",
          type: "input",
          label: "우편번호",
          required: true,
          maxlength: 20,
          target: "fieldZipcd"
        },
        {
          field: "seq_no",
          type: "number",
          label: "일련번호",
          required: true,
          min: 1,
          step: 1,
          target: "fieldSeqNo"
        },
        { field: "zipaddr", type: "input", label: "우편주소", maxlength: 300, target: "fieldZipaddr", span: "24" },
        { field: "sido", type: "input", label: "시도", maxlength: 80, target: "fieldSido" },
        { field: "sgng", type: "input", label: "시군구", maxlength: 80, target: "fieldSgng" },
        { field: "eupdiv", type: "input", label: "읍면동", maxlength: 80, target: "fieldEupdiv" },
        { field: "addr_ri", type: "input", label: "주소리", maxlength: 80, target: "fieldAddrRi" },
        { field: "iland_san", type: "input", label: "산구분", maxlength: 10, target: "fieldIlandSan" },
        { field: "san_houseno", type: "input", label: "산번지", maxlength: 20, target: "fieldSanHouseno" },
        { field: "apt_bild_nm", type: "input", label: "아파트건물명", maxlength: 120, target: "fieldAptBildNm", span: "24" },
        { field: "strt_houseno_wek", type: "input", label: "시작번지 주", maxlength: 20, target: "fieldStrtHousenoWek" },
        { field: "strt_houseno_mnst", type: "input", label: "시작번지 부", maxlength: 20, target: "fieldStrtHousenoMnst" },
        { field: "end_houseno_wek", type: "input", label: "끝번지 주", maxlength: 20, target: "fieldEndHousenoWek" },
        { field: "end_houseno_mnst", type: "input", label: "끝번지 부", maxlength: 20, target: "fieldEndHousenoMnst" },
        { field: "dong_rng_strt", type: "input", label: "동범위 시작", maxlength: 20, target: "fieldDongRngStrt" },
        { field: "dong_houseno_end", type: "input", label: "동범위 끝", maxlength: 20, target: "fieldDongHousenoEnd" },
        { field: "chg_ymd", type: "date_picker", label: "변경일자", target: "fieldChgYmd" },
        { field: "use_yn_cd", type: "select", label: "사용여부", options: common_code_options(use_yn_code), include_blank: false, required: true, target: "fieldUseYnCd" },
        { field: "create_by", type: "input", label: "등록자", disabled: true, target: "fieldCreateBy" },
        { field: "create_time", type: "input", label: "등록일시", disabled: true, target: "fieldCreateTime" },
        { field: "update_by", type: "input", label: "수정자", disabled: true, target: "fieldUpdateBy" },
        { field: "update_time", type: "input", label: "수정일시", disabled: true, target: "fieldUpdateTime" }
      ]
    end

    def use_yn_code
      if common_code_values("STD_ZIP_USE_YN").present?
        "STD_ZIP_USE_YN"
      else
        "CMM_USE_YN"
      end
    end
end
