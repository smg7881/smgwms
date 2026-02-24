import { Controller } from "@hotwired/stimulus"
import { post } from "@rails/request.js"

export default class extends Controller {
  static targets = ["masterGrid", "detailGrid"]

  static values = {
    createUrl: String,
    itemsUrl: String
  }

  connect() {
    this.masterGridController = null
    this.detailGridController = null
  }

  registerGrid(event) {
    const { controller } = event.detail
    const gridElement = event.target

    if (this.hasMasterGridTarget && gridElement === this.masterGridTarget) {
      this.masterGridController = controller
      return
    }

    if (this.hasDetailGridTarget && gridElement === this.detailGridTarget) {
      this.detailGridController = controller
    }
  }

  handleSelectionChanged(event) {
    if (!this.hasMasterGridTarget || event.target !== this.masterGridTarget) {
      return
    }

    const selectedRows = this.selectedMasterRows()
    if (selectedRows.length > 0) {
      this.loadDetailRows(selectedRows[0])
    } else {
      this.setDetailRows([])
    }
  }

  async createOrders() {
    const selectedRows = this.selectedMasterRows()
    if (selectedRows.length === 0) {
      alert("오더 생성 대상을 선택하세요.")
      return
    }

    const befOrdNos = selectedRows
      .map((row) => row.bef_ord_no)
      .filter((value, index, array) => value && array.indexOf(value) === index)

    if (befOrdNos.length === 0) {
      alert("선택한 행에 사전오더번호가 없습니다.")
      return
    }

    const confirmed = window.confirm(`${befOrdNos.length}건을 오더 생성하시겠습니까?`)
    if (!confirmed) {
      return
    }

    try {
      const response = await post(this.createUrlValue, {
        body: JSON.stringify({ bef_ord_nos: befOrdNos })
      })
      const data = await response.json()

      if (response.ok && data.success) {
        alert(data.message || "오더 생성이 완료되었습니다.")
        this.reloadMasterRows()
        this.setDetailRows([])
      } else {
        alert(data.message || "오더 생성에 실패했습니다.")
      }
    } catch (_error) {
      alert("오더 생성 요청 중 오류가 발생했습니다.")
    }
  }

  selectedMasterRows() {
    if (!this.masterGridController || !this.masterGridController.api) {
      return []
    }

    return this.masterGridController.api.getSelectedRows()
  }

  reloadMasterRows() {
    if (this.masterGridController && this.masterGridController.refresh) {
      this.masterGridController.refresh()
    }
  }

  async loadDetailRows(selectedRow) {
    if (!selectedRow) {
      this.setDetailRows([])
      return
    }

    const custOrdNo = selectedRow.cust_ord_no || ""
    const befOrdNo = selectedRow.bef_ord_no || ""
    if (custOrdNo === "" && befOrdNo === "") {
      this.setDetailRows([])
      return
    }

    const params = new URLSearchParams()
    if (custOrdNo !== "") {
      params.set("cust_ord_no", custOrdNo)
    }
    if (befOrdNo !== "") {
      params.set("bef_ord_no", befOrdNo)
    }

    try {
      const response = await fetch(`${this.itemsUrlValue}?${params.toString()}`, {
        headers: { Accept: "application/json" }
      })
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

  setDetailRows(rows) {
    if (!this.detailGridController || !this.detailGridController.api) {
      return
    }

    this.detailGridController.api.setGridOption("rowData", rows)
  }
}
