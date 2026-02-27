import BaseGridController from "controllers/base_grid_controller"
import { GridEventManager, rowDataFromGridEvent } from "controllers/grid/grid_event_manager"
import { isApiAlive, focusFirstRow, fetchJson, setManagerRowData } from "controllers/grid/grid_utils"
import { registerGridInstance } from "controllers/grid/core/grid_registration"
import { showAlert } from "components/ui/alert"

export default class MasterDetailGridController extends BaseGridController {
  connect() {
    super.connect()
    this.initialMasterSyncDone = false
    this.masterGridEvents = new GridEventManager()
    this.lastMasterRowRef = null
  }

  disconnect() {
    this.masterGridEvents?.unbindAll()
    this.lastMasterRowRef = null
    super.disconnect()
  }

  bindMasterGridEvents() {
    this.masterGridEvents.unbindAll()
    this.masterGridEvents.bind(this.manager?.api, "rowClicked", this.handleMasterGridEvent)
    this.masterGridEvents.bind(this.manager?.api, "cellFocused", this.handleMasterGridEvent)
  }

  registerGrid(event) {
    registerGridInstance(event, this, this.masterDetailGridConfigs(), () => {
      this.onMasterDetailGridsReady()
    })
  }

  handleMasterGridEvent = async (event) => {
    const rowData = rowDataFromGridEvent(this.manager?.api, event)
    if (!rowData) return

    await this.handleMasterRowChangeOnce(rowData)
  }

  async syncMasterSelectionAfterLoad({ ensureVisible = true, select = false } = {}) {
    if (!isApiAlive(this.manager?.api) || !this.isDetailReady()) return

    const firstData = focusFirstRow(this.manager.api, { ensureVisible, select })
    if (!firstData) {
      this.lastMasterRowRef = null
      await this.handleMasterRowChange(null)
      return
    }

    await this.handleMasterRowChangeOnce(firstData, { force: true })
  }

  async handleMasterRowChangeOnce(rowData, { force = false } = {}) {
    if (!force && this.lastMasterRowRef === rowData) return
    this.lastMasterRowRef = rowData
    await this.handleMasterRowChange(rowData)
  }

  isDetailReady() {
    return true
  }

  masterDetailGridConfigs() {
    return [
      {
        target: this.hasMasterGridTarget ? this.masterGridTarget : null,
        isMaster: true,
        setup: (event) => super.registerGrid(event)
      },
      ...this.detailGridConfigs()
    ]
  }

  detailGridConfigs() {
    return []
  }

  onMasterDetailGridsReady() {
    this.bindMasterGridEvents()
    this.tryInitialMasterSync()
  }

  tryInitialMasterSync() {
    if (this.initialMasterSyncDone) return
    this.initialMasterSyncDone = true
    this.syncMasterSelectionAfterLoad()
  }

  handleMasterRowDataUpdated({ resetTrackingManagers = [] } = {}) {
    resetTrackingManagers.forEach((manager) => manager?.resetTracking?.())
    if (this.initialMasterSyncDone) return
    if (!this.isDetailReady()) return

    this.initialMasterSyncDone = true
    this.syncMasterSelectionAfterLoad()
  }

  async reloadMasterRows({ url = this.gridController?.urlValue, errorMessage = "목록 조회에 실패했습니다." } = {}) {
    if (!isApiAlive(this.manager?.api)) return false
    if (!url) return false

    try {
      const rows = await fetchJson(url)
      setManagerRowData(this.manager, rows)
      await this.syncMasterSelectionAfterLoad()
      return true
    } catch {
      if (errorMessage) showAlert(errorMessage)
      return false
    }
  }

  async syncMasterDetailByCode(rowData, {
    codeField = "code",
    setSelectedCode,
    refreshLabel,
    clearDetails,
    loadDetails,
    beforeSync
  } = {}) {
    if (!this.isDetailReady()) return

    if (beforeSync) {
      beforeSync(rowData)
    }

    const code = rowData?.[codeField]
    const hasLoadableCode = Boolean(code) && !rowData?.__is_deleted && !rowData?.__is_new

    if (!hasLoadableCode) {
      if (setSelectedCode) setSelectedCode(code || "")
      if (refreshLabel) refreshLabel()
      if (clearDetails) clearDetails()
      return
    }

    if (setSelectedCode) setSelectedCode(code)
    if (refreshLabel) refreshLabel()
    if (loadDetails) await loadDetails(code)
  }
}
