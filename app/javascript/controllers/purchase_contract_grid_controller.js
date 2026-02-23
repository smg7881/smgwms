import BaseGridController from "controllers/base_grid_controller"
import GridCrudManager from "controllers/grid/grid_crud_manager"
import { GridEventManager, resolveAgGridRegistration, rowDataFromGridEvent } from "controllers/grid/grid_event_manager"
import { isApiAlive, postJson, hasChanges, fetchJson, setManagerRowData, focusFirstRow, hasPendingChanges, blockIfPendingChanges, buildTemplateUrl, refreshSelectionLabel } from "controllers/grid/grid_utils"

const CODE_FIELDS = [
  "corp_cd",
  "bzac_cd",
  "pur_ctrt_no",
  "ctrt_sctn_cd",
  "ctrt_kind_cd",
  "bef_ctrt_no",
  "cprtco_ofcr_cd",
  "ctrt_cnctr_reason_cd",
  "ctrt_ofcr_cd",
  "ctrt_dept_cd",
  "loan_limt_over_yn_cd",
  "vat_sctn_cd",
  "apv_mthd_cd",
  "apv_type_cd",
  "bilg_mthd_cd",
  "dcsn_yn_cd",
  "use_yn_cd",
  "pay_cond_cd",
  "bzac_sctn_cd",
  "work_step_no1_cd",
  "work_step_no2_cd"
]

const DATE_FIELDS = [
  "strt_ctrt_ymd",
  "ctrt_strt_day",
  "ctrt_end_day",
  "ctrt_exten_ymd",
  "ctrt_expi_noti_ymd",
  "ctrt_cnctr_ymd"
]

export default class extends BaseGridController {
  static targets = [
    ...BaseGridController.targets,
    "masterGrid",
    "settlementGrid",
    "historyGrid",
    "selectedContractLabel",
    "detailField",
    "tabButton",
    "tabPanel"
  ]

  static values = {
    ...BaseGridController.values,
    masterBatchUrl: String,
    settlementBatchUrlTemplate: String,
    settlementListUrlTemplate: String,
    historyListUrlTemplate: String,
    selectedContract: String
  }

  connect() {
    super.connect()
    this.initialMasterSyncDone = false
    this.masterGridEvents = new GridEventManager()
    this.settlementGridController = null
    this.settlementManager = null
    this.historyGridController = null
    this.currentMasterRow = null
    this.activeTab = "basic"

    this.bindDetailFieldEvents()
    this.activateTab("basic")
    this.clearDetailForm()
  }

  disconnect() {
    this.unbindDetailFieldEvents()
    this.masterGridEvents.unbindAll()

    if (this.settlementManager) {
      this.settlementManager.detach()
      this.settlementManager = null
    }

    this.settlementGridController = null
    this.historyGridController = null
    this.currentMasterRow = null
    super.disconnect()
  }

