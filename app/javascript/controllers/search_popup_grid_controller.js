import { Controller } from "@hotwired/stimulus"
import { showAlert } from "components/ui/alert"
import { GridEventManager } from "controllers/grid/grid_event_manager"

export default class extends Controller {
  static targets = ["grid", "form", "keyword", "code"]

  connect() {
    this.gridEvents = new GridEventManager()
    this.gridApi = null
    this.gridController = null

    // popup_manager.js의 "선택" 버튼 클릭 시 현재 선택 행 제출 요청 수신
    this._boundRequestSelect = this._handleRequestSelect.bind(this)
    this.element.addEventListener("popup:request-select", this._boundRequestSelect)
  }

  disconnect() {
    this.gridEvents.unbindAll()
    this.gridApi = null
    this.gridController = null
    this.element.removeEventListener("popup:request-select", this._boundRequestSelect)
  }

  registerGrid(event) {
    if (!this.hasGridTarget) return

    const gridElement = event?.target?.closest?.("[data-controller='ag-grid']")
    const { api, controller } = event.detail || {}
    if (!gridElement || gridElement !== this.gridTarget || !api) return

    this.gridController = controller || null
    this.gridApi = api
    this.gridEvents.unbindAll()
    this.gridEvents.bind(this.gridApi, "rowDoubleClicked", this.handleRowDoubleClicked)
    this.gridEvents.bind(this.gridApi, "cellKeyDown", this.handleCellKeyDown)
  }

  submitForm() {
    if (!this.hasFormTarget) return
    this.formTarget.requestSubmit()
  }

  closeModal() {
    // CustomEvent를 버블링시켜 popup_manager.js의 dialog까지 전달
    this.element.dispatchEvent(new CustomEvent("popup:close", { bubbles: true }))
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

    // turbo-frame은 같은 document이므로 CustomEvent를 직접 버블링하여 dialog까지 전달
    this.element.dispatchEvent(new CustomEvent("popup:select", {
      bubbles: true,
      detail
    }))
  }

  // ── private ───────────────────────────────────────────────────────────

  _handleRequestSelect() {
    if (this.gridApi) {
      const rows = this.gridApi.getSelectedRows()
      if (rows && rows.length > 0) {
        this.selectRow(rows[0])
      } else {
        showAlert("조회된 목록에서 항목을 먼저 선택하세요.")
      }
    } else {
      showAlert("목록을 불러오는 중입니다. 잠시 후 다시 시도하세요.")
    }
  }
}
