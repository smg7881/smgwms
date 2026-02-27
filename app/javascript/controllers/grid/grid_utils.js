import { showAlert } from "components/ui/alert"
import { isApiAlive } from "controllers/grid/core/api_guard"
import { getCsrfToken, fetchJson as fetchJsonCore, requestJson } from "controllers/grid/core/http_client"
import { registerGridInstance } from "controllers/grid/core/grid_registration"

export { isApiAlive, getCsrfToken, registerGridInstance }

export function uuid() {
  return `${Date.now()}_${Math.random().toString(36).slice(2, 8)}`
}

export async function postJson(url, body) {
  try {
    const { response, result } = await requestJson(url, { method: "POST", body })
    if (!response.ok || !result.success) {
      showAlert("저장 실패: " + (result.errors || ["요청 처리 실패"]).join(", "))
      return false
    }

    return result
  } catch {
    showAlert("저장 실패: 네트워크 오류")
    return false
  }
}

export async function fetchJson(url, { signal } = {}) {
  return fetchJsonCore(url, { signal })
}

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

export function hasChanges(operations) {
  return (
    operations.rowsToInsert.length > 0 ||
    operations.rowsToUpdate.length > 0 ||
    operations.rowsToDelete.length > 0
  )
}

export function numberOrNull(value) {
  if (value == null || value === "") return null

  const numeric = Number(value)
  if (Number.isNaN(numeric)) return null
  return numeric
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

export function hasPendingChanges(manager) {
  if (!manager) return false
  return hasChanges(manager.buildOperations())
}

export function blockIfPendingChanges(manager, entityLabel = "마스터") {
  if (!hasPendingChanges(manager)) return false
  showAlert(`${entityLabel}에 저장되지 않은 변경이 있습니다.`)
  return true
}

export function buildTemplateUrl(template, paramsOrPlaceholder, value) {
  if (paramsOrPlaceholder !== null && typeof paramsOrPlaceholder === "object") {
    return Object.entries(paramsOrPlaceholder).reduce((url, [key, val]) => {
      return url.replace(`:${key}`, encodeURIComponent(val ?? ""))
    }, template)
  }

  return template.replace(paramsOrPlaceholder, encodeURIComponent(value ?? ""))
}

export function setSelectOptions(selectEl, options, selectedValue = "", blankLabel = "전체") {
  if (!selectEl) return ""

  const normalized = (selectedValue || "").toString()
  const values = options.map((o) => o.value.toString())
  const canSelect = normalized && values.includes(normalized)

  selectEl.innerHTML = ""

  if (blankLabel !== null) {
    const blank = document.createElement("option")
    blank.value = ""
    blank.textContent = blankLabel
    selectEl.appendChild(blank)
  }

  options.forEach((opt) => {
    const el = document.createElement("option")
    el.value = opt.value
    el.textContent = opt.label
    selectEl.appendChild(el)
  })

  selectEl.value = canSelect ? normalized : ""
  return selectEl.value
}

export function clearSelectOptions(selectEl, blankLabel = "전체") {
  setSelectOptions(selectEl, [], "", blankLabel)
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
