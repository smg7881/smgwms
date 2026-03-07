import BaseGridController from "controllers/base_grid_controller"
import { switchTab, activateTab } from "controllers/ui_utils"
import {
  bindDetailFieldEvents,
  unbindDetailFieldEvents,
  fillDetailForm as fillDetailFormUtil,
  clearDetailForm as clearDetailFormUtil,
  syncDetailField as syncDetailFieldUtil,
  toDateInputValue
} from "controllers/grid/grid_form_utils"

// 코드성 입력값: 저장 전 trim + upper 정규화 대상 필드
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

// 날짜 입력값: input[type=date] 형식으로 정규화할 필드
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

    this.activeTab = "basic"

    bindDetailFieldEvents(this, null, (event) => {
      syncDetailFieldUtil(event, this)
    })
    this.activateTab("basic")
    this.clearDetailForm()
    this.refreshSelectedLabel()
  }

  disconnect() {
    unbindDetailFieldEvents(this)
    super.disconnect()
  }

  masterConfig() {
    return {
      role: "master",
      batchUrl: "masterBatchUrlValue",
      saveMessage: "매입계약 데이터가 저장되었습니다.",
      pendingEntityLabel: "매입계약 마스터",
      key: {
        field: "pur_ctrt_no",
        stateProperty: "selectedContractValue",
        labelTarget: "selectedContractLabel",
        entityLabel: "매입계약",
        emptyMessage: "매입계약을 먼저 선택하세요."
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
        masterKeyField: "pur_ctrt_no",
        placeholder: ":id",
        listUrlTemplate: "settlementListUrlTemplateValue",
        batchUrlTemplate: "settlementBatchUrlTemplateValue",
        entityLabel: "매입계약",
        selectionMessage: "매입계약을 먼저 선택해주세요.",
        saveMessage: "매입계약 정산정보가 저장되었습니다.",
        fetchErrorMessage: "정산정보 목록 조회에 실패했습니다.",
        onSaveSuccess: () => Promise.all([
          this.reloadSettlementRows(this.selectedContractValue),
          this.reloadHistoryRowsByContract(this.selectedContractValue)
        ])
      },
      {
        role: "history",
        masterKeyField: "pur_ctrt_no",
        placeholder: ":id",
        listUrlTemplate: "historyListUrlTemplateValue",
        entityLabel: "매입계약",
        fetchErrorMessage: "변경이력 조회에 실패했습니다."
      }
    ]
  }

  gridRoles() {
    return {
      master: {
        target: "masterGrid",
        manager: "masterManagerConfig",
        masterKeyField: "pur_ctrt_no"
      },
      settlement: {
        target: "settlementGrid",
        manager: "settlementManagerConfig",
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

  masterManagerConfig() {
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
      onCellValueChanged: (event) => this.normalizeMasterField(event)
    }
  }

  settlementManagerConfig() {
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

  get manager() {
    return this.gridManager("master")
  }

  set manager(_value) {}

  async reloadHistoryRowsByContract(contractNo) {
    if (!contractNo) return
    const rows = await this.loadDetailRows("history", { pur_ctrt_no: contractNo })
    this.setRows("history", rows)
  }

  async reloadHistoryRows() {
    if (!this.requireMasterSelection(this.selectedContractValue, {
      entityLabel: "매입계약",
      message: "매입계약을 먼저 선택해주세요."
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
    fillDetailFormUtil(this, rowData)
  }

  clearDetailForm() {
    clearDetailFormUtil(this)
  }

  normalizeValueForInput(fieldName, rawValue) {
    if (rawValue == null) return ""

    if (DATE_FIELDS.includes(fieldName)) {
      return toDateInputValue(rawValue)
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
      return toDateInputValue(value)
    }

    if (fieldName === "remk" || fieldName.endsWith("_cond_cd") || fieldName.endsWith("_reason_cd")) {
      return value
    }

    return value.trim()
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

    const api = this.masterManager?.api
    if (!api) return

    api.refreshCells({
      rowNodes: [event.node],
      columns: [field],
      force: true
    })
  }
}
