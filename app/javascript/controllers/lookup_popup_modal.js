/**
 * lookup_popup_modal.js
 *
 * 기존 openLookupPopup() 시그니처를 유지하면서
 * 내부 구현을 PopupManager.open()으로 위임합니다.
 *
 * 호출부(search_popup_controller.js 등)는 변경 없이 그대로 사용합니다.
 */

import { PopupManager, defaultTitle } from "controllers/popup/popup_manager"

/**
 * 검색 팝업을 열고 사용자가 선택한 항목을 Promise로 반환합니다.
 *
 * @param {object} options
 * @param {string} [options.type]    - 팝업 유형 (예: "customer", "workplace")
 * @param {string} [options.url]     - 커스텀 팝업 URL (생략 시 /search_popups/:type)
 * @param {string} [options.keyword] - 초기 검색어
 * @param {string} [options.title]   - 팝업 제목
 *
 * @returns {Promise<{code: string, name: string, display: string, ...}|null>}
 */
export function openLookupPopup({ type, url, keyword, title } = {}) {
  const popupType = String(type ?? "").trim()
  if (!popupType && !url) return Promise.resolve(null)

  const baseUrl = String(url ?? "").trim() || `/search_popups/${encodeURIComponent(popupType)}`
  const heading = String(title ?? "").trim() || defaultTitle(popupType || url)

  return PopupManager.open({
    url: baseUrl,
    keyword,
    title: heading
  })
}
