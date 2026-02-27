function findResourceFormElement() {
  return document.querySelector('[data-controller~="resource-form"]')
}

// fieldName을 리소스명으로 래핑: resourceName 지정 시 "resource[field]", 아니면 fieldName 그대로 사용
function resolveFieldName(fieldName, resourceName) {
  return resourceName ? `${resourceName}[${fieldName}]` : fieldName
}

export function getResourceFormValue(application, fieldName, { resourceName = null, toUpperCase = false } = {}) {
  if (!application) return null

  const formEl = findResourceFormElement()
  if (!formEl) return null

  const formCtrl = application.getControllerForElementAndIdentifier(formEl, "resource-form")
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
  if (!application) return

  const formEl = findResourceFormElement()
  if (!formEl) return

  const formCtrl = application.getControllerForElementAndIdentifier(formEl, "resource-form")
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
