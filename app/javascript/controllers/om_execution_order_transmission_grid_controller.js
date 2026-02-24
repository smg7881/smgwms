import { Controller } from "@hotwired/stimulus"
import { post } from "@rails/request.js"

export default class extends Controller {
    static values = {
        retransmitUrl: String
    }
    static targets = ["grid"]

    connect() {
        this.agGridController = null
    }

    onGridReady(event) {
        this.agGridController = this.application.getControllerForElementAndIdentifier(
            this.gridTarget,
            "ag-grid"
        )
    }

    reload() {
        if (this.agGridController) {
            this.agGridController.loadData()
        }
    }

    // 재전송 버튼 클릭 로직
    async retransmit() {
        if (!this.agGridController) return

        const selectedRows = this.agGridController.gridOptions.api.getSelectedRows()

        if (selectedRows.length === 0) {
            alert("재전송할 항목을 체크해주세요.")
            return
        }

        // 전송여부가 'E' (에러) 인 항목만 필터
        const errorRows = selectedRows.filter(row => row.trms_yn === 'E')

        if (errorRows.length === 0) {
            alert("선택된 항목 중 재전송 대상(전송 여부: E)이 없습니다.")
            // 선택 모두 해제
            this.agGridController.gridOptions.api.deselectAll()
            return
        }

        if (errorRows.length < selectedRows.length) {
            const confirmProceed = confirm(`선택된 ${selectedRows.length}건 중 재전송 가능한 항목(E)은 ${errorRows.length}건입니다. 진행하시겠습니까?`)
            if (!confirmProceed) return
        } else {
            if (!confirm(`${errorRows.length}건의 데이터를 재전송(상태변경 N) 하시겠습니까?`)) {
                return
            }
        }

        const payloadIds = errorRows.map(r => r.id)

        try {
            const response = await post(this.retransmitUrlValue, {
                body: JSON.stringify({ ids: payloadIds })
            })

            const data = await response.json()

            if (response.ok && data.success) {
                alert(data.message || "재전송 큐(N 상태 대기)에 등록되었습니다.")
                this.reload()
            } else {
                alert(data.message || "서버 오류로 실패했습니다.")
            }
        } catch (error) {
            console.error(error)
            alert("요청 중 네트워크 또는 시스템 오류가 발생했습니다.")
        }
    }
}
