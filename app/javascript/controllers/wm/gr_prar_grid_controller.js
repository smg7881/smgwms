import BaseGridController from "controllers/base_grid_controller"
import { buildTemplateUrl, postJson } from "controllers/grid/grid_utils"
import { isApiAlive } from "controllers/grid/core/api_guard"
import { fetchJson } from "controllers/grid/core/http_client"
import { collectRows } from "controllers/grid/grid_api_utils"
import { showAlert, confirmAction } from "components/ui/alert"
import { switchTab, activateTab } from "controllers/ui_utils"

const DETAIL_ATTR_FIELDS = [
  "stock_attr_col01",
  "stock_attr_col02",
  "stock_attr_col03",
  "stock_attr_col04",
  "stock_attr_col05",
  "stock_attr_col06",
  "stock_attr_col07",
  "stock_attr_col08",
  "stock_attr_col09",
  "stock_attr_col10"
]

export default class extends BaseGridController {
  static targets = [
    ...BaseGridController.targets,
    "masterGrid",
    "detailGrid",
    "execRsltGrid",
    "selectedMasterLabel",
    "tabButton",
    "tabPanel"
  ]

  static values = {
    ...BaseGridController.values,
    masterBatchUrl: String,
    detailBatchUrlTemplate: String,
    detailListUrlTemplate: String,
    execResultUrlTemplate: String,
    saveUrlTemplate: String,
    confirmUrlTemplate: String,
    cancelUrlTemplate: String,
    stagedLocationsUrl: String,
    selectedMaster: String
  }

  connect() {
    super.connect()
    this.stagedLocations = []
    this.selectedMasterData = null
    this.activeTab = "detail"
    this.#loadStagedLocations()
    this.activateTab("detail")
  }

  masterConfig() {
    return {
      role: "master",
      pendingEntityLabel: "입고예정",
      key: {
        field: "gr_prar_no",
        stateProperty: "selectedMasterValue",
        labelTarget: "selectedMasterLabel",
        entityLabel: "입고예정",
        emptyMessage: "입고예정을 먼저 선택해주세요."
      },
      onRowChange: {
        trackCurrentRow: false,
        syncForm: false
      },
      beforeSearch: {
        clearValidation: false,
        clearForm: false
      }
    }
  }

  detailGrids() {
    return [
      {
        role: "detail",
        methodBaseName: "detail",
        masterKeyField: "gr_prar_no",
        placeholder: ":gr_prar_id",
        listUrlTemplate: "detailListUrlTemplateValue",
        batchUrlTemplate: "detailBatchUrlTemplateValue",
        entityLabel: "입고예정",
        selectionMessage: "입고예정을 먼저 선택해주세요.",
        fetchErrorMessage: "입고예정상세 조회에 실패했습니다."
      },
      {
        role: "exec",
        methodBaseName: "exec",
        masterKeyField: "gr_prar_no",
        placeholder: ":gr_prar_id",
        listUrlTemplate: "execResultUrlTemplateValue",
        entityLabel: "입고예정",
        selectionMessage: "입고예정을 먼저 선택해주세요.",
        fetchErrorMessage: "입고처리이력 조회에 실패했습니다."
      }
    ]
  }

  gridRoles() {
    return {
      master: {
        target: "masterGrid",
        manager: this.masterManagerConfig(),
        masterKeyField: "gr_prar_no",
        isMaster: true
      },
      detail: {
        target: "detailGrid",
        manager: this.detailManagerConfig(),
        parentGrid: "master",
        onMasterRowChange: (rowData) => this.handleMasterRowChange(rowData),
        detailLoader: async (rowData) => {
          const rows = await this.loadDetailRows("detail", rowData)
          this.#updateLocationColumn()
          return rows
        }
      },
      exec: {
        target: "execRsltGrid",
        parentGrid: "master",
        detailLoader: (rowData) => this.loadDetailRows("exec", rowData)
      }
    }
  }

  onAllGridsReady() {
    this.manager = this.masterManager
    this.gridController = this.gridCtrl("master")
    this.refreshSelectedLabel()
    this.#updateLocationColumn()
  }

  get masterManager() {
    return this.gridManager("master")
  }

  get detailManager() {
    return this.gridManager("detail")
  }

  masterManagerConfig() {
    return {
      pkFields: ["gr_prar_no"],
      fields: {
        car_no: "trim",
        driver_telno: "trim",
        rmk: "trim"
      },
      defaultRow: {},
      blankCheckFields: [],
      comparableFields: ["car_no", "driver_telno", "rmk"],
      firstEditCol: "car_no",
      pkLabels: { gr_prar_no: "입고예정번호" }
    }
  }

