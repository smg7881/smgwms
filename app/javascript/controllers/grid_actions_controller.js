import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    gridId: String
  }

  saveColumnState() {
    const agGridController = this.#findAgGridController()
    if (!agGridController) return

    agGridController.saveColumnState(this.gridIdValue)
  }

  resetColumnState() {
    const agGridController = this.#findAgGridController()
    if (!agGridController) return

    agGridController.resetColumnState(this.gridIdValue)
  }

  exportCsv() {
    const agGridController = this.#findAgGridController()
    if (!agGridController) return

    agGridController.exportCsv()
  }

  #findAgGridController() {
    const gridId = this.gridIdValue
    const selector = `[data-ag-grid-grid-id-value="${gridId}"]`
    const agGridEl = document.querySelector(selector)
    if (!agGridEl) return null

    return this.application.getControllerForElementAndIdentifier(agGridEl, "ag-grid")
  }
}
