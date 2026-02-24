import { Controller } from "@hotwired/stimulus"
import { createGrid } from "ag-grid-community"
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

        this.initMasterGrid()
        this.initDetailGrid()
    }

    disconnect() {
        if (this.masterGridApi) this.masterGridApi.destroy()
        if (this.detailGridApi) this.detailGridApi.destroy()
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
        this.detailHeaderLabelTarget.textContent = "오더를 선택해주세요."
        this.detailHeaderLabelTarget.classList.remove('text-blue-600')
        this.detailHeaderLabelTarget.classList.add('text-gray-500')
    }

    // 1. 오더목록 마스터 그리드
    initMasterGrid() {
        const gridOptions = {
            columnDefs: [
                { field: "ord_stat_cd", headerName: "오더상태", width: 100, pinned: 'left', cellClassRules: { 'text-blue-600 font-bold': "x == '출고대기'" } },
                { field: "ord_no", headerName: "오더번호", width: 150, pinned: 'left' },
                { field: "creat_ymd", headerName: "생성일자", width: 110 },
                { field: "ord_type_cd", headerName: "오더유형", width: 120 },
                { field: "cust_bzac_nm", headerName: "고객거래처명", width: 150 },
                { field: "dpt_ar_nm", headerName: "출발지명", width: 130 },
                { field: "arv_ar_nm", headerName: "도착지명", width: 130 },
                { field: "ord_kind_cd", headerName: "조회 파라미터(디버그용1)", width: 180 },
                { field: "cmpt_sctn_cd", headerName: "조회 파라미터(디버그용2)", width: 180 }
            ],
            defaultColDef: {
                sortable: true,
                resizable: true
            },
            rowData: [],
            rowSelection: { mode: "singleRow" },
            onRowClicked: this.onMasterRowClicked.bind(this)
        }

        this.masterGridApi = createGrid(this.masterGridContainerTarget, gridOptions)
    }

    // 마스터 행 클릭 시 상세 아이템 조회 호출
    async onMasterRowClicked(event) {
        const row = event.data;
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
                this.detailHeaderLabelTarget.textContent = `[${row.ord_no}] 상세 항목 리스트`
                this.detailHeaderLabelTarget.classList.remove('text-gray-500')
                this.detailHeaderLabelTarget.classList.add('text-blue-600')
            }
        } catch (e) {
            console.error("아이템 상세 조회 오류", e)
        }
    }

    // 2. 오더아이템목록 하단 그리드
    initDetailGrid() {
        const gridOptions = {
            columnDefs: [
                { field: "seq", headerName: "순번", width: 70, cellClass: 'text-right' },
                { field: "item_cd", headerName: "아이템코드", width: 130 },
                { field: "item_nm", headerName: "아이템명", width: 180 },
                { field: "ord_qty", headerName: "오더수량", width: 100, type: "numericColumn", cellClass: 'bg-blue-50 font-medium' },
                { field: "qty_unit_cd", headerName: "수량단위", width: 90 },
                { field: "ord_wgt", headerName: "오더중량", width: 100, type: "numericColumn" },
                { field: "wgt_unit_cd", headerName: "중량단위", width: 90 },
                { field: "ord_vol", headerName: "오더부피", width: 100, type: "numericColumn" },
                { field: "vol_unit_cd", headerName: "부피단위", width: 90 }
            ],
            defaultColDef: {
                sortable: true,
                resizable: true
            },
            rowData: []
        }

        this.detailGridApi = createGrid(this.detailGridContainerTarget, gridOptions)
    }
}
