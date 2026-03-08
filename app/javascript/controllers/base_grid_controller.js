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
  setSearchFormValue as setSearchFormValueFromBridge,
  getSearchFieldElement as getSearchFieldElementFromBridge
} from "controllers/grid/core/search_form_bridge"
import { ModalMixin } from "controllers/concerns/modal_mixin"
import { ExcelDownloadable } from "controllers/concerns/excel_downloadable"

export default class BaseGridController extends Controller {
  static targets = ["grid", "validationBox", "validationSummary", "validationList"]

  static values = {
    batchUrl: String,
    importHistoryUrl: String
  }

  /**
   * Stimulus 컨트롤러 로드 시 자동 실행.
   * 다중 그리드 모드(gridRoles)일 경우 마스터-디테일 관계와 통신용 이벤트 브릿지를 세팅합니다.
   */
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

  /**
   * Stimulus 컨트롤러 해제 시 자동 실행.
   * 등록된 모든 그리드의 이벤트 리스너를 제거하고 API를 파기하여 메모리 누수를 방지합니다.
   */
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

  /**
   * 하위 ag_grid_controller가 준비되었을 때 발생하는 커스텀 이벤트(ag-grid:ready)를 수신합니다.
   * 단일 혹은 다중 그리드 모드에 맞게 내부 레지스트리에 API와 컨트롤러, 매니저를 등록 결합합니다.
   * @param {CustomEvent} event - ag-grid:ready 이벤트 객체
   */
  registerGrid(event) {
    const { api, controller } = event.detail

    if (this.#expectedRoles) {
      this.#registerMultiGrid(event, api, controller)
    } else {
      this.#registerSingleGrid(api, controller)
    }
  }

  /**
   * (다중 그리드 전용) 각 역할(Role)별 그리드 타겟 및 설정을 정의하여 반환합니다.
   * 오버라이드하여 사용합니다.
   * @returns {Object|null} 역할 설정 맵
   */
  gridRoles() { return null }

  /**
   * (단일 그리드 전용) GridCrudManager 설정 객체를 정의하여 반환합니다.
   * 오버라이드하여 사용합니다.
   * @returns {Object|null} 매니저 설정 객체
   */
  configureManager() { return null }

  /**
   * (다중 그리드 전용) 마스터 그리드의 역할 및 콜백 설정을 정의하여 반환합니다.
   * 오버라이드하여 사용합니다.
   * @returns {Object|null} 마스터 그리드 설정 객체
   */
  masterConfig() { return null }

  /**
   * (다중 그리드 전용) 디테일 그리드 역할 배열 및 각각의 데이터 로드 방식 등을 정의하여 반환합니다.
   * 오버라이드하여 사용합니다.
   * @returns {Array<Object>} 디테일 그리드 설정 배열
   */
  detailGrids() { return [] }

  /**
   * 반환받은 원본 설정 객체에서 GridCrudManager 생성에 필요한 설정과 기타 등록(registration) 부가 정보를 분리합니다.
   * @param {Object} rawConfig - 원본 설정 객체
   * @returns {Object} 분리된 { managerConfig, registration } 객체
   */
  splitManagerConfig(rawConfig) {
    if (!rawConfig || typeof rawConfig !== "object") {
      return { managerConfig: rawConfig || null, registration: null }
    }

    const { registration = null, ...managerConfig } = rawConfig
    return { managerConfig, registration }
  }

  /**
   * 주어진 메서드 이름(configMethod)을 호출하여 GridCrudManager 설정 규격을 최종적으로 파싱해옵니다.
   * @param {string} configMethod - 호출할 컨피그 메서드명 (예: 'configureManager')
   * @returns {Object|null} 정제된 GridCrudManager 설정 객체
   */
  resolveManagerConfig(configMethod) {
    if (!configMethod) return null

    const source = this[configMethod]
    const rawConfig = typeof source === "function" ? source.call(this) : source
    const { managerConfig } = this.splitManagerConfig(rawConfig)
    return managerConfig
  }

