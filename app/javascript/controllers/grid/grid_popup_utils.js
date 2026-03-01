/**
 * grid_popup_utils.js
 *
 * data-controller="search-popup" 팝업 필드의 코드/표시명 동기화,
 * 비활성화 상태 토글 등의 공통 DOM 조작 유틸리티 함수 모음.
 *
 * search-popup 컨트롤러 타겟 구조:
 *   - code        : 실제 코드값이 저장되는 hidden/text 입력창 (detailField 타겟과 겹침)
 *   - codeDisplay : 사용자에게 코드를 보여주는 읽기 전용 입력창
 *   - display     : 사용자에게 코드명(표시명)을 보여주는 입력창
 */

/**
 * detailField 엘리먼트가 search-popup의 code 타겟인지 확인하고
 * 팝업 루트(data-controller~="search-popup") 엘리먼트를 반환.
 * popup 타입 필드가 아니면 null 반환.
 *
 * @param {Element|null} fieldEl - 검사할 입력 엘리먼트
 * @returns {Element|null}
 */
export function popupRootForField(fieldEl) {
  if (!fieldEl) return null
  if (fieldEl.dataset.searchPopupTarget !== "code") return null
  return fieldEl.closest("[data-controller~='search-popup']")
}

/**
 * 팝업 루트의 codeDisplay 및 display 입력값을 세팅.
 * display가 null이면 display 입력창은 변경하지 않음.
 *
 * @param {Element} popupRoot - search-popup 루트 엘리먼트
 * @param {string} code       - 세팅할 코드값
 * @param {string|null} display - 세팅할 표시명 (null이면 변경 안 함)
 */
export function setPopupValues(popupRoot, code, display = null) {
  if (!popupRoot) return

  const normalizedCode = String(code ?? "").trim()

  const codeDisplayInput = popupRoot.querySelector("[data-search-popup-target='codeDisplay']")
  if (codeDisplayInput) {
    codeDisplayInput.value = normalizedCode
  }

  if (display !== null) {
    const displayInput = popupRoot.querySelector("[data-search-popup-target='display']")
    if (displayInput) {
      displayInput.value = String(display ?? "").trim()
    }
  }
}

/**
 * 팝업 루트 내 인터랙티브 요소(display 입력창, 열기 버튼)의 비활성화 상태를 토글.
 * codeDisplay 입력창은 항상 비활성화 유지(시각적 미러 용도).
 *
 * @param {Element} popupRoot - search-popup 루트 엘리먼트
 * @param {boolean} disabled  - true면 비활성화, false면 활성화
 */
export function setPopupDisabled(popupRoot, disabled) {
  if (!popupRoot) return

  const displayInput = popupRoot.querySelector("[data-search-popup-target='display']")
  if (displayInput) {
    displayInput.disabled = disabled
  }

  const codeDisplayInput = popupRoot.querySelector("[data-search-popup-target='codeDisplay']")
  if (codeDisplayInput) {
    codeDisplayInput.disabled = true
  }

  const openButton = popupRoot.querySelector("button[data-action='search-popup#open']")
  if (openButton) {
    openButton.disabled = disabled
  }
}

/**
 * rootEl 내 모든 search-popup 팝업에 대해 code 입력값을 codeDisplay에 동기화하고,
 * display가 비어있으면 code 값으로 채움.
 * 폼 초기화/데이터 세팅 직후 팝업 표시 상태를 일괄 복원할 때 사용.
 *
 * @param {Element} rootEl - 탐색 기준 루트 엘리먼트 (보통 this.element)
 */
export function syncAllPopupDisplaysFromCodes(rootEl) {
  if (!rootEl) return

  const wrappers = rootEl.querySelectorAll("[data-controller~='search-popup']")
  wrappers.forEach((wrapper) => {
    const codeInput = wrapper.querySelector("[data-search-popup-target='code']")
    const codeDisplay = wrapper.querySelector("[data-search-popup-target='codeDisplay']")
    const displayInput = wrapper.querySelector("[data-search-popup-target='display']")
    if (!codeInput) return

    const codeValue = String(codeInput.value || "").trim()
    if (codeDisplay) {
      codeDisplay.value = codeValue
    }
    if (displayInput && String(displayInput.value || "").trim() === "") {
      displayInput.value = codeValue
    }
  })
}
