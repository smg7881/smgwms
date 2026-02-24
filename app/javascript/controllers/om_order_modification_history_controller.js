import { Controller } from "@hotwired/stimulus"
import { createGrid } from "ag-grid-community"
import { get } from "@rails/request.js"

export default class extends Controller {
    static targets = [
        // 그리드
        "masterGridContainer", "detailGridContainer"
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

        // 이력 탭 리셋
        this.resetDetailTabs()
    }

    resetDetailTabs() {
        if (this.detailGridApi) {
            this.detailGridApi.setGridOption('rowData', [])
        }
    }

    // 1. 오더수정이력목록 메인 그리드
    initMasterGrid() {
        const gridOptions = {
            columnDefs: [
                { field: "sctn", headerName: "구분", width: 80, pinned: 'left' },
                { field: "hist_seq", headerName: "순번", width: 70, pinned: 'left', cellClass: 'text-right' },
                { field: "ord_no", headerName: "오더번호", width: 130 },
                { field: "cust_ord_no", headerName: "고객오더번호", width: 130 },
                { field: "ord_type_cd", headerName: "오더유형", width: 110 },
                { field: "cust_cd", headerName: "고객", width: 120 },
                { field: "ctrt_cust_cd", headerName: "계약고객", width: 120 },
                { field: "ord_req_cust_cd", headerName: "요청고객", width: 120 },
                { field: "bilg_cust_cd", headerName: "청구고객", width: 120 },
                { field: "ctrt_no", headerName: "계약번호", width: 120 },
                { field: "ord_stat_cd", headerName: "오더상태", width: 90 },
                { field: "ord_chrg_dept_cd", headerName: "오더담당부서", width: 120 },
                { field: "ord_ofcr", headerName: "담당자", width: 100 },
                { field: "retrngd_yn", headerName: "반품여부", width: 90 },
                { field: "back_ord_yn", headerName: "대기여부", width: 90 },
                { field: "cust_expr_yn", headerName: "고객긴급", width: 90, cellClassRules: { 'text-red-500 font-bold': "x == 'Y'" } },
                { field: "cls_expr_yn", headerName: "마감긴급", width: 90, cellClassRules: { 'text-red-500 font-bold': "x == 'Y'" } },
                { field: "prcl", headerName: "특이사항", width: 150 }
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

    // 마스터 행 클릭 시 상세 조회 호출
    async onMasterRowClicked(event) {
        const row = event.data;
        if (!row || !row.id) return;

        try {
            const response = await get(`/om/order_modification_histories/${row.id}`, {
                responseKind: "json"
            })

            if (response.ok) {
                const body = await response.json
                const sctnLabel = `${row.sctn} (${row.hist_seq}차)`

                // Item 맵핑 수행
                if (this.detailGridApi) {
                    this.detailGridApi.setGridOption('rowData', body.items || [])
                }
            }
        } catch (e) {
            console.error("이력 상세 정보 조회 오류", e)
        }
    }

    // 4. 아이템상세 하단 그리드
    initDetailGrid() {
        const gridOptions = {
            columnDefs: [
                { field: "sctn", headerName: "구분", width: 80 },
                { field: "seq", headerName: "순번", width: 70, cellClass: 'text-right' },
                { field: "item_cd", headerName: "아이템코드", width: 120 },
                { field: "item_nm", headerName: "아이템명", width: 160 },
                { field: "basis_unit_clas_cd", headerName: "기본단위분류", width: 110 },
                {
                    headerName: "오더내역",
                    children: [
                        { field: "ord_qty", headerName: "수량", width: 80, type: "numericColumn", cellClass: 'bg-blue-50' },
                        { field: "ord_wgt", headerName: "중량", width: 80, type: "numericColumn", cellClass: 'bg-blue-50' },
                        { field: "ord_vol", headerName: "부피", width: 80, type: "numericColumn", cellClass: 'bg-blue-50' },
                        { field: "unit_cd", headerName: "단위", width: 70 }
                    ]
                }
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
