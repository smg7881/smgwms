import BaseGridController from "controllers/base_grid_controller"
import { showAlert } from "components/ui/alert"
import { buildTemplateUrl } from "controllers/grid/grid_utils"
import { fetchJson } from "controllers/grid/core/http_client"

// 오더수동완료 화면 (마스터-디테일 + 수동완료 배치 액션)
export default class extends BaseGridController {
  static targets = [
    ...BaseGridController.targets,
    "masterGrid",
    "detailGrid",
    "reasonInput"
  ]

  static values = {
    ...BaseGridController.values,
    completeUrl: String,
    detailsUrlTemplate: String
  }

  gridRoles() {
    return {
      master: {
        target: "masterGrid",
        masterKeyField: "ord_no"
      },
      detail: {
        target: "detailGrid",
        parentGrid: "master",
        detailLoader: (rowData) => this.fetchDetailRows(rowData)
      }
    }
  }

  // 기존 ag-grid:rowClicked 바인딩 호환용
  onMasterRowClicked() { }

  async completeSelectedOrders() {
    const selected = this.selectedRows("master")
    if (selected.length === 0) {
      showAlert("수동완료할 오더를 선택하세요.")
      return
    }

    const reason = this.reasonInputTarget.value.toString().trim()
    if (reason === "") {
      showAlert("수동완료 사유를 입력하세요.")
      this.reasonInputTarget.focus()
      return
    }

    const orderNos = selected
      .map((row) => row.ord_no)
      .filter((value, index, array) => value && array.indexOf(value) === index)

    if (orderNos.length === 0) {
      showAlert("선택한 행에서 오더번호를 찾을 수 없습니다.")
      return
    }

    await this.postAction(
      this.completeUrlValue,
      { order_nos: orderNos, reason },
      {
        confirmMessage: `${orderNos.length}건을 수동완료 처리하시겠습니까?`,
        onSuccess: (result) => {
          showAlert(result.message || "수동완료 처리가 완료되었습니다.")
          this.reasonInputTarget.value = ""
          this.refreshGrid("master")
          this.setRows("detail", [])
        },
        onFail: (result) => {
          showAlert(result.message || "수동완료 처리에 실패했습니다.")
          if (Array.isArray(result.failures) && result.failures.length > 0) {
            const detailMessage = result.failures.map((row) => `${row.ord_no}: ${row.reason}`).join("\n")
            showAlert(detailMessage)
          }
          this.refreshGrid("master")
        }
      }
    )
  }

  async fetchDetailRows(rowData) {
    const ordNo = rowData?.ord_no
    if (!ordNo) return []

    const url = buildTemplateUrl(this.detailsUrlTemplateValue, "__ORD_NO__", ordNo)
    try {
      const rows = await fetchJson(url)
      return Array.isArray(rows) ? rows : []
    } catch {
      showAlert("상세 데이터를 불러오지 못했습니다.")
      return []
    }
  }
}