  detailManagerConfig() {
    return {
      pkFields: ["lineno"],
      fields: {
        gr_loc_cd: "trimUpper",
        gr_qty: "number",
        rmk: "trim",
        ...DETAIL_ATTR_FIELDS.reduce((acc, field) => {
          acc[field] = "trim"
          return acc
        }, {})
      },
      defaultRow: {},
      blankCheckFields: [],
      comparableFields: ["gr_loc_cd", "gr_qty", "rmk", ...DETAIL_ATTR_FIELDS],
      firstEditCol: "gr_qty",
      pkLabels: { lineno: "라인번호" }
    }
  }

  beforeSearchReset() {
    this.clearMasterSelection()
    this.#loadStagedLocations()
  }

  selectFirstMasterRow(masterRole = "master") {
    const api = this.gridApi(masterRole)
    if (!isApiAlive(api)) {
      return null
    }

    const displayedCount = api.getDisplayedRowCount()
    if (displayedCount === 0) {
      this.clearMasterSelection()
      return null
    }

    let selectedNode = null
    if (this.selectedMasterValue) {
      api.forEachNode((node) => {
        if (!selectedNode && node.data?.gr_prar_no === this.selectedMasterValue) {
          selectedNode = node
        }
      })
    }

    if (!selectedNode) {
      selectedNode = api.getDisplayedRowAtIndex(0)
    }

    if (selectedNode?.data) {
      selectedNode.setSelected(true, true)
      return selectedNode.data
    }

    this.clearMasterSelection()
    return null
  }

  handleMasterRowChange(rowData) {
    if (!rowData) {
      this.clearMasterSelection()
      return
    }

    const nextMaster = rowData.gr_prar_no?.toString() || ""
    if (nextMaster === this.selectedMasterValue) {
      this.selectedMasterData = rowData
      this.refreshSelectedLabel()
      return
    }

    if (this.blockDetailActionIfMasterChanged()) {
      this.restorePreviousMasterSelection()
      return
    }

    this.selectedMasterValue = nextMaster
    this.selectedMasterData = rowData
    this.refreshSelectedLabel()
    this.#updateLocationColumn()
  }

  restorePreviousMasterSelection() {
    const api = this.masterManager?.api
    if (!isApiAlive(api) || !this.selectedMasterValue) {
      return
    }

    api.forEachNode((node) => {
      if (node.data?.gr_prar_no === this.selectedMasterValue) {
        node.setSelected(true, true)
      }
    })
  }

  clearMasterSelection() {
    this.selectedMasterValue = ""
    this.selectedMasterData = null
    this.refreshSelectedLabel()
    this.clearAllDetails()
  }

  clearAllDetails() {
    this.clearDetailRows?.()
    this.clearExecRows?.()
  }

  switchTab(event) {
    switchTab(event, this)
    this.#resizeCurrentTabGrid(this.activeTab)
  }

  activateTab(tab) {
    activateTab(tab, this)
    this.#resizeCurrentTabGrid(tab)
  }

  async saveMasterRows() {
    await this.saveDetailRows()
  }

  async saveGr(event) {
    event?.preventDefault()
    await this.saveDetailRows()
  }

  async saveDetailRows() {
    const hasSelectedMaster = this.requireMasterSelection(this.selectedMasterValue, {
      entityLabel: "입고예정",
      message: "입고예정을 먼저 선택해주세요."
    })
    if (!hasSelectedMaster) {
      return
    }

    if (this.blockDetailActionIfMasterChanged()) {
      return
    }

    const api = this.detailManager?.api
    if (!isApiAlive(api)) {
      return
    }

    this.detailManager.stopEditing?.()

    const rows = collectRows(api)
    const hasInput = rows.some((row) => parseFloat(row.gr_qty) > 0)
    if (!hasInput) {
      showAlert("Warning", "입고물량을 입력한 행이 없습니다.", "warning")
      return
    }

    const negativeRow = rows.find((row) => parseFloat(row.gr_qty) < 0)
    if (negativeRow) {
      showAlert("Error", `라인 ${negativeRow.lineno}: 입고물량은 음수를 입력할 수 없습니다.`, "error")
      return
    }

    const url = buildTemplateUrl(this.saveUrlTemplateValue, { gr_prar_id: this.selectedMasterValue })
    const response = await postJson(url, { rows })
    if (!response?.success) {
      showAlert("Error", response?.errors?.join("\n") || "저장 중 오류가 발생했습니다.", "error")
      return
    }

    showAlert("Success", "입고내역이 저장되었습니다.", "success")
    this.#refreshMasterGrid()
  }

