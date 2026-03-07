/**
 * 화면 상에 존재하는 첫 번째 `search-form` 컨트롤러 래퍼 엘리먼트를 찾습니다.
 * (목록 화면 상단의 검색 조건 폼 영역)
 */
function findSearchFormElement() {
  return document.querySelector('[data-controller~="search-form"]')
}

/**
 * 전역(가장 처음 발견된) SearchForm 컨트롤러를 경유하여 특정 검색 필드의 값을 추출해 옵니다.
 *
 * @param {Object} application Stimulus 애플리케이션 인스턴스
 * @param {string} fieldName 추출할 검색 조건 필드 명칭 (ex: 'user_nm' -> 내부적으로 'q[user_nm]' 조회)
 * @param {Object} [options]
 * @param {boolean} [options.toUpperCase=true] 가져온 문자열을 대문자로 강제 변환할지 여부 (검색 조건은 주로 대문자 비교)
 * @returns {string} 파싱된 검색 조건 값
 */
export function getSearchFormValue(application, fieldName, { toUpperCase = true } = {}) {
  if (!application) return ""

  const formEl = findSearchFormElement()
  if (!formEl) return ""

  const formCtrl = application.getControllerForElementAndIdentifier(formEl, "search-form")
  if (!formCtrl || typeof formCtrl.getSearchFieldValue !== "function") return ""

  const value = String(formCtrl.getSearchFieldValue(`q[${fieldName}]`) || "").trim()
  return toUpperCase ? value.toUpperCase() : value
}

/**
 * 전역 SearchForm 요소 하위에서 `q[fieldName]` 이름 형태와 매칭되는 실제 DOM 입력 요소를 얻어옵니다.
 *
 * @param {string} fieldName 찾고자 하는 검색 조건 필드의 명칭
 * @returns {HTMLElement|null} 매칭된 입력 필드 DOM 요소
 */
export function getSearchFieldElement(fieldName) {
  const formEl = findSearchFormElement()
  if (!formEl) return null

  const elements = formEl.querySelectorAll(`[name="q[${fieldName}]"]`)
  return elements.length > 0 ? elements[elements.length - 1] : null
}

