function findResourceFormElement() {
  return document.querySelector('[data-controller~="resource-form"]')
}

function findResourceFormElementByField(fieldEl) {
  if (!fieldEl || typeof fieldEl.closest !== "function") return null
  return fieldEl.closest('[data-controller~="resource-form"]')
}

function resolveFieldName(fieldName, resourceName) {
  return resourceName ? `${resourceName}[${fieldName}]` : fieldName
}

function resolveResourceFormController(application, formEl) {
  if (!application || !formEl) return null

  const formCtrl = application.getControllerForElementAndIdentifier(formEl, "resource-form")
  if (!formCtrl) return null

  return formCtrl
}

export function getResourceFormValue(application, fieldName, { resourceName = null, toUpperCase = false } = {}) {
  const formEl = findResourceFormElement()
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

export function setResourceFormValue(application, fieldName, value, { resourceName = null } = {}) {
  const formEl = findResourceFormElement()
  const formCtrl = resolveResourceFormController(application, formEl)
  if (!formCtrl || typeof formCtrl.setResourceFieldValue !== "function") return

  const name = resolveFieldName(fieldName, resourceName)
  formCtrl.setResourceFieldValue(name, value)
}

export function getResourceFieldElement(fieldName, { resourceName = null } = {}) {
  const formEl = findResourceFormElement()
  if (!formEl) return null

  const name = resolveFieldName(fieldName, resourceName)
  const elements = formEl.querySelectorAll(`[name="${name}"]`)
  return elements.length > 0 ? elements[elements.length - 1] : null
}

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

export function setResourceFormValueFromElement(application, fieldEl, value) {
  if (!fieldEl) return false

  const fieldName = fieldEl.getAttribute("name")
  if (!fieldName) return false

  const formEl = findResourceFormElementByField(fieldEl)
  const formCtrl = resolveResourceFormController(application, formEl)
  if (!formCtrl || typeof formCtrl.setResourceFieldValue !== "function") return false

  formCtrl.setResourceFieldValue(fieldName, value)
  return true
}
