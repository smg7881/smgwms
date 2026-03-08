/**
 * GridCrudManager
 *
 * 단일 AG Grid의 CRUD 상태 추적/조작을 캡슐화하는 순수 JS 클래스.
 * Stimulus 컨트롤러와 독립적으로 동작하며, 하나의 AG Grid API에 연결된다.
 *
 * Config 스키마:
 * {
 *   pkFields:          ["workpl_cd", "area_cd"],           // PK 필드 배열 (삭제/수정 기준 키)
 *   fields:            { field_name: "trim|trimUpper|..." }, // 각 필드별 데이터 정규화 규칙
 *   defaultRow:        { use_yn: "Y" },                    // 신규 행 추가 시 적용할 기본값 객체
 *   blankCheckFields:  ["code", "name"],                   // 해당 필드들이 모두 비어있으면 '빈 행'으로 간주해 저장 대상에서 제외
 *   comparableFields:  ["name", "use_yn"],                 // 변경(Update) 감지를 위해 원본과 비교할 필드 목록
 *   firstEditCol:      "code",                             // 신규 행 추가 완료 직후 포커스를 둘 첫 번째 헤더 컬럼
 *   pkLabels:          { code: "코드" },                   // PK 필드 수정 시도 시 띄워줄 알림창(alert) 용 한글 레이블
 *   onCellValueChanged: (event) => {},                     // 셀 값 변경 시 커스텀하게 주입할 콜백
 *   onRowDataUpdated:   () => {}                           // 그리드 전체 행 데이터 갱신 시 주입할 콜백
 * }
 */
import { isApiAlive } from "controllers/grid/core/api_guard"
import { collectRows, refreshGridCells, refreshStatusCells, hideNoRowsOverlay } from "controllers/grid/grid_api_utils"
import { uuid, formatValidationError } from "controllers/grid/grid_utils"
import { showAlert } from "components/ui/alert"

// 입력값을 백엔드 DB 저장 규격에 맞게 변환하는 정규화(Normalizer) 함수 모음
const NORMALIZERS = {
  trim: (v) => (v || "").toString().trim(),                                // 앞뒤 공백 제거
  trimUpper: (v) => (v || "").toString().trim().toUpperCase(),             // 공백 제거 후 대문자 변환 (코드성 데이터)
  number: (v) => {                                                         // 숫자 타입 강제 형변환 (NaN은 null처리)
    if (v == null || v === "") return null
    const n = Number(v)
    return Number.isNaN(n) ? null : n
  }
}

// "trimUpperDefault:0001" 과 같이 파라미터가 포함된 규격 문자열을 파싱하는 팩토리 함수
function parseNormalizerSpec(spec) {
  if (spec.startsWith("trimUpperDefault:")) {
    const defaultValue = spec.split(":")[1]
    return (v) => (v || defaultValue).toString().trim().toUpperCase()
  }
  return NORMALIZERS[spec] || NORMALIZERS.trim // 매칭되는게 없으면 trim 기본 적용
}

export default class GridCrudManager {
  #api = null               // 부착된 AG-Grid API 인스턴스
  #config = null            // 생성자로부터 주입받은 설정값
  #originalMap = new Map()  // 기존 데이터의 스냅샷 (수정/수정취소, 변경여부 감지용)
  #deletedKeys = []         // 사용자가 삭제 처리한(아직 DB에는 안지워진) 기존 행의 PK 키 모음
  #isCompositePk = false    // PK 필드가 2개 이상인 복합키 여부 캐싱
  #normalizerMap = new Map()// 파싱 완료된 처리 함수 캐싱 맵

  #handleCellValueChanged = null
  #handleRowDataUpdated = null

  /**
   * 컴포넌트(주로 GridController)로부터 설정 객체를 받아 내부 상태를 초기화합니다.
   * @param {Object} config GridCrudManager 설정 스키마 객체
   */
  constructor(config) {
    this.#config = config
    this.#isCompositePk = config.pkFields.length > 1

    // 설정된 필드 규격에 맞춰 정규화 함수 바인딩
    Object.entries(config.fields).forEach(([field, spec]) => {
      this.#normalizerMap.set(field, parseNormalizerSpec(spec))
    })

    // AG Grid의 콜백 핸들러 내부에서 this스코프 유지를 위해 래핑 함수 생성
    this.#handleCellValueChanged = (event) => this.#onCellValueChanged(event)
    this.#handleRowDataUpdated = () => this.#onRowDataUpdated()
  }

