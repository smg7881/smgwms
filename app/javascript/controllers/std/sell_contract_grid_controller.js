import BaseGridController from "controllers/base_grid_controller"
import { switchTab, activateTab } from "controllers/ui_utils"
import * as GridFormUtils from "controllers/grid/grid_form_utils"
import { refreshGridCells } from "controllers/grid/grid_api_utils"

const DATE_FIELDS = [
  "ord_recp_poss_ymd",
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

    this.activeTab = "basic"

    this.bindDetailFieldEvents()
    this.activateTab("basic")
    this.clearDetailForm()
    this.refreshSelectedLabel()
  }

  disconnect() {
    this.unbindDetailFieldEvents()
    super.disconnect()
  }

  masterConfig() {
    return {
      role: "master",
      batchUrl: "masterBatchUrlValue",
      saveMessage: "매출계약 데이터가 저장되었습니다.",
      pendingEntityLabel: "매출계약 마스터",
      key: {
        field: "sell_ctrt_no",
        stateProperty: "selectedContractValue",
        labelTarget: "selectedContractLabel",
        entityLabel: "매출계약",
        emptyMessage: "매출계약을 먼저 선택하세요."
      },
      onRowChange: {
        trackCurrentRow: true,
        syncForm: true
      },
      beforeSearch: {
        clearForm: true
      },
      onSaveSuccess: () => this.refreshGrid("master"),
      onAdded: (rowData) => {
        this.activateTab("basic")
        this.onMasterRowChanged(rowData)
      }
    }
  }

  detailGrids() {
    return [
      {
        role: "settlement",
        masterKeyField: "sell_ctrt_no",
        placeholder: ":id",
        listUrlTemplate: "settlementListUrlTemplateValue",
        batchUrlTemplate: "settlementBatchUrlTemplateValue",
        entityLabel: "매출계약",
        selectionMessage: "매출계약을 먼저 선택해주세요.",
        saveMessage: "매출계약 정산정보가 저장되었습니다.",
        fetchErrorMessage: "정산정보 목록 조회에 실패했습니다.",
        onSaveSuccess: () => Promise.all([
          this.reloadSettlementRows(this.selectedContractValue),
          this.reloadHistoryRowsByContract(this.selectedContractValue)
        ])
      },
      {
        role: "history",
        masterKeyField: "sell_ctrt_no",
        placeholder: ":id",
        listUrlTemplate: "historyListUrlTemplateValue",
        entityLabel: "매출계약",
        fetchErrorMessage: "변경이력 조회에 실패했습니다."
      }
    ]
  }

  gridRoles() {
    return {
      master: {
        target: "masterGrid",
        manager: "configureManager",
        masterKeyField: "sell_ctrt_no"
      },
      settlement: {
        target: "settlementGrid",
        manager: "configureSettlementManager",
        parentGrid: "master",
        onMasterRowChange: (rowData) => this.onMasterRowChanged(rowData),
        detailLoader: (rowData) => this.loadDetailRows("settlement", rowData)
      },
      history: {
        target: "historyGrid",
        parentGrid: "master",
        detailLoader: (rowData) => this.loadDetailRows("history", rowData)
      }
    }
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
        this.settlementManager?.resetTracking?.()
        this.selectFirstMasterRow()
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

  get manager() {
    return this.gridManager("master")
  }

  set manager(_value) {}

  async reloadHistoryRowsByContract(contractNo) {
    if (!contractNo) return
    const rows = await this.loadDetailRows("history", { sell_ctrt_no: contractNo })
    this.setRows("history", rows)
  }

  async reloadHistoryRows() {
    if (!this.requireMasterSelection(this.selectedContractValue, {
      entityLabel: "매출계약",
      message: "매출계약을 먼저 선택해주세요."
    })) {
      return
    }

    await this.reloadHistoryRowsByContract(this.selectedContractValue)
  }

  preventDetailSubmit(event) {
    event.preventDefault()
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
    }

    refreshGridCells(this.masterManager?.api, {
      rowNodes: [event.node],
      columns: [field],
      force: true
    })
  }
}
