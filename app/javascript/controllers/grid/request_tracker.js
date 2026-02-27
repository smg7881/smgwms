/**
 * Abortable request helper for stale-response protection.
 */
export class AbortableRequestTracker {
  constructor() {
    this.requestId = 0
    this.abortController = null
  }

  begin() {
    this.cancelCurrent()
    this.requestId += 1
    this.abortController = new AbortController()

    return {
      requestId: this.requestId,
      signal: this.abortController.signal
    }
  }

  isLatest(requestId) {
    return requestId === this.requestId
  }

  finish(requestId) {
    if (!this.isLatest(requestId)) return
    this.abortController = null
  }

  cancelCurrent() {
    if (!this.abortController) return
    this.abortController.abort()
    this.abortController = null
  }

  cancelAll() {
    this.requestId += 1
    this.cancelCurrent()
  }
}

export function isAbortError(error) {
  return error?.name === "AbortError"
}