  configureManager() {
    return {
      pkFields: ["pur_ctrt_no"],
      fields: {
        corp_cd: "trimUpper",
        bzac_cd: "trimUpper",
        pur_ctrt_no: "trimUpper",
        pur_ctrt_nm: "trim",
        bizman_no: "trim",
        ctrt_sctn_cd: "trimUpper",
        ctrt_kind_cd: "trimUpper",
        bef_ctrt_no: "trimUpper",
        cprtco_ofcr_cd: "trimUpper",
        strt_ctrt_ymd: "trim",
        ctrt_strt_day: "trim",
        ctrt_end_day: "trim",
        ctrt_exten_ymd: "trim",
        ctrt_expi_noti_ymd: "trim",
        ctrt_cnctr_ymd: "trim",
        ctrt_cnctr_reason_cd: "trimUpper",
        ctrt_ofcr_cd: "trimUpper",
        ctrt_ofcr_nm: "trim",
        ctrt_dept_cd: "trimUpper",
        ctrt_dept_nm: "trim",
        loan_limt_over_yn_cd: "trimUpperDefault:N",
        vat_sctn_cd: "trimUpper",
        apv_mthd_cd: "trimUpper",
        apv_type_cd: "trimUpper",
        bilg_mthd_cd: "trimUpper",
        dcsn_yn_cd: "trimUpperDefault:N",
        use_yn_cd: "trimUpperDefault:Y",
        ctrt_chg_reason_cd: "trim",
        op_area_cd: "trim",
        re_ctrt_cond_cd: "trim",
        ctrt_cnctr_cond_cd: "trim",
        ctrt_cnctr_dtl_reason_cd: "trim",
        pay_cond_cd: "trimUpper",
        bzac_sctn_cd: "trimUpper",
        work_step_no1_cd: "trimUpper",
        work_step_no2_cd: "trimUpper",
        remk: "trim"
      },
      defaultRow: {
        corp_cd: "",
        bzac_cd: "",
        pur_ctrt_no: "",
        pur_ctrt_nm: "",
        bizman_no: "",
        ctrt_sctn_cd: "",
        ctrt_kind_cd: "",
        bef_ctrt_no: "",
        cprtco_ofcr_cd: "",
        strt_ctrt_ymd: "",
        ctrt_strt_day: "",
        ctrt_end_day: "",
        ctrt_exten_ymd: "",
        ctrt_expi_noti_ymd: "",
        ctrt_cnctr_ymd: "",
        ctrt_cnctr_reason_cd: "",
        ctrt_ofcr_cd: "",
        ctrt_ofcr_nm: "",
        ctrt_dept_cd: "",
        ctrt_dept_nm: "",
        loan_limt_over_yn_cd: "N",
        vat_sctn_cd: "GENERAL",
        apv_mthd_cd: "TRANSFER",
        apv_type_cd: "NORMAL",
        bilg_mthd_cd: "MONTHLY",
        dcsn_yn_cd: "N",
        use_yn_cd: "Y",
        ctrt_chg_reason_cd: "",
        op_area_cd: "",
        re_ctrt_cond_cd: "",
        ctrt_cnctr_cond_cd: "",
        ctrt_cnctr_dtl_reason_cd: "",
        pay_cond_cd: "MONTH_END",
        bzac_sctn_cd: "",
        work_step_no1_cd: "",
        work_step_no2_cd: "",
        remk: ""
      },
      blankCheckFields: ["pur_ctrt_nm"],
      comparableFields: [
        "corp_cd", "bzac_cd", "pur_ctrt_nm", "bizman_no", "ctrt_sctn_cd", "ctrt_kind_cd",
        "bef_ctrt_no", "cprtco_ofcr_cd", "strt_ctrt_ymd", "ctrt_strt_day", "ctrt_end_day",
        "ctrt_exten_ymd", "ctrt_expi_noti_ymd", "ctrt_cnctr_ymd", "ctrt_cnctr_reason_cd",
        "ctrt_ofcr_cd", "ctrt_ofcr_nm", "ctrt_dept_cd", "ctrt_dept_nm", "loan_limt_over_yn_cd",
        "vat_sctn_cd", "apv_mthd_cd", "apv_type_cd", "bilg_mthd_cd", "dcsn_yn_cd", "use_yn_cd",
        "ctrt_chg_reason_cd", "op_area_cd", "re_ctrt_cond_cd", "ctrt_cnctr_cond_cd",
        "ctrt_cnctr_dtl_reason_cd", "pay_cond_cd", "bzac_sctn_cd", "work_step_no1_cd",
        "work_step_no2_cd", "remk"
      ],
      firstEditCol: "pur_ctrt_nm",
      pkLabels: { pur_ctrt_no: "매입계약번호" },
      onCellValueChanged: (event) => this.normalizeMasterField(event),
      onRowDataUpdated: () => {
        this.settlementManager?.resetTracking()

        if (!this.initialMasterSyncDone && isApiAlive(this.settlementManager?.api) && isApiAlive(this.historyGridController?.api)) {
          this.initialMasterSyncDone = true
          this.syncMasterSelectionAfterLoad()
        }
      }
    }
  }

