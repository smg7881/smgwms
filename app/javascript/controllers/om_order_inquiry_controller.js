import { Controller } from "@hotwired/stimulus"
import { get } from "@rails/request.js"

export default class extends Controller {
    static targets = [
        "masterGridContainer",
        "detailGridContainer",
        "detailHeaderLabel"
    ]

    connect() {
        this.masterGridApi = null
        this.detailGridApi = null
    }

    // `Ui::AgGridComponent`에서 `ag-grid:ready` 이벤트로 호출됨
    initMasterGrid(event) {
        this.masterGridApi = event.detail.api
    }

    // `Ui::AgGridComponent`에서 `ag-grid:ready` 이벤트로 호출됨
    initDetailGrid(event) {
        this.detailGridApi = event.detail.api
    }

    // 검색 폼 성공 시 메인그리드 바인딩
    loadMasterData(event) {
        if (!event.detail) return;

        const response = event.detail
        if (this.masterGridApi) {
            this.masterGridApi.setGridOption('rowData', response || [])
        }

        // 디테일 영역 초기화
        this.resetDetail()
    }

    resetDetail() {
        if (this.detailGridApi) {
            this.detailGridApi.setGridOption('rowData', [])
        }
        if (this.hasDetailHeaderLabelTarget) {
            this.detailHeaderLabelTarget.textContent = "오더를 선택해주세요."
            this.detailHeaderLabelTarget.classList.remove('text-blue-600')
            this.detailHeaderLabelTarget.classList.add('text-gray-500')
        }
    }

    // 마스터 행 클릭 시 상세 아이템 조회 호출
    async onMasterRowClicked(event) {
        if (!event.detail) return;
        
        const row = event.detail.data;
        if (!row || !row.id) return;

        try {
            const response = await get(`/om/order_inquiries/${row.id}`, {
                responseKind: "json"
            })

            if (response.ok) {
                const body = await response.json
                if (this.detailGridApi) {
                    this.detailGridApi.setGridOption('rowData', body || [])
                }

                // 라벨 시각적 피드백 업데이트
                if (this.hasDetailHeaderLabelTarget) {
                    this.detailHeaderLabelTarget.textContent = `[${row.ord_no}] 상세 항목 리스트`
                    this.detailHeaderLabelTarget.classList.remove('text-gray-500')
                    this.detailHeaderLabelTarget.classList.add('text-blue-600')
                }
            }
        } catch (e) {
            console.error("아이템 상세 조회 오류", e)
        }
    }
}
