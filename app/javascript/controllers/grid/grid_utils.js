/**
 * Grid 컨트롤러 공통 유틸리티 함수
 *
 * 8개 Grid 컨트롤러에서 동일하게 사용되는 순수 유틸리티 함수를 제공한다.
 * 상태를 갖지 않으며, 모든 함수는 named export로 제공된다.
 */

export function isApiAlive(api) {
  return Boolean(api) && !(typeof api.isDestroyed === "function" && api.isDestroyed())
}

export function uuid() {
  return `${Date.now()}_${Math.random().toString(36).slice(2, 8)}`
}

export function getCsrfToken() {
  return document.querySelector("[name='csrf-token']")?.content || ""
}

export async function postJson(url, body) {
  try {
    const response = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": getCsrfToken()
      },
      body: JSON.stringify(body)
    })

    const result = await response.json()
    if (!response.ok || !result.success) {
      alert("저장 실패: " + (result.errors || ["요청 처리 실패"]).join(", "))
      return false
    }

    return true
  } catch {
    alert("저장 실패: 네트워크 오류")
    return false
  }
}

export function hideNoRowsOverlay(api) {
  if (!isApiAlive(api)) return

  const rowCount = api.getDisplayedRowCount?.() || 0
  if (rowCount > 0) {
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
