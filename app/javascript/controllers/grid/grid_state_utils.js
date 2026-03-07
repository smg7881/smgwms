/**
 * grid_state_utils.js
 *
 * 그리드 변경 상태 체크 및 비즈니스 흐름 제어 유틸리티 함수 모음.
 * 저장 전 변경 감지, 선택값 검증, 마스터 행 로드 가능 여부 판별 등.
 */
import { showAlert } from "components/ui/alert"

export function hasChanges(operations) {
  return (
    operations.rowsToInsert.length > 0 ||
    operations.rowsToUpdate.length > 0 ||
    operations.rowsToDelete.length > 0
  )
}

export function hasPendingChanges(manager) {
  if (!manager) return false
  return hasChanges(manager.buildOperations())
}

export function requireSelection(
  value,
  {
    entityLabel = "Target",
    title = "Warning",
    type = "warning",
    message = null
  } = {}
) {
  const present = value != null && String(value).trim() !== ""
  if (present) return true

  const fallback = `${entityLabel}을(를) 먼저 선택해주세요.`
  showAlert(title, message || fallback, type)
  return false
}

export function isLoadableMasterRow(rowData, keyField) {
  if (!rowData || !keyField) return false

  const keyValue = rowData[keyField]
  if (keyValue == null || String(keyValue).trim() === "") return false
  if (rowData.__is_deleted || rowData.__is_new) return false
  return true
}

export function blockIfPendingChanges(manager, entityLabel = "마스터") {
  if (!hasPendingChanges(manager)) return false
  showAlert(`${entityLabel}에 저장되지 않은 변경이 있습니다.`)
  return true
}
