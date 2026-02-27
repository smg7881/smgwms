import MasterDetailGridController from "controllers/master_detail_grid_controller"
import { showAlert } from "components/ui/alert"
import { isApiAlive, fetchJson, setManagerRowData, hasPendingChanges, blockIfPendingChanges, buildTemplateUrl, refreshSelectionLabel } from "controllers/grid/grid_utils"
import { switchTab, activateTab } from "controllers/ui_utils"
import * as GridFormUtils from "controllers/grid/grid_form_utils"
const CODE_FIELDS = [
  "corp_cd",
  "bzac_cd",
  "sell_ctrt_no",
  "ctrt_sctn_cd",
  "ctrt_kind_cd",
  "bef_ctrt_no",
  "ctrt_dept_cd",
  "ctrt_cnctr_reason_cd",
  "indgrp_cd",
  "loan_limt_over_yn_cd",
  "vat_sctn_cd",
  "apv_mthd_cd",
  "apv_type_cd",
  "bilg_mthd_cd",
  "dcsn_yn_cd",
  "use_yn_cd"
]

const DATE_FIELDS = [
  "ord_recp_poss_ymd",
  "strt_ctrt_ymd",
  "ctrt_strt_day",
  "ctrt_end_day",
  "ctrt_exten_ymd",
  "ctrt_expi_noti_ymd",
  "ctrt_cnctr_ymd"
]

export default class extends MasterDetailGridController {
  static targets = [
    ...MasterDetailGridController.targets,
    "masterGrid",
    "settlementGrid",
    "historyGrid",
    "selectedContractLabel",
    "detailField",
    "tabButton",
    "tabPanel"
  ]

  static values = {
    ...MasterDetailGridController.values,
    masterBatchUrl: String,
    settlementBatchUrlTemplate: String,
    settlementListUrlTemplate: String,
    historyListUrlTemplate: String,
    selectedContract: String
  }

