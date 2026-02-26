import BaseGridController from "controllers/base_grid_controller"
import { showAlert, confirmAction } from "components/ui/alert"
import { isApiAlive } from "controllers/grid/grid_utils"

// 대기오더관리 화면 전용 그리드 컨트롤러 (단일 그리드 + 배치 액션)
export default class extends BaseGridController {
  static values = {
    ...BaseGridController.values,
    distributeUrl: String
  }

  // 가용재고조회 버튼 클릭
  checkAvailableStock() {
    this.reloadRows()
    showAlert("가용재고 조회가 완료되었습니다. (조회 결과가 그리드에 반영됨)")
  }

  // 오더분배 버튼 클릭
  async distributeOrders() {
    const api = this.gridController?.api
    if (isApiAlive(api)) api.stopEditing()

    const selectedRows = api?.getSelectedRows() || []
    if (selectedRows.length === 0) {
      showAlert("분배할 오더를 선택해주세요.")
      return
    }

    const distributions = selectedRows
      .map((row) => ({
        ord_no: row.ord_no,
        dist_qty: Number(row.dist_qty || 0),
        dist_wgt: Number(row.dist_wgt || 0),
        dist_vol: Number(row.dist_vol || 0)
      }))
      .filter((d) => d.dist_qty > 0)

    if (distributions.length === 0) {
      showAlert("선택된 오더 중 분배 수량이 입력된 건이 없습니다. (분배 수량을 입력해주세요)")
      return
    }

    await this.postAction(
      this.distributeUrlValue,
      { distributions },
      {
        confirmMessage: `${distributions.length}건의 오더를 분배하시겠습니까?`,
        onSuccess: (result) => {
          showAlert(result.message || "오더 분배가 완료되었습니다.")
          this.reloadRows()
        }
      }
    )
  }
}
