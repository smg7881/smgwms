/**
 * 화면 상에 존재하는 첫 번째 `resource-form` 컨트롤러 래퍼 엘리먼트를 찾습니다.
 */
function findResourceFormElement() {
  return document.querySelector('[data-controller~="resource-form"]')
}

/**
 * 인자로 주어진 특정 대상 입력 필드를 감싸고 있는 가장 가까운 `resource-form` 컨트롤러 래퍼를 찾습니다.
 * @param {HTMLElement} fieldEl 입력 폼 요소
 */
function findResourceFormElementByField(fieldEl) {
  if (!fieldEl || typeof fieldEl.closest !== "function") return null
  return fieldEl.closest('[data-controller~="resource-form"]')
}

/**
 * 리소스 네임스페이스가 존재하면 Rails의 객체 매핑 방식(`user[name]`) 문자열로 감싸서 반환하고,
 * 없으면 단일 필드명(`name`) 그대로 반환합니다.
 */
function resolveFieldName(fieldName, resourceName) {
  return resourceName ? `${resourceName}[${fieldName}]` : fieldName
}

/**
 * Stimulus application 인스턴스와 대상 폼 요소를 이용해 실제 마운트된 `resource_form_controller` 인스턴스를 가져옵니다.
 */
function resolveResourceFormController(application, formEl) {
  if (!application || !formEl) return null

  const formCtrl = application.getControllerForElementAndIdentifier(formEl, "resource-form")
  if (!formCtrl) return null

  return formCtrl
}

/**
 * 전역(가장 처음 발견된) ResourceForm 컨트롤러를 경유하여 특정 필드의 값을 안전하게 추출해 옵니다.
 *
 * @param {Object} application Stimulus 애플리케이션 인스턴스
 * @param {string} fieldName 추출할 대상 필드의 명칭 (ex: 'user_name')
 * @param {Object} [options]
 * @param {string|null} [options.resourceName] 네임스페이스명 (ex: 'user' -> 'user[user_name]')
 * @param {boolean} [options.toUpperCase=false] 가져온 문자열을 대문자로 리턴할지 여부
 * @returns {any} 추출된 해당 필드의 실제 값
 */
export function getResourceFormValue(
  application,
  fieldName,
  { resourceName = null, toUpperCase = false, fieldElement = null } = {}
) {
  const formEl = fieldElement ? findResourceFormElementByField(fieldElement) : findResourceFormElement()
  const formCtrl = resolveResourceFormController(application, formEl)
  if (!formCtrl || typeof formCtrl.getResourceFieldValue !== "function") return null

  const name = resolveFieldName(fieldName, resourceName)
  const value = formCtrl.getResourceFieldValue(name)
  if (typeof value === "string") {
    const trimmed = value.trim()
    return toUpperCase ? trimmed.toUpperCase() : trimmed
  }

  return value
}

/**
 * 전역(가장 처음 발견된) ResourceForm 컨트롤러를 경유하여 특정 필드에 새로운 값을 강제로 주입합니다.
 *
 * @param {Object} application Stimulus 애플리케이션 인스턴스
 * @param {string} fieldName 값을 덮어쓸 필드의 명칭
 * @param {any} value 주입할 실제 값
 * @param {Object} [options]
 * @param {string|null} [options.resourceName] 네임스페이스명 (ex: 'user' -> 'user[user_name]')
 */
export function setResourceFormValue(application, fieldName, value, { resourceName = null, fieldElement = null } = {}) {
  if (!fieldName) return false

  const formEl = fieldElement ? findResourceFormElementByField(fieldElement) : findResourceFormElement()
  const formCtrl = resolveResourceFormController(application, formEl)
  if (!formCtrl || typeof formCtrl.setResourceFieldValue !== "function") return false

  const name = resolveFieldName(fieldName, resourceName)
  formCtrl.setResourceFieldValue(name, value)
  return true
}

/**
 * 전역 ResourceForm 요소 하위에서 주어진 이름(혹은 네임스페이스 조합)과 매칭되는 실제 DOM 입력 요소를 찾아냅니다.
 * (동일한 Name이 여러개라면 가장 마지막 노드를 선택합니다 - ex: Checkbox 등)
 *
 * @param {string} fieldName 찾고자 하는 필드의 명칭
 * @param {Object} [options]
 * @param {string|null} [options.resourceName] 네임스페이스명
 * @returns {HTMLElement|null} 매칭된 입력 필드 DOM 요소
 */
export function getResourceFieldElement(fieldName, { resourceName = null, fieldElement = null } = {}) {
  const formEl = fieldElement ? findResourceFormElementByField(fieldElement) : findResourceFormElement()
  if (!formEl) return null

  const name = resolveFieldName(fieldName, resourceName)
  const elements = formEl.querySelectorAll(`[name="${name}"]`)
  return elements.length > 0 ? elements[elements.length - 1] : null
}

/**
 * 특정 입력 필드 DOM 요소 자체로부터, 역으로 해당 요소를 주관하고 있는 ResourceForm 컨트롤러를 찾아낸 뒤
 * 브릿지(Bridge)를 통해 올바른 값을 추출해 내는 안정화된 래퍼 함수입니다.
 *
 * @param {Object} application Stimulus 애플리케이션 인스턴스
 * @param {HTMLElement} fieldEl 값을 가져올 대상 폼 필드 요소
 * @param {Object} [options]
 * @param {boolean} [options.toUpperCase=false] 대문자 강제 변환 여부
 * @returns {any} 추출된 필드의 실제 값
 */
export function getResourceFormValueFromElement(application, fieldEl, { toUpperCase = false } = {}) {
  if (!fieldEl) return null

  const fieldName = fieldEl.getAttribute("name")
  if (!fieldName) return null

  const formEl = findResourceFormElementByField(fieldEl)
  const formCtrl = resolveResourceFormController(application, formEl)
  if (!formCtrl || typeof formCtrl.getResourceFieldValue !== "function") return null

  const value = formCtrl.getResourceFieldValue(fieldName)
  if (typeof value === "string") {
    const trimmed = value.trim()
    return toUpperCase ? trimmed.toUpperCase() : trimmed
  }

  return value
}

/**
 * 특정 입력 필드 DOM 요소 자체로부터 역으로 ResourceForm 컨트롤러를 찾아내고,
 * 해당 요소를 조작하여 새로운 값을 주입(Set)하도록 명령을 위임합니다.
 *
 * @param {Object} application Stimulus 애플리케이션 인스턴스
 * @param {HTMLElement} fieldEl 값을 주입할 대상 폼 필드 요소
 * @param {any} value 밀어 넣고자 하는 실제 값
 * @returns {boolean} 브릿지 처리 성공/위임 여부
 */
export function setResourceFormValueFromElement(application, fieldEl, value) {
  if (!fieldEl) return false

  const fieldName = fieldEl.getAttribute("name")
  if (!fieldName) return false

  return setResourceFormValue(application, fieldName, value, { fieldElement: fieldEl })
}
