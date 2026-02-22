import BaseGridController from "controllers/base_grid_controller"
import GridCrudManager from "controllers/grid/grid_crud_manager"
import { GridEventManager, resolveAgGridRegistration, rowDataFromGridEvent } from "controllers/grid/grid_event_manager"
import { isApiAlive, postJson, hasChanges, fetchJson, setManagerRowData, focusFirstRow, hasPendingChanges, blockIfPendingChanges, buildTemplateUrl, refreshSelectionLabel, setSelectOptions as setSelectOptionsUtil, getSearchFieldValue } from "controllers/grid/grid_utils"

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

const DATE_FIELDS = ["aply_strt_day_cd", "aply_end_day_cd"]

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
    "lookupButton",
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

  connect() {
    super.connect()
    this.initialMasterSyncDone = false
    this.masterGridEvents = new GridEventManager()
    this.contactGridController = null
    this.contactManager = null
    this.workplaceGridController = null
    this.workplaceManager = null
    this.currentMasterRow = null
    this.activeTab = "basic"

    this.bindSearchFields()
    this.bindDetailFieldEvents()
    this.activateTab("basic")
    this.clearDetailForm()
  }

  disconnect() {
    this.unbindSearchFields()
    this.unbindDetailFieldEvents()
    this.masterGridEvents.unbindAll()

    if (this.contactManager) {
      this.contactManager.detach()
      this.contactManager = null
    }
    if (this.workplaceManager) {
      this.workplaceManager.detach()
      this.workplaceManager = null
    }

    this.contactGridController = null
    this.workplaceGridController = null
    this.currentMasterRow = null
    super.disconnect()
  }

  configureManager() {
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
      onCellValueChanged: (event) => this.normalizeMasterField(event),
      onRowDataUpdated: () => {
        this.contactManager?.resetTracking()
        this.workplaceManager?.resetTracking()

        if (!this.initialMasterSyncDone && isApiAlive(this.contactManager?.api) && isApiAlive(this.workplaceManager?.api)) {
          this.initialMasterSyncDone = true
          this.syncMasterSelectionAfterLoad()
        }
      }
    }
  }

  configureContactManager() {
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

  configureWorkplaceManager() {
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

  registerGrid(event) {
    const registration = resolveAgGridRegistration(event)
    if (!registration) return

    const { gridElement, api, controller } = registration
    if (gridElement === this.masterGridTarget) {
      super.registerGrid(event)
    } else if (gridElement === this.contactsGridTarget) {
      if (this.contactManager) {
        this.contactManager.detach()
      }
      this.contactGridController = controller
      this.contactManager = new GridCrudManager(this.configureContactManager())
      this.contactManager.attach(api)
    } else if (gridElement === this.workplacesGridTarget) {
      if (this.workplaceManager) {
        this.workplaceManager.detach()
      }
      this.workplaceGridController = controller
      this.workplaceManager = new GridCrudManager(this.configureWorkplaceManager())
      this.workplaceManager.attach(api)
    }

    if (this.manager?.api && this.contactManager?.api && this.workplaceManager?.api) {
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
      this.selectedClientValue = ""
      this.refreshSelectedClientLabel()
      this.clearDetailForm()
      this.clearContactRows()
      this.clearWorkplaceRows()
      return
    }

    this.currentMasterRow = rowData
    this.fillDetailForm(rowData)

    const clientCode = rowData?.bzac_cd
    this.selectedClientValue = clientCode || ""
    this.refreshSelectedClientLabel()

    if (!isApiAlive(this.contactManager?.api) || !isApiAlive(this.workplaceManager?.api)) return
    if (!clientCode || rowData?.__is_deleted || rowData?.__is_new) {
      this.clearContactRows()
      this.clearWorkplaceRows()
      return
    }

    await Promise.all([this.loadContactRows(clientCode), this.loadWorkplaceRows(clientCode)])
  }

  addMasterRow() {
    if (!this.manager) return

    const txResult = this.manager.addRow({}, { startCol: "bzac_nm" })
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

    alert("거래처 데이터가 저장되었습니다.")
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
      alert("거래처 목록 조회에 실패했습니다.")
    }
  }

  async syncMasterSelectionAfterLoad() {
    if (!isApiAlive(this.manager?.api)) return

    const firstData = focusFirstRow(this.manager.api)
    if (!firstData) {
      this.currentMasterRow = null
      this.selectedClientValue = ""
      this.refreshSelectedClientLabel()
      this.clearDetailForm()
      this.clearContactRows()
      this.clearWorkplaceRows()
      return
    }

    await this.handleMasterRowChange(firstData)
  }

  addContactRow() {
    if (!this.contactManager) return
    if (this.blockDetailActionIfMasterChanged()) return

    if (!this.selectedClientValue) {
      alert("거래처를 먼저 선택해주세요.")
      return
    }

    this.contactManager.addRow()
  }

  deleteContactRows() {
    if (!this.contactManager) return
    if (this.blockDetailActionIfMasterChanged()) return

    this.contactManager.deleteRows()
  }

  async saveContactRows() {
    if (!this.contactManager) return
    if (this.blockDetailActionIfMasterChanged()) return

    if (!this.selectedClientValue) {
      alert("거래처를 먼저 선택해주세요.")
      return
    }

    this.contactManager.stopEditing()
    const operations = this.contactManager.buildOperations()
    if (!hasChanges(operations)) {
      alert("변경된 데이터가 없습니다.")
      return
    }

    const batchUrl = buildTemplateUrl(this.contactBatchUrlTemplateValue, ":id", this.selectedClientValue)
    const ok = await postJson(batchUrl, operations)
    if (!ok) return

    alert("거래처 담당자 데이터가 저장되었습니다.")
    await this.loadContactRows(this.selectedClientValue)
  }

  addWorkplaceRow() {
    if (!this.workplaceManager) return
    if (this.blockDetailActionIfMasterChanged()) return

    if (!this.selectedClientValue) {
      alert("거래처를 먼저 선택해주세요.")
      return
    }

    this.workplaceManager.addRow()
  }

  deleteWorkplaceRows() {
    if (!this.workplaceManager) return
    if (this.blockDetailActionIfMasterChanged()) return

    this.workplaceManager.deleteRows()
  }

  async saveWorkplaceRows() {
    if (!this.workplaceManager) return
    if (this.blockDetailActionIfMasterChanged()) return

    if (!this.selectedClientValue) {
      alert("거래처를 먼저 선택해주세요.")
      return
    }

    this.workplaceManager.stopEditing()
    const operations = this.workplaceManager.buildOperations()
    if (!hasChanges(operations)) {
      alert("변경된 데이터가 없습니다.")
      return
    }

    const batchUrl = buildTemplateUrl(this.workplaceBatchUrlTemplateValue, ":id", this.selectedClientValue)
    const ok = await postJson(batchUrl, operations)
    if (!ok) return

    alert("거래처 작업장 데이터가 저장되었습니다.")
    await this.loadWorkplaceRows(this.selectedClientValue)
  }

  async loadContactRows(clientCode) {
    if (!isApiAlive(this.contactManager?.api)) return

    if (!clientCode) {
      this.clearContactRows()
      return
    }

    try {
      const url = buildTemplateUrl(this.contactListUrlTemplateValue, ":id", clientCode)
      const rows = await fetchJson(url)
      setManagerRowData(this.contactManager, rows)
    } catch {
      alert("담당자 목록 조회에 실패했습니다.")
    }
  }

  async loadWorkplaceRows(clientCode) {
    if (!isApiAlive(this.workplaceManager?.api)) return

    if (!clientCode) {
      this.clearWorkplaceRows()
      return
    }

    try {
      const url = buildTemplateUrl(this.workplaceListUrlTemplateValue, ":id", clientCode)
      const rows = await fetchJson(url)
      setManagerRowData(this.workplaceManager, rows)
    } catch {
      alert("작업장 목록 조회에 실패했습니다.")
    }
  }

  clearContactRows() {
    setManagerRowData(this.contactManager, [])
  }

  clearWorkplaceRows() {
    setManagerRowData(this.workplaceManager, [])
  }

  preventDetailSubmit(event) {
    event.preventDefault()
  }

  refreshSelectedClientLabel() {
    if (!this.hasSelectedClientLabelTarget) return
    refreshSelectionLabel(this.selectedClientLabelTarget, this.selectedClientValue, "거래처", "거래처를 먼저 선택하세요.")
  }

  hasMasterPendingChanges() {
    return hasPendingChanges(this.manager)
  }

  blockDetailActionIfMasterChanged() {
    return blockIfPendingChanges(this.manager, "마스터 거래처")
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
    this.updateDetailSectionOptions(rowData.bzac_sctn_grp_cd, rowData.bzac_sctn_cd)

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
    this.updateDetailSectionOptions("", "")
    this.toggleDetailFields(true)
  }

  toggleDetailFields(disabled) {
    this.detailFieldTargets.forEach((field) => {
      field.disabled = disabled
    })
    this.lookupButtonTargets.forEach((button) => {
      button.disabled = disabled
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

  openQuickLookup(event) {
    event.preventDefault()

    if (!this.currentMasterRow) {
      alert("거래처를 먼저 선택해주세요.")
      return
    }

    const button = event.currentTarget
    const fieldName = button?.dataset?.forField
    if (!fieldName) return

    const targetField = this.detailFieldTargets.find((field) => this.detailFieldKey(field) === fieldName)
    if (!targetField) return

    const label = button.dataset.fieldLabel || fieldName
    const currentValue = (targetField.value || "").toString()
    const promptedValue = window.prompt(`${label} 값을 입력하세요.`, currentValue)
    if (promptedValue === null) return

    targetField.value = promptedValue
    this.syncDetailField({ currentTarget: targetField })

    if (fieldName === "bzac_sctn_grp_cd") {
      this.handleDetailGroupChange({ currentTarget: targetField })
    }
  }

  handleDetailGroupChange(event) {
    if (!this.currentMasterRow) return
    if (!this.hasDetailSectionFieldTarget) return

    const groupCode = this.normalizeDetailFieldValue("bzac_sctn_grp_cd", event.currentTarget.value)
    const previousValue = this.hasDetailSectionFieldTarget ? this.detailSectionFieldTarget.value : ""
    this.updateDetailSectionOptions(groupCode, previousValue)

    const currentSection = this.detailSectionFieldTarget.value
    this.currentMasterRow.bzac_sctn_cd = currentSection
    this.markCurrentMasterRowUpdated()
    this.refreshMasterRowCells(["bzac_sctn_grp_cd", "bzac_sctn_cd", "__row_status"])
  }

  updateDetailSectionOptions(groupCode, selectedCode = "") {
    if (!this.hasDetailSectionFieldTarget) return

    const options = this.resolveSectionOptions(groupCode)
    setSelectOptionsUtil(this.detailSectionFieldTarget, options, selectedCode, "")
  }

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
      if (!item?.value) return
      if (seen.has(item.value)) return
      seen.add(item.value)
      deduped.push(item)
    })
    return deduped
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

    if (fieldName === "remk") {
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

  bindSearchFields() {
    this.groupField = this.searchField("bzac_sctn_grp_cd")
    this.sectionField = this.searchField("bzac_sctn_cd")

    if (this.groupField) {
      this._onGroupChange = () => this.handleGroupChange()
      this.groupField.addEventListener("change", this._onGroupChange)
    }

    this.hydrateSectionSelect()
  }

  bindDetailFieldEvents() {
    this.unbindDetailFieldEvents()

    this._onDetailInput = (event) => {
      this.syncDetailField(event)
    }
    this._onDetailChange = (event) => {
      this.syncDetailField(event)

      const key = this.detailFieldKey(event.currentTarget)
      if (key === "bzac_sctn_grp_cd") {
        this.handleDetailGroupChange(event)
      }
    }

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

  unbindSearchFields() {
    if (this.groupField && this._onGroupChange) {
      this.groupField.removeEventListener("change", this._onGroupChange)
    }
  }

  async hydrateSectionSelect() {
    const groupCode = this.selectedGroupCode()
    const selectedSectionCode = this.selectedSectionCode()
    await this.loadSectionOptions(groupCode, selectedSectionCode)
  }

  async handleGroupChange() {
    const groupCode = this.selectedGroupCode()
    await this.loadSectionOptions(groupCode, "")
  }

  async loadSectionOptions(groupCode, selectedSectionCode) {
    if (!this.hasSectionsUrlValue || !this.sectionField) return

    const query = new URLSearchParams({ bzac_sctn_grp_cd: groupCode || "" })

    try {
      const rows = await fetchJson(`${this.sectionsUrlValue}?${query.toString()}`)
      const options = rows.map((row) => ({
        value: row.detail_code,
        label: row.detail_code_name
      }))
      setSelectOptionsUtil(this.sectionField, options, selectedSectionCode)
    } catch {
      alert("거래처구분 목록 조회에 실패했습니다.")
    }
  }

  selectedGroupCode() {
    return getSearchFieldValue(this.element, "bzac_sctn_grp_cd")
  }

  selectedSectionCode() {
    return getSearchFieldValue(this.element, "bzac_sctn_cd")
  }

  searchField(name) {
    return this.element.querySelector(`[name='q[${name}]']`)
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
