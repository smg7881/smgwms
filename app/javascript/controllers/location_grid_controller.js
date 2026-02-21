import BaseGridController from "controllers/base_grid_controller"
import { uuid, hideNoRowsOverlay } from "controllers/grid/grid_utils"

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
        workpl_cd: "", area_cd: "", zone_cd: "", loc_cd: "", loc_nm: "",
        loc_class_cd: "STORAGE", loc_type_cd: "NORMAL",
        width_len: null, vert_len: null, height_len: null,
        max_weight: null, max_cbm: null,
        has_stock: "N", use_yn: "Y"
      },
      blankCheckFields: ["loc_cd", "loc_nm"],
      comparableFields: ["loc_nm", "loc_class_cd", "loc_type_cd", "width_len", "vert_len", "height_len", "max_weight", "max_cbm", "use_yn"],
      firstEditCol: "loc_cd",
      pkLabels: { workpl_cd: "작업장코드", area_cd: "AREA코드", zone_cd: "ZONE코드", loc_cd: "로케이션코드" },
      onCellValueChanged: (event) => this.normalizeCodeField(event)
    }
  }

  addRow() {
    if (!this.manager?.api) return

    const workplCd = this.selectedWorkplaceCode()
    const areaCd = this.selectedAreaCode()
    const zoneCd = this.selectedZoneCode()

    if (!workplCd || !areaCd || !zoneCd) {
      alert("작업장, AREA, ZONE을 모두 선택해야 행추가할 수 있습니다.")
      return
    }

    const api = this.manager.api
    api.applyTransaction({
      add: [{
        workpl_cd: workplCd, area_cd: areaCd, zone_cd: zoneCd,
        loc_cd: "", loc_nm: "",
        loc_class_cd: "STORAGE", loc_type_cd: "NORMAL",
        width_len: null, vert_len: null, height_len: null,
        max_weight: null, max_cbm: null,
        has_stock: "N", use_yn: "Y",
        __is_new: true, __temp_id: uuid()
      }],
      addIndex: 0
    })
    hideNoRowsOverlay(api)
    api.startEditingCell({ rowIndex: 0, colKey: "loc_cd" })
  }

  beforeDeleteRows(selectedNodes) {
    const hasStockRows = selectedNodes.filter(
      (node) => (node?.data?.has_stock || "").toString().trim().toUpperCase() === "Y"
    )
    if (hasStockRows.length > 0) {
      alert(`재고가 있는 로케이션은 삭제할 수 없습니다. (${hasStockRows.length}건)`)
      return true
    }
    return false
  }

  normalizeCodeField(event) {
    const field = event?.colDef?.field
    if (!["workpl_cd", "area_cd", "zone_cd", "loc_cd", "loc_class_cd", "loc_type_cd", "use_yn", "has_stock"].includes(field)) return
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

  // --- 의존성 검색 필드 ---

  async bindSearchFields() {
    this.workplField = this.searchField("workpl_cd")
    this.areaField = this.searchField("area_cd")
    this.zoneField = this.searchField("zone_cd")

    if (this.workplField) {
      this._onWorkplChange = () => this.handleWorkplaceChange()
      this.workplField.addEventListener("change", this._onWorkplChange)
    }

    if (this.areaField) {
      this._onAreaChange = () => this.handleAreaChange()
      this.areaField.addEventListener("change", this._onAreaChange)
    }

    await this.hydrateDependentSelects()
  }

  unbindSearchFields() {
    if (this.workplField && this._onWorkplChange) {
      this.workplField.removeEventListener("change", this._onWorkplChange)
    }
    if (this.areaField && this._onAreaChange) {
      this.areaField.removeEventListener("change", this._onAreaChange)
    }
  }

  async hydrateDependentSelects() {
    const workplCd = this.selectedWorkplaceCode()
    const areaCd = this.selectedAreaCode()
    const zoneCd = this.selectedZoneCode()

    if (!workplCd) {
      this.clearSelect(this.areaField)
      this.clearSelect(this.zoneField)
      return
    }

    await this.loadAreaOptions(workplCd, areaCd)

    if (this.selectedAreaCode()) {
      await this.loadZoneOptions(workplCd, this.selectedAreaCode(), zoneCd)
    } else {
      this.clearSelect(this.zoneField)
    }
  }

  async handleWorkplaceChange() {
    const workplCd = this.selectedWorkplaceCode()
    this.clearSelect(this.areaField)
    this.clearSelect(this.zoneField)
    if (!workplCd) return

    await this.loadAreaOptions(workplCd, "")
  }

  async handleAreaChange() {
    const workplCd = this.selectedWorkplaceCode()
    const areaCd = this.selectedAreaCode()
    this.clearSelect(this.zoneField)
    if (!workplCd || !areaCd) return

    await this.loadZoneOptions(workplCd, areaCd, "")
  }

  async loadAreaOptions(workplCd, selectedAreaCd) {
    if (!this.hasAreasUrlValue || !this.areaField) return

    const query = new URLSearchParams({ workpl_cd: workplCd })
    try {
      const response = await fetch(`${this.areasUrlValue}?${query.toString()}`, { headers: { Accept: "application/json" } })
      if (!response.ok) throw new Error(`HTTP ${response.status}`)

      const rows = await response.json()
      const options = rows.map((row) => ({
        value: row.area_cd,
        label: `${row.area_cd} - ${row.area_nm || ""}`
      }))
      this.setSelectOptions(this.areaField, options, selectedAreaCd)
    } catch {
      alert("AREA 목록 조회에 실패했습니다.")
    }
  }

  async loadZoneOptions(workplCd, areaCd, selectedZoneCd) {
    if (!this.hasZonesUrlValue || !this.zoneField) return

    const query = new URLSearchParams({ workpl_cd: workplCd, area_cd: areaCd, use_yn: "Y" })
    try {
      const response = await fetch(`${this.zonesUrlValue}?${query.toString()}`, { headers: { Accept: "application/json" } })
      if (!response.ok) throw new Error(`HTTP ${response.status}`)

      const rows = await response.json()
      const options = rows.map((row) => ({
        value: row.zone_cd,
        label: `${row.zone_cd} - ${row.zone_nm || ""}`
      }))
      this.setSelectOptions(this.zoneField, options, selectedZoneCd)
    } catch {
      alert("ZONE 목록 조회에 실패했습니다.")
    }
  }

  setSelectOptions(selectEl, options, selectedValue = "") {
    if (!selectEl) return

    const normalized = (selectedValue || "").toString()
    const values = options.map((option) => option.value.toString())
    const canSelect = normalized && values.includes(normalized)

    selectEl.innerHTML = ""

    const blankOption = document.createElement("option")
    blankOption.value = ""
    blankOption.textContent = "전체"
    selectEl.appendChild(blankOption)

    options.forEach((option) => {
      const element = document.createElement("option")
      element.value = option.value
      element.textContent = option.label
      selectEl.appendChild(element)
    })

    selectEl.value = canSelect ? normalized : ""
  }

  clearSelect(selectEl) {
    if (!selectEl) return

    selectEl.innerHTML = ""
    const blankOption = document.createElement("option")
    blankOption.value = ""
    blankOption.textContent = "전체"
    selectEl.appendChild(blankOption)
    selectEl.value = ""
  }

  selectedWorkplaceCode() {
    return (this.workplField?.value || "").trim().toUpperCase()
  }

  selectedAreaCode() {
    return (this.areaField?.value || "").trim().toUpperCase()
  }

  selectedZoneCode() {
    return (this.zoneField?.value || "").trim().toUpperCase()
  }

  searchField(name) {
    return this.element.querySelector(`[name='q[${name}]']`)
  }
}
