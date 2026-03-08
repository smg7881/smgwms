/**
 * grid_api_utils.js
 *
 * AG Grid API 직접 조작 유틸리티 함수 모음.
 * 행 데이터 세팅, 셀 리프레시, 포커스 등 Grid API 호출 관련 순수 함수들.
 */
import { isApiAlive } from "controllers/grid/core/api_guard"

/**
 * 그리드 데이터가 존재할 경우, "표시할 데이터가 없습니다" 혹은 "로딩 중" 등의 오버레이 레이어를 숨깁니다.
 * @param {Object} api AG-Grid 인스턴스
 */
export function hideNoRowsOverlay(api) {
  if (!isApiAlive(api)) return

  const rowCount = api.getDisplayedRowCount?.() || 0
  if (rowCount > 0) {
    api.setGridOption("loading", false)
    api.hideOverlay?.()
  }
}

/**
 * 현재 화면에 렌더링 된 AG-Grid의 모든 행 데이터를 순회하여 객체 배열로 추출합니다.
 * @param {Object} api AG-Grid 인스턴스
 * @returns {Array<Object>} 추출된 데이터 배열
 */
export function collectRows(api) {
  if (!isApiAlive(api)) return []

  const rows = []
  api.forEachNode((node) => {
    if (node.data) rows.push(node.data)
  })
  return rows
}

/**
 * AG-Grid의 'rowData' 옵션을 덮어씌워 데이터를 로드/갱신합니다.
 * @param {Object} api AG-Grid 인스턴스
 * @param {Array<Object>} rows 주입할 데이터 배열
 * @returns {boolean} 데이터 주입 성공 여부
 */
export function setGridRowData(api, rows = []) {
  if (!isApiAlive(api)) return false
  api.setGridOption("rowData", rows)
  return true
}

/**
 * GridCrudManager와 엮인 그리드의 데이터를 덮어씌우고, 매니저 내부의 변경 기록(Tracking)을 초기화합니다.
 * @param {Object} manager GridCrudManager 인스턴스
 * @param {Array<Object>} rows 주입할 데이터 배열
 * @returns {boolean} 데이터 주입 및 초기화 성공 여부
 */
export function setManagerRowData(manager, rows = []) {
  if (!manager || !isApiAlive(manager.api)) return false

  manager.api.setGridOption("rowData", rows)
  if (typeof manager.resetTracking === "function") {
    manager.resetTracking()
  }
  return true
}

/**
 * 특정 행 노드(들)의 상태(__row_status) 컬럼만 타겟팅하여 그리드 UI 상에서 강제 리프레시(다시 그리기)합니다.
 * @param {Object} api AG-Grid 인스턴스
 * @param {Array<RowNode>} rowNodes 다시 그릴 대상 AG-Grid 행 노드 배열
 */
export function refreshStatusCells(api, rowNodes) {
  api.refreshCells({
    rowNodes,
    columns: ["__row_status"],
    force: true
  })
}

/**
 * 데이터가 로드된 AG-Grid의 최상단(가장 첫 번째) 행 노드로 키보드 포커스와 화면 스크롤을 이동시킵니다.
 * 부가 옵션으로 대상 행의 선택(체크박스) 상태까지 동기화할 수 있습니다.
 * @param {Object} api AG-Grid 인스턴스
 * @param {Object} options 선택/포커싱 보장 옵션
 * @param {boolean} options.ensureVisible 대상 행이 가려져 있다면 화면 스크롤을 이동시켜 우선 노출시킵니다
 * @param {boolean} options.select 포커스 된 행의 자체 요소 선택 상태까지 `true`로 체크합니다
 * @returns {Object|null} 포커스 된 행 노드의 실제 데이터 객체
 */
export function focusFirstRow(api, { ensureVisible = false, select = false } = {}) {
  if (!isApiAlive(api)) return null

  const node = api.getDisplayedRowAtIndex(0)
  if (!node?.data) return null

  if (ensureVisible) api.ensureIndexVisible(0)

  const col = api.getAllDisplayedColumns()?.[0]
  if (col) api.setFocusedCell(0, col.getColId())

  if (select) node.setSelected(true, true)
  return node.data
}
