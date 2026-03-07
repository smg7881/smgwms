/**
 * BaseGridController
 *
 * AG Grid 기반 화면에서 공통으로 쓰는 Stimulus 베이스 컨트롤러입니다.
 *
 * === 단일 그리드 모드 (기존 호환) ===
 * - configureManager()를 오버라이드하여 GridCrudManager 설정을 반환하면 단일 CRUD 그리드로 동작합니다.
 * - configureManager()가 null을 반환하면 Manager 없이 읽기 전용 단일 그리드로 동작합니다.
 *
 * === 다중 그리드 모드 ===
 * - gridRoles()를 오버라이드하여 역할(role)-타겟 매핑을 반환하면 다중 그리드를 이름으로 관리합니다.
 * - 각 그리드는 gridApi(name), selectedRows(name), setRows(name, rows) 등으로 접근합니다.
 *
 * 서브 클래스 오버라이드 포인트:
 * - configureManager() [단일 모드 필수, 다중 모드 불필요] CRUD 설정 객체 또는 null 반환
 * - gridRoles()         [다중 모드 필수] { role: { target: "targetName" } } 반환
 * - onAllGridsReady()   [다중 모드 선택] 모든 그리드 등록 완료 시 호출
 * - buildNewRowOverrides() [선택] 신규 행 추가 시 기본값 반환
 * - beforeDeleteRows(nodes) [선택] 삭제 전 검증
 * - afterSaveSuccess()  [선택] 저장 성공 후 추가 행동
 * - saveMessage getter  [선택] 저장 완료 알림 문구 커스터마이징
 */
import { Controller } from "@hotwired/stimulus"
import { showAlert, confirmAction } from "components/ui/alert"
import GridCrudManager from "controllers/grid/grid_crud_manager"
import { isApiAlive } from "controllers/grid/core/api_guard"
import { fetchJson, requestJson as requestJsonCore } from "controllers/grid/core/http_client"
import { setGridRowData, setManagerRowData, focusFirstRow } from "controllers/grid/grid_api_utils"
import {
  hasChanges,
  blockIfPendingChanges,
  requireSelection,
  isLoadableMasterRow as isLoadableMasterRowUtil
} from "controllers/grid/grid_state_utils"
import { postJson, buildTemplateUrl, refreshSelectionLabel, formatValidationError } from "controllers/grid/grid_utils"
import {
  getSearchFormValue as getSearchFormValueFromBridge,
  getSearchFieldElement as getSearchFieldElementFromBridge
} from "controllers/grid/core/search_form_bridge"
import { syncAllPopupDisplaysFromCodes } from "controllers/grid/grid_popup_utils"
import { PopupManager } from "controllers/popup/popup_manager"

export default class BaseGridController extends Controller {
  static targets = ["grid", "validationBox", "validationSummary", "validationList"]

  static values = {
    batchUrl: String,
    importHistoryUrl: String
  }