  /**
   * (다중 그리드 전용) 정의된 모든 역할의 그리드가 DOM에 렌더링되고 내부 등록이 완료된 직후 1회 호출되는 Hook.
   */
  onAllGridsReady() { }

  /**
   * 공통 팝업 및 검색 폼에서 '검색 초기화'가 일어날 때 그리드를 비우면서 함께 실행되는 부가 초기화 Hook.
   */
  beforeSearchReset() { }

  /**
   * 지정한 역할명(name)을 가진 그리드의 AG-Grid API 인스턴스를 반환합니다.
   * @param {string} name - 그리드 역할명
   * @returns {Object|null} AG-Grid API 객체
   */
  gridApi(name) {
    return this.#gridRegistry.get(name)?.api || null
  }

  /**
   * 지정한 역할명(name)을 가진 하위 ag_grid_controller 인스턴스를 반환합니다.
   * @param {string} name - 그리드 역할명
   * @returns {Object|null} ag_grid_controller 인스턴스
   */
  gridCtrl(name) {
    return this.#gridRegistry.get(name)?.controller || null
  }

  /**
   * 지정한 역할명(name)을 가진 그리드에 결합된 GridCrudManager(CRUD 트래커) 인스턴스를 반환합니다.
   * @param {string} name - 그리드 역할명
   * @returns {Object|null} GridCrudManager 인스턴스
   */
  gridManager(name) {
    return this.#gridRegistry.get(name)?.manager || null
  }

  /**
   * 지정한 역할의 그리드에서 체크박스 등으로 선택된 모든 행 데이터를 배열로 반환합니다.
   * @param {string} name - 그리드 역할명
   * @returns {Array} 선택된 행 데이터 배열
   */
  selectedRows(name) {
    const api = this.gridApi(name)
    if (!isApiAlive(api)) return []
    return api.getSelectedRows()
  }

  /**
   * 지정한 역할의 그리드에 데이터를 통째로 새로 주입(Set)합니다. (기존 데이터 교체)
   * @param {string} name - 그리드 역할명
   * @param {Array} rows - 주입할 데이터 배열
   */
  setRows(name, rows) {
    const api = this.gridApi(name)
    if (!isApiAlive(api)) return
    setGridRowData(api, rows)
  }

  /**
   * 지정한 역할의 그리드가 바라보고 있는 데이터 API(URL endpoint)를 다시 호출하여 새로고침(Fetch)합니다.
   * @param {string} name - 그리드 역할명
   */
  refreshGrid(name) {
    const ctrl = this.gridCtrl(name)
    if (ctrl?.refresh) ctrl.refresh()
  }

  /**
   * 지정한 그리드의 루트(최상단 0번째 렌더된 행)에 키보드 포커싱을 강제로 위치시킵니다.
   * @param {string} name - 그리드 역할명
   * @param {Object} options 플래그 옵션 (노출 보장, 체크박스 자동 선택 등)
   * @returns {Object|null} 포커스 된 행 노드 데이터
   */
  selectFirstRow(name, { ensureVisible = true, select = false } = {}) {
    const api = this.gridApi(name)
    return focusFirstRow(api, { ensureVisible, select })
  }

  /**
   * 설정된 마스터 그리드의 첫 번째 행에 즉시 포커싱을 제공합니다. (조회 완료 후 자동 선택 용도)
   * @param {string} masterRole - 마스터 역할명 기본값 "master"
   * @returns {Object|null} 선택된 마스터 데이터
   */
  selectFirstMasterRow(masterRole = "master") {
    return this.selectFirstRow(masterRole, { ensureVisible: true, select: false })
  }

