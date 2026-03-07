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
 * 특정 입력 필드(DOM Element)가 `search-popup` 컨트롤러의 통제를 받는 
 * 코드(code) 입력창인지 판별하고, 소속된 팝업의 최상단(Root) 래퍼 엘리먼트를 찾아 반환합니다.
 *
 * @param {Element|null} fieldEl - 검사할 대상 폼 입력 요소
 * @returns {Element|null} 매칭되는 `[data-controller~="search-popup"]` 엘리먼트 (없으면 null)
 */
export function popupRootForField(fieldEl) {
  if (!fieldEl) return null
  const popupTargets = String(fieldEl.dataset.searchPopupTarget || "").split(/\s+/).filter(Boolean)
  if (!popupTargets.includes("code")) return null
  return fieldEl.closest("[data-controller~='search-popup']")
}

/**
 * 팝업 컨트롤러 래퍼 내부의 화면 표시용 입력창(codeDisplay, display)들의 값을 프로그래밍 방식으로 주입합니다.
 * 사용자가 직접 팝업을 열지 않고 코드로 데이터를 세팅할 때 시각적 동기화를 위해 사용합니다.
 *
 * @param {Element} popupRoot - search-popup 루트 래퍼 엘리먼트
 * @param {string} code       - 세팅할 실제 코드명 (DB 저장용)
 * @param {string|null} [display=null] - 세팅할 사람용 표시명 (null이면 덮어쓰지 않고 유지)
 */
export function setPopupValues(popupRoot, code, display = null) {
  if (!popupRoot) return

  const normalizedCode = String(code ?? "").trim()

  const codeDisplayInput = popupRoot.querySelector("[data-search-popup-target~='codeDisplay']")
  if (codeDisplayInput) {
    codeDisplayInput.value = normalizedCode
  }

  if (display !== null) {
    const displayInput = popupRoot.querySelector("[data-search-popup-target~='display']")
    if (displayInput) {
      displayInput.value = String(display ?? "").trim()
    }
  }
}

/**
 * 팝업 컴포넌트 전체의 활성화/비활성화(Read-Only) 상태를 일괄 제어합니다.
 * 단순히 입력창 뿐만 아니라 팝업을 여는 검색(돋보기) 버튼의 disabled 속성까지 함께 조작합니다.
 *
 * @param {Element} popupRoot - search-popup 루트 래퍼 엘리먼트
 * @param {boolean} disabled  - true 이면 잠금(사용 불가), false 이면 해제(사용 가능)
 */
export function setPopupDisabled(popupRoot, disabled) {
  if (!popupRoot) return

  const displayInput = popupRoot.querySelector("[data-search-popup-target~='display']")
  if (displayInput) {
    displayInput.disabled = disabled
  }

  const codeDisplayInput = popupRoot.querySelector("[data-search-popup-target~='codeDisplay']")
  if (codeDisplayInput) {
    codeDisplayInput.disabled = true
  }

  const openButton = popupRoot.querySelector("button[data-action~='search-popup#open']")
  if (openButton) {
    openButton.disabled = disabled
  }
}

/**
 * 특정 컨테이너(루트 요소) 하위에 존재하는 모든 search-popup 컴포넌트들을 일괄 탐색하여,
 * 안보이는 원본 코드(code) 값과 화면 표출용 텍스트창(display, codeDisplay) 간의 시각적 동기화를 강제 집행합니다.
 * (모달이 새로 열리거나 리스트에서 행을 선택해 폼 데이터가 변경된 직후 호출됨)
 *
 * @param {Element} rootEl - DOM을 탐색할 기준이 되는 상위 요소 (보통 form target 이나 document.body)
 */
export function syncAllPopupDisplaysFromCodes(rootEl) {
  if (!rootEl) return

  const wrappers = rootEl.querySelectorAll("[data-controller~='search-popup']")
  wrappers.forEach((wrapper) => {
    const codeInput = wrapper.querySelector("[data-search-popup-target~='code']")
    const codeDisplay = wrapper.querySelector("[data-search-popup-target~='codeDisplay']")
    const displayInput = wrapper.querySelector("[data-search-popup-target~='display']")
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
