import BaseGridController from "controllers/base_grid_controller"
import { showAlert } from "components/ui/alert"
import {
  fetchJson,
  setManagerRowData,
  hasPendingChanges,
  blockIfPendingChanges,
  buildTemplateUrl,
  refreshSelectionLabel,
  setSelectOptions as setSelectOptionsUtil
} from "controllers/grid/grid_utils"
import { switchTab, activateTab } from "controllers/ui_utils"

// 코드성 필드: 상세 폼/그리드 입력 시 대문자 정규화 대상
const CODE_FIELDS = [
  "bzac_cd",
  "mngt_corp_cd",
  "bzac_sctn_grp_cd",
  "bzac_sctn_cd",
  "bzac_kind_cd",
  "upper_bzac_cd",
  "rpt_bzac_cd",
  "ctry_cd",
  "tpl_logis_yn_cd",
  "if_yn_cd",
  "branch_yn_cd",
  "sell_bzac_yn_cd",
  "pur_bzac_yn_cd",
  "bilg_bzac_cd",
  "elec_taxbill_yn_cd",
  "fnc_or_cd",
  "rpt_sales_emp_cd",
  "use_yn_cd"
]

// 날짜 필드: input[type=date] 포맷으로 정규화 대상
const DATE_FIELDS = ["aply_strt_day_cd", "aply_end_day_cd"]

// 거래처 마스터 + 담당자/작업장 디테일 + 상세 폼 동기화 컨트롤러
export default class extends BaseGridController {
  static targets = [
    ...BaseGridController.targets,
    "masterGrid",
    "contactsGrid",
    "workplacesGrid",
    "selectedClientLabel",
    "detailField",
    "detailGroupField",
    "detailSectionField",
    "tabButton",
    "tabPanel"
  ]

  static values = {
    ...BaseGridController.values,
    masterBatchUrl: String,
    contactBatchUrlTemplate: String,
    contactListUrlTemplate: String,
    workplaceBatchUrlTemplate: String,
    workplaceListUrlTemplate: String,
    sectionsUrl: String,
    sectionMap: Object,
    selectedClient: String
  }

  // 초기 화면 상태/이벤트 바인딩
  connect() {
    super.connect()

    this.financialInstitutionNameCache = new Map()
    this.currentMasterRow = null
    this.activeTab = "basic"

    this.bindSearchFields()
    this.bindDetailFieldEvents()
    this.activateTab("basic")
    this.clearDetailForm()
    this.refreshSelectedClientLabel()
  }

  // 이벤트 해제 및 상태 정리
  disconnect() {
    this.unbindSearchFields()
    this.unbindDetailFieldEvents()

    this.currentMasterRow = null
    this.financialInstitutionNameCache = null

    super.disconnect()
  }

  // 다중 그리드 역할 정의 (master -> contacts/workplaces)
  gridRoles() {
    return {
      master: {
        target: "masterGrid",
        manager: this.masterManagerConfig(),
        masterKeyField: "bzac_cd"
      },
      contacts: {
        target: "contactsGrid",
        manager: this.contactManagerConfig(),
        parentGrid: "master",
        onMasterRowChange: (rowData) => this.handleMasterRowChange(rowData),
        detailLoader: async (rowData) => this.fetchContactRows(rowData)
      },
      workplaces: {
        target: "workplacesGrid",
        manager: this.workplaceManagerConfig(),
        parentGrid: "master",
        detailLoader: async (rowData) => this.fetchWorkplaceRows(rowData)
      }
    }
  }

