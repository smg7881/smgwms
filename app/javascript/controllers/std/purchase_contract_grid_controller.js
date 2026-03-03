import BaseGridController from "controllers/base_grid_controller"
import { showAlert } from "components/ui/alert"
import {
  fetchJson,
  setManagerRowData,
  hasPendingChanges,
  blockIfPendingChanges,
  buildTemplateUrl,
  refreshSelectionLabel
} from "controllers/grid/grid_utils"
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
  // 멀티 그리드 화면에서 사용하는 주요 DOM 타겟
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

  // 마스터-디테일(정산/이력) 역할 정의
  gridRoles() {
    return {
      master: {
        target: "masterGrid",
        manager: this.masterManagerConfig(),
        masterKeyField: "pur_ctrt_no"
      },
      settlement: {
        target: "settlementGrid",
        manager: this.settlementManagerConfig(),
        parentGrid: "master",
        onMasterRowChange: (rowData) => this.handleMasterRowChange(rowData),
        detailLoader: async (rowData) => this.fetchSettlementRows(rowData)
      },
      history: {
        target: "historyGrid",
        parentGrid: "master",
        detailLoader: async (rowData) => this.fetchHistoryRows(rowData)
      }
    }
  }

  // 초기 화면 상태와 상세 폼 동기화 이벤트를 설정
  connect() {
    super.connect()

    this.currentMasterRow = null
    this.activeTab = "basic"

    bindDetailFieldEvents(this, null, (event) => {
      syncDetailFieldUtil(event, this)
    })
    this.activateTab("basic")
    this.clearDetailForm()
    this.refreshSelectedContractLabel()
  }

  // 화면 이탈 시 이벤트/참조 정리
  disconnect() {
    unbindDetailFieldEvents(this)

    this.currentMasterRow = null

    super.disconnect()
  }

  // 마스터 그리드 CRUD/정규화 규칙
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

  // 정산 디테일 그리드 CRUD/정규화 규칙
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

  // 마스터 grid manager shortcut
  get masterManager() {
    return this.gridManager("master")
  }

  // grid_form_utils가 controller.manager를 참조하므로 브릿지 제공
  get manager() {
    return this.masterManager
  }

  set manager(_v) {
    // BaseGridController.connect()/disconnect()가 this.manager에 값을 대입하므로
    // 멀티그리드 컨트롤러에서는 대입을 흡수하는 setter가 필요합니다.
    // 실제 참조는 항상 getter(get manager)로 masterManager를 반환합니다.
  }

  // 정산 grid manager shortcut
  get settlementManager() {
    return this.gridManager("settlement")
  }

  // 검색 직전 화면 상태 초기화
  beforeSearchReset() {
    this.selectedContractValue = ""
    this.currentMasterRow = null
    this.refreshSelectedContractLabel()
    this.clearDetailForm()
  }

  // 마스터 선택 변경 시 상세 폼/라벨/디테일 그리드 초기화
  handleMasterRowChange(rowData) {
    this.currentMasterRow = rowData || null

    if (!rowData) {
      this.clearDetailForm()
    } else {
      this.fillDetailForm(rowData)
    }

    this.selectedContractValue = rowData?.pur_ctrt_no || ""
    this.refreshSelectedContractLabel()

    this.clearSettlementRows()
    this.clearHistoryRows()
  }

  // ----- 마스터 CRUD -----
  addMasterRow() {
    this.addRow({
      manager: this.masterManager,
      config: { startCol: "pur_ctrt_nm" },
      onAdded: (rowData) => {
        this.activateTab("basic")
        this.handleMasterRowChange(rowData)
      }
    })
  }

  deleteMasterRows() {
    this.deleteRows({ manager: this.masterManager })
  }

  async saveMasterRows() {
    await this.saveRowsWith({
      manager: this.masterManager,
      batchUrl: this.masterBatchUrlValue,
      saveMessage: "매입계약 데이터가 저장되었습니다.",
      onSuccess: () => this.refreshGrid("master")
    })
  }

  // ----- 정산 CRUD -----
  addSettlementRow() {
    if (!this.settlementManager) return
    if (this.blockDetailActionIfMasterChanged()) return

    if (!this.selectedContractValue) {
      showAlert("매입계약을 먼저 선택해주세요.")
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
      showAlert("매입계약을 먼저 선택해주세요.")
      return
    }

    const batchUrl = buildTemplateUrl(this.settlementBatchUrlTemplateValue, ":id", this.selectedContractValue)
    await this.saveRowsWith({
      manager: this.settlementManager,
      batchUrl,
      saveMessage: "매입계약 정산정보가 저장되었습니다.",
      onSuccess: () => Promise.all([
        this.reloadSettlementRows(this.selectedContractValue),
        this.reloadHistoryRowsByContract(this.selectedContractValue)
      ])
    })
  }

  // ----- 디테일 로더(마스터 선택 연동) -----
  async fetchSettlementRows(rowData) {
    const contractNo = rowData?.pur_ctrt_no
    const canLoad = Boolean(contractNo) && !rowData?.__is_deleted && !rowData?.__is_new
    if (!canLoad) return []

    return this.fetchSettlementRowsByContract(contractNo)
  }

  async fetchSettlementRowsByContract(contractNo) {
    if (!contractNo) return []

    try {
      const url = buildTemplateUrl(this.settlementListUrlTemplateValue, ":id", contractNo)
      const rows = await fetchJson(url)
      return Array.isArray(rows) ? rows : []
    } catch {
      showAlert("정산정보 목록 조회에 실패했습니다.")
      return []
    }
  }

  async fetchHistoryRows(rowData) {
    const contractNo = rowData?.pur_ctrt_no
    const canLoad = Boolean(contractNo) && !rowData?.__is_deleted && !rowData?.__is_new
    if (!canLoad) return []

    return this.fetchHistoryRowsByContract(contractNo)
  }

  async fetchHistoryRowsByContract(contractNo) {
    if (!contractNo) return []

    try {
      const url = buildTemplateUrl(this.historyListUrlTemplateValue, ":id", contractNo)
      const rows = await fetchJson(url)
      return Array.isArray(rows) ? rows : []
    } catch {
      showAlert("변경이력 조회에 실패했습니다.")
      return []
    }
  }

  // 저장 후 특정 계약 기준으로 디테일 재조회
  async reloadSettlementRows(contractNo) {
    const rows = await this.fetchSettlementRowsByContract(contractNo)
    setManagerRowData(this.settlementManager, rows)
  }

  async reloadHistoryRowsByContract(contractNo) {
    const rows = await this.fetchHistoryRowsByContract(contractNo)
    this.setRows("history", rows)
  }

  // 이력 탭 수동 새로고침 액션
  async reloadHistoryRows() {
    if (!this.selectedContractValue) {
      showAlert("매입계약을 먼저 선택해주세요.")
      return
    }

    await this.reloadHistoryRowsByContract(this.selectedContractValue)
  }

  // 디테일 그리드 비우기
  clearSettlementRows() {
    setManagerRowData(this.settlementManager, [])
  }

  clearHistoryRows() {
    this.setRows("history", [])
  }

  // 상세 폼 submit 기본 동작 차단(그리드 저장 흐름 사용)
  preventDetailSubmit(event) {
    event.preventDefault()
  }

  // 선택된 계약 라벨 표시 갱신
  refreshSelectedContractLabel() {
    if (!this.hasSelectedContractLabelTarget) return

    refreshSelectionLabel(this.selectedContractLabelTarget, this.selectedContractValue, "매입계약", "매입계약을 먼저 선택하세요.")
  }

  // 마스터 미저장 변경 여부 검사
  hasMasterPendingChanges() {
    return hasPendingChanges(this.masterManager)
  }

  blockDetailActionIfMasterChanged() {
    return blockIfPendingChanges(this.masterManager, "매입계약 마스터")
  }

  // 탭 전환
  switchTab(event) {
    switchTab(event, this)
  }

  activateTab(tab) {
    activateTab(tab, this)
  }

  // 상세 폼 <-> 마스터 행 동기화
  fillDetailForm(rowData) {
    fillDetailFormUtil(this, rowData)
  }

  clearDetailForm() {
    clearDetailFormUtil(this)
  }

  // 입력 필드 표시용 정규화
  normalizeValueForInput(fieldName, rawValue) {
    if (rawValue == null) return ""

    if (DATE_FIELDS.includes(fieldName)) {
      return toDateInputValue(rawValue)
    }

    return rawValue.toString()
  }

  // 상세 폼 저장용 정규화
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

  // 마스터 셀 입력 정규화(코드/사업자번호)
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