  configureSettlementManager() {
    return {
      pkFields: ["seq_no"],
      fields: {
        seq_no: "number",
        fnc_or_cd: "trimUpper",
        fnc_or_nm: "trim",
        acnt_no_cd: "trim",
        dpstr_nm: "trim",
        mon_cd: "trimUpper",
        aply_fnc_or_cd: "trimUpper",
        aply_fnc_or_nm: "trim",
        anno_dgrcnt: "trimUpper",
        exrt_aply_std_cd: "trimUpper",
        prvs_cyfd_amt: "number",
        exca_ofcr_cd: "trimUpper",
        exca_ofcr_nm: "trim",
        use_yn_cd: "trimUpperDefault:Y",
        remk: "trim"
      },
      defaultRow: {
        seq_no: null,
        fnc_or_cd: "",
        fnc_or_nm: "",
        acnt_no_cd: "",
        dpstr_nm: "",
        mon_cd: "KRW",
        aply_fnc_or_cd: "",
        aply_fnc_or_nm: "",
        anno_dgrcnt: "FIRST",
        exrt_aply_std_cd: "",
        prvs_cyfd_amt: null,
        exca_ofcr_cd: "",
        exca_ofcr_nm: "",
        use_yn_cd: "Y",
        remk: ""
      },
      blankCheckFields: ["fnc_or_cd"],
      comparableFields: [
        "fnc_or_cd", "fnc_or_nm", "acnt_no_cd", "dpstr_nm", "mon_cd", "aply_fnc_or_cd",
        "aply_fnc_or_nm", "anno_dgrcnt", "exrt_aply_std_cd", "prvs_cyfd_amt", "exca_ofcr_cd",
        "exca_ofcr_nm", "use_yn_cd", "remk"
      ],
      firstEditCol: "fnc_or_cd",
      pkLabels: { seq_no: "순번" }
    }
  }

