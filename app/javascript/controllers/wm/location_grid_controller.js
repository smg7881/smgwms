import BaseGridController from "controllers/base_grid_controller"
import { showAlert } from "components/ui/alert"
import { buildChainConfig, bindDependentSelects, unbindDependentSelects } from "controllers/grid/grid_dependent_select_utils"

export default class extends BaseGridController {
  static values = {
    ...BaseGridController.values,
    areasUrl: String,
    zonesUrl: String
  }

  connect() {
    super.connect()
    this.bindSearchFields()
  }

  disconnect() {
    this.unbindSearchFields()
    super.disconnect()
  }

  configureManager() {
    return {
      pkFields: ["workpl_cd", "area_cd", "zone_cd", "loc_cd"],
      fields: {
        workpl_cd: "trimUpper",
        area_cd: "trimUpper",
        zone_cd: "trimUpper",
        loc_cd: "trimUpper",
        loc_nm: "trim",
        loc_class_cd: "trimUpper",
        loc_type_cd: "trimUpper",
        width_len: "number",
        vert_len: "number",
        height_len: "number",
        max_weight: "number",
        max_cbm: "number",
        has_stock: "trimUpperDefault:N",
        use_yn: "trimUpperDefault:Y"
      },
      defaultRow: {
        workpl_cd: "",
        area_cd: "",
        zone_cd: "",
        loc_cd: "",
        loc_nm: "",
        loc_class_cd: "STORAGE",
        loc_type_cd: "NORMAL",
        width_len: null,
        vert_len: null,
        height_len: null,
        max_weight: null,
        max_cbm: null,
        has_stock: "N",
        use_yn: "Y"
      },
      blankCheckFields: ["loc_cd", "loc_nm"],
      comparableFields: [
        "loc_nm",
        "loc_class_cd",
        "loc_type_cd",
        "width_len",
        "vert_len",
        "height_len",
        "max_weight",
        "max_cbm",
        "use_yn"
      ],
      firstEditCol: "loc_cd",
      pkLabels: {
        workpl_cd: "작업장코드",
        area_cd: "AREA코드",
        zone_cd: "ZONE코드",
        loc_cd: "로케이션코드"
      },
    }
  }

  addRow(event) {
    if (event) event.preventDefault()

    const workplCd = this.getSearchFormValue("workpl_cd")
    const areaCd = this.getSearchFormValue("area_cd")
    const zoneCd = this.getSearchFormValue("zone_cd")

    if (!workplCd || !areaCd || !zoneCd) {
      showAlert("작업장, AREA, ZONE을 모두 선택해야 입력할 수 있습니다.")
      return
    }

    super.addRow({
      overrides: { workpl_cd: workplCd, area_cd: areaCd, zone_cd: zoneCd },
      config: { startCol: "loc_cd" }
    })
  }

  beforeDeleteRows(selectedNodes) {
    const hasStockRows = selectedNodes.filter(
      (node) => (node?.data?.has_stock || "").toString().trim().toUpperCase() === "Y"
    )

    if (hasStockRows.length > 0) {
      showAlert(`재고가 있는 로케이션은 삭제할 수 없습니다. (${hasStockRows.length}건)`)
      return true
    }

    return false
  }

  get saveMessage() {
    return "로케이션 데이터가 저장되었습니다."
  }

  async bindSearchFields() {
    await bindDependentSelects(this, buildChainConfig(this.#dependentSelectChain()))
  }

  unbindSearchFields() {
    unbindDependentSelects(this)
  }

  #dependentSelectChain() {
    return [
      {
        field: "workpl_cd",
        childField: "area_cd",
        url: this.areasUrlValue,
        params: (vals) => ({ workpl_cd: vals.workpl_cd }),
        valueField: "area_cd",
        labelFields: ["area_cd", "area_nm"],
        errorMessage: "AREA 목록 조회에 실패했습니다.",
      },
      {
        field: "area_cd",
        childField: "zone_cd",
        url: this.zonesUrlValue,
        params: (vals) => ({ workpl_cd: vals.workpl_cd, area_cd: vals.area_cd }),
        valueField: "zone_cd",
        labelFields: ["zone_cd", "zone_nm"],
        errorMessage: "ZONE 목록 조회에 실패했습니다.",
      }
    ]
  }
}
