import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["areaGrid", "zoneGrid", "selectedAreaLabel"]

  static values = {
    zonesUrl: String,
    batchUrl: String
  }

  connect() {
    this.selectedArea = null
    this.deletedZoneKeys = []
    this.zoneOriginalMap = new Map()
    this.areaApi = null
    this.zoneApi = null
    this.areaGridController = null
    this.zoneGridController = null
  }

  registerGrid(event) {
    const gridElement = event.target.closest("[data-controller='ag-grid']")
    if (!gridElement) return

    const { api, controller } = event.detail

    if (gridElement === this.areaGridTarget) {
      this.areaApi = api
      this.areaGridController = controller
    } else if (gridElement === this.zoneGridTarget) {
      this.zoneApi = api
      this.zoneGridController = controller
    }

    if (this.areaApi && this.zoneApi) {
      this.bindGridEvents()
      this.refreshSelectedAreaLabel()
    }
  }

  bindGridEvents() {
    this.unbindGridEvents()

    this._onAreaRowClicked = (event) => this.handleAreaRowClicked(event)
    this._onAreaCellFocused = (event) => this.handleAreaCellFocused(event)
    this._onAreaRowDataUpdated = () => this.handleAreaRowDataUpdated()
    this._onZoneCellValueChanged = (event) => this.handleZoneCellValueChanged(event)
    this._onZoneRowDataUpdated = () => this.handleZoneRowDataUpdated()

    this.areaApi.addEventListener("rowClicked", this._onAreaRowClicked)
    this.areaApi.addEventListener("cellFocused", this._onAreaCellFocused)
    this.areaApi.addEventListener("rowDataUpdated", this._onAreaRowDataUpdated)
    this.zoneApi.addEventListener("cellValueChanged", this._onZoneCellValueChanged)
    this.zoneApi.addEventListener("rowDataUpdated", this._onZoneRowDataUpdated)
  }

  unbindGridEvents() {
    if (this.isApiAlive(this.areaApi) && this._onAreaRowClicked) {
      this.areaApi.removeEventListener("rowClicked", this._onAreaRowClicked)
    }
    if (this.isApiAlive(this.areaApi) && this._onAreaCellFocused) {
      this.areaApi.removeEventListener("cellFocused", this._onAreaCellFocused)
    }
    if (this.isApiAlive(this.areaApi) && this._onAreaRowDataUpdated) {
      this.areaApi.removeEventListener("rowDataUpdated", this._onAreaRowDataUpdated)
    }
    if (this.isApiAlive(this.zoneApi) && this._onZoneCellValueChanged) {
      this.zoneApi.removeEventListener("cellValueChanged", this._onZoneCellValueChanged)
    }
    if (this.isApiAlive(this.zoneApi) && this._onZoneRowDataUpdated) {
      this.zoneApi.removeEventListener("rowDataUpdated", this._onZoneRowDataUpdated)
    }
  }

  disconnect() {
    this.unbindGridEvents()
    this.selectedArea = null
    this.areaApi = null
    this.zoneApi = null
    this.areaGridController = null
    this.zoneGridController = null
  }

  handleAreaRowClicked(event) {
    this.selectArea(event?.data)
  }

  handleAreaCellFocused(event) {
    if (event.rowIndex == null || event.rowIndex < 0) return
    if (!this.isApiAlive(this.areaApi)) return

    const rowNode = this.areaApi.getDisplayedRowAtIndex(event.rowIndex)
    if (!rowNode?.data) return

    this.selectArea(rowNode.data)
  }

  handleAreaRowDataUpdated() {
    this.selectedArea = null
    this.refreshSelectedAreaLabel()
    this.clearZoneGrid()
  }

  handleZoneRowDataUpdated() {
    this.resetZoneTracking()
  }

  selectArea(areaRow) {
    const workplCd = areaRow?.workpl_cd
    const areaCd = areaRow?.area_cd
    if (!workplCd || !areaCd) {
      this.selectedArea = null
      this.refreshSelectedAreaLabel()
      this.clearZoneGrid()
      return
    }

    const nextKey = `${workplCd}::${areaCd}`
    const currentKey = this.selectedArea ? `${this.selectedArea.workpl_cd}::${this.selectedArea.area_cd}` : ""
    if (nextKey === currentKey) return

    this.selectedArea = {
      workpl_cd: workplCd,
      area_cd: areaCd,
      area_nm: areaRow.area_nm
    }
    this.refreshSelectedAreaLabel()
    this.loadZoneRows()
  }

  async loadZoneRows() {
    if (!this.isApiAlive(this.zoneApi)) return
    if (!this.selectedArea) {
      this.clearZoneGrid()
      return
    }

    const query = new URLSearchParams({
      workpl_cd: this.selectedArea.workpl_cd,
      area_cd: this.selectedArea.area_cd
    })

    const zoneKeyword = this.zoneKeywordFromSearch()
    if (zoneKeyword) query.set("zone_cd", zoneKeyword)

    const useYn = this.useYnFromSearch()
    if (useYn) query.set("use_yn", useYn)

    try {
      const response = await fetch(`${this.zonesUrlValue}?${query.toString()}`, { headers: { Accept: "application/json" } })
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`)
      }

      const rows = await response.json()
      if (!this.isApiAlive(this.zoneApi)) return

      this.zoneApi.setGridOption("rowData", rows)
      this.resetZoneTracking()
      this.hideNoRowsOverlay()
    } catch {
      alert("보관 Zone 조회에 실패했습니다.")
    }
  }

  addZoneRow() {
    if (!this.isApiAlive(this.zoneApi)) return
    if (!this.selectedArea) {
      alert("좌측 목록에서 구역을 먼저 선택하세요.")
      return
    }

    this.zoneApi.applyTransaction({
      add: [
        {
          workpl_cd: this.selectedArea.workpl_cd,
          area_cd: this.selectedArea.area_cd,
          zone_cd: "",
          zone_nm: "",
          zone_desc: "",
          use_yn: "Y",
          __is_new: true,
          __temp_id: this.uuid()
        }
      ],
      addIndex: 0
    })
    this.hideNoRowsOverlay()
    this.zoneApi.startEditingCell({ rowIndex: 0, colKey: "zone_cd" })
  }

  deleteZoneRows() {
    if (!this.isApiAlive(this.zoneApi)) return
    if (!this.selectedArea) {
      alert("좌측 목록에서 구역을 먼저 선택하세요.")
      return
    }

    const selectedNodes = this.zoneApi.getSelectedNodes()
    if (!selectedNodes.length) {
      alert("삭제할 행을 선택하세요.")
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
      if (key) this.deletedZoneKeys.push(key)
      row.__is_deleted = true
      delete row.__is_updated
      nodesToRefresh.push(node)
    })

    if (rowsToRemove.length > 0) {
      this.zoneApi.applyTransaction({ remove: rowsToRemove })
    }
    if (nodesToRefresh.length > 0) {
      this.refreshStatusCells(nodesToRefresh)
    }
  }

  async saveZoneRows() {
    if (!this.isApiAlive(this.zoneApi)) return
    if (!this.selectedArea) {
      alert("좌측 목록에서 구역을 먼저 선택하세요.")
      return
    }

    this.zoneApi.stopEditing()
    const operations = this.buildOperations()
    if (!this.hasChanges(operations)) {
      alert("변경된 데이터가 없습니다.")
      return
    }

    const ok = await this.postJson(this.batchUrlValue, operations)
    if (!ok) return

    alert("보관존 데이터가 저장되었습니다.")
    this.loadZoneRows()
  }

  buildOperations() {
    const rows = this.collectZoneRows()

    const rowsToInsert = rows
      .filter((row) => row.__is_new && !row.__is_deleted && !this.isBlankRow(row))
      .map((row) => this.pickFields(row))

    const rowsToUpdate = rows
      .filter((row) => !row.__is_new && !row.__is_deleted && this.zoneRowChanged(row))
      .map((row) => this.pickFields(row))

    const deleteKeyMap = new Map()
    this.deletedZoneKeys.forEach((key) => deleteKeyMap.set(this.serializeDeleteKey(key), key))
    rows
      .filter((row) => row.__is_deleted)
      .map((row) => this.pickDeleteKey(row))
      .filter(Boolean)
      .forEach((key) => deleteKeyMap.set(this.serializeDeleteKey(key), key))

    return {
      rowsToInsert,
      rowsToUpdate,
      rowsToDelete: Array.from(deleteKeyMap.values())
    }
  }

  collectZoneRows() {
    if (!this.isApiAlive(this.zoneApi)) return []

    const rows = []
    this.zoneApi.forEachNode((node) => {
      if (node.data) rows.push(node.data)
    })
    return rows
  }

  pickFields(row) {
    return {
      workpl_cd: (row.workpl_cd || "").trim().toUpperCase(),
      area_cd: (row.area_cd || "").trim().toUpperCase(),
      zone_cd: (row.zone_cd || "").trim().toUpperCase(),
      zone_nm: (row.zone_nm || "").trim(),
      zone_desc: (row.zone_desc || "").trim(),
      use_yn: (row.use_yn || "Y").trim().toUpperCase()
    }
  }

  pickDeleteKey(row) {
    const workplCd = (row.workpl_cd || "").trim().toUpperCase()
    const areaCd = (row.area_cd || "").trim().toUpperCase()
    const zoneCd = (row.zone_cd || "").trim().toUpperCase()
    if (!workplCd || !areaCd || !zoneCd) return null

    return { workpl_cd: workplCd, area_cd: areaCd, zone_cd: zoneCd }
  }

  serializeDeleteKey(key) {
    return `${key.workpl_cd}::${key.area_cd}::${key.zone_cd}`
  }

  zoneRowChanged(row) {
    const original = this.zoneOriginalMap.get(this.rowKey(row))
    if (!original) return true

    return (
      (row.zone_nm || "") !== (original.zone_nm || "") ||
      (row.zone_desc || "") !== (original.zone_desc || "") ||
      (row.use_yn || "") !== (original.use_yn || "")
    )
  }

  resetZoneTracking() {
    this.deletedZoneKeys = []
    this.zoneOriginalMap = new Map()

    this.collectZoneRows().forEach((row) => {
      if (row.__is_new) {
        delete row.__is_updated
        delete row.__is_deleted
        return
      }

      const key = this.rowKey(row)
      if (key) this.zoneOriginalMap.set(key, { ...row })
      delete row.__is_new
      delete row.__is_updated
      delete row.__is_deleted
      delete row.__temp_id
    })
  }

  handleZoneCellValueChanged(event) {
    if (this.preventInvalidZoneCodeEdit(event)) return
    this.markRowUpdated(event)
  }

  preventInvalidZoneCodeEdit(event) {
    if (event?.colDef?.field !== "zone_cd") return false
    if (!event?.node?.data) return false

    const row = event.node.data
    row.zone_cd = (row.zone_cd || "").trim().toUpperCase()

    if (row.__is_new) {
      this.zoneApi.refreshCells({
        rowNodes: [event.node],
        columns: ["zone_cd"],
        force: true
      })
      return false
    }

    row.zone_cd = event.oldValue || ""
    this.zoneApi.refreshCells({
      rowNodes: [event.node],
      columns: ["zone_cd"],
      force: true
    })
    alert("기존 Zone코드는 수정할 수 없습니다.")
    return true
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
    this.zoneApi.refreshCells({
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
      (row.zone_cd || "").trim() === "" &&
      (row.zone_nm || "").trim() === ""
    )
  }

  clearZoneGrid() {
    if (!this.isApiAlive(this.zoneApi)) return

    this.zoneApi.setGridOption("rowData", [])
    this.resetZoneTracking()
  }

  refreshSelectedAreaLabel() {
    if (!this.hasSelectedAreaLabelTarget) return

    if (!this.selectedArea) {
      this.selectedAreaLabelTarget.textContent = "구역을 먼저 선택하세요."
      return
    }

    this.selectedAreaLabelTarget.textContent = `선택 구역: ${this.selectedArea.area_cd} / ${this.selectedArea.area_nm || ""}`
  }

  zoneKeywordFromSearch() {
    const field = this.element.querySelector("[name='q[zone_cd]']")
    return (field?.value || "").trim()
  }

  useYnFromSearch() {
    const field = this.element.querySelector("[name='q[use_yn]']")
    return (field?.value || "").trim().toUpperCase()
  }

  rowKey(row) {
    const workplCd = (row.workpl_cd || "").trim().toUpperCase()
    const areaCd = (row.area_cd || "").trim().toUpperCase()
    const zoneCd = (row.zone_cd || "").trim().toUpperCase()
    if (!workplCd || !areaCd || !zoneCd) return null

    return `${workplCd}::${areaCd}::${zoneCd}`
  }

  hideNoRowsOverlay() {
    if (!this.isApiAlive(this.zoneApi)) return

    const rowCount = this.zoneApi.getDisplayedRowCount?.() || 0
    if (rowCount > 0) {
      this.zoneApi.hideOverlay?.()
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
