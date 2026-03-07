import BaseGridController from "controllers/base_grid_controller"
import { showAlert } from "components/ui/alert"
import { fetchJson } from "controllers/grid/grid_utils"

// 사전오더접수 화면 (마스터-디테일 + 오더생성 배치 액션)
export default class extends BaseGridController {
  static targets = [
    ...BaseGridController.targets,
    "masterGrid",
    "detailGrid"
  ]

  static values = {
    ...BaseGridController.values,
    createUrl: String,
    itemsUrl: String
  }

  gridRoles() {
    return {
      master: {
        target: "masterGrid",
        masterKeyField: "bef_ord_no"
      },
      detail: {
        target: "detailGrid",
        parentGrid: "master",
        detailLoader: (rowData) => this.fetchDetailRows(rowData)
      }
    }
  }

  // 기존 ag-grid:selectionChanged 바인딩 호환용
  handleSelectionChanged() { }

  async createOrders() {
    const selected = this.selectedRows("master")
    if (selected.length === 0) {
      showAlert("오더 생성 대상을 선택하세요.")
      return
    }

    const befOrdNos = selected
      .map((row) => row.bef_ord_no)
      .filter((value, index, array) => value && array.indexOf(value) === index)

    if (befOrdNos.length === 0) {
      showAlert("선택한 행에 사전오더번호가 없습니다.")
      return
    }

    await this.postAction(
      this.createUrlValue,
      { bef_ord_nos: befOrdNos },
      {
        confirmMessage: `${befOrdNos.length}건을 오더 생성하시겠습니까?`,
        onSuccess: (result) => {
          showAlert(result.message || "오더 생성이 완료되었습니다.")
          this.refreshGrid("master")
          this.setRows("detail", [])
        },
        onFail: (result) => {
          showAlert(result.message || "오더 생성에 실패했습니다.")
        }
      }
    )
  }

  async fetchDetailRows(selectedRow) {
    if (!selectedRow) {
      return []
    }

    const custOrdNo = selectedRow.cust_ord_no || ""
    const befOrdNo = selectedRow.bef_ord_no || ""
    if (custOrdNo === "" && befOrdNo === "") {
      return []
    }

    const params = new URLSearchParams()
    if (custOrdNo !== "") params.set("cust_ord_no", custOrdNo)
    if (befOrdNo !== "") params.set("bef_ord_no", befOrdNo)

    try {
      const rows = await fetchJson(`${this.itemsUrlValue}?${params.toString()}`)
      return Array.isArray(rows) ? rows : []
    } catch {
      showAlert("상세 데이터를 불러오지 못했습니다.")
      return []
    }
  }
}