  // 마스터 거래처 CRUD/정규화 규칙
  masterManagerConfig() {
    return {
      pkFields: ["bzac_cd"],
      fields: {
        bzac_cd: "trimUpper",
        bzac_nm: "trim",
        mngt_corp_cd: "trimUpper",
        bizman_no: "trim",
        bzac_sctn_grp_cd: "trimUpper",
        bzac_sctn_cd: "trimUpper",
        bzac_kind_cd: "trimUpper",
        upper_bzac_cd: "trimUpper",
        rpt_bzac_cd: "trimUpper",
        ctry_cd: "trimUpperDefault:KR",
        tpl_logis_yn_cd: "trimUpperDefault:N",
        if_yn_cd: "trimUpperDefault:N",
        branch_yn_cd: "trimUpperDefault:N",
        sell_bzac_yn_cd: "trimUpperDefault:Y",
        pur_bzac_yn_cd: "trimUpperDefault:Y",
        bilg_bzac_cd: "trimUpper",
        elec_taxbill_yn_cd: "trimUpperDefault:N",
        fnc_or_cd: "trimUpper",
        acnt_no_cd: "trim",
        zip_cd: "trim",
        addr_cd: "trim",
        addr_dtl_cd: "trim",
        rpt_sales_emp_cd: "trimUpper",
        rpt_sales_emp_nm: "trim",
        aply_strt_day_cd: "trim",
        aply_end_day_cd: "trim",
        use_yn_cd: "trimUpperDefault:Y",
        remk: "trim"
      },
      defaultRow: {
        bzac_cd: "",
        bzac_nm: "",
        mngt_corp_cd: "",
        bizman_no: "",
        bzac_sctn_grp_cd: "",
        bzac_sctn_cd: "",
        bzac_kind_cd: "CORP",
        upper_bzac_cd: "",
        rpt_bzac_cd: "",
        ctry_cd: "KR",
        tpl_logis_yn_cd: "N",
        if_yn_cd: "N",
        branch_yn_cd: "N",
        sell_bzac_yn_cd: "Y",
        pur_bzac_yn_cd: "Y",
        bilg_bzac_cd: "",
        elec_taxbill_yn_cd: "N",
        fnc_or_cd: "",
        acnt_no_cd: "",
        zip_cd: "",
        addr_cd: "",
        addr_dtl_cd: "",
        rpt_sales_emp_cd: "",
        rpt_sales_emp_nm: "",
        aply_strt_day_cd: "",
        aply_end_day_cd: "",
        use_yn_cd: "Y",
        remk: ""
      },
      blankCheckFields: ["bzac_nm", "bizman_no"],
      comparableFields: [
        "bzac_nm",
        "mngt_corp_cd",
        "bizman_no",
        "bzac_sctn_grp_cd",
        "bzac_sctn_cd",
        "bzac_kind_cd",
        "upper_bzac_cd",
        "rpt_bzac_cd",
        "ctry_cd",
        "tpl_logis_yn_cd",
        "if_yn_cd",
        "branch_yn_cd",
        "sell_bzac_yn_cd",
        "pur_bzac_yn_cd",
        "bilg_bzac_cd",
        "elec_taxbill_yn_cd",
        "fnc_or_cd",
        "acnt_no_cd",
        "zip_cd",
        "addr_cd",
        "addr_dtl_cd",
        "rpt_sales_emp_cd",
        "rpt_sales_emp_nm",
        "aply_strt_day_cd",
        "aply_end_day_cd",
        "use_yn_cd",
        "remk"
      ],
      firstEditCol: "bzac_nm",
      pkLabels: { bzac_cd: "거래처코드" },
      onCellValueChanged: (event) => this.normalizeMasterField(event)
    }
  }

  // 담당자 그리드 CRUD 규칙
  contactManagerConfig() {
    return {
      pkFields: ["seq_cd"],
      fields: {
        seq_cd: "number",
        nm_cd: "trim",
        ofic_telno_cd: "trim",
        mbp_no_cd: "trim",
        email_cd: "trim",
        rpt_yn_cd: "trimUpperDefault:N",
        use_yn_cd: "trimUpperDefault:Y"
      },
      defaultRow: {
        seq_cd: null,
        nm_cd: "",
        ofic_telno_cd: "",
        mbp_no_cd: "",
        email_cd: "",
        rpt_yn_cd: "N",
        use_yn_cd: "Y"
      },
      blankCheckFields: ["nm_cd"],
      comparableFields: ["nm_cd", "ofic_telno_cd", "mbp_no_cd", "email_cd", "rpt_yn_cd", "use_yn_cd"],
      firstEditCol: "nm_cd",
      pkLabels: { seq_cd: "순번" }
    }
  }

