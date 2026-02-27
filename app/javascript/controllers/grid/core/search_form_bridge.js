function findSearchFormElement() {
  return document.querySelector('[data-controller~="search-form"]')
}

export function getSearchFormValue(application, fieldName, { toUpperCase = true } = {}) {
  if (!application) return ""

  const formEl = findSearchFormElement()
  if (!formEl) return ""

  const formCtrl = application.getControllerForElementAndIdentifier(formEl, "search-form")
  if (!formCtrl || typeof formCtrl.getSearchFieldValue !== "function") return ""

  const value = String(formCtrl.getSearchFieldValue(`q[${fieldName}]`) || "").trim()
  return toUpperCase ? value.toUpperCase() : value
}

export function getSearchFieldElement(fieldName) {
  const formEl = findSearchFormElement()
  if (!formEl) return null

  const elements = formEl.querySelectorAll(`[name="q[${fieldName}]"]`)
  return elements.length > 0 ? elements[elements.length - 1] : null
}

