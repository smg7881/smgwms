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

export function uuid() {
  return `${Date.now()}_${Math.random().toString(36).slice(2, 8)}`
}

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

export function numberOrNull(value) {
  if (value == null || value === "") return null

  const numeric = Number(value)
  if (Number.isNaN(numeric)) return null
  return numeric
}

export function buildTemplateUrl(template, paramsOrPlaceholder, value) {
  if (paramsOrPlaceholder !== null && typeof paramsOrPlaceholder === "object") {
    return Object.entries(paramsOrPlaceholder).reduce((url, [key, val]) => {
      return url.replace(`:${key}`, encodeURIComponent(val ?? ""))
    }, template)
  }

  return template.replace(paramsOrPlaceholder, encodeURIComponent(value ?? ""))
}

export function refreshSelectionLabel(target, value, entityLabel, emptyMessage) {
  if (!target) return
  target.textContent = value
    ? `선택 ${entityLabel}: ${value}`
    : (emptyMessage || `${entityLabel}을(를) 먼저 선택해주세요.`)
}

export function resolveNameFromMap(map, code) {
  if (!code || !map) return ""
  return map[code] || ""
}

export function buildCompositeKey(fields, separator = "::") {
  return fields.join(separator)
}

export function formatValidationError(error) {
  const scopeLabel = error?.scope === "insert" ? "추가" : "수정"
  const rowLabel = Number.isInteger(error?.rowIndex) ? `${error.rowIndex + 1}행` : "행"
  const fieldLabel = error?.fieldLabel || error?.field || "입력값"
  const message = error?.message || `${fieldLabel} 입력값을 확인하세요.`
  return `[${scopeLabel} ${rowLabel}] ${message}`
}