  // 작업장 그리드 CRUD 규칙
  workplaceManagerConfig() {
    return {
      pkFields: ["seq_cd"],
      fields: {
        seq_cd: "number",
        workpl_nm_cd: "trim",
        workpl_sctn_cd: "trimUpper",
        ofcr_cd: "trimUpper",
        use_yn_cd: "trimUpperDefault:Y"
      },
      defaultRow: {
        seq_cd: null,
        workpl_nm_cd: "",
        workpl_sctn_cd: "",
        ofcr_cd: "",
        use_yn_cd: "Y"
      },
      blankCheckFields: ["workpl_nm_cd"],
      comparableFields: ["workpl_nm_cd", "workpl_sctn_cd", "ofcr_cd", "use_yn_cd"],
      firstEditCol: "workpl_nm_cd",
      pkLabels: { seq_cd: "순번" }
    }
  }

  // 역할별 매니저 접근 getter
  get masterManager() {
    return this.gridManager("master")
  }

  get contactManager() {
    return this.gridManager("contacts")
  }

  get workplaceManager() {
    return this.gridManager("workplaces")
  }

  // 검색 전 상태 초기화
  beforeSearchReset() {
    this.selectedClientValue = ""
    this.currentMasterRow = null
    this.refreshSelectedClientLabel()
    this.clearDetailForm()
  }

  // 마스터 행 변경 시 상세 폼/선택 라벨/디테일 데이터 초기화
  handleMasterRowChange(rowData) {
    this.currentMasterRow = rowData || null

    if (!rowData) {
      this.clearDetailForm()
    } else {
      this.fillDetailForm(rowData)
    }

    this.selectedClientValue = rowData?.bzac_cd || ""
    this.refreshSelectedClientLabel()

    this.clearContactRows()
    this.clearWorkplaceRows()
  }

  // ----- 마스터 CRUD -----
  addMasterRow() {
    this.addRow({
      manager: this.masterManager,
      config: { startCol: "bzac_nm" },
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
      saveMessage: "거래처 데이터가 저장되었습니다.",
      onSuccess: () => this.refreshGrid("master")
    })
  }

  // ----- 담당자 CRUD -----
  addContactRow() {
    if (!this.contactManager) return
    if (this.blockDetailActionIfMasterChanged()) return

    if (!this.selectedClientValue) {
      showAlert("거래처를 먼저 선택해주세요.")
      return
    }

    this.addRow({ manager: this.contactManager })
  }

  deleteContactRows() {
    if (!this.contactManager) return
    if (this.blockDetailActionIfMasterChanged()) return

    this.deleteRows({ manager: this.contactManager })
  }

  async saveContactRows() {
    if (!this.contactManager) return
    if (this.blockDetailActionIfMasterChanged()) return

    if (!this.selectedClientValue) {
      showAlert("거래처를 먼저 선택해주세요.")
      return
    }

    const batchUrl = buildTemplateUrl(this.contactBatchUrlTemplateValue, ":id", this.selectedClientValue)
    await this.saveRowsWith({
      manager: this.contactManager,
      batchUrl,
      saveMessage: "거래처 담당자 데이터가 저장되었습니다.",
      onSuccess: () => this.reloadContactRows(this.selectedClientValue)
    })
  }

  // ----- 작업장 CRUD -----
  addWorkplaceRow() {
    if (!this.workplaceManager) return
    if (this.blockDetailActionIfMasterChanged()) return

    if (!this.selectedClientValue) {
      showAlert("거래처를 먼저 선택해주세요.")
      return
    }

    this.addRow({ manager: this.workplaceManager })
  }

