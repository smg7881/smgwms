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
        { field: "danger_yn_cd", headerName: "위험물여부", minWidth: 110, cellRenderer: "codeUseYnCellRenderer" },
        { field: "png_yn_cd", headerName: "포장여부", minWidth: 95, cellRenderer: "codeUseYnCellRenderer" },
        { field: "mstair_lading_yn_cd", headerName: "계단적재여부", minWidth: 130, cellRenderer: "codeUseYnCellRenderer" },
        { field: "if_yn_cd", headerName: "인터페이스여부", minWidth: 130, cellRenderer: "codeUseYnCellRenderer" },
        { field: "wgt_unit_cd", headerName: "중량단위코드", minWidth: 125, refData: common_code_map("STD_WGT_UNIT") },
        { field: "qty_unit_cd", headerName: "수량단위코드", minWidth: 125, refData: common_code_map("STD_QTY_UNIT") },
        { field: "tmpt_unit_cd", headerName: "온도단위코드", minWidth: 125, refData: common_code_map("STD_TMPT_UNIT") },
        { field: "vol_unit_cd", headerName: "부피단위코드", minWidth: 125, refData: common_code_map("STD_VOL_UNIT") },
        { field: "basis_unit_cd", headerName: "기본단위코드", minWidth: 125, refData: common_code_map("STD_BASIS_UNIT") },
        { field: "len_unit_cd", headerName: "길이단위코드", minWidth: 125, refData: common_code_map("STD_LEN_UNIT") },
        { field: "pckg_qty", headerName: "포장수량", minWidth: 110, type: "numericColumn" },
        { field: "tot_wgt_kg", headerName: "총중량(KG)", minWidth: 120, type: "numericColumn" },
        { field: "net_wgt_kg", headerName: "순중량(KG)", minWidth: 120, type: "numericColumn" },
        { field: "vessel_tmpt_c", headerName: "용기온도(C)", minWidth: 120, type: "numericColumn" },
        { field: "vessel_width_m", headerName: "용기가로(M)", minWidth: 120, type: "numericColumn" },
        { field: "vessel_vert_m", headerName: "용기세로(M)", minWidth: 120, type: "numericColumn" },
        { field: "vessel_hght_m", headerName: "용기높이(M)", minWidth: 120, type: "numericColumn" },
        { field: "vessel_vol_cbm", headerName: "용기부피(CBM)", minWidth: 130, type: "numericColumn" },
        { field: "use_yn_cd", headerName: "사용여부", minWidth: 95, cellRenderer: "codeUseYnCellRenderer" },
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
        { field: "bzac_nm", type: "input", label: "거래처명", disabled: true, target: "fieldBzacNm" },
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
        { field: "goodsnm_nm", type: "input", label: "품명명", disabled: true, target: "fieldGoodsnmNm" },
        { field: "danger_yn_cd", type: "select", label: "위험물여부", options: yn_options, include_blank: false, required: true, target: "fieldDangerYnCd" },
        { field: "png_yn_cd", type: "select", label: "포장여부", options: yn_options, include_blank: false, required: true, target: "fieldPngYnCd" },
        { field: "mstair_lading_yn_cd", type: "select", label: "계단적재여부", options: yn_options, include_blank: false, required: true, target: "fieldMstairLadingYnCd" },
        { field: "if_yn_cd", type: "select", label: "인터페이스여부", options: yn_options, include_blank: false, required: true, target: "fieldIfYnCd" },
        { field: "wgt_unit_cd", type: "select", label: "중량단위코드", options: common_code_options("STD_WGT_UNIT"), include_blank: true, target: "fieldWgtUnitCd" },
        { field: "qty_unit_cd", type: "select", label: "수량단위코드", options: common_code_options("STD_QTY_UNIT"), include_blank: true, target: "fieldQtyUnitCd" },
        { field: "tmpt_unit_cd", type: "select", label: "온도단위코드", options: common_code_options("STD_TMPT_UNIT"), include_blank: true, target: "fieldTmptUnitCd" },
        { field: "vol_unit_cd", type: "select", label: "부피단위코드", options: common_code_options("STD_VOL_UNIT"), include_blank: true, target: "fieldVolUnitCd" },
        { field: "basis_unit_cd", type: "select", label: "기본단위코드", options: common_code_options("STD_BASIS_UNIT"), include_blank: true, target: "fieldBasisUnitCd" },
        { field: "len_unit_cd", type: "select", label: "길이단위코드", options: common_code_options("STD_LEN_UNIT"), include_blank: true, target: "fieldLenUnitCd" },
        { field: "pckg_qty", type: "number", label: "포장수량", step: "0.001", min: "0", target: "fieldPckgQty" },
        { field: "tot_wgt_kg", type: "number", label: "총중량(KG)", step: "0.001", min: "0", target: "fieldTotWgtKg" },
        { field: "net_wgt_kg", type: "number", label: "순중량(KG)", step: "0.001", min: "0", target: "fieldNetWgtKg" },
        { field: "vessel_tmpt_c", type: "number", label: "용기온도(C)", step: "0.001", target: "fieldVesselTmptC" },
        { field: "vessel_width_m", type: "number", label: "용기가로(M)", step: "0.001", min: "0", target: "fieldVesselWidthM" },
        { field: "vessel_vert_m", type: "number", label: "용기세로(M)", step: "0.001", min: "0", target: "fieldVesselVertM" },
        { field: "vessel_hght_m", type: "number", label: "용기높이(M)", step: "0.001", min: "0", target: "fieldVesselHghtM" },
        { field: "vessel_vol_cbm", type: "number", label: "용기부피(CBM)", step: "0.001", min: "0", target: "fieldVesselVolCbm" },
        { field: "use_yn_cd", type: "select", label: "사용여부", options: yn_options, include_blank: false, required: true, target: "fieldUseYnCd" },
        { field: "prod_nm_cd", type: "input", label: "제조자명", required: true, maxlength: 100, target: "fieldProdNmCd" },
        { field: "regr_nm_cd", type: "input", label: "등록자명", disabled: true, target: "fieldRegrNmCd" },
        { field: "reg_date", type: "input", label: "등록일시", disabled: true, target: "fieldRegDate" },
        { field: "mdfr_nm_cd", type: "input", label: "수정자명", disabled: true, target: "fieldMdfrNmCd" },
        { field: "chgdt", type: "input", label: "수정일시", disabled: true, target: "fieldChgdt" }
      ]
    end

    def yn_options
      common_code_options("CMM_USE_YN")
    end
end