  connect() {
    this.manager = null
    this.gridController = null

    this.#gridRegistry = new Map()
    this.#expectedRoles = this.gridRoles()
    if (!this.#expectedRoles || Object.keys(this.#expectedRoles).length === 0) {
      this.#expectedRoles = null
    }

    this.#roleChildren = new Map()
    this.#masterRoles = new Set()
    this.#masterLastKeys = new Map()
    this.#masterDispatchTokens = new Map()
    this.#domBindings = new Map()
    this.#roleApiBindings = new Map()
    this.#allRolesReadyFired = false
    this.#initMasterDetail()

    if (this.#expectedRoles) {
      this.#initializeRoleRelations()
      this.#beforeSearchHandler = () => this.#handleBeforeSearch()
      document.addEventListener("grid:before-search", this.#beforeSearchHandler)
    }
  }

  disconnect() {
    if (this.#beforeSearchHandler) {
      document.removeEventListener("grid:before-search", this.#beforeSearchHandler)
      this.#beforeSearchHandler = null
    }

    this.#gridRegistry.forEach((_entry, role) => {
      this.#unbindRoleEvents(role)
    })

    this.#gridRegistry.forEach(({ manager }) => {
      if (manager) manager.detach()
    })
    this.#gridRegistry.clear()

    this.#roleChildren.clear()
    this.#masterRoles.clear()
    this.#masterLastKeys.clear()
    this.#masterDispatchTokens.clear()
    this.#domBindings.clear()
    this.#roleApiBindings.clear()

    if (this.manager) {
      this.manager.detach()
      this.manager = null
    }
    this.gridController = null

    this.currentMasterRow = null
    this._masterCfg = null
    this._detailCfgs = []
  }

  registerGrid(event) {
    const { api, controller } = event.detail

    if (this.#expectedRoles) {
      this.#registerMultiGrid(event, api, controller)
    } else {
      this.#registerSingleGrid(api, controller)
    }
  }

  gridRoles() { return null }

  configureManager() { return null }
  masterConfig() { return null }
  detailGrids() { return [] }

  splitManagerConfig(rawConfig) {
    if (!rawConfig || typeof rawConfig !== "object") {
      return { managerConfig: rawConfig || null, registration: null }
    }

    const { registration = null, ...managerConfig } = rawConfig
    return { managerConfig, registration }
  }

  resolveManagerConfig(configMethod) {
    if (!configMethod) return null

    const source = this[configMethod]
    const rawConfig = typeof source === "function" ? source.call(this) : source
    const { managerConfig } = this.splitManagerConfig(rawConfig)
    return managerConfig
  }

  onAllGridsReady() { }
  beforeSearchReset() { }

  gridApi(name) {
    return this.#gridRegistry.get(name)?.api || null
  }

  gridCtrl(name) {
    return this.#gridRegistry.get(name)?.controller || null
  }

  gridManager(name) {
    return this.#gridRegistry.get(name)?.manager || null
  }

  selectedRows(name) {
    const api = this.gridApi(name)
    if (!isApiAlive(api)) return []
    return api.getSelectedRows()
  }

  setRows(name, rows) {
    const api = this.gridApi(name)
    if (!isApiAlive(api)) return
    setGridRowData(api, rows)
  }

  refreshGrid(name) {
    const ctrl = this.gridCtrl(name)
    if (ctrl?.refresh) ctrl.refresh()
  }

  selectFirstRow(name, { ensureVisible = true, select = false } = {}) {
    const api = this.gridApi(name)
    return focusFirstRow(api, { ensureVisible, select })
  }

  selectFirstMasterRow(masterRole = "master") {
    return this.selectFirstRow(masterRole, { ensureVisible: true, select: false })
  }

  buildDetailBatchUrl(template, masterValue, placeholder = ":id") {
    const value = masterValue == null ? "" : String(masterValue).trim()
    if (!template || value === "") return null
    return buildTemplateUrl(template, placeholder, value)
  }

  requireMasterSelection(selectedValue, { entityLabel = "Master", message = null } = {}) {
    return requireSelection(selectedValue, {
      entityLabel,
      message
    })
  }

  isMasterRowLoadable(rowData, keyField) {
    return isLoadableMasterRowUtil(rowData, keyField)
  }

  blockIfMasterPendingChanges(manager = this.gridManager("master"), entityLabel = "Master") {
    return blockIfPendingChanges(manager, entityLabel)
  }

  blockDetailActionIfMasterChanged(manager = this.gridManager("master"), entityLabel = "Master") {
    return this.blockIfMasterPendingChanges(manager, entityLabel)
  }

  async postAction(url, body, { confirmMessage, onSuccess, onFail } = {}) {
    if (confirmMessage && !confirmAction(confirmMessage)) return false

    try {
      const { response, result } = await requestJsonCore(url, { method: "POST", body })

      if (response.ok && result.success) {
        if (onSuccess) {
          onSuccess(result)
        } else {
          showAlert(result.message || "처리가 완료되었습니다.")
        }
        return true
      }

      if (onFail) {
        onFail(result)
      } else {
        showAlert(result.message || "처리에 실패했습니다.")
      }
      return false
    } catch {
      showAlert("요청 중 네트워크 오류가 발생했습니다.")
      return false
    }
  }

  addRow({
    manager = this.manager,
    overrides = this.buildNewRowOverrides?.() || {},
    config = this.buildAddRowConfig?.() || {},
    onAdded = null
  } = {}) {
    if (!manager) return null
    const txResult = manager.addRow(overrides || {}, config || {})
    const addedNode = txResult?.add?.[0]
    if (onAdded && addedNode?.data) {
      onAdded(addedNode.data, { addedNode, txResult })
    }
    return txResult
  }

  deleteRows({
    manager = this.manager,
    beforeDelete = this.beforeDeleteRows?.bind(this),
    deleteLabel = null
  } = {}) {
    if (!manager) return false
    if (typeof manager.deleteRows === "function") {
      return manager.deleteRows({ beforeDelete })
    }
    if (typeof manager.deleteSelectedRows === "function") {
      return manager.deleteSelectedRows(deleteLabel)
    }
    return false
  }

  async saveRows({
    manager = this.manager,
    batchUrl = this.batchUrlValue,
    saveMessage = this.saveMessage,
    emptyMessage = "변경된 데이터가 없습니다.",
    onSuccess = () => this.reloadRows()
  } = {}) {
    if (!manager) return false
    if (!batchUrl) {
      showAlert("저장 URL이 설정되지 않았습니다.")
      return false
    }

    return this.saveRowsWith({
      manager,
      batchUrl,
      saveMessage,
      emptyMessage,
      onSuccess
    })
  }

  async saveRowsWith({
    manager,
    batchUrl,
    saveMessage = this.saveMessage,
    emptyMessage = "변경된 데이터가 없습니다.",
    onSuccess = null
  } = {}) {
    if (!manager) return false

    manager.stopEditing?.()

    const validationResult = typeof manager.validateRows === "function"
      ? manager.validateRows()
      : { valid: true, errors: [] }
    if (!validationResult.valid) {
      const errors = Array.isArray(validationResult.errors) ? validationResult.errors : []
      const firstError = validationResult.firstError || errors[0] || null
      const summary = typeof manager.formatValidationSummary === "function"
        ? manager.formatValidationSummary(errors, { maxItems: 3 })
        : (firstError?.message || "입력값을 확인해주세요.")

      const renderedInline = typeof this.showValidationErrors === "function"
        ? this.showValidationErrors({ errors, firstError, summary, manager }) === true
        : false

      if (typeof manager.focusValidationError === "function" && firstError) {
        manager.focusValidationError(firstError)
      }

      if (!renderedInline) {
        showAlert("Validation", summary, "warning")
      }
      return false
    }

    if (typeof this.clearValidationErrors === "function") {
      this.clearValidationErrors()
    }

    const operations = manager.buildOperations
      ? manager.buildOperations()
      : manager.getChanges?.()

    if (!operations || !hasChanges(operations)) {
      showAlert(emptyMessage)
      return false
    }

    const ok = await postJson(batchUrl, operations)
    if (!ok) return false

    if (saveMessage) {
      showAlert(saveMessage)
    }

    if (onSuccess) {
      await onSuccess()
    }

    return true
  }

  reloadRows() {
    if (this.gridController?.refresh) {
      this.gridController.refresh()
    }
  }

  get saveMessage() {
    return "저장이 완료되었습니다."
  }

  showValidationErrors({ errors = [], firstError = null, summary = "", manager = null } = {}) {
    if (!this.hasValidationBoxTarget || !this.hasValidationListTarget) return false

    this.beforeShowValidationErrors?.({ errors, firstError, summary, manager })

    const list = Array.isArray(errors) ? errors : []
    const maxItems = 10
    const visible = list.slice(0, maxItems)

    if (this.hasValidationSummaryTarget) {
      this.validationSummaryTarget.textContent = summary || "입력값을 확인해주세요."
    }

    this.validationListTarget.innerHTML = ""
    visible.forEach((error) => {
      const item = document.createElement("li")
      item.textContent = formatValidationError(error)
      this.validationListTarget.appendChild(item)
    })

    if (list.length > maxItems) {
      const more = document.createElement("li")
      more.textContent = `외 ${list.length - maxItems}건`
      this.validationListTarget.appendChild(more)
    }

    this.validationBoxTarget.hidden = false
    this.validationBoxTarget.scrollIntoView({ behavior: "smooth", block: "nearest" })
    return true
  }

  clearValidationErrors() {
    if (!this.hasValidationBoxTarget) return
    this.validationBoxTarget.hidden = true
    if (this.hasValidationSummaryTarget) this.validationSummaryTarget.textContent = ""
    if (this.hasValidationListTarget) this.validationListTarget.innerHTML = ""
  }

  connectBase({ events = [] } = {}) {
    this.dragState = null
    this._eventSubscriptions = events.map(({ name, handler }) => {
      this.element.addEventListener(name, handler)
      return { name, handler }
    })

    this._boundDelegatedClick = this.handleDelegatedClick.bind(this)
    this._boundDragMove = this.handleDragMove.bind(this)
    this._boundEndDrag = this.endDrag.bind(this)

    this.element.addEventListener("click", this._boundDelegatedClick)
    window.addEventListener("mousemove", this._boundDragMove)
    window.addEventListener("mouseup", this._boundEndDrag)
  }

  disconnectBase() {
    ;(this._eventSubscriptions || []).forEach(({ name, handler }) => {
      this.element.removeEventListener(name, handler)
    })
    this._eventSubscriptions = []

    if (this._boundDelegatedClick) {
      this.element.removeEventListener("click", this._boundDelegatedClick)
    }
    if (this._boundDragMove) {
      window.removeEventListener("mousemove", this._boundDragMove)
    }
    if (this._boundEndDrag) {
      window.removeEventListener("mouseup", this._boundEndDrag)
    }
  }

  get cancelRoleSelector() {
    return `[data-${this.identifier}-role='cancel']`
  }

  openModal() {
    this._popupInstance = PopupManager.open({ dialogEl: this.overlayTarget })
  }

  closeModal() {
    this._popupInstance?.close()
    this._popupInstance = null
    this.endDrag()
  }

  onBackdropClick(_event) {}

  stopPropagation(event) {
    event.stopPropagation()
  }

  handleDelegatedClick(event) {
    const cancelButton = event.target.closest(this.cancelRoleSelector)
    if (cancelButton) {
      event.preventDefault()
      this.closeModal()
    }
  }

  startDrag(event) {
    if (event.button !== 0) return
    if (!this.hasModalTarget || !this.hasOverlayTarget) return
    if (event.target.closest("button")) return

    const modalRect = this.modalTarget.getBoundingClientRect()
    this.modalTarget.style.position = "absolute"
    this.modalTarget.style.left = `${modalRect.left}px`
    this.modalTarget.style.top = `${modalRect.top}px`
    this.modalTarget.style.margin = "0"

    this.dragState = {
      offsetX: event.clientX - modalRect.left,
      offsetY: event.clientY - modalRect.top
    }

    document.body.style.userSelect = "none"
    this.modalTarget.style.cursor = "grabbing"
    event.preventDefault()
  }

  handleDragMove(event) {
    if (!this.dragState || !this.hasModalTarget) return

    const maxLeft = Math.max(0, window.innerWidth - this.modalTarget.offsetWidth)
    const maxTop = Math.max(0, window.innerHeight - this.modalTarget.offsetHeight)
    const nextLeft = event.clientX - this.dragState.offsetX
    const nextTop = event.clientY - this.dragState.offsetY
    const clampedLeft = Math.min(Math.max(0, nextLeft), maxLeft)
    const clampedTop = Math.min(Math.max(0, nextTop), maxTop)

    this.modalTarget.style.left = `${clampedLeft}px`
    this.modalTarget.style.top = `${clampedTop}px`
  }

  endDrag() {
    this.dragState = null
    document.body.style.userSelect = ""
    if (this.hasModalTarget) {
      this.modalTarget.style.cursor = ""
    }
  }

  buildJsonPayload() {
    const formData = new FormData(this.formTarget)
    const payload = {}

    for (const [rawKey, value] of formData.entries()) {
      const match = rawKey.match(/^[^\[]+\[([^\]]+)\]$/)
      const key = match ? match[1] : rawKey
      payload[key] = value
    }

    Object.keys(payload).forEach((key) => {
      if (payload[key] === "") payload[key] = null
    })

    return payload
  }

  async handleDelete(event) {
    const { id } = event.detail
    const displayName = event.detail[this.constructor.deleteConfirmKey] || id

    if (!await confirmAction(`"${displayName}" ${this.constructor.entityLabel}를 삭제하시겠습니까?`)) return

    try {
      const { response, result } = await this.requestJson(this.deleteUrlValue.replace(":id", id), {
        method: "DELETE"
      })

      if (!response.ok || !result.success) {
        showAlert("삭제 실패: " + (result.errors || ["요청 처리 실패"]).join(", "))
        return
      }

      showAlert(result.message || "삭제되었습니다")
      this._refreshModalGrid()
    } catch {
      showAlert("삭제 실패: 네트워크 오류")
    }
  }

  async save() {
    const payload = this.buildJsonPayload()
    if (this.hasFieldIdTarget && this.fieldIdTarget.value) payload.id = this.fieldIdTarget.value

    const isCreate = this.mode === "create"
    const id = payload.id
    delete payload.id

    const url = isCreate ? this.createUrlValue : this.updateUrlValue.replace(":id", id)
    const method = isCreate ? "POST" : "PATCH"

    try {
      const { response, result } = await this.requestJson(url, {
        method,
        body: { [this.constructor.resourceName]: payload }
      })

      if (!response.ok || !result.success) {
        showAlert("저장 실패: " + (result.errors || ["요청 처리 실패"]).join(", "))
        return
      }

      showAlert(result.message || "저장되었습니다")
      this.closeModal()
      this._refreshModalGrid()
    } catch {
      showAlert("저장 실패: 네트워크 오류")
    }
  }

  submit(event) {
    event.preventDefault()
    this.save()
  }

  async requestJson(url, { method, body, isMultipart = false }) {
    return requestJsonCore(url, { method, body, isMultipart })
  }

  setFieldValue(fieldName, value) {
    if (!this.hasFormTarget) return

    const resourceName = this.constructor.resourceName
    const input = this.findFieldInput(resourceName, fieldName)
    if (!input) return

    const normalizedValue = value == null ? "" : value

    if (input.type === "checkbox") {
      const truthy = normalizedValue === true || normalizedValue === "Y" || normalizedValue === "1" || normalizedValue === 1
      input.checked = truthy
      return
    }

    if (input.tomselect) {
      if (input.multiple) {
        const values = Array.isArray(normalizedValue) ? normalizedValue.map((v) => String(v)) : []
        input.tomselect.setValue(values, true)
      } else {
        input.tomselect.setValue(String(normalizedValue), true)
      }
      return
    }

    input.value = normalizedValue
  }

  setFieldValues(values = {}) {
    Object.entries(values).forEach(([fieldName, value]) => {
      this.setFieldValue(fieldName, value)
    })
  }

  findFieldInput(resourceName, fieldName) {
    let input = null

    if (resourceName) {
      input = this.formTarget.querySelector(`[name='${resourceName}[${fieldName}]']`)
    }

    if (!input) {
      input = this.formTarget.querySelector(`[name$='[${fieldName}]']`)
    }

    return input
  }

  syncPopupDisplaysFromCodes() {
    syncAllPopupDisplaysFromCodes(this.element)
  }

  formatDateTime(value) {
    if (!value) return ""

    const date = value instanceof Date ? value : new Date(value)
    if (Number.isNaN(date.getTime())) {
      return String(value)
    }

    const year = date.getFullYear()
    const month = String(date.getMonth() + 1).padStart(2, "0")
    const day = String(date.getDate()).padStart(2, "0")
    const hour = String(date.getHours()).padStart(2, "0")
    const minute = String(date.getMinutes()).padStart(2, "0")
    const second = String(date.getSeconds()).padStart(2, "0")
    return `${year}-${month}-${day} ${hour}:${minute}:${second}`
  }

  _refreshModalGrid() {
    const agGridEl = this.element.querySelector("[data-controller='ag-grid']")
    if (agGridEl) {
      this.application.getControllerForElementAndIdentifier(agGridEl, "ag-grid")?.refresh()
    }
  }

  openImportHistory() {
    if (this.hasImportHistoryUrlValue) {
      window.location.href = this.importHistoryUrlValue
    }
  }

  openExcelImport() {
    const fileInput = this.element.querySelector("[data-excel-import-input]")
    if (fileInput) {
      fileInput.click()
    }
  }

  submitExcelImport(event) {
    const input = event.target
    if (input.files.length === 0) return

    const form = input.closest("form")
    form?.requestSubmit()
    input.value = ""
  }

  onMasterRowChanged(rowData) {
    const cfg = this._masterCfg
    if (!cfg) return

    if (cfg.onRowChange?.trackCurrentRow !== false) {
      this.currentMasterRow = rowData || null
    }

    const keyField = cfg.key?.field
    const stateProp = cfg.key?.stateProperty
    if (keyField && stateProp) {
      this[stateProp] = rowData?.[keyField] || ""
    }

    this.refreshSelectedLabel()

    if (cfg.onRowChange?.syncForm) {
      if (rowData) {
        this.fillDetailForm?.(rowData)
      } else {
        this.clearDetailForm?.()
      }
    }

    if (typeof cfg.onRowChange?.afterChange === "function") {
      cfg.onRowChange.afterChange.call(this, rowData)
    }
  }

  refreshSelectedLabel() {
    const cfg = this._masterCfg?.key
    if (!cfg?.stateProperty || !cfg?.labelTarget) return

    const targetGetter = `${cfg.labelTarget}Target`
    const hasGetter = `has${cfg.labelTarget.charAt(0).toUpperCase() + cfg.labelTarget.slice(1)}Target`
    if (!this[hasGetter]) return

    refreshSelectionLabel(this[targetGetter], this[cfg.stateProperty], cfg.entityLabel, cfg.emptyMessage)
  }

  async loadDetailRows(role, rowData) {
    const cfg = this._detailCfgs?.find((item) => item.role === role)
    if (!cfg) return []

    const keyField = cfg.masterKeyField
    const keyValue = rowData?.[keyField]
    if (!keyValue || rowData?.__is_deleted || rowData?.__is_new) return []

    try {
      const template = this[cfg.listUrlTemplate]
      if (!template) return []
      const url = buildTemplateUrl(template, cfg.placeholder || ":id", keyValue)
      const rows = await fetchJson(url)
      return Array.isArray(rows) ? rows : []
    } catch {
      showAlert(cfg.fetchErrorMessage || "데이터 조회에 실패했습니다.")
      return []
    }
  }

  #initMasterDetail() {
    this._masterCfg = this.masterConfig?.() || null
    this._detailCfgs = this.detailGrids?.() || []

    if (!this._masterCfg && this._detailCfgs.length === 0) return

    this.#generateMasterMethods()
    this.#generateDetailMethods()
  }

  #generateMasterMethods() {
    const cfg = this._masterCfg
    if (!cfg) return

    const proto = Object.getPrototypeOf(this)
    const role = cfg.role || "master"
    const pendingEntityLabel = cfg.pendingEntityLabel || cfg.key?.entityLabel || "마스터"

    if (!Object.getOwnPropertyDescriptor(proto, "masterManager")) {
      Object.defineProperty(proto, "masterManager", {
        get() { return this.gridManager(role) },
        configurable: true
      })
    }

    if (!this.#hasCustomMethod("blockDetailActionIfMasterChanged")) {
      this.blockDetailActionIfMasterChanged = () =>
        blockIfPendingChanges(this.gridManager(role), pendingEntityLabel)
    }

    if (!this.#hasCustomMethod("beforeSearchReset")) {
      this.beforeSearchReset = () => {
        const keyProp = cfg.key?.stateProperty
        if (keyProp) this[keyProp] = ""
        this.currentMasterRow = null
        this.refreshSelectedLabel()
        if (cfg.beforeSearch?.clearValidation) this.clearValidationErrors?.()
        if (cfg.beforeSearch?.clearForm || cfg.onRowChange?.syncForm) this.clearDetailForm?.()
      }
    }

    if (!this.#hasCustomMethod("addMasterRow")) {
      this.addMasterRow = (opts = {}) => {
        const manager = this.gridManager(role)
        if (!manager) return
        const onAdded = opts.onAdded || cfg.onAdded || null
        this.addRow({ manager, ...opts, onAdded })
      }
    }

    if (!this.#hasCustomMethod("deleteMasterRows")) {
      this.deleteMasterRows = () => {
        const manager = this.gridManager(role)
        if (!manager) return
        this.deleteRows({ manager })
      }
    }

    if (!this.#hasCustomMethod("saveMasterRows")) {
      this.saveMasterRows = async () => {
        const manager = this.gridManager(role)
        if (!manager) return
        await this.saveRowsWith({
          manager,
          batchUrl: this[cfg.batchUrl],
          saveMessage: cfg.saveMessage,
          onSuccess: cfg.onSaveSuccess || (() => this.refreshGrid(role))
        })
      }
    }
  }

  #generateDetailMethods() {
    const details = this._detailCfgs || []
    const proto = Object.getPrototypeOf(this)

    details.forEach((cfg) => {
      const role = cfg.role
      if (!role) return

      const methodBase = this.#resolveRoleMethodBase(role, cfg)
      if (!methodBase) return
      const methodSuffix = methodBase.charAt(0).toUpperCase() + methodBase.slice(1)
      const managerAlias = cfg.managerAlias || `${methodBase}Manager`

      if (!Object.getOwnPropertyDescriptor(proto, managerAlias)) {
        Object.defineProperty(proto, managerAlias, {
          get() { return this.gridManager(role) },
          configurable: true
        })
      }

      const addName = `add${methodSuffix}Row`
      if (!this.#hasCustomMethod(addName)) {
        this[addName] = () => {
          const manager = this.gridManager(role)
          if (!manager) return
          if (this.blockDetailActionIfMasterChanged?.()) return

          const stateProp = this._masterCfg?.key?.stateProperty
          const selectedValue = stateProp ? this[stateProp] : ""
          if (stateProp && (selectedValue == null || String(selectedValue).trim() === "")) {
            const entityLabel = cfg.entityLabel || this._masterCfg?.key?.entityLabel || "Master"
            const message = cfg.selectionMessage || `${entityLabel}을(를) 먼저 선택해주세요.`
            showAlert(message)
            return
          }

          let overrides = {}
          if (typeof cfg.overrides === "function") {
            overrides = cfg.overrides.call(this, { selectedValue, role }) || {}
          } else if (cfg.overrides && typeof cfg.overrides === "object") {
            overrides = { ...cfg.overrides }
          }

          this.addRow({ manager, overrides, onAdded: cfg.onAdded || null })
        }
      }

      const deleteName = `delete${methodSuffix}Rows`
      if (!this.#hasCustomMethod(deleteName)) {
        this[deleteName] = () => {
          const manager = this.gridManager(role)
          if (!manager) return
          if (this.blockDetailActionIfMasterChanged?.()) return
          this.deleteRows({ manager })
        }
      }

      const saveName = `save${methodSuffix}Rows`
      if (!this.#hasCustomMethod(saveName)) {
        this[saveName] = async () => {
          const manager = this.gridManager(role)
          if (!manager) return
          if (this.blockDetailActionIfMasterChanged?.()) return

          const stateProp = this._masterCfg?.key?.stateProperty
          const selectedValue = stateProp ? this[stateProp] : ""
          if (stateProp && (selectedValue == null || String(selectedValue).trim() === "")) {
            const entityLabel = cfg.entityLabel || this._masterCfg?.key?.entityLabel || "Master"
            const message = cfg.selectionMessage || `${entityLabel}을(를) 먼저 선택해주세요.`
            showAlert(message)
            return
          }

          const template = this[cfg.batchUrlTemplate]
          if (!template) {
            showAlert("저장 URL이 설정되지 않았습니다.")
            return
          }
          const batchUrl = buildTemplateUrl(template, cfg.placeholder || ":id", selectedValue)
          await this.saveRowsWith({
            manager,
            batchUrl,
            saveMessage: cfg.saveMessage,
            onSuccess: cfg.onSaveSuccess || (() => this[`reload${methodSuffix}Rows`](selectedValue))
          })
        }
      }

      const fetchName = `fetch${methodSuffix}Rows`
      if (!this.#hasCustomMethod(fetchName)) {
        this[fetchName] = (rowData) => this.loadDetailRows(role, rowData)
      }

      const reloadName = `reload${methodSuffix}Rows`
      if (!this.#hasCustomMethod(reloadName)) {
        this[reloadName] = async (key) => {
          const stateProp = this._masterCfg?.key?.stateProperty
          const actualKey = key ?? (stateProp ? this[stateProp] : null)
          if (!actualKey) return

          const fakeRowData = { [cfg.masterKeyField]: actualKey }
          const rows = await this.loadDetailRows(role, fakeRowData)
          setManagerRowData(this.gridManager(role), rows)
        }
      }

      const clearName = `clear${methodSuffix}Rows`
      if (!this.#hasCustomMethod(clearName)) {
        this[clearName] = () => {
          setManagerRowData(this.gridManager(role), [])
        }
      }
    })
  }

  #hasCustomMethod(methodName) {
    const proto = Object.getPrototypeOf(this)
    const hasOwnProtoMethod = Object.prototype.hasOwnProperty.call(proto, methodName) &&
      typeof proto[methodName] === "function"
    const hasOwnInstanceMethod = Object.prototype.hasOwnProperty.call(this, methodName) &&
      typeof this[methodName] === "function"
    return hasOwnProtoMethod || hasOwnInstanceMethod
  }

  #resolveRoleMethodBase(role, cfg = {}) {
    if (cfg.methodBaseName) return cfg.methodBaseName
    if (role.endsWith("s")) return role.slice(0, -1)
    return role
  }

  #gridRegistry
  #expectedRoles
  #roleChildren
  #masterRoles
  #masterLastKeys
  #masterDispatchTokens
  #domBindings
  #roleApiBindings
  #allRolesReadyFired
  #beforeSearchHandler

  #registerSingleGrid(api, controller) {
    this.gridController = controller

    const config = this.resolveManagerConfig("configureManager")
    if (config) {
      this.manager = new GridCrudManager(config)
      this.manager.attach(api)
    } else {
      this.manager = null
      this._singleGridApi = api
    }
  }

  #registerMultiGrid(event, api, controller) {
    const gridElement = event.target?.closest?.("[data-controller='ag-grid']")
    if (!gridElement) return

    const matchedRole = this.#findRoleForElement(gridElement)
    if (!matchedRole) return

    const existing = this.#gridRegistry.get(matchedRole)
    this.#unbindRoleEvents(matchedRole)
    if (existing?.manager) existing.manager.detach()

    const roleConfig = this.#expectedRoles[matchedRole] || {}
    let manager = null
    const managerConfig = this.#resolveRoleManagerConfig(matchedRole, roleConfig)
    if (managerConfig) {
      manager = new GridCrudManager(managerConfig)
      manager.attach(api)
    }

    this.#gridRegistry.set(matchedRole, {
      api,
      controller,
      manager,
      element: gridElement
    })

    if (this.#masterRoles.has(matchedRole)) {
      this.#bindMasterRoleEvents(matchedRole, gridElement, api)
    }

    const roleNames = Object.keys(this.#expectedRoles)
    const allReady = roleNames.every((name) => this.#gridRegistry.has(name))
    if (allReady && !this.#allRolesReadyFired) {
      this.#allRolesReadyFired = true
      this.onAllGridsReady()
    }
  }

  #resolveRoleManagerConfig(roleName, roleConfig) {
    const source = roleConfig?.manager
    if (source == null) return null

    let rawConfig = null
    if (typeof source === "string") {
      rawConfig = this.resolveManagerConfig(source)
    } else if (typeof source === "function") {
      rawConfig = source.call(this, { roleName, roleConfig })
    } else {
      rawConfig = source
    }

    const { managerConfig } = this.splitManagerConfig(rawConfig)
    return managerConfig
  }

  #findRoleForElement(gridElement) {
    if (!this.#expectedRoles) return null

    for (const [role, config] of Object.entries(this.#expectedRoles)) {
      const targetName = config.target
      const targetEl = this.#resolveTarget(targetName)
      if (!targetEl) continue

      if (targetEl === gridElement || targetEl.contains(gridElement)) {
        return role
      }
    }
    return null
  }

  #resolveTarget(targetName) {
    const getter = `${targetName}Target`
    const hasGetter = `has${targetName.charAt(0).toUpperCase() + targetName.slice(1)}Target`
    if (this[hasGetter] && this[getter]) {
      return this[getter]
    }
    return null
  }

  #initializeRoleRelations() {
    if (!this.#expectedRoles) return

    Object.entries(this.#expectedRoles).forEach(([roleName, config]) => {
      if (config?.isMaster === true) {
        this.#masterRoles.add(roleName)
      }

      const parentRole = config?.parentGrid
      if (!parentRole || !this.#expectedRoles[parentRole]) return

      if (!this.#roleChildren.has(parentRole)) {
        this.#roleChildren.set(parentRole, [])
      }
      this.#roleChildren.get(parentRole).push(roleName)
      this.#masterRoles.add(parentRole)
    })
  }

  #bindMasterRoleEvents(roleName, gridElement, api) {
    const rowFocusedHandler = (event) => {
      const rowData = event?.detail?.data || null
      this.#handleMasterRowFocused(roleName, rowData)
    }

    gridElement.addEventListener("ag-grid:rowFocused", rowFocusedHandler)
    this.#domBindings.set(roleName, rowFocusedHandler)

    const rowDataUpdatedHandler = () => {
      this.#handleMasterRowDataUpdated(roleName)
    }

    if (isApiAlive(api)) {
      api.addEventListener("rowDataUpdated", rowDataUpdatedHandler)
      this.#roleApiBindings.set(roleName, [{ api, eventName: "rowDataUpdated", handler: rowDataUpdatedHandler }])
    }
  }

  #unbindRoleEvents(roleName) {
    const registration = this.#gridRegistry.get(roleName)

    const rowFocusedHandler = this.#domBindings.get(roleName)
    if (registration?.element && rowFocusedHandler) {
      registration.element.removeEventListener("ag-grid:rowFocused", rowFocusedHandler)
    }
    this.#domBindings.delete(roleName)

    const apiBindings = this.#roleApiBindings.get(roleName) || []
    apiBindings.forEach(({ api, eventName, handler }) => {
      if (isApiAlive(api)) {
        api.removeEventListener(eventName, handler)
      }
    })
    this.#roleApiBindings.delete(roleName)
  }

  #handleMasterRowDataUpdated(roleName) {
    const childRoles = this.#roleChildren.get(roleName) || []
    childRoles.forEach((childRole) => {
      this.#clearRoleRows(childRole)
      this.gridManager(childRole)?.resetTracking?.()
    })

    const roleConfig = this.#expectedRoles?.[roleName] || {}
    if (roleConfig.autoLoadOnReady === false) return

    // 데이터 재로드 후 동일 키의 행도 반드시 재디스패치되도록 중복 방지 키 초기화
    this.#masterLastKeys.delete(roleName)

    const rowData = this.selectFirstMasterRow(roleName)
    this.#handleMasterRowFocused(roleName, rowData)
  }

  #handleMasterRowFocused(roleName, rowData) {
    if (!this.#expectedRoles) return

    const dedupeKey = this.#resolveMasterDedupeKey(roleName, rowData)
    if (dedupeKey !== null) {
      const lastKey = this.#masterLastKeys.get(roleName)
      if (lastKey === dedupeKey) return
      this.#masterLastKeys.set(roleName, dedupeKey)
    }

    this.#dispatchMasterToChildren(roleName, rowData)
  }

  #resolveMasterDedupeKey(roleName, rowData) {
    const roleConfig = this.#expectedRoles?.[roleName] || {}
    const keyField = roleConfig.masterKeyField

    if (!keyField) return null
    if (!rowData) return "__EMPTY__"

    const value = rowData[keyField]
    return value == null ? "__EMPTY__" : String(value)
  }

  async #dispatchMasterToChildren(roleName, rowData) {
    const childRoles = this.#roleChildren.get(roleName) || []
    if (childRoles.length === 0) return

    const token = (this.#masterDispatchTokens.get(roleName) || 0) + 1
    this.#masterDispatchTokens.set(roleName, token)

    const skipLoad = !rowData || rowData.__is_deleted || rowData.__is_new

    await Promise.all(childRoles.map(async (childRole) => {
      const roleConfig = this.#expectedRoles?.[childRole] || {}

      if (typeof roleConfig.onMasterRowChange === "function") {
        try {
          roleConfig.onMasterRowChange.call(this, rowData)
        } catch (error) {
          console.error(`[${this.identifier}] onMasterRowChange error:`, error)
        }
      }

      if (skipLoad) {
        this.#clearRoleRows(childRole)
        return
      }

      if (typeof roleConfig.detailLoader !== "function") return

      try {
        const loadedRows = await roleConfig.detailLoader.call(this, rowData, {
          masterRole: roleName,
          detailRole: childRole,
          masterApi: this.gridApi(roleName),
          detailApi: this.gridApi(childRole)
        })

        if (this.#masterDispatchTokens.get(roleName) !== token) return

        const rows = Array.isArray(loadedRows) ? loadedRows : []
        const manager = this.gridManager(childRole)
        if (manager) {
          setManagerRowData(manager, rows)
        } else {
          this.setRows(childRole, rows)
        }
      } catch (error) {
        if (this.#masterDispatchTokens.get(roleName) !== token) return
        console.error(`[${this.identifier}] detailLoader error:`, error)
        this.#clearRoleRows(childRole)
      }
    }))
  }

  #clearRoleRows(roleName) {
    const manager = this.gridManager(roleName)
    if (manager) {
      setManagerRowData(manager, [])
      return
    }

    this.setRows(roleName, [])
  }

  #handleBeforeSearch() {
    if (this.#expectedRoles) {
      this.#masterLastKeys.clear()
      this.#masterDispatchTokens.clear()

      Object.keys(this.#expectedRoles).forEach((roleName) => {
        this.#clearRoleRows(roleName)
        this.gridManager(roleName)?.resetTracking?.()
      })
      this.beforeSearchReset()
      return
    }

    if (this.manager) {
      setManagerRowData(this.manager, [])
      this.beforeSearchReset()
      return
    }

    if (isApiAlive(this._singleGridApi)) {
      setGridRowData(this._singleGridApi, [])
    }
    this.beforeSearchReset()
  }

  getSearchFormValue(fieldName, { toUpperCase = true } = {}) {
    return getSearchFormValueFromBridge(this.application, fieldName, { toUpperCase })
  }

  getSearchFieldElement(fieldName) {
    return getSearchFieldElementFromBridge(fieldName)
  }
}