  /**
   * 매니저에 부착된 실제 AG-Grid API 객체를 반환합니다.
   * 컨트롤러 등 외부에서 API에 직접 접근해야 할 때 사용됩니다.
   * @returns {Object|null} AG-Grid API 인스턴스
   */
  get api() {
    return this.#api
  }

  /**
   * 생성된 AG-Grid 인스턴스(API)를 매니저에 연결(Binding)하고,
   * 셀 값 변경 및 행 데이터 갱신 이벤트를 추적하기 시작합니다.
   * @param {Object} api 연결할 AG-Grid API 인스턴스
   */
  attach(api) {
    this.#api = api
    api.addEventListener("cellValueChanged", this.#handleCellValueChanged)
    api.addEventListener("rowDataUpdated", this.#handleRowDataUpdated)
  }

  /**
   * AG-Grid 컴포넌트 파기 시 메모리 누수 방지를 위해 부착했던 이벤트 리스너를 모두 제거하고,
   * 추적 중이던 원본 데이터 스냅샷 등 내부 리소스를 비웁니다.
   */
  detach() {
    if (isApiAlive(this.#api)) {
      this.#api.removeEventListener("cellValueChanged", this.#handleCellValueChanged)
      this.#api.removeEventListener("rowDataUpdated", this.#handleRowDataUpdated)
    }
    this.#api = null
    this.#originalMap = new Map()
    this.#deletedKeys = []
  }

  /**
   * 그리드 최상단(0번 인덱스)에 완전히 비어있거나 특정 기본값(overrides)이 세팅된 새 행을 추가합니다.
   * 신규 플래그(`__is_new`), 식별용 임시 ID(`__temp_id`)를 부여하고 포커스를 이동합니다.
   * @param {Object} overrides 덮어씌울 초기 데이터 객체
   * @param {Object} [options]
   * @param {string} [options.startCol] 행 추가 직후 포커싱 대상이 될 기준 컬럼명
   * @returns {Object|undefined} AG-Grid Transaction 적용 결과 객체
   */
  addRow(overrides = {}, { startCol } = {}) {
    if (!isApiAlive(this.#api)) return

    const newRow = {
      ...this.#config.defaultRow,
      ...overrides,
      __is_new: true,
      __temp_id: uuid()
    }

    const txResult = this.#api.applyTransaction({ add: [newRow], addIndex: 0 })
    hideNoRowsOverlay(this.#api)

    refreshGridCells(this.#api, { columns: ["__row_no"], force: true })
    this.#api.startEditingCell({ rowIndex: 0, colKey: startCol || this.#config.firstEditCol })

    return txResult
  }

  /**
   * 화면상에서 체크된(선택된) 데이터 행들을 찾아 '삭제됨'(`__is_deleted`) 상태로 무효화 처리합니다.
   * 아직 저장된 적이 없는 신규 행일 경우 서버 전송 없이 화면 DOM에서만 즉시 날려버립니다.
   * @param {Object} [options]
   * @param {Function} [options.beforeDelete] 삭제 직전에 호출되어 진행 여부를 가르는 훅 함수
   * @returns {boolean} 삭제 처리 진행(성공) 여부
   */
  deleteRows({ beforeDelete } = {}) {
    if (!isApiAlive(this.#api)) return false

    const selectedNodes = this.#api.getSelectedNodes()
    if (!selectedNodes.length) {
      showAlert("삭제할 행을 선택하세요.")
      return false
    }

    if (beforeDelete) {
      const blocked = beforeDelete(selectedNodes)
      if (blocked) return false
    }

    const rowsToRemove = []
    const nodesToRefresh = []

    selectedNodes.forEach((node) => {
      const row = node.data
      if (!row) return

      if (row.__is_new) {
        rowsToRemove.push(row)
        return
      }

      const key = this.#extractDeleteKey(row)
      if (key) this.#deletedKeys.push(key)

      row.__is_deleted = true
      delete row.__is_updated
      nodesToRefresh.push(node)
    })

    if (rowsToRemove.length > 0) {
      this.#api.applyTransaction({ remove: rowsToRemove })
      refreshGridCells(this.#api, { columns: ["__row_no"], force: true })
    }

    if (nodesToRefresh.length > 0) {
      refreshStatusCells(this.#api, nodesToRefresh)
    }

    return true
  }

  /**
   * 현재 메모리에 누적된 모든 변경점(신규, 수정, 삭제)들을 수집하여, 백엔드 API가 요구하는 배열 페이로드로 조립합니다.
   * 무의미한 빈 칸 행들은 필터링하며, 수정점들은 정의된 Normalizer 함수를 거치게 됩니다.
   * @returns {Object} `{ rowsToInsert: [...], rowsToUpdate: [...], rowsToDelete: [...] }` 형태의 연산 객체
   */
  buildOperations() {
    const rows = collectRows(this.#api)

    const rowsToInsert = rows
      .filter((row) => row.__is_new && !row.__is_deleted && !this.#isBlankRow(row))
      .map((row) => this.#pickFields(row))

    const rowsToUpdate = rows
      .filter((row) => !row.__is_new && !row.__is_deleted && this.#rowChanged(row))
      .map((row) => this.#pickFields(row))

    if (this.#isCompositePk) {
      const deleteKeyMap = new Map()
      this.#deletedKeys.forEach((key) => {
        deleteKeyMap.set(this.#serializeKey(key), key)
      })

      rows
        .filter((row) => row.__is_deleted)
        .map((row) => this.#extractDeleteKey(row))
        .filter(Boolean)
        .forEach((key) => {
          deleteKeyMap.set(this.#serializeKey(key), key)
        })

      return { rowsToInsert, rowsToUpdate, rowsToDelete: Array.from(deleteKeyMap.values()) }
    }

    const pkField = this.#config.pkFields[0]
    const rowsToDelete = [
      ...this.#deletedKeys,
      ...rows.filter((row) => row.__is_deleted && row[pkField]).map((row) => row[pkField])
    ]

    return { rowsToInsert, rowsToUpdate, rowsToDelete: [...new Set(rowsToDelete)] }
  }

  /**
   * 저장소 동기화(Save 완료) 혹은 데이터 전면 Re-Fetch가 이루어졌을 때 호출합니다.
   * 수정 여부 플래그들을 비우고 모든 현존 데이터를 다시 새로운 '기준점 원본'으로 캐시 맵에 저장해 둡니다.
   */
  resetTracking() {
    this.#deletedKeys = []
    this.#originalMap = new Map()

    collectRows(this.#api).forEach((row) => {
      if (row.__is_new) {
        delete row.__is_updated
        delete row.__is_deleted
        return
      }

      const key = this.#rowKey(row)
      if (key) this.#originalMap.set(key, { ...row })

      delete row.__is_new
      delete row.__is_updated
      delete row.__is_deleted
      delete row.__temp_id
    })
  }

  /**
   * 사용자가 인라인 텍스트 셀을 '타이핑 중'인 상태에서 무언가 다른 조작(저장 등)을 명령했을 때,
   * 편집 모드를 즉시 빠져나와 임시 타이핑 값을 그리드 데이터 객체 안에 확정시킵니다.
   */
  stopEditing() {
    if (isApiAlive(this.#api)) {
      this.#api.stopEditing()
    }
  }

  /**
   * 그리드 내 존재하는 신규/수정 변경 분들에 한정하여 설정된 유효성 규칙(Validation Rules)을 통과하는지 검증합니다.
   * 복합 필드 규정이나 복잡한 row-level 체크 등이 처리됩니다.
   * @returns {Object} `{ valid: boolean, errors: Array, firstError: Object|null }` 형태의 결과 객체
   */
  validateRows() {
    if (!isApiAlive(this.#api)) {
      return { valid: true, errors: [], firstError: null }
    }

    const rules = this.#config.validationRules
    if (!rules || typeof rules !== "object") {
      return { valid: true, errors: [], firstError: null }
    }

    const candidates = this.#collectValidationCandidates()
    if (candidates.length === 0) {
      return { valid: true, errors: [], firstError: null }
    }

    const errors = []
    candidates.forEach((candidate) => {
      const normalizedRow = this.#pickFields(candidate.row)
      this.#applyRequiredFieldRules(rules, candidate, normalizedRow, errors)
      this.#applyFieldRules(rules, candidate, normalizedRow, errors)
      this.#applyRowRules(rules, candidate, normalizedRow, errors)
    })

    return {
      valid: errors.length === 0,
      errors,
      firstError: errors[0] || null
    }
  }

  /**
   * 검증(Validation) 실패 시, 실패 원인이 된 첫 번째 셀의 실제 화면 DOM 위치를 탐색해
   * 스크롤을 이동하고 붉게 반짝이도록(Flash) 포커스 처리를 가미해주는 편의 헬퍼 메서드.
   * @param {Object} error validateRows 로부터 반환된 단일 에러 객체 (firstError)
   * @returns {boolean} 에러 셀 특정 및 포커스 성공 여부
   */
  focusValidationError(error) {
    if (!isApiAlive(this.#api) || !error) return false

    const targetNode = this.#findNodeByValidationError(error)
    if (!targetNode) return false

    const rowIndex = typeof targetNode.rowIndex === "number" ? targetNode.rowIndex : null
    if (rowIndex == null || rowIndex < 0) return false

    this.#api.ensureIndexVisible?.(rowIndex)

    const colKey = this.#resolveFocusColumn(error.field)
    if (colKey) {
      this.#api.setFocusedCell?.(rowIndex, colKey)
      this.#api.flashCells?.({ rowNodes: [targetNode], columns: [colKey] })
    }
    targetNode.setSelected?.(true, true)

    return true
  }

  /**
   * (N개의 항목은 생략) 등 여러 건 발생한 밸리데이션 에러 문구들을 한 줄로 축약(Summary)하여
   * Alert 창이나 인라인 에러 바에 표출하기 좋게 예쁘게 다듬어 반환합니다.
   * @param {Array<Object>} errors 발생한 모든 에러 목록
   * @param {Object} [options] 최대 노출 아이템 수 등 옵션
   * @returns {string} 조합된 최종 에러 메시지 텍스트
   */
  formatValidationSummary(errors, { maxItems = 3 } = {}) {
    const list = Array.isArray(errors) ? errors : []
    if (list.length === 0) {
      return "입력값을 확인해주세요."
    }

    const head = list.slice(0, Math.max(1, maxItems)).map((error) => formatValidationError(error))
    const remain = list.length - head.length
    if (remain > 0) {
      head.push(`외 ${remain}건`)
    }

    return head.join(" | ")
  }

  /**
   * ==========================================
   * Private 내부 처리용 헬퍼 구역
   * ==========================================
   */

  /**
   * 그리드에서 엔터/더블클릭/포커스-아웃 등으로 셀의 데이터 변경이 최종 확정(Commit)감지되었을 때 수행됩니다.
   * @param {Object} event AG-Grid cellValueChanged 이벤트 객체
   */
  #onCellValueChanged(event) {
    if (this.#preventInvalidPrimaryKeyEdit(event)) return
    if (this.#config.onCellValueChanged) {
      this.#config.onCellValueChanged(event)
    }
    this.#markRowUpdated(event)
  }

  /**
   * 외부(주로 setGridAction) 호출 등으로 인해 전체 rowData 배열이 통째로 새로 주입/교체되었을 때 추적망 구조를 초기화합니다.
   */
  #onRowDataUpdated() {
    this.resetTracking()
    if (this.#config.onRowDataUpdated) {
      this.#config.onRowDataUpdated()
    }
  }

  /**
   * 이미 DB에 존재하는(신규 추가가 아닌) 행의 Primary Key 컬럼 값을 사용자가 편집 시도하는 것을 원천 차단하고
   * 기존 값으로 즉시 강제 복구(Rollback)시킵니다.
   * @param {Object} event AG-Grid 이벤트 객체
   * @returns {boolean} PK 훼손 시도로 판별되어 롤백되었는지 여부
   */
  #preventInvalidPrimaryKeyEdit(event) {
    const field = event?.colDef?.field
    if (!this.#config.pkFields.includes(field)) return false
    if (!event?.node?.data) return false

    const row = event.node.data
    if (row.__is_new) return false

    row[field] = event.oldValue || ""
    refreshGridCells(this.#api, {
      rowNodes: [event.node],
      columns: [field],
      force: true
    })

    const label = this.#config.pkLabels?.[field] || field
    showAlert(`기존 ${label}는 수정할 수 없습니다.`)
    return true
  }

  /**
   * 셀 수정 발생 시 값의 변경(Diff)이 실제로 감지되었다면 해당 데이터 객체에 
   * `__is_updated` 플래그를 달아주고 좌측 상태 아이콘 셀을 리프레시합니다.
   * @param {Object} event AG-Grid 이벤트 객체
   */
  #markRowUpdated(event) {
    if (!event?.node?.data) return
    if (event.colDef?.field === "__row_status") return
    if (event.newValue === event.oldValue) return

    const row = event.node.data
    if (row.__is_new || row.__is_deleted) return

    row.__is_updated = true
    refreshStatusCells(this.#api, [event.node])
  }

  /**
   * 현재 그리드에 존재하는 행들 중에서 유효성 검증(Validation) 대상이 될 행 후보를 추출하여 반환합니다.
   * 완전히 삭제 처리된 행이거나 아무 값도 입력되지 않은 빈 행(__is_new + isBlankRow)은 제외하며,
   * 새롭게 추가된 행이거나 원본과 비교하여 변경 사항이 감지된 행만을 검증 대상으로 삼습니다.
   * @returns {Array<{scope: string, row: Object, rowIndex: number}>} 검증 대상 메타 정보 객체의 배열
   */
  #collectValidationCandidates() {
    const candidates = []
    this.#api.forEachNode((node) => {
      const row = node?.data
      if (!row) return
      if (row.__is_deleted) return

      if (row.__is_new) {
        if (this.#isBlankRow(row)) return
        candidates.push({ scope: "insert", row, rowIndex: node.rowIndex })
        return
      }

      if (this.#rowChanged(row)) {
        candidates.push({ scope: "update", row, rowIndex: node.rowIndex })
      }
    })
    return candidates
  }

  /**
   * 단일/복수 필드의 '필수 입력(requiredFields)' 관련 검증을 수행하고 실패 시 에러 목록(errors 배열)에 누적합니다.
   * 대상 컬럼이 비어있다면, 에러 객체를 생성하여 저장합니다.
   * @param {Object} rules 검증 규칙 전체 객체
   * @param {Object} candidate 평가 중인 행의 범위와 rowIndex 등 메타 정보
   * @param {Object} normalizedRow 정규화(Normalizer 적용)된 행 데이터
   * @param {Array<Object>} errors 위반 시 축적할 에러 레퍼런스 배열
   */
  #applyRequiredFieldRules(rules, candidate, normalizedRow, errors) {
    const requiredFields = Array.isArray(rules.requiredFields) ? rules.requiredFields : []
    requiredFields.forEach((field) => {
      const value = this.#resolveFieldValue(candidate.row, normalizedRow, field)
      if (this.#isEmptyValue(value)) {
        const label = this.#resolveFieldLabel(rules, field)
        errors.push(this.#buildValidationError({
          candidate,
          field,
          fieldLabel: label,
          code: "required",
          message: `${label}은(는) 필수입니다.`
        }))
      }
    })
  }

  /**
   * 개별 컬럼(필드) 단위의 다양한 속성 관련 제약 조건 규칙(fieldRules)들
   * (정규성 만족 여부, enum 포함 범위 확인, 커스텀 validate 체크 등)을 검증하여 에러 발생 시 누적시킵니다.
   * @param {Object} rules 검증 규칙 체계
   * @param {Object} candidate 소속 행 메타 데이터
   * @param {Object} normalizedRow 정규화된 데이터
   * @param {Array<Object>} errors 위반 시 축적할 에러 레퍼런스 배열
   */
  #applyFieldRules(rules, candidate, normalizedRow, errors) {
    const fieldRules = rules.fieldRules || {}
    Object.entries(fieldRules).forEach(([field, ruleList]) => {
      const value = this.#resolveFieldValue(candidate.row, normalizedRow, field)
      const rulesForField = Array.isArray(ruleList) ? ruleList : []
      const label = this.#resolveFieldLabel(rules, field)
      rulesForField.forEach((rule) => {
        const resolved = this.#evaluateFieldRule(rule, value, {
          field,
          label,
          row: candidate.row,
          normalizedRow,
          scope: candidate.scope
        })
        if (!resolved.valid) {
          errors.push(this.#buildValidationError({
            candidate,
            field: resolved.field || field,
            fieldLabel: resolved.fieldLabel || label,
            code: resolved.code || "invalid",
            message: resolved.message || `${label} 입력값을 확인하세요.`
          }))
        }
      })
    })
  }

  /**
   * 행(Row) 자체, 즉 1개 행 전반에 부여된 상위 레벨의 복합 규칙 제약들을 확인합니다.
   * 주로 여러 필드의 상태나 상관 관계를 동시에 체크할 때(예: 종료일자가 시작일자 이후인가? 등) 사용합니다.
   * @param {Object} rules 검증 규칙 체계
   * @param {Object} candidate 소속 행 메타 데이터
   * @param {Object} normalizedRow 정규화 데이터
   * @param {Array<Object>} errors 축적할 에러 배열
   */
  #applyRowRules(rules, candidate, normalizedRow, errors) {
    const rowRules = Array.isArray(rules.rowRules) ? rules.rowRules : []
    rowRules.forEach((rule) => {
      const resolved = this.#evaluateRowRule(rule, {
        row: candidate.row,
        normalizedRow,
        scope: candidate.scope
      })
      if (!resolved.valid) {
        const field = resolved.field || rule?.field || ""
        const label = this.#resolveFieldLabel(rules, field)
        errors.push(this.#buildValidationError({
          candidate,
          field,
          fieldLabel: label,
          code: resolved.code || rule?.code || "row_invalid",
          message: resolved.message || (field ? `${label} 입력값을 확인하세요.` : "행 입력값을 확인하세요.")
        }))
      }
    })
  }

  /**
   * 실제로 단일 필드에 지정된 1개의 Rule 평가 작업을 수행합니다.
   * 'required', 'minLength', 'maxLength', 'pattern', 'enum', 'custom' 패턴의
   * 파라미터 제약 검증을 분류하여 처리합니다.
   * @param {Object} rule 각 필드의 개별 Rule 객체
   * @param {any} value 해당 필드의 검증 대상 값
   * @param {Object} context 대상 필드 및 행 전체 등의 컨텍스트 참조
   * @returns {Object} `{ valid: boolean, code?: string, message?: string }` 형태의 결과 객체
   */
  #evaluateFieldRule(rule, value, context) {
    if (!rule || typeof rule !== "object") {
      return { valid: true }
    }

    const type = rule.type || "custom"
    const allowBlank = rule.allowBlank !== false
    const text = value == null ? "" : value.toString().trim()

    // 1. 공백 허용이며 비어있는 값이면 검사 통과 (단, 필수조건은 제외)
    if (allowBlank && text === "" && type !== "required") {
      return { valid: true }
    }

    // 2. 필수 입력 단일 체크
    if (type === "required") {
      if (this.#isEmptyValue(value)) {
        return { valid: false, code: "required", message: rule.message }
      }
      return { valid: true }
    }

    // 3. 최소 글자 길이 체크
    if (type === "minLength") {
      const limit = Number(rule.value ?? rule.min)
      if (!Number.isNaN(limit) && text.length < limit) {
        return { valid: false, code: "minLength", message: rule.message || `${context.label || context.field}은(는) 최소 ${limit}자 이상이어야 합니다.` }
      }
      return { valid: true }
    }

    // 4. 최대 글자 길이 체크
    if (type === "maxLength") {
      const limit = Number(rule.value ?? rule.max)
      if (!Number.isNaN(limit) && text.length > limit) {
        return { valid: false, code: "maxLength", message: rule.message || `${context.label || context.field}은(는) 최대 ${limit}자까지 입력할 수 있습니다.` }
      }
      return { valid: true }
    }

    // 5. 정규표현식 준수 여부 체크
    if (type === "pattern") {
      const pattern = rule.value instanceof RegExp ? rule.value : null
      if (pattern && !pattern.test(text)) {
        return { valid: false, code: "pattern", message: rule.message }
      }
      return { valid: true }
    }

    // 6. 열거형(enum) 포함 여부(사전 정의된 선택값 내인지) 체크
    if (type === "enum") {
      const values = Array.isArray(rule.values) ? rule.values.map((entry) => entry?.toString?.() ?? "") : []
      if (text !== "" && !values.includes(text)) {
        return { valid: false, code: "enum", message: rule.message }
      }
      return { valid: true }
    }

    // 7. 사용자가 직접 주입한 커스텀 로직(validate) 검사 함수 구동
    if (type === "custom" && typeof rule.validate === "function") {
      return this.#normalizeValidationResult(
        rule.validate(value, context),
        { code: rule.code || "custom", message: rule.message, field: context.field, fieldLabel: context.label }
      )
    }

    return { valid: true }
  }

  /**
   * 행 단위의 종합 규칙인 '커스텀 validate' 함수를 실행하고 그 복합 결과를 평가합니다.
   * 주로 여러 필드의 상태 간 관계 위배 시 사용됩니다.
   * @param {Object} rule 평기 진행할 규칙 객체
   * @param {Object} context 해당 로우에 대한 검증 컨텍스트 객체
   * @returns {Object} 검증 결과
   */
  #evaluateRowRule(rule, context) {
    if (!rule || typeof rule.validate !== "function") {
      return { valid: true }
    }

    return this.#normalizeValidationResult(
      rule.validate(context),
      { code: rule.code || "row_custom", message: rule.message, field: rule.field || "", fieldLabel: rule.fieldLabel }
    )
  }

  /**
   * 커스텀 validate 함수가 유연하게 리턴한 다양한 자료형의 값(boolean, string 포함)을
   * 매니저 코어가 표준으로 인식할 수 있는 내부 객체 모형(장부) 에러 포맷으로 일괄 변환-정규화(Normalize) 해줍니다.
   * @param {any} result 평가 함수에서 반환받은 원시 결과 형태
   * @param {Object} defaults 값 누락 등에 대한 초기 기본(디폴트값) 폴백 세팅
   * @returns {Object} `{ valid, code, message, field, fieldLabel }` 규격화 완성된 확인 속성 객체
   */
  #normalizeValidationResult(result, defaults = {}) {
    if (result === true || result == null) {
      return { valid: true }
    }
    if (result === false) {
      return { valid: false, code: defaults.code, message: defaults.message, field: defaults.field, fieldLabel: defaults.fieldLabel }
    }
    if (typeof result === "string") {
      return { valid: false, code: defaults.code, message: result, field: defaults.field, fieldLabel: defaults.fieldLabel }
    }
    if (typeof result === "object") {
      return {
        valid: result.valid !== false,
        code: result.code || defaults.code,
        message: result.message || defaults.message,
        field: result.field || defaults.field,
        fieldLabel: result.fieldLabel || defaults.fieldLabel
      }
    }
    return { valid: true }
  }

  /**
   * 정규화된 데이터 객체와 원본 입력 데이터 객체를 바탕으로
   * 현재 시점에서 밸리데이션 검사를 해야 하는 해당 필드의 실제 스냅샷 값을 도출해 옵니다.
   * @param {Object} row 원본 행
   * @param {Object} normalizedRow 필터 정규화가 완료된 행
   * @param {string} field 필드 키 문자열
   * @returns {any} 값
   */
  #resolveFieldValue(row, normalizedRow, field) {
    if (Object.prototype.hasOwnProperty.call(normalizedRow, field)) {
      return normalizedRow[field]
    }
    return row[field]
  }

  /**
   * 경고, 문구 등 사용자 통지 시 사용하기 위해, 영문이나 DB의 컬럼명 속성명을
   * 한글이나 UI상의 명찰 이름(label)으로 변환 매칭합니다. fallback 속성으로 원본 키명도 활용합니다.
   * @param {Object} rules 룰 집합 객체(내부 매핑 데이터 fieldLabels)
   * @param {string} field 컬럼명 대상 키값
   * @returns {string} 결정된 라벨 이름
   */
  #resolveFieldLabel(rules, field) {
    if (!field) return "입력값"
    const labels = rules.fieldLabels || {}
    return labels[field] || field
  }

  /**
   * 특정 컬럼이나 입력의 값이 비어 있는(null 혹은 공란) 상태인지 여부를 판별하는 유틸리티입니다.
   * 숫자 타입의 0은 값인 것으로 판별합니다.
   * @param {any} value 판별 입력 데이터
   * @returns {boolean} 값이 공란이거나 완전히 비어 있으면 true
   */
  #isEmptyValue(value) {
    if (value == null) return true
    if (typeof value === "string") return value.trim() === ""
    return false
  }

  /**
   * 유효성 검사 도중 위반 사항을 감지했을 시,
   * 추후 알림 바(Alerts) 표출 혹은 행 스크롤/포커싱 점프 대상을 설정하기위한
   * 식별이 가능하도록 표준 에러 규격 객체(에러 티켓)를 생성 반환합니다.
   * @param {Object} scope 및 각종 생성용 파라미터 값들 추출용 객체
   * @returns {Object} 티켓 객체
   */
  #buildValidationError({ candidate, field, fieldLabel = "", code, message }) {
    return {
      scope: candidate.scope,
      rowIndex: candidate.rowIndex,
      rowKey: this.#rowKey(candidate.row),
      tempId: candidate.row.__temp_id || null,
      field: field || "",
      fieldLabel: fieldLabel || "",
      code,
      message
    }
  }

  /**
   * 발생한 규격 에러 객체(티켓)를 바탕으로,
   * AG-Grid 내부에서 직접 화면 내 노드로 관리중인 실제 RowNode DOM 타겟을 탐색해 냅니다.
   * 포커싱 연출, 스크롤 이동 연동을 위해 필연적으로 호출되는 추적 함수입니다.
   * @param {Object} error 에러 발생 티켓
   * @returns {Object|null} Node 인스턴스 발견 시 반환
   */
  #findNodeByValidationError(error) {
    let foundNode = null
    this.#api.forEachNode((node) => {
      if (foundNode || !node?.data) return

      const row = node.data
      if (error.tempId && row.__temp_id && error.tempId === row.__temp_id) {
        foundNode = node
        return
      }

      if (error.rowKey) {
        const rowKey = this.#rowKey(row)
        if (rowKey && rowKey === error.rowKey) {
          foundNode = node
          return
        }
      }

      if (typeof error.rowIndex === "number" && node.rowIndex === error.rowIndex) {
        foundNode = node
      }
    })
    return foundNode
  }

  /**
   * 그리드 내 존재하는 컴포넌트 헤더, 필터 포커스 이동을 위한 DOM(colId) 이름 추출
   */
  #resolveFocusColumn(field) {
    const displayedCols = this.#api.getAllDisplayedColumns?.() || []
    const colIds = displayedCols.map((col) => col.getColId())

    if (field && colIds.includes(field)) return field
    if (this.#config.firstEditCol && colIds.includes(this.#config.firstEditCol)) {
      return this.#config.firstEditCol
    }
    return colIds[0] || null
  }

  /**
   * 백엔드 API와의 통신을 위해 `config.fields`에 명시된 속성들만 row 객체에서 추출합니다.
   * 이때 Normalizer(예: 정수로 파싱, 영문 대문자 변환 등)를 거친 'Clean Data' 맵을 반환합니다.
   */
  #pickFields(row) {
    const result = {}
    Object.entries(this.#config.fields).forEach(([field, _spec]) => {
      const normalizer = this.#normalizerMap.get(field)
      result[field] = normalizer(row[field])
    })
    return result
  }

  /**
   * 삭제 예정 행(row)에서 고유 식별(PK) 값들을 파악합니다.
   * 단일 식별자인지 복합 키인지에 알맞게 추출하여 문자열 혹은 오브젝트를 반환합니다.
   */
  #extractDeleteKey(row) {
    if (this.#isCompositePk) {
      const key = {}
      for (const field of this.#config.pkFields) {
        const value = (row[field] || "").toString().trim().toUpperCase()
        if (!value) return null
        key[field] = value
      }
      return key
    }

    const pkField = this.#config.pkFields[0]
    return (row[pkField] || "").toString().trim() || null
  }

  /**
   * 중복 제거 로직(Delete Set 등) 구동 시, 복합키의 다차원 검출을 위해 객체를 식별 문자열 형태로 포맷팅합니다.
   * 형태: `A_PK::B_PK`
   */
  #serializeKey(key) {
    if (typeof key === "string") return key
    return this.#config.pkFields.map((f) => key[f]).join("::")
  }

  /**
   * 주어진 row 객체에서 Primary Key 필드만 추출하여, 원본-현재값 대조 등의 식별에 사용할 복합 문자열을 만듭니다.
   */
  #rowKey(row) {
    const parts = this.#config.pkFields.map((f) => (row[f] || "").toString().trim().toUpperCase())
    if (parts.some((p) => !p)) return null
    return parts.join("::")
  }

  /**
   * 현재 그리드의 입력값(row)과 가장 처음 fetch 하였을 당시 스냅샷 맵(#originalMap)을 비교 대조합니다.
   * `config.comparableFields` 목록을 바탕으로 하여 "의미 있는 데이터의 변경" 인지 판독합니다.
   * 수정 점이 존재하면 true, 동일히 롤백되었거나 값이 같다면 false를 반환합니다.
   */
  #rowChanged(row) {
    const key = this.#rowKey(row)
    const original = key ? this.#originalMap.get(key) : null
    if (!original) return true

    return this.#config.comparableFields.some((field) => {
      const spec = this.#config.fields[field]
      if (spec === "number") {
        const a = row[field] == null ? "" : row[field].toString().trim()
        const b = original[field] == null ? "" : original[field].toString().trim()
        return a !== b
      }
      return (row[field] || "").toString().trim() !== (original[field] || "").toString().trim()
    })
  }

  /**
   * `blankCheckFields` 로 지정한 행 내부 모든 컬럼이 공란(비워진) 상태인지 판별합니다.
   * 새 행(AddRow) 처리 후 작성하지 않고 쓰레기로 남겨둔 더미 건을 걸러낼 때 쓰입니다.
   */
  #isBlankRow(row) {
    return this.#config.blankCheckFields.every((field) => (row[field] || "").toString().trim() === "")
  }
}