  deleteWorkplaceRows() {
    if (!this.workplaceManager) return
    if (this.blockDetailActionIfMasterChanged()) return

    this.deleteRows({ manager: this.workplaceManager })
  }

  async saveWorkplaceRows() {
    if (!this.workplaceManager) return
    if (this.blockDetailActionIfMasterChanged()) return

    if (!this.selectedClientValue) {
      showAlert("거래처를 먼저 선택해주세요.")
      return
    }

    const batchUrl = buildTemplateUrl(this.workplaceBatchUrlTemplateValue, ":id", this.selectedClientValue)
    await this.saveRowsWith({
      manager: this.workplaceManager,
      batchUrl,
      saveMessage: "거래처 작업장 데이터가 저장되었습니다.",
      onSuccess: () => this.reloadWorkplaceRows(this.selectedClientValue)
    })
  }

  // ----- 디테일 조회/재조회 -----
  async fetchContactRows(rowData) {
    const clientCode = rowData?.bzac_cd
    const canLoad = Boolean(clientCode) && !rowData?.__is_deleted && !rowData?.__is_new
    if (!canLoad) return []

    return this.fetchContactRowsByClient(clientCode)
  }

  async fetchContactRowsByClient(clientCode) {
    if (!clientCode) return []

    try {
      const url = buildTemplateUrl(this.contactListUrlTemplateValue, ":id", clientCode)
      const rows = await fetchJson(url)
      return Array.isArray(rows) ? rows : []
    } catch {
      showAlert("담당자 목록 조회에 실패했습니다.")
      return []
    }
  }

  async fetchWorkplaceRows(rowData) {
    const clientCode = rowData?.bzac_cd
    const canLoad = Boolean(clientCode) && !rowData?.__is_deleted && !rowData?.__is_new
    if (!canLoad) return []

    return this.fetchWorkplaceRowsByClient(clientCode)
  }

  async fetchWorkplaceRowsByClient(clientCode) {
    if (!clientCode) return []

    try {
      const url = buildTemplateUrl(this.workplaceListUrlTemplateValue, ":id", clientCode)
      const rows = await fetchJson(url)
      return Array.isArray(rows) ? rows : []
    } catch {
      showAlert("작업장 목록 조회에 실패했습니다.")
      return []
    }
  }

  async reloadContactRows(clientCode) {
    const rows = await this.fetchContactRowsByClient(clientCode)
    setManagerRowData(this.contactManager, rows)
  }

  async reloadWorkplaceRows(clientCode) {
    const rows = await this.fetchWorkplaceRowsByClient(clientCode)
    setManagerRowData(this.workplaceManager, rows)
  }

  // 디테일 그리드 비우기
  clearContactRows() {
    setManagerRowData(this.contactManager, [])
  }

  clearWorkplaceRows() {
    setManagerRowData(this.workplaceManager, [])
  }

  // 상세 폼 submit 기본 동작 차단 (그리드 저장 흐름 사용)
  preventDetailSubmit(event) {
    event.preventDefault()
  }

  // 선택 거래처 라벨 갱신
  refreshSelectedClientLabel() {
    if (!this.hasSelectedClientLabelTarget) return

    refreshSelectionLabel(this.selectedClientLabelTarget, this.selectedClientValue, "거래처", "거래처를 먼저 선택하세요.")
  }

  // 마스터 변경 미저장 상태 체크
  hasMasterPendingChanges() {
    return hasPendingChanges(this.masterManager)
  }

  blockDetailActionIfMasterChanged() {
    return blockIfPendingChanges(this.masterManager, "마스터 거래처")
  }

  // 탭 전환
  switchTab(event) {
    switchTab(event, this)
  }

  activateTab(tab) {
    activateTab(tab, this)
  }

