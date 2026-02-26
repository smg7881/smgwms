import BaseGridController from "controllers/base_grid_controller"
import { showAlert, confirmAction } from "components/ui/alert"

// 실행오더전송 화면 전용 그리드 컨트롤러 (단일 그리드 + 재전송 액션)
export default class extends BaseGridController {
  static values = {
    ...BaseGridController.values,
    retransmitUrl: String
  }

  // 재전송 버튼 클릭 로직
  async retransmit() {
    const api = this.gridController?.api
    if (!api) return

    const selectedRows = api.getSelectedRows()
    if (selectedRows.length === 0) {
      showAlert("재전송할 항목을 체크해주세요.")
      return
    }

    // 전송여부가 'E' (에러) 인 항목만 필터
    const errorRows = selectedRows.filter((row) => row.trms_yn === "E")
    if (errorRows.length === 0) {
      showAlert("선택된 항목 중 재전송 대상(전송 여부: E)이 없습니다.")
      api.deselectAll()
      return
    }

    let confirmMessage
    if (errorRows.length < selectedRows.length) {
      confirmMessage = `선택된 ${selectedRows.length}건 중 재전송 가능한 항목(E)은 ${errorRows.length}건입니다. 진행하시겠습니까?`
    } else {
      confirmMessage = `${errorRows.length}건의 데이터를 재전송(상태변경 N) 하시겠습니까?`
    }

    await this.postAction(
      this.retransmitUrlValue,
      { ids: errorRows.map((r) => r.id) },
      {
        confirmMessage,
        onSuccess: (result) => {
          showAlert(result.message || "재전송 큐(N 상태 대기)에 등록되었습니다.")
          this.reloadRows()
        }
      }
    )
  }
}