  connect() {
    super.connect()
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
      pkFields: ["sell_ctrt_no"],
      fields: {
        corp_cd: "trimUpper",
        bzac_cd: "trimUpper",
        sell_ctrt_no: "trimUpper",
        sell_ctrt_nm: "trim",
        bizman_no: "trim",
        ctrt_sctn_cd: "trimUpper",
        ctrt_kind_cd: "trimUpper",
        bef_ctrt_no: "trimUpper",
        ctrt_dept_cd: "trimUpper",
        ctrt_dept_nm: "trim",
        ord_recp_poss_ymd: "trim",
        strt_ctrt_ymd: "trim",
        ctrt_strt_day: "trim",
        ctrt_end_day: "trim",
        ctrt_exten_ymd: "trim",
        ctrt_expi_noti_ymd: "trim",
        ctrt_cnctr_ymd: "trim",
        ctrt_cnctr_reason_cd: "trimUpper",
        indgrp_cd: "trimUpper",
        loan_limt_over_yn_cd: "trimUpperDefault:N",
        ctrt_amt: "number",
        vat_sctn_cd: "trimUpper",
        apv_mthd_cd: "trimUpper",
        apv_type_cd: "trimUpper",
        bilg_mthd_cd: "trimUpper",
        dcsn_yn_cd: "trimUpperDefault:N",
        use_yn_cd: "trimUpperDefault:Y",
        ctrt_amt_chg_reason: "trim",
        main_rsbt_clause: "trim",
        re_ctrt_cond: "trim",
        ctrt_cnctr_cond: "trim",
        ctrt_cnctr_dtl_reason: "trim",
        sell_bnfit_amt: "number",
        sell_bnfit_rt: "number",
        contrbtn_bnfit_amt: "number",
        contrbtn_bnfit_rt: "number",
        remk: "trim"
      },
      defaultRow: {
        corp_cd: "",
        bzac_cd: "",
        sell_ctrt_no: "",
        sell_ctrt_nm: "",
        bizman_no: "",
        ctrt_sctn_cd: "",
        ctrt_kind_cd: "",
        bef_ctrt_no: "",
        ctrt_dept_cd: "",
        ctrt_dept_nm: "",
        ord_recp_poss_ymd: "",
        strt_ctrt_ymd: "",
        ctrt_strt_day: "",
        ctrt_end_day: "",
        ctrt_exten_ymd: "",
        ctrt_expi_noti_ymd: "",
        ctrt_cnctr_ymd: "",
        ctrt_cnctr_reason_cd: "",
        indgrp_cd: "",
        loan_limt_over_yn_cd: "N",
        ctrt_amt: null,
        vat_sctn_cd: "GENERAL",
        apv_mthd_cd: "TRANSFER",
        apv_type_cd: "NORMAL",
        bilg_mthd_cd: "MONTHLY",
        dcsn_yn_cd: "N",
        use_yn_cd: "Y",
        ctrt_amt_chg_reason: "",
        main_rsbt_clause: "",
        re_ctrt_cond: "",
        ctrt_cnctr_cond: "",
        ctrt_cnctr_dtl_reason: "",
        sell_bnfit_amt: null,
        sell_bnfit_rt: null,
        contrbtn_bnfit_amt: null,
        contrbtn_bnfit_rt: null,
        remk: ""
      },
      blankCheckFields: ["sell_ctrt_nm"],
      comparableFields: [
        "corp_cd", "bzac_cd", "sell_ctrt_nm", "bizman_no", "ctrt_sctn_cd", "ctrt_kind_cd",
        "bef_ctrt_no", "ctrt_dept_cd", "ctrt_dept_nm", "ord_recp_poss_ymd",
        "strt_ctrt_ymd", "ctrt_strt_day", "ctrt_end_day",
        "ctrt_exten_ymd", "ctrt_expi_noti_ymd", "ctrt_cnctr_ymd", "ctrt_cnctr_reason_cd",
        "indgrp_cd", "loan_limt_over_yn_cd", "ctrt_amt",
        "vat_sctn_cd", "apv_mthd_cd", "apv_type_cd", "bilg_mthd_cd", "dcsn_yn_cd", "use_yn_cd",
        "ctrt_amt_chg_reason", "main_rsbt_clause", "re_ctrt_cond", "ctrt_cnctr_cond",
        "ctrt_cnctr_dtl_reason",
        "sell_bnfit_amt", "sell_bnfit_rt", "contrbtn_bnfit_amt", "contrbtn_bnfit_rt",
        "remk"
      ],
      firstEditCol: "sell_ctrt_nm",
      pkLabels: { sell_ctrt_no: "매출계약번호" },
      onCellValueChanged: (event) => this.normalizeMasterField(event),
      onRowDataUpdated: () => {
        this.handleMasterRowDataUpdated({ resetTrackingManagers: [this.settlementManager] })
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
        main_bank_yn_cd: "trimUpper",
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
        main_bank_yn_cd: "N",
        exca_ofcr_cd: "",
        exca_ofcr_nm: "",
        use_yn_cd: "Y",
        remk: ""
      },
      blankCheckFields: ["fnc_or_cd"],
      comparableFields: [
        "fnc_or_cd", "fnc_or_nm", "acnt_no_cd", "dpstr_nm", "mon_cd", "aply_fnc_or_cd",
        "aply_fnc_or_nm", "anno_dgrcnt", "exrt_aply_std_cd", "prvs_cyfd_amt", "main_bank_yn_cd",
        "exca_ofcr_cd", "exca_ofcr_nm", "use_yn_cd", "remk"
      ],
      firstEditCol: "fnc_or_cd",
      pkLabels: { seq_no: "순번" }
    }
  }

  detailGridConfigs() {
    return [
      {
        target: this.hasSettlementGridTarget ? this.settlementGridTarget : null,
        controllerKey: "settlementGridController",
        managerKey: "settlementManager",
        configMethod: "configureSettlementManager"
      },
      {
        target: this.hasHistoryGridTarget ? this.historyGridTarget : null,
        controllerKey: "historyGridController"
      }
    ]
  }

  isDetailReady() {
    return isApiAlive(this.settlementManager?.api) && isApiAlive(this.historyGridController?.api)
  }

  async handleMasterRowChange(rowData) {
    await this.syncMasterDetailByCode(rowData, {
      codeField: "sell_ctrt_no",
      beforeSync: (masterRow) => {
        this.currentMasterRow = masterRow || null
        if (!masterRow) {
          this.clearDetailForm()
          return
        }

        this.fillDetailForm(masterRow)
      },
      setSelectedCode: (code) => { this.selectedContractValue = code },
      refreshLabel: () => this.refreshSelectedContractLabel(),
      clearDetails: () => {
        this.clearSettlementRows()
        this.clearHistoryRows()
      },
      loadDetails: async (contractNo) => {
        await Promise.all([this.loadSettlementRows(contractNo), this.loadHistoryRows(contractNo)])
      }
    })
  }

  addMasterRow() {
    this.addRow({
      manager: this.manager,
      config: { startCol: "sell_ctrt_nm" },
      onAdded: (rowData) => {
        this.activateTab("basic")
        this.handleMasterRowChangeOnce(rowData, { force: true })
      }
    })
  }

  deleteMasterRows() {
    this.deleteRows()
  }

  async saveMasterRows() {
    await this.saveRowsWith({
      manager: this.manager,
      batchUrl: this.batchUrlValue,
      saveMessage: this.saveMessage,
      onSuccess: () => this.afterSaveSuccess()
    })
  }

  get batchUrlValue() {
    return this.masterBatchUrlValue
  }

  get saveMessage() {
    return "매출계약 데이터가 저장되었습니다."
  }

  async afterSaveSuccess() {
    await this.reloadMasterRows()
  }

  async reloadMasterRows() {
    await super.reloadMasterRows({ errorMessage: "매출계약 목록 조회에 실패했습니다." })
  }

  addSettlementRow() {
    if (!this.settlementManager) return
    if (this.blockDetailActionIfMasterChanged()) return

    if (!this.selectedContractValue) {
      showAlert("매출계약을 먼저 선택해주세요.")
      return
    }

    this.addRow({ manager: this.settlementManager })
  }

  deleteSettlementRows() {
    if (!this.settlementManager) return
    if (this.blockDetailActionIfMasterChanged()) return

    this.deleteRows({ manager: this.settlementManager })
  }

  async saveSettlementRows() {
    if (!this.settlementManager) return
    if (this.blockDetailActionIfMasterChanged()) return

    if (!this.selectedContractValue) {
      showAlert("매출계약을 먼저 선택해주세요.")
      return
    }

    const batchUrl = buildTemplateUrl(this.settlementBatchUrlTemplateValue, ":id", this.selectedContractValue)
    await this.saveRowsWith({
      manager: this.settlementManager,
      batchUrl,
      saveMessage: "매출계약 정산정보가 저장되었습니다.",
      onSuccess: () => Promise.all([
        this.loadSettlementRows(this.selectedContractValue),
        this.loadHistoryRows(this.selectedContractValue)
      ])
    })
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
      showAlert("정산정보 목록 조회에 실패했습니다.")
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
      showAlert("변경이력 조회에 실패했습니다.")
    }
  }

  async reloadHistoryRows() {
    if (!this.selectedContractValue) {
      showAlert("매출계약을 먼저 선택해주세요.")
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
    refreshSelectionLabel(this.selectedContractLabelTarget, this.selectedContractValue, "매출계약", "매출계약을 먼저 선택하세요.")
  }

  hasMasterPendingChanges() {
    return hasPendingChanges(this.manager)
  }

  blockDetailActionIfMasterChanged() {
    return blockIfPendingChanges(this.manager, "매출계약 마스터")
  }

  switchTab(event) {
    switchTab(event, this)
  }

  activateTab(tab) {
    activateTab(tab, this)
  }

  fillDetailForm(rowData) {
    GridFormUtils.fillDetailForm(this, rowData)
  }

  clearDetailForm() {
    GridFormUtils.clearDetailForm(this)
  }

  toggleDetailFields(disabled) {
    GridFormUtils.toggleDetailFields(this, disabled)
  }

  syncDetailField(event) {
    GridFormUtils.syncDetailField(event, this)
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

    if (fieldName === "remk" || fieldName.endsWith("_cond") || fieldName.endsWith("_reason") || fieldName.endsWith("_clause")) {
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
    GridFormUtils.markCurrentMasterRowUpdated(this)
  }

  refreshMasterRowCells(columns = []) {
    GridFormUtils.refreshMasterRowCells(this, columns)
  }

  findMasterNodeByData(rowData) {
    return GridFormUtils.findMasterNodeByData(this, rowData)
  }

  bindDetailFieldEvents() {
    GridFormUtils.bindDetailFieldEvents(this)
  }

  unbindDetailFieldEvents() {
    GridFormUtils.unbindDetailFieldEvents(this)
  }

  detailFieldKey(fieldEl) {
    return GridFormUtils.detailFieldKey(fieldEl)
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