  // ----- 상세 폼 <-> 마스터 행 동기화 -----
  fillDetailForm(rowData) {
    this.toggleDetailFields(false)
    this.updateDetailSectionOptions(rowData?.bzac_sctn_grp_cd, rowData?.bzac_sctn_cd)

    this.detailFieldTargets.forEach((field) => {
      const key = this.detailFieldKey(field)
      if (!key) return

      const value = this.normalizeValueForInput(key, rowData?.[key])
      field.value = value
      this.syncPopupFieldPresentation(field, key, value, rowData)
    })
  }

  clearDetailForm() {
    this.detailFieldTargets.forEach((field) => {
      field.value = ""
      const key = this.detailFieldKey(field)
      this.syncPopupFieldPresentation(field, key, "")
    })

    this.updateDetailSectionOptions("", "")
    this.toggleDetailFields(true)
  }

  toggleDetailFields(disabled) {
    this.detailFieldTargets.forEach((field) => {
      field.disabled = disabled
      this.togglePopupFieldDisabled(field, disabled)
    })
  }

  syncDetailField(event) {
    if (!this.currentMasterRow) return

    const field = event.currentTarget
    const key = this.detailFieldKey(field)
    if (!key) return

    const normalized = this.normalizeDetailFieldValue(key, field.value)
    if (field.value !== normalized) {
      field.value = normalized
    }

    this.currentMasterRow[key] = normalized

    if (key === "fnc_or_cd") {
      this.syncPopupFieldPresentation(field, key, normalized)
    }

    this.markCurrentMasterRowUpdated()
    this.refreshMasterRowCells([key, "__row_status"])
  }

  // 거래처구분그룹 변경 시 거래처구분 옵션/값 동기화
  handleDetailGroupChange(event) {
    if (!this.currentMasterRow) return
    if (!this.hasDetailSectionFieldTarget) return

    const groupCode = this.normalizeDetailFieldValue("bzac_sctn_grp_cd", event.currentTarget.value)
    const previousSection = this.detailSectionFieldTarget.value

    this.updateDetailSectionOptions(groupCode, previousSection)

    const currentSection = this.detailSectionFieldTarget.value
    this.currentMasterRow.bzac_sctn_cd = currentSection

    this.markCurrentMasterRowUpdated()
    this.refreshMasterRowCells(["bzac_sctn_grp_cd", "bzac_sctn_cd", "__row_status"])
  }

  // 상세 폼 select 옵션 구성
  updateDetailSectionOptions(groupCode, selectedCode = "") {
    if (!this.hasDetailSectionFieldTarget) return

    const options = this.resolveSectionOptions(groupCode)
    setSelectOptionsUtil(this.detailSectionFieldTarget, options, selectedCode, "")
  }

  // sectionMap 기반 옵션 계산 (그룹 미선택 시 전체 dedupe)
  resolveSectionOptions(groupCode) {
    const map = this.sectionMapValue || {}
    const normalizedGroup = (groupCode || "").toString().trim().toUpperCase()

    if (normalizedGroup && map[normalizedGroup]) {
      return map[normalizedGroup]
    }

    const all = Object.values(map).flat()
    const deduped = []
    const seen = new Set()

    all.forEach((item) => {
      const value = item?.value
      if (!value || seen.has(value)) return

      seen.add(value)
      deduped.push(item)
    })

    return deduped
  }

  // 입력값 표시용 정규화
  normalizeValueForInput(fieldName, rawValue) {
    if (rawValue == null) return ""

    if (DATE_FIELDS.includes(fieldName)) {
      return this.toDateInputValue(rawValue)
    }

    return rawValue.toString()
  }

  // 저장 전 상세 필드 정규화
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

    if (fieldName === "remk") {
      return value
    }

