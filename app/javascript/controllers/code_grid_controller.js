import BaseGridController from "controllers/base_grid_controller"
import GridCrudManager from "controllers/grid/grid_crud_manager"
import { isApiAlive, postJson, hasChanges } from "controllers/grid/grid_utils"

export default class extends BaseGridController {
  static targets = [...BaseGridController.targets, "masterGrid", "detailGrid", "selectedCodeLabel"]

  static values = {
    ...BaseGridController.values,
    masterBatchUrl: String,
    detailBatchUrlTemplate: String,
    detailListUrlTemplate: String,
    selectedCode: String
  }

  connect() {
    super.connect()
    this.initialMasterSyncDone = false
    this.detailGridController = null
    this.detailManager = null
  }

  configureManager() {
    return {
      pkFields: ["code"],
      fields: {
        code: "trim",
        code_name: "trim",
        use_yn: "trimUpperDefault:Y"
      },
      defaultRow: { code: "", code_name: "", use_yn: "Y" },
      blankCheckFields: ["code", "code_name"],
      comparableFields: ["code_name", "use_yn"],
      firstEditCol: "code",
      pkLabels: { code: "코드" },
      onRowDataUpdated: () => {
        this.detailManager?.resetTracking()
        if (!this.initialMasterSyncDone) {
          this.initialMasterSyncDone = true
          this.syncMasterSelectionAfterLoad()
        }
      }
    }
  }

  configureDetailManager() {
    return {
      pkFields: ["detail_code"],
      fields: {
        detail_code: "trim",
        detail_code_name: "trim",
        short_name: "trim",
        ref_code: "trim",
        sort_order: "number",
        use_yn: "trimUpperDefault:Y"
      },
      defaultRow: { code: "", detail_code: "", detail_code_name: "", short_name: "", ref_code: "", sort_order: 0, use_yn: "Y" },
      blankCheckFields: ["detail_code", "detail_code_name"],
      comparableFields: ["detail_code_name", "short_name", "ref_code", "sort_order", "use_yn"],
      firstEditCol: "detail_code",
      pkLabels: { detail_code: "상세코드" }
    }
  }

  registerGrid(event) {
    const gridElement = event.target.closest("[data-controller='ag-grid']")
    if (!gridElement) return

    if (gridElement === this.masterGridTarget) {
      super.registerGrid(event)
    } else if (gridElement === this.detailGridTarget) {
      const { api, controller } = event.detail
      this.detailGridController = controller
      this.detailManager = new GridCrudManager(this.configureDetailManager())
      this.detailManager.attach(api)
    }

    if (this.manager?.api && this.detailManager?.api) {
      this.bindMasterGridEvents()
    }
  }

  disconnect() {
    this.unbindMasterGridEvents()
    if (this.detailManager) {
      this.detailManager.detach()
      this.detailManager = null
    }
    this.detailGridController = null
    super.disconnect()
  }

  // --- 마스터 그리드 이벤트 ---

  bindMasterGridEvents() {
    this.manager.api.addEventListener("rowClicked", this.handleMasterRowClicked)
    this.manager.api.addEventListener("cellFocused", this.handleMasterCellFocused)
  }

  unbindMasterGridEvents() {
    if (isApiAlive(this.manager?.api)) {
      this.manager.api.removeEventListener("rowClicked", this.handleMasterRowClicked)
      this.manager.api.removeEventListener("cellFocused", this.handleMasterCellFocused)
    }
  }

  handleMasterRowClicked = async (event) => {
    await this.handleMasterRowChange(event.data)
  }

  handleMasterCellFocused = async (event) => {
    if (event.rowIndex == null || event.rowIndex < 0) return
    if (!isApiAlive(this.manager?.api)) return

    const rowNode = this.manager.api.getDisplayedRowAtIndex(event.rowIndex)
    if (!rowNode?.data) return

    await this.handleMasterRowChange(rowNode.data)
  }

  async handleMasterRowChange(rowData) {
    if (!isApiAlive(this.detailManager?.api)) return

    const code = rowData?.code
    if (!code || rowData?.__is_deleted) {
      this.selectedCodeValue = ""
      this.refreshSelectedCodeLabel()
      this.detailManager.api.setGridOption("rowData", [])
      this.detailManager.resetTracking()
      return
    }

    if (rowData?.__is_new) {
      this.selectedCodeValue = code
      this.refreshSelectedCodeLabel()
      this.detailManager.api.setGridOption("rowData", [])
      this.detailManager.resetTracking()
      return
    }

    this.selectedCodeValue = code
    this.refreshSelectedCodeLabel()
    await this.loadDetailRows(code)
  }

