import BaseGridController from "controllers/base_grid_controller"
import { fetchJson } from "controllers/grid/core/http_client"
import { showAlert } from "components/ui/alert"

export default class extends BaseGridController {
  static targets = [
    ...BaseGridController.targets,
    "masterGridContainer",
    "detailGridContainer",
    "detailHeaderLabel"
  ]

  connect() {
    super.connect()
    this.searchForm = this.element.querySelector("[data-search-form-target='form']")
    this.boundSearchSubmit = this.handleSearchSubmit.bind(this)
    this.searchForm?.addEventListener("submit", this.boundSearchSubmit)
  }

  disconnect() {
    this.searchForm?.removeEventListener("submit", this.boundSearchSubmit)
    this.searchForm = null
    this.boundSearchSubmit = null
    super.disconnect()
  }

  gridRoles() {
    return {
      master: {
        target: "masterGridContainer",
        masterKeyField: "id"
      },
      detail: {
        target: "detailGridContainer",
        parentGrid: "master",
        onMasterRowChange: (rowData) => this.updateDetailHeader(rowData),
        detailLoader: (rowData) => this.fetchDetailRows(rowData)
      }
    }
  }

  loadMasterData(event) {
    if (!event.detail) return
    this.setRows("master", event.detail || [])
  }

  onMasterRowClicked() { }

  beforeSearchReset() {
    this.updateDetailHeader(null)
  }

  async handleSearchSubmit(event) {
    event.preventDefault()

    const form = event.currentTarget
    if (!form?.checkValidity()) {
      form?.reportValidity()
      return
    }

    document.dispatchEvent(new CustomEvent("grid:before-search", { bubbles: false }))

    try {
      const rows = await fetchJson(this.buildSearchUrl(form))
      this.setRows("master", Array.isArray(rows) ? rows : [])
      this.updateDetailHeader(null)
    } catch (error) {
      console.error("order inquiry search failed", error)
      showAlert("오더 조회에 실패했습니다.")
    }
  }

  buildSearchUrl(form) {
    const url = new URL(form.action, window.location.origin)
    const params = new URLSearchParams(new FormData(form))
    url.search = params.toString()
    return url.toString()
  }

  async fetchDetailRows(rowData) {
    const rowId = rowData?.id
    if (!rowId) return []

    try {
      const body = await fetchJson(`/om/order_inquiries/${rowId}`)
      return Array.isArray(body) ? body : []
    } catch (error) {
      console.error("order inquiry detail fetch failed", error)
      return []
    }
  }

  updateDetailHeader(rowData) {
    if (!this.hasDetailHeaderLabelTarget) return

    if (rowData?.ord_no) {
      this.detailHeaderLabelTarget.textContent = `[${rowData.ord_no}] 상세 품목 리스트`
      this.detailHeaderLabelTarget.classList.remove("text-gray-500")
      this.detailHeaderLabelTarget.classList.add("text-blue-600")
    } else {
      this.detailHeaderLabelTarget.textContent = "오더를 선택해주세요."
      this.detailHeaderLabelTarget.classList.remove("text-blue-600")
      this.detailHeaderLabelTarget.classList.add("text-gray-500")
    }
  }
}
