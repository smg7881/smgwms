import BaseGridController from "controllers/base_grid_controller"
import { GridEventManager, rowDataFromGridEvent } from "controllers/grid/grid_event_manager"
import { isApiAlive, focusFirstRow, fetchJson, setManagerRowData } from "controllers/grid/grid_utils"
import { registerGridInstance } from "controllers/grid/core/grid_registration"
import { showAlert } from "components/ui/alert"

/**
 * MasterDetailGridController
 *
 * Shared base controller for screens that use a Master grid and one or more Detail grids.
 *
 * Responsibilities:
 * - Register master/detail grids in a unified way.
 * - Listen to master selection events and route them into a single change pipeline.
 * - Prevent duplicate detail reloads when the same row is selected repeatedly.
 * - Run one-time initial sync after first data load.
 * - Provide a reusable code-based sync utility for subclass controllers.
 */
export default class MasterDetailGridController extends BaseGridController {
  // Initialize sync state and event manager for master grid selection events.
  connect() {
    super.connect()
    // Guards one-time initial sync flow.
    this.initialMasterSyncDone = false
    // Handles bind/unbind of rowClicked/cellFocused listeners.
    this.masterGridEvents = new GridEventManager()
    // Keeps the last processed row reference to avoid duplicate work.
    this.lastMasterRowRef = null
  }

  // Clean up listeners and references before delegating to parent cleanup.
  disconnect() {
    this.masterGridEvents?.unbindAll()
    this.lastMasterRowRef = null
    super.disconnect()
  }

  // Bind master-grid selection related events to a single handler.
  bindMasterGridEvents() {
    this.masterGridEvents.unbindAll()
    this.masterGridEvents.bind(this.manager?.api, "rowClicked", this.handleMasterGridEvent)
    this.masterGridEvents.bind(this.manager?.api, "cellFocused", this.handleMasterGridEvent)
  }

  // Register all master/detail grids and run post-ready hook once everything is attached.
  registerGrid(event) {
    registerGridInstance(event, this, this.masterDetailGridConfigs(), () => {
      this.onMasterDetailGridsReady()
    })
  }

  // Normalize a master-grid event into row data, then process it via duplicate-safe handler.
  handleMasterGridEvent = async (event) => {
    const rowData = rowDataFromGridEvent(this.manager?.api, event)
    if (!rowData) return

    await this.handleMasterRowChangeOnce(rowData)
  }

  // After master rows are loaded, sync detail state from the first visible row.
  async syncMasterSelectionAfterLoad({ ensureVisible = true, select = false } = {}) {
    if (!isApiAlive(this.manager?.api) || !this.isDetailReady()) return

    const firstData = focusFirstRow(this.manager.api, { ensureVisible, select })
    if (!firstData) {
      // If master is empty, propagate null so subclass can clear detail state.
      this.lastMasterRowRef = null
      await this.handleMasterRowChange(null)
      return
    }

    await this.handleMasterRowChangeOnce(firstData, { force: true })
  }

  // Process master-row change only when needed (or always when force=true).
  async handleMasterRowChangeOnce(rowData, { force = false } = {}) {
    if (!force && this.lastMasterRowRef === rowData) return
    this.lastMasterRowRef = rowData
    await this.handleMasterRowChange(rowData)
  }

  // Overridable readiness gate for detail area (default: always ready).
  isDetailReady() {
    return true
  }

  // Build registration config: one master grid + optional detail grids from subclass.
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

  // Subclass hook: return detail-grid registration configs.
  detailGridConfigs() {
    return []
  }

  // Called when all master/detail grids are ready.
  onMasterDetailGridsReady() {
    this.bindMasterGridEvents()
    this.tryInitialMasterSync()
  }

  // Trigger initial sync exactly once during screen lifecycle.
  tryInitialMasterSync() {
    if (this.initialMasterSyncDone) return
    this.initialMasterSyncDone = true
    this.syncMasterSelectionAfterLoad()
  }

  // Handle post-update flow after master rowData refresh.
  // 1) Reset tracking for dependent managers.
  // 2) Run initial sync if not done yet and detail is ready.
  handleMasterRowDataUpdated({ resetTrackingManagers = [] } = {}) {
    resetTrackingManagers.forEach((manager) => manager?.resetTracking?.())
    if (this.initialMasterSyncDone) return
    if (!this.isDetailReady()) return

    this.initialMasterSyncDone = true
    this.syncMasterSelectionAfterLoad()
  }

  // Reload master rows from URL and re-sync selection/detail on success.
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

  // Generic utility to sync master/detail by a code field.
  // - If code is missing/new/deleted, clear detail side.
  // - Otherwise, update selected-code state/label and load details.
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
