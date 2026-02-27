import { fetchJson } from "controllers/grid/core/http_client"
import { isApiAlive } from "controllers/grid/core/api_guard"

const ERROR_OVERLAY_TEMPLATE = [
  '<div style="padding:20px;text-align:center;">',
  '<div style="color:#f85149;font-weight:600;margin-bottom:4px;">데이터 로딩 실패</div>',
  '<div style="color:#8b949e;font-size:12px;">네트워크 상태를 확인해주세요</div>',
  "</div>"
].join("")

function applyLoadedRows(api, rows, defaultNoRowsTemplate) {
  api.setGridOption("loading", false)
  api.setGridOption("overlayNoRowsTemplate", defaultNoRowsTemplate)
  api.setGridOption("rowData", rows)

  if (rows.length === 0) api.showNoRowsOverlay()
  else api.hideOverlay()
}

function applyLoadErrorOverlay(api) {
  api.setGridOption("loading", false)
  api.setGridOption("overlayNoRowsTemplate", ERROR_OVERLAY_TEMPLATE)
  api.showNoRowsOverlay()
}

export async function loadClientGridData({
  api,
  url,
  defaultNoRowsTemplate,
  isCurrentApi = () => true,
  beforeApply = null
} = {}) {
  if (!isApiAlive(api) || !url) return

  api.setGridOption("loading", true)

  try {
    const rows = await fetchJson(url)
    if (!isApiAlive(api) || !isCurrentApi()) return

    if (typeof beforeApply === "function") {
      beforeApply(rows)
    }
    applyLoadedRows(api, rows, defaultNoRowsTemplate)
  } catch (error) {
    console.error("[ag-grid] data load failed:", error)
    if (!isApiAlive(api) || !isCurrentApi()) return
    applyLoadErrorOverlay(api)
  }
}

export async function loadServerGridPage({
  api,
  url,
  page,
  perPage,
  defaultNoRowsTemplate,
  isCurrentApi = () => true,
  beforeApply = null,
  onTotal = null
} = {}) {
  if (!isApiAlive(api) || !url) return

  api.setGridOption("loading", true)

  const parsedUrl = new URL(url, window.location.origin)
  parsedUrl.searchParams.set("page", page)
  parsedUrl.searchParams.set("per_page", perPage)

  try {
    const data = await fetchJson(parsedUrl.toString())
    if (!isApiAlive(api) || !isCurrentApi()) return

    const rows = data.rows || []
    if (typeof beforeApply === "function") {
      beforeApply(rows)
    }
    if (typeof onTotal === "function") {
      onTotal(data.total || 0)
    }

    applyLoadedRows(api, rows, defaultNoRowsTemplate)
    api.setGridOption("paginationPageSize", perPage)
  } catch (error) {
    console.error("[ag-grid] server page load failed:", error)
    if (!isApiAlive(api) || !isCurrentApi()) return
    applyLoadErrorOverlay(api)
  }
}

