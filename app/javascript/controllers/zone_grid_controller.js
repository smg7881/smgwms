import { Controller } from "@hotwired/stimulus"
import GridCrudManager from "controllers/grid/grid_crud_manager"
import { isApiAlive, postJson, hasChanges, hideNoRowsOverlay } from "controllers/grid/grid_utils"

export default class extends Controller {
  static targets = ["areaGrid", "zoneGrid", "selectedAreaLabel"]

  static values = {
    zonesUrl: String,
    batchUrl: String
  }

  connect() {
    this.selectedArea = null
    this.areaApi = null
    this.zoneApi = null
    this.areaGridController = null
    this.zoneGridController = null
    this.zoneManager = null
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
      this.zoneManager = new GridCrudManager({
        pkFields: ["workpl_cd", "area_cd", "zone_cd"],
        fields: {
          workpl_cd: "trimUpper",
          area_cd: "trimUpper",
          zone_cd: "trimUpper",
          zone_nm: "trim",
          zone_desc: "trim",
          use_yn: "trimUpperDefault:Y"
        },
        defaultRow: { workpl_cd: "", area_cd: "", zone_cd: "", zone_nm: "", zone_desc: "", use_yn: "Y" },
        blankCheckFields: ["zone_cd", "zone_nm"],
        comparableFields: ["zone_nm", "zone_desc", "use_yn"],
        firstEditCol: "zone_cd",
        pkLabels: { zone_cd: "Zone코드" }
      })
      this.zoneManager.attach(api)
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

    this.areaApi.addEventListener("rowClicked", this._onAreaRowClicked)
    this.areaApi.addEventListener("cellFocused", this._onAreaCellFocused)
    this.areaApi.addEventListener("rowDataUpdated", this._onAreaRowDataUpdated)
  }

  unbindGridEvents() {
    if (isApiAlive(this.areaApi) && this._onAreaRowClicked) {
      this.areaApi.removeEventListener("rowClicked", this._onAreaRowClicked)
    }
    if (isApiAlive(this.areaApi) && this._onAreaCellFocused) {
      this.areaApi.removeEventListener("cellFocused", this._onAreaCellFocused)
    }
    if (isApiAlive(this.areaApi) && this._onAreaRowDataUpdated) {
      this.areaApi.removeEventListener("rowDataUpdated", this._onAreaRowDataUpdated)
    }
  }

  disconnect() {
    this.unbindGridEvents()
    if (this.zoneManager) {
      this.zoneManager.detach()
      this.zoneManager = null
    }
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
    if (!isApiAlive(this.areaApi)) return

    const rowNode = this.areaApi.getDisplayedRowAtIndex(event.rowIndex)
    if (!rowNode?.data) return

    this.selectArea(rowNode.data)
  }

  handleAreaRowDataUpdated() {
    this.selectedArea = null
    this.refreshSelectedAreaLabel()
    this.clearZoneGrid()
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

    this.selectedArea = { workpl_cd: workplCd, area_cd: areaCd, area_nm: areaRow.area_nm }
    this.refreshSelectedAreaLabel()
    this.loadZoneRows()
  }

  async loadZoneRows() {
    if (!isApiAlive(this.zoneApi)) return
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
      if (!response.ok) throw new Error(`HTTP ${response.status}`)

      const rows = await response.json()
      if (!isApiAlive(this.zoneApi)) return

      this.zoneApi.setGridOption("rowData", rows)
      this.zoneManager.resetTracking()
      hideNoRowsOverlay(this.zoneApi)
    } catch {
      alert("보관 Zone 조회에 실패했습니다.")
    }
  }

  addZoneRow() {
    if (!this.zoneManager) return
    if (!this.selectedArea) {
      alert("좌측 목록에서 구역을 먼저 선택하세요.")
      return
    }

    this.zoneManager.addRow({
      workpl_cd: this.selectedArea.workpl_cd,
      area_cd: this.selectedArea.area_cd
    })
  }

  deleteZoneRows() {
    if (!this.zoneManager) return
    if (!this.selectedArea) {
      alert("좌측 목록에서 구역을 먼저 선택하세요.")
      return
    }

    this.zoneManager.deleteRows()
  }

  async saveZoneRows() {
    if (!this.zoneManager) return
    if (!this.selectedArea) {
      alert("좌측 목록에서 구역을 먼저 선택하세요.")
      return
    }

    this.zoneManager.stopEditing()
    const operations = this.zoneManager.buildOperations()
    if (!hasChanges(operations)) {
      alert("변경된 데이터가 없습니다.")
      return
    }

    const ok = await postJson(this.batchUrlValue, operations)
    if (!ok) return

    alert("보관존 데이터가 저장되었습니다.")
    this.loadZoneRows()
  }

  clearZoneGrid() {
    if (!isApiAlive(this.zoneApi)) return
    this.zoneApi.setGridOption("rowData", [])
    if (this.zoneManager) this.zoneManager.resetTracking()
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
}
