function findSearchFormElement() {
  return document.querySelector('[data-controller~="search-form"]')
}

function findSearchFormElementByField(fieldEl) {
  if (!fieldEl || typeof fieldEl.closest !== "function") return null
  return fieldEl.closest('[data-controller~="search-form"]')
}

function resolveSearchFieldName(fieldName) {
  if (!fieldName) return ""
  const normalized = String(fieldName)
  return normalized.startsWith("q[") ? normalized : `q[${normalized}]`
}

function resolveSearchFormController(application, formEl) {
  if (!application || !formEl) return null

  const formCtrl = application.getControllerForElementAndIdentifier(formEl, "search-form")
  if (!formCtrl) return null

  return formCtrl
}

export function getSearchFormValue(application, fieldName, { toUpperCase = true, fieldElement = null } = {}) {
  if (!application) return ""

  const formEl = fieldElement ? findSearchFormElementByField(fieldElement) : findSearchFormElement()
  const formCtrl = resolveSearchFormController(application, formEl)
  if (!formCtrl || typeof formCtrl.getSearchFieldValue !== "function") return ""

  const value = String(formCtrl.getSearchFieldValue(resolveSearchFieldName(fieldName)) || "").trim()
  return toUpperCase ? value.toUpperCase() : value
}

export function setSearchFormValue(application, fieldName, value, { fieldElement = null } = {}) {
  if (!application || !fieldName) return false

  const formEl = fieldElement ? findSearchFormElementByField(fieldElement) : findSearchFormElement()
  const formCtrl = resolveSearchFormController(application, formEl)
  if (!formCtrl || typeof formCtrl.setSearchFieldValue !== "function") return false

  formCtrl.setSearchFieldValue(resolveSearchFieldName(fieldName), value)
  return true
}

export function getSearchFieldElement(fieldName, { fieldElement = null } = {}) {
  const formEl = fieldElement ? findSearchFormElementByField(fieldElement) : findSearchFormElement()
  if (!formEl) return null

  const elements = formEl.querySelectorAll(`[name="${resolveSearchFieldName(fieldName)}"]`)
  return elements.length > 0 ? elements[elements.length - 1] : null
}