    return value.trim()
  }

  // 날짜형 문자열을 yyyy-mm-dd로 변환
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

  // 마스터 행 변경 플래그 처리
  markCurrentMasterRowUpdated() {
    if (!this.currentMasterRow) return
    if (this.currentMasterRow.__is_new || this.currentMasterRow.__is_deleted) return

    this.currentMasterRow.__is_updated = true
  }

  // 마스터 그리드 셀 부분 갱신
  refreshMasterRowCells(columns = []) {
    const node = this.findMasterNodeByData(this.currentMasterRow)
    const api = this.masterManager?.api

    if (!node || !api) return

    api.refreshCells({
      rowNodes: [node],
      columns,
      force: true
    })
  }

  // 현재 선택된 마스터 rowData에 대응하는 node 검색
  findMasterNodeByData(rowData) {
    const api = this.masterManager?.api
    if (!api || !rowData) return null

    let found = null
    api.forEachNode((node) => {
      if (node.data === rowData) {
        found = node
      }
    })

    return found
  }

  // ----- 검색 조건 연동 (구분그룹 -> 구분) -----
  bindSearchFields() {
    this.groupFieldElement = this.getSearchFieldElement("bzac_sctn_grp_cd")
    this.sectionFieldElement = this.getSearchFieldElement("bzac_sctn_cd")

    if (this.groupFieldElement) {
      this._onGroupChange = () => this.handleGroupChange()
      this.groupFieldElement.addEventListener("change", this._onGroupChange)
    }

    this.hydrateSectionSelect()
  }

  // 검색 이벤트 해제
  unbindSearchFields() {
    if (!this.groupFieldElement || !this._onGroupChange) return

    this.groupFieldElement.removeEventListener("change", this._onGroupChange)
    this._onGroupChange = null
  }

  // ----- 상세 폼 입력 이벤트 바인딩 -----
  bindDetailFieldEvents() {
    this.unbindDetailFieldEvents()

    this._onDetailInput = (event) => {
      this.syncDetailField(event)
    }

    this._onDetailChange = (event) => {
      this.syncDetailField(event)

      const key = this.detailFieldKey(event.currentTarget)
      if (key === "fnc_or_cd") {
        this.syncPopupFieldPresentation(event.currentTarget, key, event.currentTarget.value)
      }
      if (key === "bzac_sctn_grp_cd") {
        this.handleDetailGroupChange(event)
      }
    }

    this.detailFieldTargets.forEach((field) => {
      field.addEventListener("input", this._onDetailInput)
      field.addEventListener("change", this._onDetailChange)
    })
  }

  // 상세 폼 입력 이벤트 해제
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

  // 검색 폼 초기값으로 구분 select 세팅
  async hydrateSectionSelect() {
    const groupCode = this.groupKeywordFromSearch()
    const sectionCode = this.sectionKeywordFromSearch()
    await this.loadSectionOptions(groupCode, sectionCode)
  }

  // 구분그룹 변경 시 구분 목록 재조회
  async handleGroupChange() {
    const groupCode = this.groupKeywordFromSearch()
    await this.loadSectionOptions(groupCode, "")
  }

  // 서버에서 구분 목록 조회 후 select 옵션 적용
  async loadSectionOptions(groupCode, selectedSectionCode) {
    if (!this.hasSectionsUrlValue || !this.sectionFieldElement) return

    const query = new URLSearchParams({ bzac_sctn_grp_cd: groupCode || "" })

    try {
      const rows = await fetchJson(`${this.sectionsUrlValue}?${query.toString()}`)
      const options = Array.isArray(rows)
        ? rows.map((row) => ({ value: row.detail_code, label: row.detail_code_name }))
        : []

      setSelectOptionsUtil(this.sectionFieldElement, options, selectedSectionCode)
    } catch {
      showAlert("거래처구분 목록 조회에 실패했습니다.")
    }
  }

  // 검색 폼 값 추출 헬퍼
  groupKeywordFromSearch() {
    return this.getSearchFormValue("bzac_sctn_grp_cd")
  }

  sectionKeywordFromSearch() {
    return this.getSearchFormValue("bzac_sctn_cd")
  }

  // 상세 필드 DOM에서 데이터 키 추출
  detailFieldKey(fieldElement) {
    if (!fieldElement) return ""

    const datasetKey = fieldElement.dataset.field
    if (datasetKey) return datasetKey

    const nameAttr = fieldElement.getAttribute("name") || ""
    const fromName = nameAttr.match(/\[([^\]]+)\]$/)
    if (fromName) return fromName[1]

    const idAttr = fieldElement.getAttribute("id") || ""
    const fromId = idAttr.match(/_([a-z0-9_]+)$/i)
    if (fromId) return fromId[1]

    return ""
  }

  // popup 필드의 code/display 표시 동기화
  syncPopupFieldPresentation(fieldElement, key, value, rowData = null) {
    const popupRoot = this.popupRootForField(fieldElement)
    if (!popupRoot || !key) return

    const codeDisplay = popupRoot.querySelector("[data-search-popup-target='codeDisplay']")
    if (codeDisplay) {
      codeDisplay.value = value || ""
    }

    const displayInput = popupRoot.querySelector("[data-search-popup-target='display']")
    if (!displayInput) return

    if (key === "fnc_or_cd") {
      const seededName = (rowData?.fnc_or_nm || "").toString().trim()
      displayInput.value = seededName || value || ""
      this.resolveFinancialInstitutionNameForPopup(popupRoot, value)
    }
  }

  // popup 필드 비활성화 상태 동기화
  togglePopupFieldDisabled(fieldElement, disabled) {
    const popupRoot = this.popupRootForField(fieldElement)
    if (!popupRoot) return

    const displayInput = popupRoot.querySelector("[data-search-popup-target='display']")
    if (displayInput) {
      displayInput.disabled = disabled
    }

    const codeDisplay = popupRoot.querySelector("[data-search-popup-target='codeDisplay']")
    if (codeDisplay) {
      codeDisplay.disabled = true
    }

    const openButton = popupRoot.querySelector("button[data-action='search-popup#open']")
    if (openButton) {
      openButton.disabled = disabled
    }
  }

  // 상세 필드가 popup 타입인지 판별 후 루트 반환
  popupRootForField(fieldElement) {
    if (!fieldElement) return null
    if (fieldElement.dataset.searchPopupTarget !== "code") return null

    return fieldElement.closest("[data-controller~='search-popup']")
  }

  // 금융기관명 지연 조회 + 캐시
  async resolveFinancialInstitutionNameForPopup(popupRoot, code) {
    const normalizedCode = (code || "").toString().trim().toUpperCase()
    if (!popupRoot || !normalizedCode) return

    const displayInput = popupRoot.querySelector("[data-search-popup-target='display']")
    if (!displayInput) return

    const cachedName = this.financialInstitutionNameCache?.get(normalizedCode)
    if (cachedName) {
      const currentDisplay = displayInput.value.trim()
      if (currentDisplay === "" || currentDisplay.toUpperCase() === normalizedCode) {
        displayInput.value = cachedName
      }
      return
    }

    try {
      const query = new URLSearchParams({
        "search_popup_form[fnc_or_cd]": normalizedCode,
        "search_popup_form[use_yn]": "Y"
      })
      const rows = await fetchJson(`/search_popups/financial_institution?format=json&${query.toString()}`)
      const matched = Array.isArray(rows)
        ? rows.find((row) => {
          const rowCode = String(row?.fnc_or_cd ?? row?.code ?? "").trim().toUpperCase()
          return rowCode === normalizedCode
        })
        : null

      const resolvedName = String(matched?.fnc_or_nm ?? matched?.name ?? "").trim()
      if (!resolvedName) return

      this.financialInstitutionNameCache?.set(normalizedCode, resolvedName)

      const currentDisplay = displayInput.value.trim()
      if (currentDisplay === "" || currentDisplay.toUpperCase() === normalizedCode) {
        displayInput.value = resolvedName
      }
    } catch {
      // noop
    }
  }

  // 마스터 셀 입력 정규화 (코드/사업자번호)
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
