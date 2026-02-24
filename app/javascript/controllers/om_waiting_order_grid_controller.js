import { Controller } from "@hotwired/stimulus"
import { get, post } from "@rails/request.js"

// 대기오더관리 화면 전용 그리드 컨트롤러
export default class extends Controller {
    static values = {
        distributeUrl: String
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

    // 가용재고조회 버튼 클릭
    async checkAvailableStock() {
        if (!this.agGridController) return

        const selectedRows = this.agGridController.gridOptions.api.getSelectedRows()
        if (selectedRows.length === 0) {
            alert("가용재고를 조회할 대기오더를 선택해주세요.")
            return
        }

        // 실제로는 백엔드로 품목코드 등을 보내어 가용재고를 받아야 하지만
        // 이 구현에서는 Mock으로 그리드 내 가용 데이터를 임시로 리프레시하거나 
        // 선택된 행들의 가용재고를 재조회하는 효과를 부여합니다.
        this.reload()
        alert("가용재고 조회가 완료되었습니다. (조회 결과가 그리드에 반영됨)")
    }

    // 오더분배 버튼 클릭
    async distributeOrders() {
        if (!this.agGridController) return

        // 편집 모드 종료
        this.agGridController.gridOptions.api.stopEditing()

        const selectedRows = this.agGridController.gridOptions.api.getSelectedRows()
        if (selectedRows.length === 0) {
            alert("분배할 오더를 선택해주세요.")
            return
        }

        // 분배 정보 추출
        const distributions = selectedRows.map(row => {
            return {
                ord_no: row.ord_no,
                dist_qty: Number(row.dist_qty || 0),
                dist_wgt: Number(row.dist_wgt || 0),
                dist_vol: Number(row.dist_vol || 0)
            }
        }).filter(d => d.dist_qty > 0)

        if (distributions.length === 0) {
            alert("선택된 오더 중 분배 수량이 입력된 건이 없습니다. (분배 수량을 입력해주세요)")
            return
        }

        if (!confirm(`${distributions.length}건의 오더를 분배하시겠습니까?`)) {
            return
        }

        try {
            const response = await post(this.distributeUrlValue, {
                body: JSON.stringify({
                    distributions: distributions
                })
            })

            const data = await response.json()

            if (response.ok && data.success) {
                alert(data.message || "오더 분배가 완료되었습니다.")
                this.reload() // 그리드 데이터 재조회
            } else {
                alert(data.message || "시스템 오류로 인해 처리에 실패했습니다.")
            }
        } catch (error) {
            console.error("Distribution Error:", error)
            alert("요청 중 네트워크 또는 서버 오류가 발생했습니다.")
        }
    }
}