  /**
   * 주어진 템플릿 형태의 URL(예: /api/orders/:id/items)에서 지정된 파라미터(:id)를 실제 masterValue 값으로 치환하여 구체적인 Fetch 엔드포인트를 반환합니다.
   * @param {string} template URL 템플릿
   * @param {string|number} masterValue 치환될 값
   * @param {string} placeholder 치환 타겟 (기본 ":id")
   * @returns {string|null} 조합된 실제 URL
   */
  buildDetailBatchUrl(template, masterValue, placeholder = ":id") {
    const value = masterValue == null ? "" : String(masterValue).trim()
    if (!template || value === "") return null
    return buildTemplateUrl(template, placeholder, value)
  }

  /**
   * 화면 처리 시 특정 행이 '선택된 상태' 인지를 보장받기 위한 방어 로직입니다.
   * 누락된 경우 Alert 경고창과 함께 false를 반환하여 후속 액션 진행을 차단시킵니다.
   */
  requireMasterSelection(selectedValue, { entityLabel = "Master", message = null } = {}) {
    return requireSelection(selectedValue, {
      entityLabel,
      message
    })
  }

  /**
   * 해당 RowData가 아직 서버에 저장되지 않은 신규 추가상태 거나 삭제 상태인지 여부를 판별하여
   * 디테일 데이터베이스 조회(Fetch)를 건너뛸지(Loadable 한지) 결정합니다.
   */
  isMasterRowLoadable(rowData, keyField) {
    return isLoadableMasterRowUtil(rowData, keyField)
  }

  /**
   * 현재 지목된 Manager (기본 Master) 안에 작성 중이거나 변경된 내역(Pending Changes)이 존재하는지 확인합니다.
   * 수정사항이 존재할 경우 사용자의 타겟 변경 등 다른 동작을 가로막고 Alert를 표출합니다.
   */
  blockIfMasterPendingChanges(manager = this.gridManager("master"), entityLabel = "Master") {
    return blockIfPendingChanges(manager, entityLabel)
  }

  /**
   * 디테일 그리드의 새 행 추가 등 세부 조작을 시도할 때, 마스터 측에 보존되지 않은 수정 내역이 있는지를 검사해 차단합니다.
   */
  blockDetailActionIfMasterChanged(manager = this.gridManager("master"), entityLabel = "Master") {
    return this.blockIfMasterPendingChanges(manager, entityLabel)
  }

