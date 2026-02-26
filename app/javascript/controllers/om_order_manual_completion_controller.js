import BaseGridController from "controllers/base_grid_controller"
import { showAlert, confirmAction } from "components/ui/alert"
import { fetchJson } from "controllers/grid/grid_utils"

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
      master: { target: "masterGrid" },
      detail: { target: "detailGrid" }
    }
  }

  onMasterRowClicked(event) {
    if (!this.hasMasterGridTarget || event.target !== this.masterGridTarget) return

    const row = event.detail?.data || event.detail?.node?.data || null
    const ordNo = row?.ord_no || ""

    if (ordNo === "") {
      this.setRows("detail", [])
      return
    }

    this.#loadDetailRows(ordNo)
  }

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

  // ─── Private ───

  async #loadDetailRows(ordNo) {
    const url = this.detailsUrlTemplateValue.replace("__ORD_NO__", encodeURIComponent(ordNo))

    try {
      const rows = await fetchJson(url)
      this.setRows("detail", Array.isArray(rows) ? rows : [])
    } catch {
      this.setRows("detail", [])
      showAlert("상세 데이터를 불러오지 못했습니다.")
    }
  }
}