  registerGrid(event) {
    const registration = resolveAgGridRegistration(event)
    if (!registration) return

    const { gridElement, api, controller } = registration
    if (gridElement === this.masterGridTarget) {
      super.registerGrid(event)
    } else if (gridElement === this.settlementGridTarget) {
      if (this.settlementManager) {
        this.settlementManager.detach()
      }
      this.settlementGridController = controller
      this.settlementManager = new GridCrudManager(this.configureSettlementManager())
      this.settlementManager.attach(api)
    } else if (gridElement === this.historyGridTarget) {
      this.historyGridController = controller
    }

    if (this.manager?.api && this.settlementManager?.api && this.historyGridController?.api) {
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
    if (!rowData) {
      this.currentMasterRow = null
      this.selectedContractValue = ""
      this.refreshSelectedContractLabel()
      this.clearDetailForm()
      this.clearSettlementRows()
      this.clearHistoryRows()
      return
    }

    this.currentMasterRow = rowData
    this.fillDetailForm(rowData)

    const contractNo = rowData?.pur_ctrt_no
    this.selectedContractValue = contractNo || ""
    this.refreshSelectedContractLabel()

    if (!isApiAlive(this.settlementManager?.api) || !isApiAlive(this.historyGridController?.api)) return
    if (!contractNo || rowData?.__is_deleted || rowData?.__is_new) {
      this.clearSettlementRows()
      this.clearHistoryRows()
      return
    }

    await Promise.all([this.loadSettlementRows(contractNo), this.loadHistoryRows(contractNo)])
  }

  addMasterRow() {
    if (!this.manager) return

    const txResult = this.manager.addRow({}, { startCol: "pur_ctrt_nm" })
    const addedNode = txResult?.add?.[0]
    if (addedNode?.data) {
      this.activateTab("basic")
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

    alert("매입계약 데이터가 저장되었습니다.")
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
      alert("매입계약 목록 조회에 실패했습니다.")
    }
  }

  async syncMasterSelectionAfterLoad() {
    if (!isApiAlive(this.manager?.api)) return

    const firstData = focusFirstRow(this.manager.api)
    if (!firstData) {
      this.currentMasterRow = null
      this.selectedContractValue = ""
      this.refreshSelectedContractLabel()
      this.clearDetailForm()
      this.clearSettlementRows()
      this.clearHistoryRows()
      return
    }

    await this.handleMasterRowChange(firstData)
  }

  addSettlementRow() {
    if (!this.settlementManager) return
    if (this.blockDetailActionIfMasterChanged()) return

    if (!this.selectedContractValue) {
      alert("매입계약을 먼저 선택해주세요.")
      return
    }

    this.settlementManager.addRow()
  }

  deleteSettlementRows() {
    if (!this.settlementManager) return
    if (this.blockDetailActionIfMasterChanged()) return

    this.settlementManager.deleteRows()
  }

  async saveSettlementRows() {
    if (!this.settlementManager) return
    if (this.blockDetailActionIfMasterChanged()) return

    if (!this.selectedContractValue) {
      alert("매입계약을 먼저 선택해주세요.")
      return
    }

    this.settlementManager.stopEditing()
    const operations = this.settlementManager.buildOperations()
    if (!hasChanges(operations)) {
      alert("변경된 데이터가 없습니다.")
      return
    }

    const batchUrl = buildTemplateUrl(this.settlementBatchUrlTemplateValue, ":id", this.selectedContractValue)
    const ok = await postJson(batchUrl, operations)
    if (!ok) return

    alert("매입계약 정산정보가 저장되었습니다.")
    await Promise.all([
      this.loadSettlementRows(this.selectedContractValue),
      this.loadHistoryRows(this.selectedContractValue)
    ])
  }

  async loadSettlementRows(contractNo) {
    if (!isApiAlive(this.settlementManager?.api)) return

    if (!contractNo) {
      this.clearSettlementRows()
      return
    }

    try {
      const url = buildTemplateUrl(this.settlementListUrlTemplateValue, ":id", contractNo)
      const rows = await fetchJson(url)
      setManagerRowData(this.settlementManager, rows)
    } catch {
      alert("정산정보 목록 조회에 실패했습니다.")
    }
  }

  async loadHistoryRows(contractNo) {
    if (!isApiAlive(this.historyGridController?.api)) return

    if (!contractNo) {
      this.clearHistoryRows()
      return
    }

    try {
      const url = buildTemplateUrl(this.historyListUrlTemplateValue, ":id", contractNo)
      const rows = await fetchJson(url)
      this.historyGridController.api.setGridOption("rowData", rows)
    } catch {
      alert("변경이력 조회에 실패했습니다.")
    }
  }

  async reloadHistoryRows() {
    if (!this.selectedContractValue) {
      alert("매입계약을 먼저 선택해주세요.")
      return
    }
    await this.loadHistoryRows(this.selectedContractValue)
  }

  clearSettlementRows() {
    setManagerRowData(this.settlementManager, [])
  }

  clearHistoryRows() {
    if (!isApiAlive(this.historyGridController?.api)) return
    this.historyGridController.api.setGridOption("rowData", [])
  }

  preventDetailSubmit(event) {
    event.preventDefault()
  }

  refreshSelectedContractLabel() {
    if (!this.hasSelectedContractLabelTarget) return
    refreshSelectionLabel(this.selectedContractLabelTarget, this.selectedContractValue, "매입계약", "매입계약을 먼저 선택하세요.")
  }

  hasMasterPendingChanges() {
    return hasPendingChanges(this.manager)
  }

  blockDetailActionIfMasterChanged() {
    return blockIfPendingChanges(this.manager, "매입계약 마스터")
  }

  switchTab(event) {
    event.preventDefault()
    const tab = event.currentTarget?.dataset?.tab
    if (!tab) return

    this.activateTab(tab)
  }

  activateTab(tab) {
    this.activeTab = tab

    this.tabButtonTargets.forEach((button) => {
      const isActive = button.dataset.tab === tab
      button.classList.toggle("is-active", isActive)
      button.setAttribute("aria-selected", isActive ? "true" : "false")
    })
    this.tabPanelTargets.forEach((panel) => {
      const isActive = panel.dataset.tabPanel === tab
      panel.classList.toggle("is-active", isActive)
      panel.hidden = !isActive
    })
  }

  fillDetailForm(rowData) {
    this.toggleDetailFields(false)

    this.detailFieldTargets.forEach((field) => {
      const key = this.detailFieldKey(field)
      if (!key) return

      field.value = this.normalizeValueForInput(key, rowData[key])
    })
  }

  clearDetailForm() {
    this.detailFieldTargets.forEach((field) => {
      field.value = ""
    })
    this.toggleDetailFields(true)
  }

  toggleDetailFields(disabled) {
    this.detailFieldTargets.forEach((field) => {
      field.disabled = disabled
    })
  }

  syncDetailField(event) {
    if (!this.currentMasterRow) return

    const fieldEl = event.currentTarget
    const key = this.detailFieldKey(fieldEl)
    if (!key) return

    const normalized = this.normalizeDetailFieldValue(key, fieldEl.value)
    if (fieldEl.value !== normalized) {
      fieldEl.value = normalized
    }

    this.currentMasterRow[key] = normalized
    this.markCurrentMasterRowUpdated()
    this.refreshMasterRowCells([key, "__row_status"])
  }

  normalizeValueForInput(fieldName, rawValue) {
    if (rawValue == null) return ""

    if (DATE_FIELDS.includes(fieldName)) {
      return this.toDateInputValue(rawValue)
    }

    return rawValue.toString()
  }

  normalizeDetailFieldValue(fieldName, rawValue) {
    const value = (rawValue || "").toString()

    if (fieldName === "bizman_no") {
      return value.replace(/[^0-9]/g, "")
    }

    if (CODE_FIELDS.includes(fieldName)) {
      return value.trim().toUpperCase()
    }

    if (DATE_FIELDS.includes(fieldName)) {
      return this.toDateInputValue(value)
    }

    if (fieldName === "remk" || fieldName.endsWith("_cond_cd") || fieldName.endsWith("_reason_cd")) {
      return value
    }

    return value.trim()
  }

  toDateInputValue(value) {
    const source = (value || "").toString().trim()
    if (source === "") return ""
    if (/^\d{4}-\d{2}-\d{2}$/.test(source)) return source

    const parsed = new Date(source)
    if (Number.isNaN(parsed.getTime())) return ""

    const yyyy = parsed.getFullYear()
    const mm = `${parsed.getMonth() + 1}`.padStart(2, "0")
    const dd = `${parsed.getDate()}`.padStart(2, "0")
    return `${yyyy}-${mm}-${dd}`
  }

  markCurrentMasterRowUpdated() {
    if (!this.currentMasterRow) return
    if (this.currentMasterRow.__is_new || this.currentMasterRow.__is_deleted) return

    this.currentMasterRow.__is_updated = true
  }

  refreshMasterRowCells(columns = []) {
    if (!isApiAlive(this.manager?.api) || !this.currentMasterRow) return

    const node = this.findMasterNodeByData(this.currentMasterRow)
    if (!node) return

    this.manager.api.refreshCells({
      rowNodes: [node],
      columns,
      force: true
    })
  }

  findMasterNodeByData(rowData) {
    if (!isApiAlive(this.manager?.api) || !rowData) return null

    let found = null
    this.manager.api.forEachNode((node) => {
      if (node.data === rowData) {
        found = node
      }
    })
    return found
  }

  bindDetailFieldEvents() {
    this.unbindDetailFieldEvents()

    this._onDetailInput = (event) => this.syncDetailField(event)
    this._onDetailChange = (event) => this.syncDetailField(event)

    this.detailFieldTargets.forEach((field) => {
      field.addEventListener("input", this._onDetailInput)
      field.addEventListener("change", this._onDetailChange)
    })
  }

  unbindDetailFieldEvents() {
    if (!this._onDetailInput && !this._onDetailChange) return

    this.detailFieldTargets.forEach((field) => {
      if (this._onDetailInput) {
        field.removeEventListener("input", this._onDetailInput)
      }
      if (this._onDetailChange) {
        field.removeEventListener("change", this._onDetailChange)
      }
    })

    this._onDetailInput = null
    this._onDetailChange = null
  }

  detailFieldKey(fieldEl) {
    if (!fieldEl) return ""

    const keyFromDataset = fieldEl.dataset.field
    if (keyFromDataset) return keyFromDataset

    const nameAttr = fieldEl.getAttribute("name") || ""
    const matchFromName = nameAttr.match(/\[([^\]]+)\]$/)
    if (matchFromName) return matchFromName[1]

    const idAttr = fieldEl.getAttribute("id") || ""
    const matchFromId = idAttr.match(/_([a-z0-9_]+)$/i)
    if (matchFromId) return matchFromId[1]

    return ""
  }

  normalizeMasterField(event) {
    const field = event?.colDef?.field
    if (!field || !event?.node?.data) return

    const row = event.node.data
    if (field === "bizman_no") {
      row[field] = (row[field] || "").toString().replace(/[^0-9]/g, "")
    } else if (CODE_FIELDS.includes(field)) {
      row[field] = (row[field] || "").toString().trim().toUpperCase()
    }

    this.manager.api.refreshCells({
      rowNodes: [event.node],
      columns: [field],
      force: true
    })
  }
}
