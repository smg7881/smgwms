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
    this.gridEvents.bind(this.gridApi, "rowDoubleClicked", this.handleRowDoubleClicked)
    this.gridEvents.bind(this.gridApi, "cellKeyDown", this.handleCellKeyDown)
  }

  submitForm() {
    if (!this.hasFormTarget) return
    this.formTarget.requestSubmit()
  }

  selectFromRenderer(event) {
    event.stopPropagation()
    this.selectRow(event.detail?.row)
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

    const modal = document.getElementById("search-popup-modal")
    if (!modal) return

    const code = String(row.code ?? "").trim()
    const name = String(row.name ?? row.display ?? "").trim()

    modal.dispatchEvent(new CustomEvent("search-popup:select", {
      bubbles: true,
      detail: {
        code,
        name,
        display: name
      }
    }))
  }
}
