import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["masterGrid", "detailGrid", "reasonInput"]

  static values = {
    completeUrl: String,
    detailsUrlTemplate: String
  }

  connect() {
    this.masterGridController = null
    this.detailGridController = null
  }

  registerMasterGrid(event) {
    if (!this.hasMasterGridTarget || event.target !== this.masterGridTarget) {
      return
    }

    this.masterGridController = event.detail.controller
  }

  registerDetailGrid(event) {
    if (!this.hasDetailGridTarget || event.target !== this.detailGridTarget) {
      return
    }

    this.detailGridController = event.detail.controller
  }

  onMasterRowClicked(event) {
    if (!this.hasMasterGridTarget || event.target !== this.masterGridTarget) {
      return
    }

    const row = event.detail?.data || event.detail?.node?.data || null
    const ordNo = row?.ord_no || ""

    if (ordNo === "") {
      this.setDetailRows([])
      return
    }

    this.loadDetailRows(ordNo)
  }

  async loadDetailRows(ordNo) {
    const url = this.detailsUrlTemplateValue.replace("__ORD_NO__", encodeURIComponent(ordNo))

    try {
      const response = await fetch(url, { headers: { Accept: "application/json" } })
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`)
      }

      const rows = await response.json()
      this.setDetailRows(Array.isArray(rows) ? rows : [])
    } catch (_error) {
      this.setDetailRows([])
      alert("상세 데이터를 불러오지 못했습니다.")
    }
  }

  async completeSelectedOrders() {
    const selectedRows = this.selectedMasterRows()
    if (selectedRows.length === 0) {
      alert("수동완료할 오더를 선택하세요.")
      return
    }

    const reason = this.reasonInputTarget.value.toString().trim()
    if (reason === "") {
      alert("수동완료 사유를 입력하세요.")
      this.reasonInputTarget.focus()
      return
    }

    const orderNos = selectedRows
      .map((row) => row.ord_no)
      .filter((value, index, array) => value && array.indexOf(value) === index)

    if (orderNos.length === 0) {
      alert("선택한 행에서 오더번호를 찾을 수 없습니다.")
      return
    }

    const confirmed = window.confirm(`${orderNos.length}건을 수동완료 처리하시겠습니까?`)
    if (!confirmed) {
      return
    }

    try {
      const response = await fetch(this.completeUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": this.csrfToken
        },
        body: JSON.stringify({
          order_nos: orderNos,
          reason
        })
      })
      const result = await response.json()

      if (response.ok && result.success) {
        alert(result.message || "수동완료 처리가 완료되었습니다.")
        this.reasonInputTarget.value = ""
        this.refreshMasterGrid()
        this.setDetailRows([])
        return
      }

      alert(result.message || "수동완료 처리에 실패했습니다.")
      if (Array.isArray(result.failures) && result.failures.length > 0) {
        const detailMessage = result.failures.map((row) => `${row.ord_no}: ${row.reason}`).join("\n")
        alert(detailMessage)
      }
      this.refreshMasterGrid()
    } catch (_error) {
      alert("수동완료 처리 중 오류가 발생했습니다.")
    }
  }

  selectedMasterRows() {
    if (!this.masterGridController || !this.masterGridController.api) {
      return []
    }

    return this.masterGridController.api.getSelectedRows()
  }

  refreshMasterGrid() {
    if (this.masterGridController && this.masterGridController.refresh) {
      this.masterGridController.refresh()
    }
  }

  setDetailRows(rows) {
    if (!this.detailGridController || !this.detailGridController.api) {
      return
    }

    this.detailGridController.api.setGridOption("rowData", rows)
  }

  get csrfToken() {
    const token = document.querySelector("[name='csrf-token']")
    if (token) {
      return token.content
    }

    return ""
  }
}