  /**
   * 서버 측으로 JSON 형식의 POST 데이터를 전송하고 성공/실패 여부를 쉽게 처리하는 공통 헬퍼 함수입니다.
   * 알림(Alert), 컨펌 모달(Confirm) 등을 통합 지원합니다.
   * @param {string} url - 전송할 API 주소
   * @param {Object} body - 전송할 JSON Payload
   * @param {Object} options - confirmMessage, onSuccess, onFail 콜백 옵션
   * @returns {Promise<boolean>} 성공 여부
   */
  async postAction(url, body, { confirmMessage, onSuccess, onFail } = {}) {
    if (confirmMessage && !await confirmAction(confirmMessage)) return false

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

  /**
   * Manager를 통해 현재 그리드에 새로운(빈 혹은 오버라이드된) 행 데이터를 추가합니다.
   * @param {Object} options 매니저, 초기값(overrides), 설정 및 추가 후 콜백(onAdded)
   * @returns {Object|null} 트랜잭션 결과 객체
   */
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

  /**
   * Manager를 통해 현재 그리드에서 선택되거나 지정된 행(들)을 삭제 처리(__is_deleted 플래그)합니다.
   * @param {Object} options 매니저, 삭제 전 검증 콜백(beforeDelete), 삭제 시 사용할 라벨(deleteLabel)
   * @returns {boolean} 삭제 처리 진행 여부
   */
  deleteRows({
    manager = this.manager,
    beforeDelete = this.beforeDeleteRows?.bind(this),
    deleteLabel = null
  } = {}) {
    if (!manager) return false
    if (typeof manager.deleteRows === "function") {
      return manager.deleteRows({ beforeDelete })
    }
    return false
  }

  /**
   * 현재 단일 그리드의 변경사항(GridCrudManager)을 일괄 검증 및 서버에 저장(batch_save)하도록 넘깁니다.
   * saveRowsWith 헬퍼를 래핑합니다.
   */
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

  /**
   * Manager(GridCrudManager)에 기록된 C/U/D 변경사항들을 프론트에서 먼저 검증(Validation)한 뒤,
   * 설정된 일괄 저장(batchUrl) API로 묶어서 POST 전송합니다.
   * 검증 실패 시 인라인(Validation Box) 혹은 Toast 기반 에러를 표출하고 저장을 강제 중단합니다.
   * @param {Object} options 전달받는 Manager, url, 메시지 및 성공 콜백 옵션
   * @returns {Promise<boolean>} 요청/저장 성공 여부
   */
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

  /**
   * 통신 성공 등 특정한 시점에 현재 그리드를 새로고침합니다.
   */
  reloadRows() {
    if (this.gridController?.refresh) {
      this.gridController.refresh()
    }
  }

  /**
   * 저장 성공 시 표시할 기본 알림 메시지를 반환합니다. getter로 선언되어 서브클래스에서 재정의할 수 있습니다.
   * @returns {string} 메시지
   */
  get saveMessage() {
    return "저장이 완료되었습니다."
  }

  /**
   * Manager 연산을 통해 반환된 검증 오류(validation errors) 데이터들을,
   * 화면 내부에 미리 약속된 validationTarget(오류 안내 박스/리스트)들에 시각적 HTML 요소로 렌더링합니다.
   * @param {Object} params 에러 객체 배열, 요약 텍스트, 엮인 manager 등
   * @returns {boolean} 해당 뷰에 오류 UI를 성공적으로 그렸는지 여부
   */
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

  /**
   * 화면 내 렌더링된 Validation 에러 박스 및 텍스트를 숨김 처리하고 안의 내용을 비웁니다.
   */
  clearValidationErrors() {
    if (!this.hasValidationBoxTarget) return
    this.validationBoxTarget.hidden = true
    if (this.hasValidationSummaryTarget) this.validationSummaryTarget.textContent = ""
    if (this.hasValidationListTarget) this.validationListTarget.innerHTML = ""
  }

  /**
   * (다중 그리드 전용) 메인 마스터 그리드에서 데이터 행이 변경되어 포커스를 다시 받았을 때 호출됩니다.
   * masterConfig의 onRowChange 옵션(syncForm, 폼 채우기 지원 등)에 맞춰 화면 라벨과 내부 폼을 연동합니다.
   * @param {Object|null} rowData 현재 선택된 마스터 데이터
   */
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

  /**
   * 마스터 그리드의 상태 키에 따라, 연결된 DOM 엘리먼트 타겟에 '현재 선택된 마스터' 정보를 텍스트로 표출(갱신)합니다.
   * (예: "지정된 창고가 없습니다", "001 (본사 창고) 선택됨")
   */
  refreshSelectedLabel() {
    const cfg = this._masterCfg?.key
    if (!cfg?.stateProperty || !cfg?.labelTarget) return

    const targetGetter = `${cfg.labelTarget}Target`
    const hasGetter = `has${cfg.labelTarget.charAt(0).toUpperCase() + cfg.labelTarget.slice(1)}Target`
    if (!this[hasGetter]) return

    refreshSelectionLabel(this[targetGetter], this[cfg.stateProperty], cfg.entityLabel, cfg.emptyMessage)
  }

  /**
   * 디테일 단위 그리드의 데이터를 백엔드에서 비동기로 조회해옵니다. (단일 페칭용 헬퍼)
   * @param {string} role 디테일 역할명
   * @param {Object} rowData 마스터 그리드의 데이터 객체
   * @returns {Promise<Array>} 페칭 완료된 목록 배열
   */
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

  /**
   * (다중 그리드 전용) 각 그리드 설정 정보(masterConfig, detailGrids)를 읽은 뒤,
   * 동적으로 컨트롤러 내부에 `addDetailRow`, `saveDetailRows` 등 CRUD 프록시(위임) 메서드들을 미리 생성(메타프로그래밍)해둡니다.
   */
  #initMasterDetail() {
    this._masterCfg = this.masterConfig?.() || null
    this._detailCfgs = this.detailGrids?.() || []

    if (!this._masterCfg && this._detailCfgs.length === 0) return

    this.#generateMasterMethods()
    this.#generateDetailMethods()
  }

