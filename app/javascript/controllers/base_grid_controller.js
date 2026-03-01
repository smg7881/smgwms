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
import {
  isApiAlive,
  setGridRowData,
  setManagerRowData,
  focusFirstRow,
  postJson,
  hasChanges
} from "controllers/grid/grid_utils"
import { requestJson } from "controllers/grid/core/http_client"
import {
  getSearchFormValue as getSearchFormValueFromBridge,
  getSearchFieldElement as getSearchFieldElementFromBridge
} from "controllers/grid/core/search_form_bridge"

export default class BaseGridController extends Controller {
  static targets = ["grid"]

  static values = {
    batchUrl: String
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

  async postAction(url, body, { confirmMessage, onSuccess, onFail } = {}) {
    if (confirmMessage && !confirmAction(confirmMessage)) return false

    try {
      const { response, result } = await requestJson(url, { method: "POST", body })

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
