import { Controller } from "@hotwired/stimulus"
import { showAlert, confirmAction } from "components/ui/alert"
import { GridEventManager } from "controllers/grid/grid_event_manager"
import { registerGridInstance } from "controllers/grid/grid_utils"

export default class extends Controller {
  static targets = ["grid", "form", "keyword", "code"]

  connect() {
    this.gridEvents = new GridEventManager()
    this.gridApi = null

    this.messageListener = (event) => {
      if (event.data?.source === "search-popup-modal" && event.data?.type === "request-select") {
        if (this.gridApi) {
          const rows = this.gridApi.getSelectedRows()
          if (rows && rows.length > 0) {
            this.selectRow(rows[0])
          } else {
            showAlert("조회된 목록에서 항목을 먼저 선택하세요.")
          }
        }
      }
    }
    window.addEventListener("message", this.messageListener)
  }

  disconnect() {
    this.gridEvents.unbindAll()
    this.gridApi = null
    if (this.messageListener) {
      window.removeEventListener("message", this.messageListener)
    }
  }

  registerGrid(event) {
    registerGridInstance(event, this, [
      {
        target: this.hasGridTarget ? this.gridTarget : null,
        controllerKey: "gridController",
        managerKey: "gridApi",
        setup: () => {
          this.gridEvents.unbindAll()
          this.gridEvents.bind(this.gridApi, "rowDoubleClicked", this.handleRowDoubleClicked)
          this.gridEvents.bind(this.gridApi, "cellKeyDown", this.handleCellKeyDown)
        }
      }
    ], () => {
      // setup callbacks already handle binding
      this.gridEvents.unbindAll()
      this.gridEvents.bind(this.gridApi, "rowDoubleClicked", this.handleRowDoubleClicked)
      this.gridEvents.bind(this.gridApi, "cellKeyDown", this.handleCellKeyDown)
    })
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
      ...row,
      code,
      name,
      display: name,
      corp_cd: row.corp_cd,
      corp_nm: row.corp_nm,
      ctry_cd: row.ctry_cd,
      ctry_nm: row.ctry_nm ?? row.ctry,
      fnc_or_cd: row.fnc_or_cd,
      fnc_or_nm: row.fnc_or_nm,
      fnc_or_eng_nm: row.fnc_or_eng_nm,
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