  // --- 마스터 CRUD ---

  addMasterRow() {
    if (!this.manager) return

    const txResult = this.manager.addRow()
    const addedNode = txResult?.add?.[0]
    if (addedNode?.data) {
      this.handleMasterRowChange(addedNode.data)
    }
  }

  deleteMasterRows() {
    if (!this.manager) return
    this.manager.deleteRows()
  }

  async saveMasterRows() {
    if (!this.manager) return

    this.manager.stopEditing()
    const operations = this.manager.buildOperations()
    if (!hasChanges(operations)) {
      alert("변경된 데이터가 없습니다.")
      return
    }

    const ok = await postJson(this.masterBatchUrlValue, operations)
    if (!ok) return

    alert("코드 저장이 완료되었습니다.")
    await this.reloadMasterRows()
  }

  async reloadMasterRows() {
    if (!isApiAlive(this.manager?.api)) return

    const response = await fetch(this.gridController.urlValue, { headers: { Accept: "application/json" } })
    const data = await response.json()
    this.manager.api.setGridOption("rowData", data)
    this.manager.resetTracking()
    await this.syncMasterSelectionAfterLoad()
  }

  async syncMasterSelectionAfterLoad() {
    if (!isApiAlive(this.manager?.api) || !isApiAlive(this.detailManager?.api)) return

    const firstRowNode = this.manager.api.getDisplayedRowAtIndex(0)

    if (!firstRowNode?.data) {
      this.selectedCodeValue = ""
      this.refreshSelectedCodeLabel()
      this.detailManager.api.setGridOption("rowData", [])
      this.detailManager.resetTracking()
      return
    }

    const firstCol = this.manager.api.getAllDisplayedColumns()?.[0]
    if (firstCol) {
      this.manager.api.setFocusedCell(0, firstCol.getColId())
    }

    await this.handleMasterRowChange(firstRowNode.data)
  }

  // --- 디테일 CRUD ---

  addDetailRow() {
    if (!this.detailManager) return
    if (this.blockDetailActionIfMasterChanged()) return

    if (!this.selectedCodeValue) {
      alert("코드를 먼저 선택하세요.")
      return
    }

    this.detailManager.addRow({ code: this.selectedCodeValue })
  }

  deleteDetailRows() {
    if (!this.detailManager) return
    if (this.blockDetailActionIfMasterChanged()) return
    this.detailManager.deleteRows()
  }

  async saveDetailRows() {
    if (!this.detailManager) return
    if (this.blockDetailActionIfMasterChanged()) return

    if (!this.selectedCodeValue) {
      alert("코드를 먼저 선택하세요.")
      return
    }

    this.detailManager.stopEditing()
    const operations = this.detailManager.buildOperations()
    if (!hasChanges(operations)) {
      alert("변경된 데이터가 없습니다.")
      return
    }

    const batchUrl = this.detailBatchUrlTemplateValue.replace(":code", encodeURIComponent(this.selectedCodeValue))
    const ok = await postJson(batchUrl, operations)
    if (!ok) return

    alert("상세코드 저장이 완료되었습니다.")
    await this.loadDetailRows(this.selectedCodeValue)
  }

  async loadDetailRows(code) {
    if (!isApiAlive(this.detailManager?.api)) return

    if (!code) {
      this.detailManager.api.setGridOption("rowData", [])
      this.detailManager.resetTracking()
      return
    }

    const url = this.detailListUrlTemplateValue.replace(":code", encodeURIComponent(code))
    const response = await fetch(url, { headers: { Accept: "application/json" } })
    if (!response.ok) {
      alert("상세코드 조회에 실패했습니다.")
      return
    }

    const data = await response.json()
    this.detailManager.api.setGridOption("rowData", data)
    this.detailManager.resetTracking()
  }

  // --- UI ---

  refreshSelectedCodeLabel() {
    if (!this.hasSelectedCodeLabelTarget) return

    if (this.selectedCodeValue) {
      this.selectedCodeLabelTarget.textContent = `선택 코드: ${this.selectedCodeValue}`
    } else {
      this.selectedCodeLabelTarget.textContent = "코드를 먼저 선택하세요."
    }
  }

  hasMasterPendingChanges() {
    if (!this.manager) return false
    return hasChanges(this.manager.buildOperations())
  }

  blockDetailActionIfMasterChanged() {
    if (!this.hasMasterPendingChanges()) return false
    alert("마스터 코드가 변경이 있습니다.")
    return true
  }
}
