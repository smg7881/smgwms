/**
 * grid_utils.js
 *
 * 그리드 관련 범용 유틸리티 + 하위호환 re-export 허브.
 *
 * 직접 구현:
 *   uuid, numberOrNull, buildTemplateUrl, refreshSelectionLabel,
 *   resolveNameFromMap, buildCompositeKey, formatValidationError, postJson
 *
 * 하위호환 re-export (기존 import 경로 유지):
 *   core/api_guard   → isApiAlive
 *   core/http_client → getCsrfToken, fetchJson
 *   grid_api_utils   → setGridRowData, setManagerRowData, collectRows,
 *                       refreshStatusCells, hideNoRowsOverlay, focusFirstRow
 *   grid_state_utils → hasChanges, hasPendingChanges, requireSelection,
 *                       isLoadableMasterRow, blockIfPendingChanges
 *   grid_select_utils → setSelectOptions, clearSelectOptions
 */
import { showAlert } from "components/ui/alert"
import { requestJson } from "controllers/grid/core/http_client"

// ── 하위호환 re-export ──────────────────────────────────────────────────────
export { isApiAlive } from "controllers/grid/core/api_guard"
export { getCsrfToken, fetchJson } from "controllers/grid/core/http_client"
export {
  hideNoRowsOverlay,
  collectRows,
  setGridRowData,
  setManagerRowData,
  refreshStatusCells,
  focusFirstRow
} from "controllers/grid/grid_api_utils"
export {
  hasChanges,
  hasPendingChanges,
  requireSelection,
  isLoadableMasterRow,
  blockIfPendingChanges
} from "controllers/grid/grid_state_utils"
export { setSelectOptions, clearSelectOptions } from "controllers/grid/grid_select_utils"

// ── 직접 구현 ───────────────────────────────────────────────────────────────

/**
 * 임시 고유 ID(UUID 형태)를 발신/생성합니다. (현재 Timestamp + 무작위 문자열 조합)
 * 폼이나 그리드의 임시 데이터 식별자로 많이 쓰입니다.
 * 
 * @returns {string} 고유 식별자 문자열
 */
export function uuid() {
  return `${Date.now()}_${Math.random().toString(36).slice(2, 8)}`
}

/**
 * fetchJson 기반의 POST 통신 작업을 수행하며, 성공 여부에 따른 기본 Alert 에러 핸들링 로직이 내장되어 있습니다.
 *
 * @param {string} url 데이터를 전송할 백엔드 API 엔드포인트
 * @param {Object} body 전송할 페이로드 객체
 * @param {Object} [options] 추가 옵션 객체
 * @param {Function|null} [options.onError] 에러 발생 시 커스텀 처리 콜백 (없으면 alert 송출)
 * @returns {Promise<Object|boolean>} 서버 저장(성공) 시 result 객체, 실패 시 false
 */
export async function postJson(url, body, { onError = null } = {}) {
  const handleError = (message) => {
    if (onError) onError(message)
    else showAlert(message, null, "error")
  }

  try {
    const { response, result } = await requestJson(url, { method: "POST", body })
    if (!response.ok || !result.success) {
      handleError("저장 실패: " + (result.errors || ["요청 처리 실패"]).join(", "))
      return false
    }

    return result
  } catch {
    handleError("저장 실패: 네트워크 오류")
    return false
  }
}

/**
 * 문자열이나 빈 값들을 안전하게 Number 타입으로 캐스팅합니다.
 * 값이 아예 없거나 Not a Number 일 경우 숫자 0 대신 null을 반환합니다.
 *
 * @param {any} value 캐스팅할 원본 데이터
 * @returns {number|null} 파싱된 숫자 또는 null
 */
export function numberOrNull(value) {
  if (value == null || value === "") return null

  const numeric = Number(value)
  if (Number.isNaN(numeric)) return null
  return numeric
}

/**
 * 동적 URL의 템플릿 스트링(/:id/:pk 형태)에 파라미터 값들을 포맷팅하여 합성(Replace)해 줍니다.
 *
 * @param {string} template 원본 템플릿 URL (정규식 기반 :key 형태)
 * @param {Object|string} paramsOrPlaceholder 객체이면 다중 변환 적용, 문자열이면 단일 변환 키
 * @param {string} [value] 단일 변환일 경우 넘겨질 변환 대상 값
 * @returns {string} 동적으로 파싱된 실제 URL
 */
export function buildTemplateUrl(template, paramsOrPlaceholder, value) {
  if (paramsOrPlaceholder !== null && typeof paramsOrPlaceholder === "object") {
    return Object.entries(paramsOrPlaceholder).reduce((url, [key, val]) => {
      return url.replace(`:${key}`, encodeURIComponent(val ?? ""))
    }, template)
  }

  return template.replace(paramsOrPlaceholder, encodeURIComponent(value ?? ""))
}

/**
 * 화면 상에 현재 "선택된 대상" 이 무엇인지 텍스트 라벨을 업데이트해 줍니다.
 *
 * @param {HTMLElement} target 텍스트가 바인딩 될 라벨 DOM 엘리먼트
 * @param {string} value 표시할 현재 대상의 이름/값
 * @param {string} entityLabel 대상의 성격 (ex: '작업장', '창고' 등)
 * @param {string} [emptyMessage] 값이 비어 있을 때 띄울 커스텀 미선택 메시지
 */
export function refreshSelectionLabel(target, value, entityLabel, emptyMessage) {
  if (!target) return
  target.textContent = value
    ? `선택 ${entityLabel}: ${value}`
    : (emptyMessage || `${entityLabel}을(를) 먼저 선택해주세요.`)
}

/**
 * Key-Value 쌍으로 이뤄진 맵 데이터 객체에서, 코드(Key)에 해당하는 원본 이름(Label) 문자열을 탐색합니다.
 *
 * @param {Object} map 탐색 대상이 될 맵 객체
 * @param {string} code 역추적할 코드명 (Key)
 * @returns {string} 매칭된 문자열 풀네임 (없으면 빈칸)
 */
export function resolveNameFromMap(map, code) {
  if (!code || !map) return ""
  return map[code] || ""
}

/**
 * 복수의 Primary Key 조합을 바탕으로 1개의 다차원 식별용 복합 문자열 키(`A::B`)를 구성합니다.
 *
 * @param {Array<string>} fields 복합키 필드 목록
 * @param {string} [separator="::"] 구분자로 쓰일 문자열
 * @returns {string} 직렬화된 복합 문자열 키
 */
export function buildCompositeKey(fields, separator = "::") {
  return fields.join(separator)
}

/**
 * 컨트롤러 내부나 GridCrudManager 에서 발생한 Validation Rule 오류 객체를
 * "[추가 3행] 사업자번호 입력값을 확인하세요." 형태의 읽기 편한 에러 메시지로 가공해 줍니다.
 *
 * @param {Object} error Validation 에러 객체 (scope, rowIndex, fieldLabel, message 등 내포)
 * @returns {string} 가공 및 번역된 문자열 에러 메시지
 */
export function formatValidationError(error) {
  const scopeLabel = error?.scope === "insert" ? "추가" : "수정"
  const rowLabel = Number.isInteger(error?.rowIndex) ? `${error.rowIndex + 1}행` : "행"
  const fieldLabel = error?.fieldLabel || error?.field || "입력값"
  const message = error?.message || `${fieldLabel} 입력값을 확인하세요.`
  return `[${scopeLabel} ${rowLabel}] ${message}`
}
