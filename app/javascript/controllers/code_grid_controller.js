import BaseGridController from "controllers/base_grid_controller"
import GridCrudManager from "controllers/grid/grid_crud_manager"
import { GridEventManager, resolveAgGridRegistration, rowDataFromGridEvent } from "controllers/grid/grid_event_manager"
import { isApiAlive, postJson, hasChanges, fetchJson, setManagerRowData } from "controllers/grid/grid_utils"

// BaseGridController override: 마스터-디테일 2중 그리드 CRUD와 선택 연동을 확장합니다.

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
    this.masterGridEvents = new GridEventManager()
    this.detailGridController = null
    this.detailManager = null
  }

  disconnect() {
    this.masterGridEvents.unbindAll()

    if (this.detailManager) {
      this.detailManager.detach()
      this.detailManager = null
    }

    this.detailGridController = null
    super.disconnect()
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

        if (!this.initialMasterSyncDone && isApiAlive(this.detailManager?.api)) {
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
      defaultRow: {
        code: "",
        detail_code: "",
        detail_code_name: "",
        short_name: "",
        ref_code: "",
        sort_order: 0,
        use_yn: "Y"
      },
      blankCheckFields: ["detail_code", "detail_code_name"],
      comparableFields: ["detail_code_name", "short_name", "ref_code", "sort_order", "use_yn"],
      firstEditCol: "detail_code",
      pkLabels: { detail_code: "상세코드" }
    }
  }

  registerGrid(event) {
    const registration = resolveAgGridRegistration(event)
    if (!registration) return

    const { gridElement, api, controller } = registration

    if (gridElement === this.masterGridTarget) {
      super.registerGrid(event)
    } else if (gridElement === this.detailGridTarget) {
      if (this.detailManager) {
        this.detailManager.detach()
      }
      this.detailGridController = controller
      this.detailManager = new GridCrudManager(this.configureDetailManager())
      this.detailManager.attach(api)
    }

    if (this.manager?.api && this.detailManager?.api) {
      this.bindMasterGridEvents()
      if (!this.initialMasterSyncDone) {
        this.initialMasterSyncDone = true
        this.syncMasterSelectionAfterLoad()
      }
    }
  }

  bindMasterGridEvents() {
    this.masterGridEvents.unbindAll()
    this.masterGridEvents.bind(this.manager?.api, "rowClicked", this.handleMasterRowClicked)
    this.masterGridEvents.bind(this.manager?.api, "cellFocused", this.handleMasterCellFocused)
  }

  handleMasterRowClicked = async (event) => {
    const rowData = rowDataFromGridEvent(this.manager?.api, event)
    await this.handleMasterRowChange(rowData)
  }

  handleMasterCellFocused = async (event) => {
    const rowData = rowDataFromGridEvent(this.manager?.api, event)
    if (!rowData) return

    await this.handleMasterRowChange(rowData)
  }

  async handleMasterRowChange(rowData) {
    if (!isApiAlive(this.detailManager?.api)) return

    const code = rowData?.code
    if (!code || rowData?.__is_deleted || rowData?.__is_new) {
      this.selectedCodeValue = code || ""
      this.refreshSelectedCodeLabel()
      this.clearDetailRows()
      return
    }

    this.selectedCodeValue = code
    this.refreshSelectedCodeLabel()
    await this.loadDetailRows(code)
  }

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

    alert("코드 데이터가 저장되었습니다.")
    await this.reloadMasterRows()
  }

  async reloadMasterRows() {
    if (!isApiAlive(this.manager?.api)) return
    if (!this.gridController?.urlValue) return

    try {
      const rows = await fetchJson(this.gridController.urlValue)
      setManagerRowData(this.manager, rows)
      await this.syncMasterSelectionAfterLoad()
    } catch {
      alert("코드 목록 조회에 실패했습니다.")
    }
  }

  async syncMasterSelectionAfterLoad() {
    if (!isApiAlive(this.manager?.api) || !isApiAlive(this.detailManager?.api)) return

    const firstRowNode = this.manager.api.getDisplayedRowAtIndex(0)
    if (!firstRowNode?.data) {
      this.selectedCodeValue = ""
      this.refreshSelectedCodeLabel()
      this.clearDetailRows()
      return
    }

    const firstCol = this.manager.api.getAllDisplayedColumns()?.[0]
    if (firstCol) {
      this.manager.api.setFocusedCell(0, firstCol.getColId())
    }

    await this.handleMasterRowChange(firstRowNode.data)
  }

  addDetailRow() {
    if (!this.detailManager) return
    if (this.blockDetailActionIfMasterChanged()) return

    if (!this.selectedCodeValue) {
      alert("코드를 먼저 선택해주세요.")
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
      alert("코드를 먼저 선택해주세요.")
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

    alert("상세코드 데이터가 저장되었습니다.")
    await this.loadDetailRows(this.selectedCodeValue)
  }

  async loadDetailRows(code) {
    if (!isApiAlive(this.detailManager?.api)) return

    if (!code) {
      this.clearDetailRows()
      return
    }

    try {
      const url = this.detailListUrlTemplateValue.replace(":code", encodeURIComponent(code))
      const rows = await fetchJson(url)
      setManagerRowData(this.detailManager, rows)
    } catch {
      alert("상세코드 목록 조회에 실패했습니다.")
    }
  }

  clearDetailRows() {
    setManagerRowData(this.detailManager, [])
  }

  refreshSelectedCodeLabel() {
    if (!this.hasSelectedCodeLabelTarget) return

    if (this.selectedCodeValue) {
      this.selectedCodeLabelTarget.textContent = `선택 코드: ${this.selectedCodeValue}`
    } else {
      this.selectedCodeLabelTarget.textContent = "코드를 먼저 선택해주세요."
    }
  }

  hasMasterPendingChanges() {
    if (!this.manager) return false
    return hasChanges(this.manager.buildOperations())
  }

  blockDetailActionIfMasterChanged() {
    if (!this.hasMasterPendingChanges()) return false

    alert("마스터 코드에 저장되지 않은 변경이 있습니다.")
    return true
  }
}


