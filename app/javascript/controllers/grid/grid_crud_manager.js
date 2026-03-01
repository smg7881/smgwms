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
import { isApiAlive, uuid, collectRows, refreshStatusCells, hideNoRowsOverlay } from "controllers/grid/grid_utils"
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

  // 외부에서 AG Grid Api를 직접 접근하기 위한 게이트웨이 게터
  get api() {
    return this.#api
  }

  // AG Grid 생성 직후 API 객체를 전달받아 이벤트 감지기를 부착
  attach(api) {
    this.#api = api
    api.addEventListener("cellValueChanged", this.#handleCellValueChanged)
    api.addEventListener("rowDataUpdated", this.#handleRowDataUpdated)
  }

  // AG Grid 파괴 시 함께 호출되어 이벤트 누수를 막는 연결 해제 메서드
  detach() {
    if (isApiAlive(this.#api)) {
      this.#api.removeEventListener("cellValueChanged", this.#handleCellValueChanged)
      this.#api.removeEventListener("rowDataUpdated", this.#handleRowDataUpdated)
    }
    this.#api = null
    this.#originalMap = new Map()
    this.#deletedKeys = []
  }

  // 그리드에 빈 새 행을 추가 (주로 + 혹은 '추가' 버튼 트리거)
  addRow(overrides = {}, { startCol } = {}) {
    if (!isApiAlive(this.#api)) return

    // 새 행에 초기값, 가상 신규 플래그(__is_new) 및 임시 ID 할당
    const newRow = {
      ...this.#config.defaultRow,
      ...overrides,
      __is_new: true,
      __temp_id: uuid()
    }

    // 그리드의 0번(최상단) 인덱스에 데이터 밀어넣기 처리 (AG Transaction API 사용)
    const txResult = this.#api.applyTransaction({ add: [newRow], addIndex: 0 })
    hideNoRowsOverlay(this.#api) // 오버레이 지우기

    // 방금 생긴 0번 행의 첫 컬럼에 에디터 포커싱 (사용자 편의성)
    this.#api.startEditingCell({ rowIndex: 0, colKey: startCol || this.#config.firstEditCol })
    return txResult
  }

  // 체크박스로 선택된 그리드 행들을 '삭제 대기' 상태로 전환 (물리적 삭제는 Save 호춯 시 수행됨)
  deleteRows({ beforeDelete } = {}) {
    if (!isApiAlive(this.#api)) return false

    // 선택된 노드 가져오기
    const selectedNodes = this.#api.getSelectedNodes()
    if (!selectedNodes.length) {
      showAlert("삭제할 행을 선택하세요.")
      return false
    }

    // 삭제 전 사용자 정의된 사전 검증 함수(외래키 제약 등)가 있다면 실행
    if (beforeDelete) {
      const blocked = beforeDelete(selectedNodes) // true를 반환하면 삭제 행위 전면 취소
      if (blocked) return false
    }

    const rowsToRemove = []   // 화면에서 아예 날려버릴 신규 작성 행
    const nodesToRefresh = [] // 빨간선(-) 긋고 화면엔 살려둘 기존 데이터 행

    selectedNodes.forEach((node) => {
      const row = node.data
      if (!row) return

      // 방금 추가했던 신규 데이터는 그냥 화면에서 날려버려도 무관
      if (row.__is_new) {
        rowsToRemove.push(row)
        return
      }

      // 기존 DB에 존재하던 데이터는 "삭제 예정" 목록(#deletedKeys)에 등록하고 취소선 처리용 플래그 부착
      const key = this.#extractDeleteKey(row)
      if (key) this.#deletedKeys.push(key)
      row.__is_deleted = true
      delete row.__is_updated // 수정 상태 표시 지우기
      nodesToRefresh.push(node)
    })

    // 신규 추가건은 즉시 DOM/State 제거
    if (rowsToRemove.length > 0) {
      this.#api.applyTransaction({ remove: rowsToRemove })
    }
    // 삭제 대기건은 상태 아이콘 표출 컬럼 갱신
    if (nodesToRefresh.length > 0) {
      refreshStatusCells(this.#api, nodesToRefresh)
    }

    return true
  }

  // 현재 그리드의 데이터 중 C(추가), U(수정), D(삭제) 요건만 걸러서 백엔드가 요구하는 페이로드 형식으로 제조
  buildOperations() {
    const rows = collectRows(this.#api)

    // INSERT 대상: 새 행(__is_new) + 삭제 아님 + 지정된 검사 필드가 비어있지 않은 유의미한 건들
    const rowsToInsert = rows
      .filter((row) => row.__is_new && !row.__is_deleted && !this.#isBlankRow(row))
      .map((row) => this.#pickFields(row))

    // UPDATE 대상: 기존 행 + 삭제 아님 + comparableFields 값 대조 시 변경점이 있는 건들
    const rowsToUpdate = rows
      .filter((row) => !row.__is_new && !row.__is_deleted && this.#rowChanged(row))
      .map((row) => this.#pickFields(row))

    // DELETE 대상 정리 로직 (복합키 vs 단일키 분기)
    if (this.#isCompositePk) {
      const deleteKeyMap = new Map() // 중복 제거용
      // 사용자가 선택해 지워둔 행
      this.#deletedKeys.forEach((key) => {
        deleteKeyMap.set(this.#serializeKey(key), key)
      })
      // 포착안됐으나 행에 __is_deleted 박혀있는 것 안전 확보
      rows
        .filter((row) => row.__is_deleted)
        .map((row) => this.#extractDeleteKey(row))
        .filter(Boolean)
        .forEach((key) => {
          deleteKeyMap.set(this.#serializeKey(key), key)
        })

      return { rowsToInsert, rowsToUpdate, rowsToDelete: Array.from(deleteKeyMap.values()) }
    }

    // 단일 PK 페이로드 모음 추출
    const pkField = this.#config.pkFields[0]
    const rowsToDelete = [
      ...this.#deletedKeys,
      ...rows.filter((row) => row.__is_deleted && row[pkField]).map((row) => row[pkField])
    ]

    // 중복 제거 후 반환 (단일키일 경우 Array<String>)
    return { rowsToInsert, rowsToUpdate, rowsToDelete: [...new Set(rowsToDelete)] }
  }

  // 저장(Save) 완료 혹은 데이터 새로고침 발생 시 변경 추적 모니터링 내부 상태를 백지로 되돌림
  resetTracking() {
    this.#deletedKeys = []
    this.#originalMap = new Map()

    collectRows(this.#api).forEach((row) => {
      // 이제 막 서버에서 읽은 상태라면 가상 플래그 제거
      if (row.__is_new) {
        delete row.__is_updated
        delete row.__is_deleted
        return
      }

      // 화면상의 모든 행을 순회하며 '수정 전 원본 스냅샷'을 Map 객체에 보관 (이후 rowChanged 검사 용도)
      const key = this.#rowKey(row)
      if (key) this.#originalMap.set(key, { ...row })
      delete row.__is_new
      delete row.__is_updated
      delete row.__is_deleted
      delete row.__temp_id
    })
  }

  // 셀 기반 인라인 에디터가 열려 있다면 강제로 닫음 (저장 직전 등에 사용)
  stopEditing() {
    if (isApiAlive(this.#api)) {
      this.#api.stopEditing()
    }
  }

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

  formatValidationSummary(errors, { maxItems = 3 } = {}) {
    const list = Array.isArray(errors) ? errors : []
    if (list.length === 0) {
      return "입력값을 확인해주세요."
    }

    const head = list.slice(0, Math.max(1, maxItems)).map((error) => this.#formatSingleValidationError(error))
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

  // 그리드에서 엔터/클릭벗어남 등으로 셀의 데이터 변경이 감지되었을 때 수행
  #onCellValueChanged(event) {
    if (this.#preventInvalidPrimaryKeyEdit(event)) return
    if (this.#config.onCellValueChanged) {
      this.#config.onCellValueChanged(event) // config에서 할당한 별도 행위(연쇄 연산 등)가 있다면 유발
    }
    this.#markRowUpdated(event) // 변경 아이콘 달아주기
  }

  // 외부(주로 setGridOptions)에서 전체 rowData 어레이가 통째로 교체되었을 때 추적망 리셋
  #onRowDataUpdated() {
    this.resetTracking()
    if (this.#config.onRowDataUpdated) {
      this.#config.onRowDataUpdated()
    }
  }

  // 기존행(이미 DB에 있는 행)의 PK 컬럼을 편집 시도하는 것을 차단하고 롤백시킴
  #preventInvalidPrimaryKeyEdit(event) {
    const field = event?.colDef?.field
    if (!this.#config.pkFields.includes(field)) return false // PK 아니면 상관없음
    if (!event?.node?.data) return false

    const row = event.node.data
    if (row.__is_new) return false // 새로 작성 중인 행은 PK 수정 가능

    // 이전 값(oldValue)으로 즉시 강제 복구
    row[field] = event.oldValue || ""
    this.#api.refreshCells({
      rowNodes: [event.node],
      columns: [field],
      force: true
    })

    const label = this.#config.pkLabels?.[field] || field
    showAlert(`기존 ${label}는 수정할 수 없습니다.`)
    return true
  }

  // 수정 발생 시, 값에 차이가 생겼다면 __is_updated 플래그 달고 상태셀 리플래시
  #markRowUpdated(event) {
    if (!event?.node?.data) return
    if (event.colDef?.field === "__row_status") return // 상태 셀이 무한 트리거되는것 방지
    if (event.newValue === event.oldValue) return

    const row = event.node.data
    if (row.__is_new || row.__is_deleted) return

    row.__is_updated = true
    refreshStatusCells(this.#api, [event.node])
  }

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

  #evaluateFieldRule(rule, value, context) {
    if (!rule || typeof rule !== "object") {
      return { valid: true }
    }

    const type = rule.type || "custom"
    const allowBlank = rule.allowBlank !== false
    const text = value == null ? "" : value.toString().trim()

    if (allowBlank && text === "" && type !== "required") {
      return { valid: true }
    }

    if (type === "required") {
      if (this.#isEmptyValue(value)) {
        return { valid: false, code: "required", message: rule.message }
      }
      return { valid: true }
    }

    if (type === "minLength") {
      const limit = Number(rule.value ?? rule.min)
      if (!Number.isNaN(limit) && text.length < limit) {
        return { valid: false, code: "minLength", message: rule.message || `${context.label || context.field}은(는) 최소 ${limit}자 이상이어야 합니다.` }
      }
      return { valid: true }
    }

    if (type === "maxLength") {
      const limit = Number(rule.value ?? rule.max)
      if (!Number.isNaN(limit) && text.length > limit) {
        return { valid: false, code: "maxLength", message: rule.message || `${context.label || context.field}은(는) 최대 ${limit}자까지 입력할 수 있습니다.` }
      }
      return { valid: true }
    }

    if (type === "pattern") {
      const pattern = rule.value instanceof RegExp ? rule.value : null
      if (pattern && !pattern.test(text)) {
        return { valid: false, code: "pattern", message: rule.message }
      }
      return { valid: true }
    }

    if (type === "enum") {
      const values = Array.isArray(rule.values) ? rule.values.map((entry) => entry?.toString?.() ?? "") : []
      if (text !== "" && !values.includes(text)) {
        return { valid: false, code: "enum", message: rule.message }
      }
      return { valid: true }
    }

    if (type === "custom" && typeof rule.validate === "function") {
      return this.#normalizeValidationResult(
        rule.validate(value, context),
        { code: rule.code || "custom", message: rule.message, field: context.field, fieldLabel: context.label }
      )
    }

    return { valid: true }
  }

  #evaluateRowRule(rule, context) {
    if (!rule || typeof rule.validate !== "function") {
      return { valid: true }
    }

    return this.#normalizeValidationResult(
      rule.validate(context),
      { code: rule.code || "row_custom", message: rule.message, field: rule.field || "", fieldLabel: rule.fieldLabel }
    )
  }

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
        valid: result.valid !== false ? true : false,
        code: result.code || defaults.code,
        message: result.message || defaults.message,
        field: result.field || defaults.field,
        fieldLabel: result.fieldLabel || defaults.fieldLabel
      }
    }
    return { valid: true }
  }

  #resolveFieldValue(row, normalizedRow, field) {
    if (Object.prototype.hasOwnProperty.call(normalizedRow, field)) {
      return normalizedRow[field]
    }
    return row[field]
  }

  #resolveFieldLabel(rules, field) {
    if (!field) return "입력값"
    const labels = rules.fieldLabels || {}
    return labels[field] || field
  }

  #isEmptyValue(value) {
    if (value == null) return true
    if (typeof value === "string") return value.trim() === ""
    return false
  }

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

  #resolveFocusColumn(field) {
    const displayedCols = this.#api.getAllDisplayedColumns?.() || []
    const colIds = displayedCols.map((col) => col.getColId())

    if (field && colIds.includes(field)) return field
    if (this.#config.firstEditCol && colIds.includes(this.#config.firstEditCol)) {
      return this.#config.firstEditCol
    }
    return colIds[0] || null
  }

  #formatSingleValidationError(error) {
    const scopeLabel = error?.scope === "insert" ? "추가" : "수정"
    const rowLabel = Number.isInteger(error?.rowIndex) ? `${error.rowIndex + 1}행` : "행"
    const fieldLabel = error?.fieldLabel || error?.field || "입력값"
    const message = error?.message || `${fieldLabel} 입력값을 확인하세요.`
    return `[${scopeLabel} ${rowLabel}] ${message}`
  }

  // 백엔드 통신용. 등록된 config.fields 속성들만 row객체에서 뽑되 normalizer(예: trimUpper)를 거친 클린한 데이터 객체를 반환
  #pickFields(row) {
    const result = {}
    Object.entries(this.#config.fields).forEach(([field, _spec]) => {
      const normalizer = this.#normalizerMap.get(field)
      result[field] = normalizer(row[field])
    })
    return result
  }

  // 대상 로우에서 삭제 키(단일 / 복합 객체형)를 골라냄
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

  // 복합키 Map 키용 문자열(A::B 형태) 직렬화
  #serializeKey(key) {
    if (typeof key === "string") return key
    return this.#config.pkFields.map((f) => key[f]).join("::")
  }

  // row객체에서 PK 값을 결합한 고유 식별자 문자열 획득
  #rowKey(row) {
    const parts = this.#config.pkFields.map((f) => (row[f] || "").toString().trim().toUpperCase())
    if (parts.some((p) => !p)) return null
    return parts.join("::")
  }

  // 현재 그리드의 입력값과 맨 처음 fetch 당시 담아둔 #originalMap을 대조하여
  // 수정해야 할 대상인지 판별 (수정했다가 다시 원상복구한 노드 잡기 방지)
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

  // 빈 내용으로 AddRow 후 작성하지 않고 내버려둔 일종의 쓰레기 더미 행인지 판별
  #isBlankRow(row) {
    return this.#config.blankCheckFields.every((field) => (row[field] || "").toString().trim() === "")
  }
}
