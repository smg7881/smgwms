import { Controller } from "@hotwired/stimulus"
import { GridEventManager, resolveAgGridRegistration } from "controllers/grid/grid_event_manager"

export default class extends Controller {
  static targets = ["grid", "form", "keyword", "code"]

  connect() {
    this.gridEvents = new GridEventManager()
    this.gridApi = null
  }

  disconnect() {
    this.gridEvents.unbindAll()
    this.gridApi = null
  }

  registerGrid(event) {
    const registration = resolveAgGridRegistration(event)
    if (!registration) return
    if (!this.hasGridTarget) return
    if (registration.gridElement !== this.gridTarget) return

    this.gridApi = registration.api
    this.gridEvents.unbindAll()
    this.gridEvents.bind(this.gridApi, "rowClicked", this.handleRowClicked)
    this.gridEvents.bind(this.gridApi, "rowDoubleClicked", this.handleRowDoubleClicked)
    this.gridEvents.bind(this.gridApi, "cellKeyDown", this.handleCellKeyDown)
  }

  submitForm() {
    if (!this.hasFormTarget) return
    this.formTarget.requestSubmit()
  }

  closeModal() {
    if (this.isEmbeddedPopup()) {
      this.postToParent("search-popup-close")
      return
    }

    const modal = document.getElementById("search-popup-modal")
    if (!modal) return
    modal.dispatchEvent(new CustomEvent("search-popup:close", { bubbles: true }))
  }

  selectFromRenderer(event) {
    event.stopPropagation()
    this.selectRow(event.detail?.row)
  }

  handleRowClicked = (event) => {
    this.selectRow(event?.data)
  }

  handleRowDoubleClicked = (event) => {
    this.selectRow(event?.data)
  }

  handleCellKeyDown = (event) => {
    if (event?.event?.key !== "Enter") return

    event.event.preventDefault()
    this.selectRow(event?.data)
  }

  selectRow(row) {
    if (!row) return

    const code = String(row.code ?? row.corp_cd ?? "").trim()
    const name = String(row.name ?? row.corp_nm ?? row.display ?? "").trim()
    const detail = {
      code,
      name,
      display: name,
      corp_cd: row.corp_cd,
      corp_nm: row.corp_nm,
      upper_corp_cd: row.upper_corp_cd,
      upper_corp_nm: row.upper_corp_nm
    }

    if (this.isEmbeddedPopup()) {
      this.postToParent("search-popup-select", detail)
      return
    }

    const modal = document.getElementById("search-popup-modal")
    if (!modal) return

    modal.dispatchEvent(new CustomEvent("search-popup:select", {
      bubbles: true,
      detail
    }))
  }

  isEmbeddedPopup() {
    try {
      return window.parent && window.parent !== window
    } catch (_error) {
      return false
    }
  }

  postToParent(type, detail = null) {
    try {
      window.parent.postMessage({
        source: "search-popup-iframe",
        type,
        detail
      }, window.location.origin)
    } catch (_error) {
      // noop
    }
  }
}