  async confirmGr(event) {
    event?.preventDefault()

    const hasSelectedMaster = this.requireMasterSelection(this.selectedMasterValue, {
      entityLabel: "입고예정",
      message: "입고예정을 먼저 선택해주세요."
    })
    if (!hasSelectedMaster) {
      return
    }

    if (this.blockDetailActionIfMasterChanged()) {
      return
    }

    const masterData = this.selectedMasterData
    if (masterData?.gr_stat_cd !== "20") {
      showAlert("Warning", "입고확정불가: 입고상태가 '입고처리(20)' 상태일 때만 확정이 가능합니다.", "warning")
      return
    }

    const ok = await confirmAction("입고확정", `입고예정번호 [${this.selectedMasterValue}]을 확정 처리하시겠습니까?`)
    if (!ok) {
      return
    }

    const url = buildTemplateUrl(this.confirmUrlTemplateValue, { gr_prar_id: this.selectedMasterValue })
    const response = await postJson(url, { gr_prar_no: this.selectedMasterValue })
    if (!response?.success) {
      showAlert("Error", response?.errors?.join("\n") || "입고확정 처리 중 오류가 발생했습니다.", "error")
      return
    }

    showAlert("Success", "입고확정 처리가 완료되었습니다.", "success")
    this.#refreshMasterGrid()
  }

  async cancelGr(event) {
    event?.preventDefault()

    const hasSelectedMaster = this.requireMasterSelection(this.selectedMasterValue, {
      entityLabel: "입고예정",
      message: "입고예정을 먼저 선택해주세요."
    })
    if (!hasSelectedMaster) {
      return
    }

    if (this.blockDetailActionIfMasterChanged()) {
      return
    }

    const ok = await confirmAction(
      "입고취소",
      `입고예정번호 [${this.selectedMasterValue}]를 취소 처리하시겠습니까?\n취소 시 생성된 재고가 차감됩니다.`
    )
    if (!ok) {
      return
    }

    const url = buildTemplateUrl(this.cancelUrlTemplateValue, { gr_prar_id: this.selectedMasterValue })
    const response = await postJson(url, { gr_prar_no: this.selectedMasterValue })
    if (!response?.success) {
      showAlert("Error", response?.errors?.join("\n") || "입고취소 처리 중 오류가 발생했습니다.", "error")
      return
    }

    showAlert("Success", "입고취소 처리가 완료되었습니다.", "success")
    this.clearMasterSelection()
    this.#refreshMasterGrid()
  }

  blockDetailActionIfMasterChanged() {
    return this.blockIfMasterPendingChanges(this.masterManager, "입고예정")
  }

  activeTab = "detail"

  async #loadStagedLocations() {
    const workplCd = this.getSearchFormValue("workpl_cd")
    if (!workplCd) {
      this.stagedLocations = []
      this.#updateLocationColumn()
      return
    }

    try {
      const url = `${this.stagedLocationsUrlValue}&workpl_cd=${encodeURIComponent(workplCd)}`
      const rows = await fetchJson(url)
      this.stagedLocations = Array.isArray(rows) ? rows.map((row) => row.value).filter(Boolean) : []
      this.#updateLocationColumn()
    } catch {
      this.stagedLocations = []
      this.#updateLocationColumn()
    }
  }

  #updateLocationColumn() {
    const api = this.detailManager?.api
    if (!isApiAlive(api)) {
      return
    }

    const columnDefs = api.getColumnDefs() || []
    const locationColumn = columnDefs.find((column) => column.field === "gr_loc_cd")
    if (!locationColumn) {
      return
    }

    locationColumn.cellEditorParams = { values: this.stagedLocations }
    api.setGridOption("columnDefs", columnDefs)
  }

  #resizeCurrentTabGrid(tab) {
    if (tab === "detail") {
      this.sizeColumnsToFitWhenVisible("detail", { delay: 50 })
    } else if (tab === "exec") {
      this.sizeColumnsToFitWhenVisible("exec", { delay: 50 })
    }
  }

  #refreshMasterGrid() {
    this.dispatch("search", { target: document.querySelector('[data-controller="search-form"]') })
  }
}
