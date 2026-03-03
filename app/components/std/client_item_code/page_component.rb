class Std::ClientItemCode::PageComponent < Std::BasePageComponent
  private
    def collection_path(**) = helpers.std_client_item_codes_path(**)
    def member_path(id, **) = helpers.std_client_item_code_path(id, **)

    def search_fields
      [
        { field: "bzac_nm", type: "popup", label: "거래처", popup_type: "client", code_field: "bzac_cd", placeholder: "거래처 선택" },
        { field: "item_cd", type: "input", label: "거래처아이템코드", placeholder: "코드 입력" },
        { field: "item_nm", type: "input", label: "아이템명", placeholder: "아이템명 입력" },
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
        { field: "item_cd", headerName: "아이템코드", minWidth: 130 },
        { field: "item_nm", headerName: "아이템명", minWidth: 170 },
        { field: "bzac_cd", headerName: "거래처코드", minWidth: 130 },
        { field: "bzac_nm", headerName: "거래처명", minWidth: 170 },
        { field: "goodsnm_cd", headerName: "품명코드", minWidth: 130 },
        { field: "goodsnm_nm", headerName: "품명명", minWidth: 170 },
        { field: "danger_yn_cd", headerName: "위험물여부", minWidth: 110, cellRenderer: "createStatusBadge", cellRendererParams: { trueLabel: "Y" } },
        { field: "png_yn_cd", headerName: "포장여부", minWidth: 95, cellRenderer: "createStatusBadge", cellRendererParams: { trueLabel: "Y" } },
        { field: "mstair_lading_yn_cd", headerName: "계단적재여부", minWidth: 130, cellRenderer: "createStatusBadge", cellRendererParams: { trueLabel: "Y" } },
        { field: "if_yn_cd", headerName: "인터페이스여부", minWidth: 130, cellRenderer: "createStatusBadge", cellRendererParams: { trueLabel: "Y" } },
        { field: "wgt_unit_cd", headerName: "중량단위코드", minWidth: 125, refData: common_code_map(unit_code_for(:wgt)) },
        { field: "qty_unit_cd", headerName: "수량단위코드", minWidth: 125, refData: common_code_map(unit_code_for(:qty)) },
        { field: "tmpt_unit_cd", headerName: "온도단위코드", minWidth: 125, refData: common_code_map(unit_code_for(:tmpt)) },
        { field: "vol_unit_cd", headerName: "부피단위코드", minWidth: 125, refData: common_code_map(unit_code_for(:vol)) },
        { field: "basis_unit_cd", headerName: "기본단위코드", minWidth: 125, refData: common_code_map(unit_code_for(:basis)) },
        { field: "len_unit_cd", headerName: "길이단위코드", minWidth: 125, refData: common_code_map(unit_code_for(:len)) },
        { field: "pckg_qty", headerName: "포장수량", minWidth: 110, type: "numericColumn" },
        { field: "tot_wgt_kg", headerName: "총중량(KG)", minWidth: 120, type: "numericColumn" },
        { field: "net_wgt_kg", headerName: "순중량(KG)", minWidth: 120, type: "numericColumn" },
        { field: "vessel_tmpt_c", headerName: "용기온도(C)", minWidth: 120, type: "numericColumn" },
        { field: "vessel_width_m", headerName: "용기가로(M)", minWidth: 120, type: "numericColumn" },
        { field: "vessel_vert_m", headerName: "용기세로(M)", minWidth: 120, type: "numericColumn" },
        { field: "vessel_hght_m", headerName: "용기높이(M)", minWidth: 120, type: "numericColumn" },
        { field: "vessel_vol_cbm", headerName: "용기부피(CBM)", minWidth: 130, type: "numericColumn" },
        { field: "use_yn_cd", headerName: "사용여부", minWidth: 95, cellRenderer: "createStatusBadge", cellRendererParams: { trueLabel: "Y" } },
        { field: "prod_nm_cd", headerName: "제조자명", minWidth: 120 },
        { field: "regr_nm_cd", headerName: "등록자명", minWidth: 120 },
        { field: "reg_date", headerName: "등록일시", minWidth: 160, formatter: "datetime" },
        { field: "mdfr_nm_cd", headerName: "수정자명", minWidth: 120 },
        { field: "chgdt", headerName: "수정일시", minWidth: 160, formatter: "datetime" },
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
            { type: "edit",   eventName: "std-client-item-code-crud:edit",   dataKeys: { clientItemCodeData: nil } },
            { type: "delete", eventName: "std-client-item-code-crud:delete", dataKeys: { id: "id", itemCd: "item_cd||id" } }
          ] }
        }
      ]
    end

    def form_fields
      [
        { field: "item_cd", type: "input", label: "아이템코드", required: true, maxlength: 20, target: "fieldItemCd" },
        { field: "item_nm", type: "input", label: "아이템명", required: true, maxlength: 200, target: "fieldItemNm" },
        {
          field: "bzac_lookup",
          type: "popup",
          label: "거래처",
          popup_type: "client",
          code_field: "bzac_cd",
          required: true,
          target: "fieldBzacCd",
          placeholder: "거래처 선택"
        },
        {
          field: "goods_lookup",
          type: "popup",
          label: "품명코드",
          popup_type: "good",
          code_field: "goodsnm_cd",
          required: true,
          target: "fieldGoodsnmCd",
          placeholder: "품명코드 선택"
        },
        { field: "danger_yn_cd", type: "select", label: "위험물여부", options: yn_options, include_blank: false, required: true, target: "fieldDangerYnCd", span: middle_field_span, tom_select: false },
        { field: "png_yn_cd", type: "select", label: "포장여부", options: yn_options, include_blank: false, required: true, target: "fieldPngYnCd", span: middle_field_span, tom_select: false },
        { field: "mstair_lading_yn_cd", type: "select", label: "계단적재여부", options: yn_options, include_blank: false, required: true, target: "fieldMstairLadingYnCd", span: middle_field_span, tom_select: false },
        { field: "if_yn_cd", type: "select", label: "인터페이스여부", options: yn_options, include_blank: false, required: true, target: "fieldIfYnCd", span: middle_field_span, tom_select: false },
        { field: "wgt_unit_cd", type: "select", label: "중량단위코드", options: common_code_options(unit_code_for(:wgt)), include_blank: true, target: "fieldWgtUnitCd", span: middle_field_span, tom_select: false },
        { field: "qty_unit_cd", type: "select", label: "수량단위코드", options: common_code_options(unit_code_for(:qty)), include_blank: true, target: "fieldQtyUnitCd", span: middle_field_span, tom_select: false },
        { field: "tmpt_unit_cd", type: "select", label: "온도단위코드", options: common_code_options(unit_code_for(:tmpt)), include_blank: true, target: "fieldTmptUnitCd", span: middle_field_span, tom_select: false },
        { field: "vol_unit_cd", type: "select", label: "부피단위코드", options: common_code_options(unit_code_for(:vol)), include_blank: true, target: "fieldVolUnitCd", span: middle_field_span, tom_select: false },
        { field: "basis_unit_cd", type: "select", label: "기본단위코드", options: common_code_options(unit_code_for(:basis)), include_blank: true, target: "fieldBasisUnitCd", span: middle_field_span, tom_select: false },
        { field: "len_unit_cd", type: "select", label: "길이단위코드", options: common_code_options(unit_code_for(:len)), include_blank: true, target: "fieldLenUnitCd", span: middle_field_span, tom_select: false },
        { field: "pckg_qty", type: "number", label: "포장수량", step: "0.001", min: "0", target: "fieldPckgQty", span: middle_field_span },
        { field: "tot_wgt_kg", type: "number", label: "총중량(KG)", step: "0.001", min: "0", target: "fieldTotWgtKg", span: middle_field_span },
        { field: "net_wgt_kg", type: "number", label: "순중량(KG)", step: "0.001", min: "0", target: "fieldNetWgtKg", span: middle_field_span },
        { field: "vessel_tmpt_c", type: "number", label: "용기온도(C)", step: "0.001", target: "fieldVesselTmptC", span: middle_field_span },
        { field: "vessel_width_m", type: "number", label: "용기가로(M)", step: "0.001", min: "0", target: "fieldVesselWidthM", span: middle_field_span },
        { field: "vessel_vert_m", type: "number", label: "용기세로(M)", step: "0.001", min: "0", target: "fieldVesselVertM", span: middle_field_span },
        { field: "vessel_hght_m", type: "number", label: "용기높이(M)", step: "0.001", min: "0", target: "fieldVesselHghtM", span: middle_field_span },
        { field: "vessel_vol_cbm", type: "number", label: "용기부피(CBM)", step: "0.001", min: "0", target: "fieldVesselVolCbm", span: middle_field_span },
        { field: "use_yn_cd", type: "select", label: "사용여부", options: yn_options, include_blank: false, required: true, target: "fieldUseYnCd", span: middle_field_span, tom_select: false },
        { field: "prod_nm_cd", type: "input", label: "제조자명", required: true, maxlength: 100, target: "fieldProdNmCd", span: middle_field_span },
        { field: "regr_nm_cd", type: "input", label: "등록자명", disabled: true, target: "fieldRegrNmCd" },
        { field: "reg_date", type: "input", label: "등록일시", disabled: true, target: "fieldRegDate" },
        { field: "mdfr_nm_cd", type: "input", label: "수정자명", disabled: true, target: "fieldMdfrNmCd" },
        { field: "chgdt", type: "input", label: "수정일시", disabled: true, target: "fieldChgdt" }
      ]
    end

    def yn_options
      common_code_options("CMM_USE_YN")
    end

    def middle_field_span
      "24 s:12 m:8"
    end

    def unit_code_for(type)
      @unit_code_for ||= {
        wgt: resolved_unit_code("24", "STD_WGT_UNIT"),
        qty: resolved_unit_code("21", "STD_QTY_UNIT"),
        tmpt: resolved_unit_code("22", "STD_TMPT_UNIT"),
        vol: resolved_unit_code("23", "STD_VOL_UNIT"),
        basis: resolved_unit_code("20", "STD_BASIS_UNIT", require_alpha_value: true),
        len: resolved_unit_code("19", "STD_LEN_UNIT")
      }
      @unit_code_for.fetch(type)
    end

    def resolved_unit_code(primary_code, fallback_code, require_alpha_value: false)
      values = common_code_values(primary_code)

      if values.present?
        if require_alpha_value
          if values.any? { |value| value.to_s.match?(/[A-Z]/i) }
            primary_code
          else
            fallback_code
          end
        else
          primary_code
        end
      else
        fallback_code
      end
    end
end