  /**
   * 마스터 전용 프록시 함수(addMasterRow, deleteMasterRows, saveMasterRows 등)를 컨트롤러 인스턴스에 주입합니다.
   */
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

  /**
   * 디테일 전용 프록시 함수(addXXXRow, deleteXXXRows, saveXXXRows, loadXXXRows 등)를 역할별로 생성해 주입합니다.
   */
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

  /**
   * 이미 객체 또는 프로토타입 체인 상에 커스텀으로 구현(오버라이드)된 함수의 존재를 판별합니다.
   * 동적 프록시 함수 생성을 덮어씌울지 무시할지를 결정하는 데 이용합니다.
   */
  #hasCustomMethod(methodName) {
    const proto = Object.getPrototypeOf(this)
    const hasOwnProtoMethod = Object.prototype.hasOwnProperty.call(proto, methodName) &&
      typeof proto[methodName] === "function"
    const hasOwnInstanceMethod = Object.prototype.hasOwnProperty.call(this, methodName) &&
      typeof this[methodName] === "function"
    return hasOwnProtoMethod || hasOwnInstanceMethod
  }

  /**
   * 디테일 그리드의 role 이름에 알맞은 메서드 접두어를 추출합니다. (예: "items" -> "item")
   */
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

  /**
   * (단일 그리드 모드) 렌더링 된 AG-Grid 인스턴스를 컨트롤러에 직접 1:1 결합(bind)합니다.
   * configureManager()의 반환값에 따라 Manager를 부착합니다.
   */
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

  /**
   * (다중 그리드 모드) 이벤트 타겟 요소를 분석해 해당 그리드가 속한 역할(Role)을 판별한 후
   * 해시 맵(GridRegistry)에 API, Controller, Manager 등을 결합해 다건 저장합니다.
   */
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

  /**
   * 역할(Role)별로 지정된 GridCrudManager 설정을 파싱해 객체로 반환해줍니다. (string 혹은 function 지원)
   */
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

  /**
   * 발송된 이벤트의 DOM 요소를 기반으로, gridRoles() 에 정의해둔 target 엘리먼트들 중
   * 일치하거나 포함되는 역할(Role) 명칭을 찾아 문자열로 반환합니다.
   */
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

  /**
   * nameTarget 프로퍼티 Getter 규칙을 활용해, 실제 Stimulus Target DOM 엘리먼트를 반환합니다.
   */
  #resolveTarget(targetName) {
    const getter = `${targetName}Target`
    const hasGetter = `has${targetName.charAt(0).toUpperCase() + targetName.slice(1)}Target`
    if (this[hasGetter] && this[getter]) {
      return this[getter]
    }
    return null
  }

  /**
   * 다중 그리드 모드에서 설정된 isMaster 플래그 및 parentGrid 관계(부모-자식 다대다)를 분석해,
   * 추후 디스패치 전파에 사용할 역할 트리(Role Graph) 메모리를 구성해둡니다.
   */
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

  /**
   * 식별된 마스터 그리드 전용으로, 포커스 변경(rowFocused) 및 데이터 새로고침(rowDataUpdated) 이벤트를
   * DOM과 AG-Grid API 모두에서 리스닝하도록 바인딩합니다.
   */
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

  /**
   * 등록을 해제/초기화 시 해당 역할(Role) 그리드에 묶어두었던 리스너(DOM, API)를 해제합니다.
   */
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

  /**
   * 마스터 그리드의 데이터 갱신 시 연계된 모든 자식(Detail) 그리드의 상태를 초기화하고,
   * 필요하다면 새 마스터의 첫 행을 다시 자동으로 포커싱해 이벤트 연쇄를 발생킵니다.
   */
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

  /**
   * (다중 그리드 전용) 메인 마스터 그리드에서 포커싱/선택된 행이 변경되었을 때 내부적으로 호출됩니다.
   * 이전에 바로 클릭했던 동일한 행인지(dedupeKey 중복 디스패치 방지)를 판별 후, 이상이 없으면
   * 디테일 그리드들을 업데이트 시키는 디스패치 라우터(#dispatchMasterToChildren)를 트리거합니다.
   * @param {string} roleName 이벤트가 발생된 마스터 그리드 역할명
   * @param {Object} rowData 새로 포커싱 된 마스터 데이터 객체
   */
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

  /**
   * 마스터 행 데이터 중 고유 키(masterKeyField)를 추출하여, 빈 값이거나 식별 불가 시 처리할 기본값을 산출합니다.
   */
  #resolveMasterDedupeKey(roleName, rowData) {
    const roleConfig = this.#expectedRoles?.[roleName] || {}
    const keyField = roleConfig.masterKeyField

    if (!keyField) return null
    if (!rowData) return "__EMPTY__"

    const value = rowData[keyField]
    return value == null ? "__EMPTY__" : String(value)
  }

  /**
   * (다중 그리드 전용) 마스터 행 변경 이벤트를 구독(parentGrid 옵션) 중인 하위 자식 디테일 그리드들에게
   * 변경된 마스터 데이터를 동시 전달하고, 각자가 가진 비동기 로더(detailLoader) 콜백을 실행시켜
   * 하위 그리드 데이터를 연쇄적으로 갱신(네트워크 fetch 등) 시킵니다.
   * 진행 도중 마스터 포커스가 또 옮겨질 경우(동시성 문제), token 매칭을 통해 폐기 처리도 병행합니다.
   * @param {string} roleName 마스터 그리드 역할명
   * @param {Object} rowData 변경 전파 트리거가 된 마스터 최신 데이터
   */
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

  /**
   * 디테일 전용 화면 비우기 로직. 매니저가 있으면 데이터 셋만 초기화하고, 없으면 그리드를 직판으로 빈 배열 치환합니다.
   */
  #clearRoleRows(roleName) {
    const manager = this.gridManager(roleName)
    if (manager) {
      setManagerRowData(manager, [])
      return
    }

    this.setRows(roleName, [])
  }

  /**
   * 검색 폼이 제출리기 전(grid:before-search)에 컨트롤러와 메모리 상의 추적/캐싱 상태들을 모두 초기화시킵니다.
   */
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

  /**
   * 검색 바(SearchForm) 브릿지를 통해 현재 화면에 공통 적용된 지정 폼 컴포넌트의 특정 필드 값을 추출해 옵니다.
   */
  getSearchFormValue(fieldName, { toUpperCase = true, fieldElement = null } = {}) {
    return getSearchFormValueFromBridge(this.application, fieldName, { toUpperCase, fieldElement })
  }

  /**
   * 검색 폼 브릿지를 통해 지정 필드 값 설정
   */
  setSearchFormValue(fieldName, value, { fieldElement = null } = {}) {
    return setSearchFormValueFromBridge(this.application, fieldName, value, { fieldElement })
  }

  /**
   * 검색 폼 내부에 속한 특정 필드의 DOM Element를 획득해 리턴합니다.
   */
  getSearchFieldElement(fieldName, { fieldElement = null } = {}) {
    return getSearchFieldElementFromBridge(fieldName, { fieldElement })
  }
}

// ModalMixin: cancelRoleSelector getter를 포함하므로 Object.defineProperties로 적용
Object.defineProperties(BaseGridController.prototype, Object.getOwnPropertyDescriptors(ModalMixin))
// ExcelDownloadable: getter 없으므로 Object.assign으로 적용
Object.assign(BaseGridController.prototype, ExcelDownloadable)
