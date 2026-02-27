export function getCsrfToken() {
  return document.querySelector("[name='csrf-token']")?.content || ""
}

export async function requestJson(url, {
  method = "GET",
  body,
  signal,
  headers = {},
  isMultipart = false
} = {}) {
  const mergedHeaders = {
    Accept: "application/json",
    "X-CSRF-Token": getCsrfToken(),
    ...headers
  }

  if (!isMultipart) {
    mergedHeaders["Content-Type"] = mergedHeaders["Content-Type"] || "application/json"
  }

  const response = await fetch(url, {
    method,
    headers: mergedHeaders,
    body: body == null ? undefined : (isMultipart ? body : JSON.stringify(body)),
    signal
  })

  const result = await response.json()
  return { response, result }
}

export async function fetchJson(url, { signal } = {}) {
  const response = await fetch(url, {
    headers: { Accept: "application/json" },
    signal
  })

  if (!response.ok) {
    throw new Error(`HTTP ${response.status}`)
  }

  return response.json()
}

