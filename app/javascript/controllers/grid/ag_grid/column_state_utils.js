/**
 * column_state_utils.js
 *
 * AG Grid 컬럼 상태(순서·너비·숨김)를 localStorage에 저장하고 복원하는 유틸리티 함수 모음.
 * ag_grid_controller.js에서 분리된 순수 로직입니다.
 */
import { isApiAlive } from "controllers/grid/core/api_guard"

/**
 * localStorage 키를 반환합니다.
 */
export function columnStateStorageKey(gridId) {
  return `ag-grid-state:${gridId}`
}

/**
 * 현재 컬럼 상태(순서·너비·숨김)를 localStorage에 저장합니다.
 *
 * @param {object} gridApi - AG Grid API 인스턴스
 * @param {string} gridId - 저장에 사용할 고유 ID
 * @returns {boolean} 저장 성공 여부
 */
export function saveColumnState(gridApi, gridId) {
  if (!gridId || !isApiAlive(gridApi)) return false

  const state = gridApi.getColumnState()
  localStorage.setItem(columnStateStorageKey(gridId), JSON.stringify(state))
  return true
}

/**
 * localStorage에서 컬럼 상태를 삭제하고 기본 상태로 초기화합니다.
 *
 * @param {object} gridApi - AG Grid API 인스턴스
 * @param {string} gridId - 삭제에 사용할 고유 ID
 * @returns {boolean} 초기화 성공 여부
 */
export function resetColumnState(gridApi, gridId) {
  if (!gridId || !isApiAlive(gridApi)) return false

  localStorage.removeItem(columnStateStorageKey(gridId))
  gridApi.resetColumnState()
  return true
}

/**
 * localStorage에 저장된 컬럼 상태를 읽어 그리드에 복원합니다.
 * 저장된 상태가 없거나 JSON이 손상된 경우 캐시를 자동 삭제합니다.
 *
 * @param {object} gridApi - AG Grid API 인스턴스
 * @param {string} gridId - 복원에 사용할 고유 ID
 * @param {() => void} [onRestored] - 복원 후 호출할 콜백 (컬럼 순서 재정렬 등)
 * @returns {boolean} 복원 성공 여부
 */
export function restoreColumnState(gridApi, gridId, onRestored) {
  if (!gridId || !isApiAlive(gridApi)) return false

  const saved = localStorage.getItem(columnStateStorageKey(gridId))
  if (!saved) return false

  try {
    const state = JSON.parse(saved)
    gridApi.applyColumnState({ state, applyOrder: true })
    if (typeof onRestored === "function") onRestored()
    return true
  } catch (e) {
    console.warn("[ag-grid] failed to restore column state:", e)
    localStorage.removeItem(columnStateStorageKey(gridId))
    return false
  }
}
