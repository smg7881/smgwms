import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["grid"]

  static values = {
    batchUrl: String,
    areasUrl: String,
    zonesUrl: String
  }

  connect() {
    this.deletedLocationKeys = []
    this.gridApi = null
    this.gridController = null
    this.originalMap = new Map()
    this.bindSearchFields()
  }

  registerGrid(event) {
    const { api, controller } = event.detail
    this.gridController = controller
    this.gridApi = api
    this.gridApi.addEventListener("cellValueChanged", this.handleCellValueChanged)
    this.gridApi.addEventListener("rowDataUpdated", this.handleRowDataUpdated)
  }

  disconnect() {
    if (this.isApiAlive(this.gridApi)) {
      this.gridApi.removeEventListener("cellValueChanged", this.handleCellValueChanged)
      this.gridApi.removeEventListener("rowDataUpdated", this.handleRowDataUpdated)
    }
    this.unbindSearchFields()
    this.gridApi = null
    this.gridController = null
    this.originalMap = null
  }

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
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`)
      }

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

    const query = new URLSearchParams({
      workpl_cd: workplCd,
      area_cd: areaCd,
      use_yn: "Y"
    })
    try {
      const response = await fetch(`${this.zonesUrlValue}?${query.toString()}`, { headers: { Accept: "application/json" } })
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`)
      }

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

    if (canSelect) {
      selectEl.value = normalized
    } else {
      selectEl.value = ""
    }
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

  addRow() {
    if (!this.isApiAlive(this.gridApi)) return

    const workplCd = this.selectedWorkplaceCode()
    const areaCd = this.selectedAreaCode()
    const zoneCd = this.selectedZoneCode()

    if (!workplCd || !areaCd || !zoneCd) {
      alert("작업장, AREA, ZONE을 모두 선택해야 행추가할 수 있습니다.")
      return
    }

    this.gridApi.applyTransaction({
      add: [
        {
          workpl_cd: workplCd,
          area_cd: areaCd,
          zone_cd: zoneCd,
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
          use_yn: "Y",
          __is_new: true,
          __temp_id: this.uuid()
        }
      ],
      addIndex: 0
    })
    this.hideNoRowsOverlay()
    this.gridApi.startEditingCell({ rowIndex: 0, colKey: "loc_cd" })
  }

  deleteRows() {
    if (!this.isApiAlive(this.gridApi)) return

    const selectedNodes = this.gridApi.getSelectedNodes()
    if (!selectedNodes.length) {
      alert("삭제할 행을 선택하세요.")
      return
    }

    const hasStockRows = selectedNodes.filter((node) => (node?.data?.has_stock || "").toString().trim().toUpperCase() === "Y")
    if (hasStockRows.length > 0) {
      alert(`재고가 있는 로케이션은 삭제할 수 없습니다. (${hasStockRows.length}건)`)
      return
    }

    const rowsToRemove = []
    const nodesToRefresh = []

    selectedNodes.forEach((node) => {
      const row = node.data
      if (!row) return

      if (row.__is_new) {
        rowsToRemove.push(row)
        return
      }

      const key = this.pickDeleteKey(row)
      if (key) this.deletedLocationKeys.push(key)
      row.__is_deleted = true
      delete row.__is_updated
      nodesToRefresh.push(node)
    })

    if (rowsToRemove.length > 0) {
      this.gridApi.applyTransaction({ remove: rowsToRemove })
    }
    if (nodesToRefresh.length > 0) {
      this.refreshStatusCells(nodesToRefresh)
    }
  }

  async saveRows() {
    if (!this.isApiAlive(this.gridApi)) return

    this.gridApi.stopEditing()
    const operations = this.buildOperations()
    if (!this.hasChanges(operations)) {
      alert("변경된 데이터가 없습니다.")
      return
    }

    const ok = await this.postJson(this.batchUrlValue, operations)
    if (!ok) return

    alert("로케이션 데이터가 저장되었습니다.")
    this.reloadRows()
  }

  reloadRows() {
    if (this.gridController?.refresh) {
      this.gridController.refresh()
    }
  }

  buildOperations() {
    const rows = this.collectRows()

    const rowsToInsert = rows
      .filter((row) => row.__is_new && !row.__is_deleted && !this.isBlankRow(row))
      .map((row) => this.pickFields(row))

    const rowsToUpdate = rows
      .filter((row) => !row.__is_new && !row.__is_deleted && this.rowChanged(row))
      .map((row) => this.pickFields(row))

    const deleteKeyMap = new Map()
    this.deletedLocationKeys.forEach((key) => {
      deleteKeyMap.set(this.serializeDeleteKey(key), key)
    })
    rows
      .filter((row) => row.__is_deleted)
      .map((row) => this.pickDeleteKey(row))
      .filter(Boolean)
      .forEach((key) => {
        deleteKeyMap.set(this.serializeDeleteKey(key), key)
      })

    return {
      rowsToInsert,
      rowsToUpdate,
      rowsToDelete: Array.from(deleteKeyMap.values())
    }
  }

  pickFields(row) {
    return {
      workpl_cd: (row.workpl_cd || "").trim().toUpperCase(),
      area_cd: (row.area_cd || "").trim().toUpperCase(),
      zone_cd: (row.zone_cd || "").trim().toUpperCase(),
      loc_cd: (row.loc_cd || "").trim().toUpperCase(),
      loc_nm: (row.loc_nm || "").trim(),
      loc_class_cd: (row.loc_class_cd || "").trim().toUpperCase(),
      loc_type_cd: (row.loc_type_cd || "").trim().toUpperCase(),
      width_len: this.numberOrNull(row.width_len),
      vert_len: this.numberOrNull(row.vert_len),
      height_len: this.numberOrNull(row.height_len),
      max_weight: this.numberOrNull(row.max_weight),
      max_cbm: this.numberOrNull(row.max_cbm),
      has_stock: (row.has_stock || "N").trim().toUpperCase(),
      use_yn: (row.use_yn || "Y").trim().toUpperCase()
    }
  }

  pickDeleteKey(row) {
    const workplCd = (row.workpl_cd || "").trim().toUpperCase()
    const areaCd = (row.area_cd || "").trim().toUpperCase()
    const zoneCd = (row.zone_cd || "").trim().toUpperCase()
    const locCd = (row.loc_cd || "").trim().toUpperCase()
    if (!workplCd || !areaCd || !zoneCd || !locCd) return null

    return { workpl_cd: workplCd, area_cd: areaCd, zone_cd: zoneCd, loc_cd: locCd }
  }

  serializeDeleteKey(key) {
    return `${key.workpl_cd}::${key.area_cd}::${key.zone_cd}::${key.loc_cd}`
  }

  collectRows() {
    if (!this.isApiAlive(this.gridApi)) return []

    const rows = []
    this.gridApi.forEachNode((node) => {
      if (node.data) rows.push(node.data)
    })
    return rows
  }

  rowChanged(row) {
    const original = this.originalMap.get(this.rowKey(row))
    if (!original) return true

    const fields = [
      "loc_nm",
      "loc_class_cd",
      "loc_type_cd",
      "width_len",
      "vert_len",
      "height_len",
      "max_weight",
      "max_cbm",
      "use_yn"
    ]

    return fields.some((field) => this.normalizeForCompare(row[field]) !== this.normalizeForCompare(original[field]))
  }

  resetTracking() {
    this.deletedLocationKeys = []
    this.originalMap = new Map()

    this.collectRows().forEach((row) => {
      if (row.__is_new) {
        delete row.__is_updated
        delete row.__is_deleted
        return
      }

      const key = this.rowKey(row)
      if (key) this.originalMap.set(key, { ...row })
      delete row.__is_new
      delete row.__is_updated
      delete row.__is_deleted
      delete row.__temp_id
    })
  }

  handleRowDataUpdated = () => {
    this.resetTracking()
  }

  handleCellValueChanged = (event) => {
    if (this.preventInvalidPrimaryKeyEdit(event)) return
    this.normalizeCodeField(event)
    this.markRowUpdated(event)
  }

  preventInvalidPrimaryKeyEdit(event) {
    const field = event?.colDef?.field
    if (!["workpl_cd", "area_cd", "zone_cd", "loc_cd"].includes(field)) return false
    if (!event?.node?.data) return false

    const row = event.node.data
    if (row.__is_new) return false

    row[field] = event.oldValue || ""
    this.gridApi.refreshCells({
      rowNodes: [event.node],
      columns: [field],
      force: true
    })
    alert("기존 키 컬럼은 수정할 수 없습니다.")
    return true
  }

  normalizeCodeField(event) {
    const field = event?.colDef?.field
    if (!["workpl_cd", "area_cd", "zone_cd", "loc_cd", "loc_class_cd", "loc_type_cd", "use_yn", "has_stock"].includes(field)) return
    if (!event?.node?.data) return

    const row = event.node.data
    row[field] = (row[field] || "").toString().trim().toUpperCase()
    this.gridApi.refreshCells({
      rowNodes: [event.node],
      columns: [field],
      force: true
    })
  }

  markRowUpdated(event) {
    if (!event?.node?.data) return
    if (event.colDef?.field === "__row_status") return
    if (event.newValue === event.oldValue) return

    const row = event.node.data
    if (row.__is_new || row.__is_deleted) return

    row.__is_updated = true
    this.refreshStatusCells([event.node])
  }

  refreshStatusCells(rowNodes) {
    this.gridApi.refreshCells({
      rowNodes,
      columns: ["__row_status"],
      force: true
    })
  }

  hasChanges(operations) {
    return (
      operations.rowsToInsert.length > 0 ||
      operations.rowsToUpdate.length > 0 ||
      operations.rowsToDelete.length > 0
    )
  }

  isBlankRow(row) {
    return (
      (row.loc_cd || "").trim() === "" &&
      (row.loc_nm || "").trim() === ""
    )
  }

  normalizeForCompare(value) {
    if (value == null) return ""
    return value.toString().trim()
  }

  numberOrNull(value) {
    if (value == null || value === "") return null

    const numeric = Number(value)
    if (Number.isNaN(numeric)) return null
    return numeric
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

  rowKey(row) {
    const workplCd = (row.workpl_cd || "").trim().toUpperCase()
    const areaCd = (row.area_cd || "").trim().toUpperCase()
    const zoneCd = (row.zone_cd || "").trim().toUpperCase()
    const locCd = (row.loc_cd || "").trim().toUpperCase()
    if (!workplCd || !areaCd || !zoneCd || !locCd) return null

    return `${workplCd}::${areaCd}::${zoneCd}::${locCd}`
  }

  hideNoRowsOverlay() {
    if (!this.isApiAlive(this.gridApi)) return

    const rowCount = this.gridApi.getDisplayedRowCount?.() || 0
    if (rowCount > 0) {
      this.gridApi.hideOverlay?.()
    }
  }

  async postJson(url, body) {
    try {
      const response = await fetch(url, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfToken
        },
        body: JSON.stringify(body)
      })

      const result = await response.json()
      if (!response.ok || !result.success) {
        alert("저장 실패: " + (result.errors || ["요청 처리 실패"]).join(", "))
        return false
      }

      return true
    } catch {
      alert("저장 실패: 네트워크 오류")
      return false
    }
  }

  get csrfToken() {
    return document.querySelector("[name='csrf-token']")?.content || ""
  }

  uuid() {
    return `${Date.now()}_${Math.random().toString(36).slice(2, 8)}`
  }

  isApiAlive(api) {
    return Boolean(api) && !(typeof api.isDestroyed === "function" && api.isDestroyed())
  }
}
