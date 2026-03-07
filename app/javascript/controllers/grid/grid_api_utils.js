/**
 * grid_api_utils.js
 *
 * AG Grid API 직접 조작 유틸리티 함수 모음.
 * 행 데이터 세팅, 셀 리프레시, 포커스 등 Grid API 호출 관련 순수 함수들.
 */
import { isApiAlive } from "controllers/grid/core/api_guard"

export function hideNoRowsOverlay(api) {
  if (!isApiAlive(api)) return

  const rowCount = api.getDisplayedRowCount?.() || 0
  if (rowCount > 0) {
    if (typeof api.setGridOption === "function") {
      api.setGridOption("loading", false)
    }
    api.hideOverlay?.()
  }
}

export function collectRows(api) {
  if (!isApiAlive(api)) return []

  const rows = []
  api.forEachNode((node) => {
    if (node.data) rows.push(node.data)
  })
  return rows
}

export function setGridRowData(api, rows = []) {
  if (!isApiAlive(api)) return false
  api.setGridOption("rowData", rows)
  return true
}

export function setManagerRowData(manager, rows = []) {
  if (!manager || !isApiAlive(manager.api)) return false

  manager.api.setGridOption("rowData", rows)
  if (typeof manager.resetTracking === "function") {
    manager.resetTracking()
  }
  return true
}

export function refreshStatusCells(api, rowNodes) {
  api.refreshCells({
    rowNodes,
    columns: ["__row_status"],
    force: true
  })
}

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
