import BaseGridController from "controllers/base_grid_controller"
import { showAlert } from "components/ui/alert"
import { setSelectOptions as setSelectOptionsUtil, clearSelectOptions } from "controllers/grid/grid_select_utils"
import { bindDependentSelects, unbindDependentSelects, loadSelectOptions } from "controllers/grid/grid_dependent_select_utils"

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
      onCellValueChanged: (event) => this.normalizeCodeField(event)
    }
  }

  addRow() {
    if (!this.manager?.api) return

    const workplCd = this.workplKeywordFromSearch()
    const areaCd = this.areaKeywordFromSearch()
    const zoneCd = this.zoneKeywordFromSearch()

    if (!workplCd || !areaCd || !zoneCd) {
      showAlert("작업장, AREA, ZONE을 모두 선택해야 입력할 수 있습니다.")
      return
    }

    super.addRow()
  }

  buildNewRowOverrides() {
    return {
      workpl_cd: this.workplKeywordFromSearch(),
      area_cd: this.areaKeywordFromSearch(),
      zone_cd: this.zoneKeywordFromSearch()
    }
  }

  buildAddRowConfig() {
    return { startCol: "loc_cd" }
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

  normalizeCodeField(event) {
    const field = event?.colDef?.field
    const codeFields = ["workpl_cd", "area_cd", "zone_cd", "loc_cd", "loc_class_cd", "loc_type_cd", "use_yn", "has_stock"]
    if (!codeFields.includes(field)) return
    if (!event?.node?.data) return

    const row = event.node.data
    row[field] = (row[field] || "").toString().trim().toUpperCase()
    this.manager.api.refreshCells({
      rowNodes: [event.node],
      columns: [field],
      force: true
    })
  }

  get saveMessage() {
    return "로케이션 데이터가 저장되었습니다."
  }

  async bindSearchFields() {
    await bindDependentSelects(this, this.#dependentSelectConfig())
  }

  unbindSearchFields() {
    unbindDependentSelects(this)
  }

  async loadAreaOptions(workplCd, selectedAreaCd) {
    if (!this.hasAreasUrlValue) return
    const areaField = this.getSearchFieldElement("area_cd")
    if (!areaField) return

    const rows = await loadSelectOptions(
      this,
      this.areasUrlValue,
      { workpl_cd: workplCd },
      "AREA 목록 조회에 실패했습니다."
    )
    if (!rows) return

    const options = rows.map((row) => ({
      value: row.area_cd,
      label: `${row.area_cd} - ${row.area_nm || ""}`
    }))

    setSelectOptionsUtil(areaField, options, selectedAreaCd)
  }

  async loadZoneOptions(workplCd, areaCd, selectedZoneCd) {
    if (!this.hasZonesUrlValue) return
    const zoneField = this.getSearchFieldElement("zone_cd")
    if (!zoneField) return

    const rows = await loadSelectOptions(
      this,
      this.zonesUrlValue,
      { workpl_cd: workplCd, area_cd: areaCd, use_yn: "Y" },
      "ZONE 목록 조회에 실패했습니다."
    )
    if (!rows) return

    const options = rows.map((row) => ({
      value: row.zone_cd,
      label: `${row.zone_cd} - ${row.zone_nm || ""}`
    }))

    setSelectOptionsUtil(zoneField, options, selectedZoneCd)
  }

  workplKeywordFromSearch() {
    return this.getSearchFormValue("workpl_cd")
  }

  areaKeywordFromSearch() {
    return this.getSearchFormValue("area_cd")
  }

  zoneKeywordFromSearch() {
    return this.getSearchFormValue("zone_cd")
  }

  #dependentSelectConfig() {
    return {
      fields: ["workpl_cd", "area_cd", "zone_cd"],
      onChange: [
        async (controller, fields) => {
          const workplCd = controller.workplKeywordFromSearch()
          clearSelectOptions(fields[1])
          clearSelectOptions(fields[2])
          if (!workplCd) return
          await controller.loadAreaOptions(workplCd, "")
        },
        async (controller, fields) => {
          const workplCd = controller.workplKeywordFromSearch()
          const areaCd = controller.areaKeywordFromSearch()
          clearSelectOptions(fields[2])
          if (!workplCd || !areaCd) return
          await controller.loadZoneOptions(workplCd, areaCd, "")
        }
      ],
      hydrate: async (controller, fields) => {
        const workplCd = controller.workplKeywordFromSearch()
        const areaCd = controller.areaKeywordFromSearch()
        const zoneCd = controller.zoneKeywordFromSearch()

        if (!workplCd) {
          clearSelectOptions(fields[1])
          clearSelectOptions(fields[2])
          return
        }

        await controller.loadAreaOptions(workplCd, areaCd)

        if (controller.areaKeywordFromSearch()) {
          await controller.loadZoneOptions(workplCd, controller.areaKeywordFromSearch(), zoneCd)
        } else {
          clearSelectOptions(fields[2])
        }
      }
    }
  }
}
