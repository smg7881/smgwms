import BaseGridController from "controllers/base_grid_controller"
import { buildTemplateUrl, postJson } from "controllers/grid/grid_utils"
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
    "pickGrid",
    "selectedMasterLabel",
    "tabButton",
    "tabPanel"
  ]

  static values = {
    ...BaseGridController.values,
    masterBatchUrl: String,
    detailBatchUrlTemplate: String,
    detailListUrlTemplate: String,
    pickListUrlTemplate: String,
    assignUrlTemplate: String,
    pickUrlTemplate: String,
    confirmUrlTemplate: String,
    cancelUrlTemplate: String,
    selectedMaster: String
  }

  connect() {
    super.connect()
    this.selectedMasterData = null
    this.activeTab = "detail"
    this.activateTab("detail")
  }

  gridRoles() {
    return {
      master: {
        target: "masterGrid",
        manager: this.masterManagerConfig(),
        masterKeyField: "gi_prar_no",
        isMaster: true
      },
      detail: {
        target: "detailGrid",
        manager: this.detailManagerConfig(),
        parentGrid: "master",
        onMasterRowChange: (rowData) => this.handleMasterRowChange(rowData),
        detailLoader: async (rowData) => this.loadDetailRows("detail", rowData)
      },
      pick: {
        target: "pickGrid",
        manager: this.pickManagerConfig(),
        parentGrid: "master",
        detailLoader: async (rowData) => this.loadDetailRows("pick", rowData)
      }
    }
  }

  detailGrids() {
    return [
      {
        role: "detail",
        methodBaseName: "detail",
        masterKeyField: "gi_prar_no",
        placeholder: ":gi_prar_id",
        listUrlTemplate: "detailListUrlTemplateValue",
        batchUrlTemplate: "detailBatchUrlTemplateValue",
        entityLabel: "출고예정",
        selectionMessage: "출고예정을 먼저 선택하세요.",
        fetchErrorMessage: "출고상세 조회에 실패했습니다."
      },
      {
        role: "pick",
        methodBaseName: "pick",
        masterKeyField: "gi_prar_no",
        placeholder: ":gi_prar_id",
        listUrlTemplate: "pickListUrlTemplateValue",
        entityLabel: "출고예정",
        selectionMessage: "출고예정을 먼저 선택하세요.",
        fetchErrorMessage: "할당/피킹 목록 조회에 실패했습니다."
      }
    ]
  }

  onAllGridsReady() {
    this.manager = this.gridManager("master")
    this.gridController = this.gridCtrl("master")
    this.refreshSelectedLabel()
  }

  get masterManager() {
    return this.gridManager("master")
  }

  get detailManager() {
    return this.gridManager("detail")
  }

  get pickManager() {
    return this.gridManager("pick")
  }

  masterManagerConfig() {
    return {
      pkFields: ["gi_prar_no"],
      fields: {
        car_no: "trim",
        driver_telno: "trim",
        rmk: "trim"
      },
      defaultRow: {},
      blankCheckFields: [],
      comparableFields: ["car_no", "driver_telno", "rmk"],
      firstEditCol: "car_no",
      pkLabels: { gi_prar_no: "출고예정번호" }
    }
  }

  detailManagerConfig() {
    return {
      pkFields: ["lineno"],
      fields: {
        rmk: "trim",
        ...DETAIL_ATTR_FIELDS.reduce((acc, field) => {
          acc[field] = "trim"
          return acc
        }, {})
      },
      defaultRow: {},
      blankCheckFields: [],
      comparableFields: ["rmk", ...DETAIL_ATTR_FIELDS],
      firstEditCol: "rmk",
      pkLabels: { lineno: "라인번호" }
    }
  }

  pickManagerConfig() {
    return {
      pkFields: ["pick_no"],
      fields: {
        assign_qty: "number",
        pick_qty: "number",
        rmk: "trim"
      },
      defaultRow: {},
      blankCheckFields: [],
      comparableFields: ["assign_qty", "pick_qty", "rmk"],
      firstEditCol: "assign_qty",
      pkLabels: { pick_no: "피킹번호" }
    }
  }

  beforeSearchReset() {
    this.clearMasterSelection()
  }

  handleMasterRowChange(rowData) {
    if (!rowData) {
      this.clearMasterSelection()
      return
    }

    const nextMaster = rowData.gi_prar_no?.toString() || ""
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
  }

  restorePreviousMasterSelection() {
    const api = this.masterManager?.api
    if (!api || !this.selectedMasterValue) {
      return
    }

    api.forEachNode((node) => {
      if (node.data?.gi_prar_no === this.selectedMasterValue) {
        node.setSelected(true, true)
      }
    })
  }

  clearMasterSelection() {
    this.selectedMasterValue = ""
    this.selectedMasterData = null
    this.refreshSelectedLabel()
    this.clearDetailRows?.()
    this.clearPickRows?.()
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
    await this.saveRowsWith({
      manager: this.masterManager,
      batchUrl: this.masterBatchUrlValue,
      saveMessage: "출고지시가 저장되었습니다.",
      onSuccess: () => this.refreshGrid("master")
    })
  }

  async saveDetailRows() {
    const event = arguments[0]
    event?.preventDefault()

    const hasSelectedMaster = this.requireMasterSelection(this.selectedMasterValue, {
      entityLabel: "출고예정",
      message: "출고예정을 먼저 선택하세요."
    })
    if (!hasSelectedMaster) {
      return
    }

    if (this.blockDetailActionIfMasterChanged()) {
      return
    }

    const batchUrl = buildTemplateUrl(this.detailBatchUrlTemplateValue, { gi_prar_id: this.selectedMasterValue })
    await this.saveRowsWith({
      manager: this.detailManager,
      batchUrl,
      saveMessage: "출고상세가 저장되었습니다.",
      onSuccess: () => this.refreshGrid("detail")
    })
  }

  async assignGi(event) {
    event?.preventDefault()
    await this.#processPickAction({
      requiredStatus: "10",
      actionName: "할당",
      confirmMessage: "할당 처리하시겠습니까?",
      urlTemplate: this.assignUrlTemplateValue,
      payloadBuilder: (rows) => ({ rows: rows.map((row) => ({ pick_no: row.pick_no, assign_qty: row.assign_qty })) })
    })
  }

  async pickGi(event) {
    event?.preventDefault()
    await this.#processPickAction({
      requiredStatus: "20",
      actionName: "피킹",
      confirmMessage: "피킹 처리하시겠습니까?",
      urlTemplate: this.pickUrlTemplateValue,
      payloadBuilder: (rows) => ({ rows: rows.map((row) => ({ pick_no: row.pick_no, pick_qty: row.pick_qty })) })
    })
  }

  async confirmGi(event) {
    event?.preventDefault()

    const hasSelectedMaster = this.requireMasterSelection(this.selectedMasterValue, {
      entityLabel: "출고예정",
      message: "출고예정을 먼저 선택하세요."
    })
    if (!hasSelectedMaster) {
      return
    }

    if (this.blockDetailActionIfMasterChanged()) {
      return
    }

    if (this.selectedMasterData?.gi_stat_cd !== "30") {
      showAlert("Warning", "출고확정은 피킹(30) 상태에서만 가능합니다.", "warning")
      return
    }

    const ok = await confirmAction("출고확정", `출고예정번호 [${this.selectedMasterValue}]를 확정하시겠습니까?`)
    if (!ok) {
      return
    }

    const url = buildTemplateUrl(this.confirmUrlTemplateValue, { gi_prar_id: this.selectedMasterValue })
    const response = await postJson(url, { gi_prar_no: this.selectedMasterValue })
    if (!response?.success) {
      showAlert("Error", response?.errors?.join("\n") || "출고확정 처리 중 오류가 발생했습니다.", "error")
      return
    }

    showAlert("Success", response.message || "출고확정 처리가 완료되었습니다.", "success")
    this.#refreshMasterGrid()
  }

  async cancelGi(event) {
    event?.preventDefault()

    const hasSelectedMaster = this.requireMasterSelection(this.selectedMasterValue, {
      entityLabel: "출고예정",
      message: "출고예정을 먼저 선택하세요."
    })
    if (!hasSelectedMaster) {
      return
    }

    if (this.blockDetailActionIfMasterChanged()) {
      return
    }

    const ok = await confirmAction("출고취소", `출고예정번호 [${this.selectedMasterValue}]를 취소하시겠습니까?`)
    if (!ok) {
      return
    }

    const url = buildTemplateUrl(this.cancelUrlTemplateValue, { gi_prar_id: this.selectedMasterValue })
    const response = await postJson(url, { gi_prar_no: this.selectedMasterValue })
    if (!response?.success) {
      showAlert("Error", response?.errors?.join("\n") || "출고취소 처리 중 오류가 발생했습니다.", "error")
      return
    }

    showAlert("Success", response.message || "출고취소 처리가 완료되었습니다.", "success")
    this.#refreshMasterGrid()
  }

  blockDetailActionIfMasterChanged() {
    return this.blockIfMasterPendingChanges(this.masterManager, "출고지시")
  }

  async #processPickAction({ requiredStatus, actionName, confirmMessage, urlTemplate, payloadBuilder }) {
    const hasSelectedMaster = this.requireMasterSelection(this.selectedMasterValue, {
      entityLabel: "출고예정",
      message: "출고예정을 먼저 선택하세요."
    })
    if (!hasSelectedMaster) {
      return
    }

    if (this.blockDetailActionIfMasterChanged()) {
      return
    }

    if (this.selectedMasterData?.gi_stat_cd !== requiredStatus) {
      showAlert("Warning", `${actionName}은 상태 ${requiredStatus}에서만 가능합니다.`, "warning")
      return
    }

    const rows = collectRows(this.pickManager?.api)
    if (!Array.isArray(rows) || rows.length === 0) {
      showAlert("Warning", "처리할 피킹 데이터가 없습니다.", "warning")
      return
    }

    const hasNegative = rows.some((row) => Number(row.assign_qty || 0) < 0 || Number(row.pick_qty || 0) < 0)
    if (hasNegative) {
      showAlert("Warning", "할당/피킹 수량에는 음수를 입력할 수 없습니다.", "warning")
      return
    }

    const ok = await confirmAction(actionName, confirmMessage)
    if (!ok) {
      return
    }

    const url = buildTemplateUrl(urlTemplate, { gi_prar_id: this.selectedMasterValue })
    const response = await postJson(url, payloadBuilder(rows))
    if (!response?.success) {
      showAlert("Error", response?.errors?.join("\n") || `${actionName} 처리 중 오류가 발생했습니다.`, "error")
      return
    }

    showAlert("Success", response.message || `${actionName} 처리가 완료되었습니다.`, "success")
    this.#refreshMasterGrid()
  }

  #resizeCurrentTabGrid(tab) {
    if (tab === "detail") {
      this.sizeColumnsToFitWhenVisible("detail", { delay: 50 })
    } else if (tab === "pick") {
      this.sizeColumnsToFitWhenVisible("pick", { delay: 50 })
    }
  }

  #refreshMasterGrid() {
    this.dispatch("search", { target: document.querySelector('[data-controller="search-form"]') })
  }
}
