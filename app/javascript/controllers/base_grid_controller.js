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
import { GridEventManager } from "controllers/grid/grid_event_manager"
import { isApiAlive, setGridRowData, postJson, hasChanges, getCsrfToken } from "controllers/grid/grid_utils"

export default class BaseGridController extends Controller {
  static targets = ["grid"]

  static values = {
    batchUrl: String
  }

  // ─── Lifecycle ───

  connect() {
    // 단일 그리드 모드 호환용
    this.manager = null
    this.gridController = null

    // 다중 그리드 레지스트리
    this.#gridRegistry = new Map()
    this.#gridEvents = new GridEventManager()
    this.#expectedRoles = this.gridRoles()
  }

  disconnect() {
    // 다중 그리드 정리
    this.#gridEvents.unbindAll()
    this.#gridRegistry.forEach(({ manager }) => {
      if (manager) manager.detach()
    })
    this.#gridRegistry.clear()

    // 단일 그리드 정리
    if (this.manager) {
      this.manager.detach()
      this.manager = null
    }
    this.gridController = null
  }

  // ─── 그리드 등록 ───

  registerGrid(event) {
    const { api, controller } = event.detail

    if (this.#expectedRoles) {
      this.#registerMultiGrid(event, api, controller)
    } else {
      this.#registerSingleGrid(api, controller)
    }
  }

  // ─── 서브 클래스 오버라이드 포인트 ───

  // 다중 그리드 모드 시 역할-타겟 매핑 반환. null이면 단일 그리드 모드.
  gridRoles() { return null }

  // 단일 CRUD 그리드 설정. null 반환 시 Manager 생성 스킵 (읽기 전용 그리드).
  configureManager() { return null }

  // 다중 그리드 모드에서 모든 그리드 등록이 완료되었을 때 호출되는 훅.
  onAllGridsReady() { }

  // ─── 다중 그리드 접근 API ───

  gridApi(name) {
    return this.#gridRegistry.get(name)?.api || null
  }

  gridCtrl(name) {
    return this.#gridRegistry.get(name)?.controller || null
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

  // ─── POST 헬퍼 (배치 액션 패턴) ───

  async postAction(url, body, { confirmMessage, onSuccess, onFail } = {}) {
    if (confirmMessage && !confirmAction(confirmMessage)) return false

    try {
      const response = await fetch(url, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": getCsrfToken()
        },
        body: JSON.stringify(body)
      })

      const result = await response.json()

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

  // ─── 단일 그리드 CRUD 액션 (기존 호환) ───

  addRow() {
    if (!this.manager) return
    const overrides = this.buildNewRowOverrides?.() || {}
    this.manager.addRow(overrides)
  }

  deleteRows() {
    if (!this.manager) return
    this.manager.deleteRows({
      beforeDelete: this.beforeDeleteRows?.bind(this)
    })
  }

  async saveRows() {
    if (!this.manager) return

    this.manager.stopEditing()

    const operations = this.manager.buildOperations()
    if (!hasChanges(operations)) {
      showAlert("변경된 데이터가 없습니다.")
      return
    }

    const ok = await postJson(this.batchUrlValue, operations)
    if (!ok) return

    showAlert(this.saveMessage)

    if (this.afterSaveSuccess) {
      this.afterSaveSuccess()
    } else {
      this.reloadRows()
    }
  }

  reloadRows() {
    if (this.gridController?.refresh) {
      this.gridController.refresh()
    }
  }

  get saveMessage() {
    return "저장이 완료되었습니다."
  }

  // ─── Private ───

  #gridRegistry
  #gridEvents
  #expectedRoles

  #registerSingleGrid(api, controller) {
    this.gridController = controller

    const config = this.configureManager()
    if (config) {
      this.manager = new GridCrudManager(config)
      this.manager.attach(api)
    } else {
      // Manager 없이 API만 보관 (읽기 전용 그리드)
      this.manager = null
      this._singleGridApi = api
    }
  }

  #registerMultiGrid(event, api, controller) {
    const gridElement = event.target?.closest?.("[data-controller='ag-grid']")
    if (!gridElement) return

    const matchedRole = this.#findRoleForElement(gridElement)
    if (!matchedRole) return

    // 기존 등록 정리
    const existing = this.#gridRegistry.get(matchedRole)
    if (existing?.manager) existing.manager.detach()

    this.#gridRegistry.set(matchedRole, { api, controller, manager: null })

    // 모든 그리드 등록 완료 체크
    const roleNames = Object.keys(this.#expectedRoles)
    if (roleNames.every((name) => this.#gridRegistry.has(name))) {
      this.onAllGridsReady()
    }
  }

  #findRoleForElement(gridElement) {
    if (!this.#expectedRoles) return null

    for (const [role, config] of Object.entries(this.#expectedRoles)) {
      const targetName = config.target
      // Stimulus target 속성으로 매칭: data-<controller>-target="targetName"
      // gridElement 자체 또는 그 부모가 target일 수 있으므로 closest와 querySelector 모두 시도
      const targetEl = this.#resolveTarget(targetName)
      if (!targetEl) continue

      if (targetEl === gridElement || targetEl.contains(gridElement)) {
        return role
      }
    }
    return null
  }

  #resolveTarget(targetName) {
    // Stimulus targets 배열에서 해당 타겟 엘리먼트를 가져옴
    const getter = `${targetName}Target`
    const hasGetter = `has${targetName.charAt(0).toUpperCase() + targetName.slice(1)}Target`
    if (this[hasGetter] && this[getter]) {
      return this[getter]
    }
    return null
  }

  // ─── Search Form 통합 연동 ───

  /**
   * 화면 내 search_form_controller 개체를 찾아 특정 필드의 값을 반환합니다.
   * @param {string} fieldName 찾고자 하는 조건 필드명 (q 태그 제외, 예: 'workpl_cd')
   * @param {Object} options 옵션 객체 { toUpperCase: true/false }
   * @returns {string} 찾아낸 값
   */
  getSearchFormValue(fieldName, { toUpperCase = true } = {}) {
    if (!this.application) return ""
    const formEl = document.querySelector('[data-controller~="search-form"]')
    if (!formEl) return ""

    const formCtrl = this.application.getControllerForElementAndIdentifier(formEl, "search-form")
    if (!formCtrl || typeof formCtrl.getSearchFieldValue !== "function") return ""

    const val = String(formCtrl.getSearchFieldValue(`q[${fieldName}]`) || "").trim()
    return toUpperCase ? val.toUpperCase() : val
  }

  /**
   * 화면 내 search_form 컨테이너에서 특정 필드의 DOM 엘리먼트를 반환합니다.
   * @param {string} fieldName - q 태그 제외 필드명 (예: 'workpl_cd')
   * @returns {Element|null}
   */
  getSearchFieldElement(fieldName) {
    const formEl = document.querySelector('[data-controller~="search-form"]')
    if (!formEl) return null
    const elements = formEl.querySelectorAll(`[name="q[${fieldName}]"]`)
    return elements.length > 0 ? elements[elements.length - 1] : null
  }
}
