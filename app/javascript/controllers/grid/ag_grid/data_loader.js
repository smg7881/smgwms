/**
 * AG Grid에 데이터를 로드하고 상태(로딩 중, 에러, 빈 데이터 등)를 관리하는 모듈입니다.
 */

import { fetchJson } from "controllers/grid/core/http_client"
import { isApiAlive } from "controllers/grid/core/api_guard"

// 데이터 로드 실패 시 그리드 중앙에 표시할 에러 오버레이 HTML 템플릿
const ERROR_OVERLAY_TEMPLATE = [
  '<div style="padding:20px;text-align:center;">',
  '<div style="color:#f85149;font-weight:600;margin-bottom:4px;">데이터 로딩 실패</div>',
  '<div style="color:#8b949e;font-size:12px;">네트워크 상태를 확인해주세요</div>',
  "</div>"
].join("")

/**
 * 성공적으로 불러온 데이터를 그리드에 적용하고 오버레이 상태를 업데이트합니다.
 *
 * @param {Object} api - AG Grid API 인스턴스
 * @param {Array} rows - 적용할 행 데이터 배열
 * @param {string} defaultNoRowsTemplate - 데이터가 없을 때 표시할 기본 템플릿
 */
function applyLoadedRows(api, rows, defaultNoRowsTemplate) {
  api.setGridOption("loading", false) // 로딩 스피너 숨김
  api.setGridOption("overlayNoRowsTemplate", defaultNoRowsTemplate) // 에러 후 성공 시 오버레이 복구
  api.setGridOption("rowData", rows) // 실제 데이터 매핑

  // 데이터가 없으면 '데이터 없음' 오버레이 표시, 있으면 오버레이 숨김
  if (rows.length === 0) api.showNoRowsOverlay()
  else api.hideOverlay()
}

/**
 * 데이터 로딩 중 에러가 발생했을 때 에러 오버레이를 표시합니다.
 *
 * @param {Object} api - AG Grid API 인스턴스
 */
function applyLoadErrorOverlay(api) {
  api.setGridOption("loading", false) // 로딩 스피너 숨김
  api.setGridOption("overlayNoRowsTemplate", ERROR_OVERLAY_TEMPLATE) // 에러 템플릿으로 교체
  api.showNoRowsOverlay() // 오버레이 표시
}

/**
 * 여러 형태의 API 응답 페이로드를 읽어 일관된 배열(Array) 형태로 정규화합니다.
 *
 * @param {any} payload - API 응답 데이터 (배열 또는 객체)
 * @returns {Array} 정규화된 행 데이터 배열
 */
function normalizeClientRows(payload) {
  if (Array.isArray(payload)) return payload
  if (payload && Array.isArray(payload.data)) return payload.data
  if (payload && Array.isArray(payload.rows)) return payload.rows
  return []
}

/**
 * 클라이언트 사이드 그리드(데이터 전체 리드)용 데이터를 서버에서 불러와 적용합니다.
 *
 * @param {Object} params
 * @param {Object} params.api - AG Grid API 인스턴스
 * @param {string} params.url - 데이터를 불러올 API URL
 * @param {string} params.defaultNoRowsTemplate - 기존 기본 빈 행 오버레이 템플릿
 * @param {Function} [params.isCurrentApi] - 요청 중 조건 변경 방지를 위한 검증 함수
 * @param {Function} [params.beforeApply] - 데이터를 그리드에 주입하기 직전 실행될 Hook
 */
export async function loadClientGridData({
  api,
  url,
  defaultNoRowsTemplate,
  isCurrentApi = () => true,
  beforeApply = null
} = {}) {
  // 방어 코드: 그리드가 파괴되었거나 URL이 없으면 중단
  if (!isApiAlive(api) || !url) return

  // 로딩 상태 시작
  api.setGridOption("loading", true)

  try {
    const payload = await fetchJson(url)
    const rows = normalizeClientRows(payload)

    // 비동기 통신 완료 후 렌더링 직전에 그리드 상태 재검증
    if (!isApiAlive(api) || !isCurrentApi()) return

    // 데이터 주입 전 전처리 로직이 있다면 실행
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

/**
 * 서버 사이드 페이지네이션 그리드용 특정 페이지 데이터를 불러와 적용합니다.
 *
 * @param {Object} params
 * @param {Object} params.api - AG Grid API 인스턴스
 * @param {string} params.url - 데이터를 불러올 API 기본 URL
 * @param {number} params.page - 요청할 페이지 번호
 * @param {number} params.perPage - 페이지 당 행 수
 * @param {string} params.defaultNoRowsTemplate - 기존 기본 빈 행 오버레이 템플릿
 * @param {Function} [params.isCurrentApi] - 요청 중 조건 변경 방지를 위한 검증 함수
 * @param {Function} [params.beforeApply] - 데이터를 그리드에 주입하기 직전 실행될 Hook
 * @param {Function} [params.onTotal] - 전체 데이터 갯수 콜백 함수
 */
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
  // 방어 코드
  if (!isApiAlive(api) || !url) return

  api.setGridOption("loading", true)

  // URL 객체를 사용해 페이지네이션 파라 파라미터 조합
  const parsedUrl = new URL(url, window.location.origin)
  parsedUrl.searchParams.set("page", page)
  parsedUrl.searchParams.set("per_page", perPage)

  try {
    const data = await fetchJson(parsedUrl.toString())
    if (!isApiAlive(api) || !isCurrentApi()) return

    const rows = data.rows || []

    // 데이터 주입 전 Hook 실행
    if (typeof beforeApply === "function") {
      beforeApply(rows)
    }

    // 페이지네이션 컴포넌트 등에 필요한 총 데이터 카운트 전달
    if (typeof onTotal === "function") {
      onTotal(data.total || 0)
    }

    applyLoadedRows(api, rows, defaultNoRowsTemplate)
    api.setGridOption("paginationPageSize", perPage) // 그리드 페이지 사이즈 연동
  } catch (error) {
    console.error("[ag-grid] server page load failed:", error)
    if (!isApiAlive(api) || !isCurrentApi()) return
    applyLoadErrorOverlay(api)
  }
}
