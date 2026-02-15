import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connectBase({ events = [] } = {}) {
    this.dragState = null
    this._eventSubscriptions = events.map(({ name, handler }) => {
      this.element.addEventListener(name, handler)
      return { name, handler }
    })

    this._boundDelegatedClick = this.handleDelegatedClick.bind(this)
    this._boundDragMove = this.handleDragMove.bind(this)
    this._boundEndDrag = this.endDrag.bind(this)

    this.element.addEventListener("click", this._boundDelegatedClick)
    window.addEventListener("mousemove", this._boundDragMove)
    window.addEventListener("mouseup", this._boundEndDrag)
  }

  disconnectBase() {
    ;(this._eventSubscriptions || []).forEach(({ name, handler }) => {
      this.element.removeEventListener(name, handler)
    })
    this._eventSubscriptions = []

    if (this._boundDelegatedClick) {
      this.element.removeEventListener("click", this._boundDelegatedClick)
    }
    if (this._boundDragMove) {
      window.removeEventListener("mousemove", this._boundDragMove)
    }
    if (this._boundEndDrag) {
      window.removeEventListener("mouseup", this._boundEndDrag)
    }
  }

  get csrfToken() {
    return document.querySelector("[name='csrf-token']")?.content || ""
  }

  get cancelRoleSelector() {
    return `[data-${this.identifier}-role='cancel']`
  }

  openModal() {
    this.overlayTarget.hidden = false
  }

  closeModal() {
    this.overlayTarget.hidden = true
    this.endDrag()
  }

  stopPropagation(event) {
    event.stopPropagation()
  }

  handleDelegatedClick(event) {
    const cancelButton = event.target.closest(this.cancelRoleSelector)
    if (cancelButton) {
      event.preventDefault()
      this.closeModal()
    }
  }

  startDrag(event) {
    if (event.button !== 0) return
    if (!this.hasModalTarget || !this.hasOverlayTarget) return
    if (event.target.closest("button")) return

    const modalRect = this.modalTarget.getBoundingClientRect()
    this.modalTarget.style.position = "absolute"
    this.modalTarget.style.left = `${modalRect.left}px`
    this.modalTarget.style.top = `${modalRect.top}px`
    this.modalTarget.style.margin = "0"

    this.dragState = {
      offsetX: event.clientX - modalRect.left,
      offsetY: event.clientY - modalRect.top
    }

    document.body.style.userSelect = "none"
    this.modalTarget.style.cursor = "grabbing"
    event.preventDefault()
  }

  handleDragMove(event) {
    if (!this.dragState || !this.hasModalTarget) return

    const maxLeft = Math.max(0, window.innerWidth - this.modalTarget.offsetWidth)
    const maxTop = Math.max(0, window.innerHeight - this.modalTarget.offsetHeight)
    const nextLeft = event.clientX - this.dragState.offsetX
    const nextTop = event.clientY - this.dragState.offsetY
    const clampedLeft = Math.min(Math.max(0, nextLeft), maxLeft)
    const clampedTop = Math.min(Math.max(0, nextTop), maxTop)

    this.modalTarget.style.left = `${clampedLeft}px`
    this.modalTarget.style.top = `${clampedTop}px`
  }

  endDrag() {
    this.dragState = null
    document.body.style.userSelect = ""
    if (this.hasModalTarget) {
      this.modalTarget.style.cursor = ""
    }
  }

  refreshGrid() {
    const agGridEl = this.element.querySelector("[data-controller='ag-grid']")
    const agGridController = this.application.getControllerForElementAndIdentifier(agGridEl, "ag-grid")
    agGridController?.refresh()
  }

  exportCsv() {
    const agGridEl = this.element.querySelector("[data-controller='ag-grid']")
    const agGridController = this.application.getControllerForElementAndIdentifier(agGridEl, "ag-grid")
    agGridController?.exportCsv()
  }

  buildJsonPayload() {
    const formData = new FormData(this.formTarget)
    const payload = {}
    for (const [rawKey, value] of formData.entries()) {
      const match = rawKey.match(/^[^\[]+\[([^\]]+)\]$/)
      const key = match ? match[1] : rawKey
      payload[key] = value
    }

    Object.keys(payload).forEach((key) => {
      if (payload[key] === "") payload[key] = null
    })

    return payload
  }

  async requestJson(url, { method, body, isMultipart = false }) {
    const headers = { "X-CSRF-Token": this.csrfToken }
    if (!isMultipart) headers["Content-Type"] = "application/json"

    const response = await fetch(url, {
      method,
      headers,
      body: isMultipart ? body : JSON.stringify(body)
    })

    const result = await response.json()
    return { response, result }
  }
}
