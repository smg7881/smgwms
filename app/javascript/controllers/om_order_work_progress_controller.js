import { Controller } from "@hotwired/stimulus"
import { createGrid } from "ag-grid-community"

export default class extends Controller {
    static targets = [
        // Form Inputs
        "custOrdNo", "ordNo", "custOrdTypeNm", "ordReqCustNm",
        "ctrtNo", "ctrtCustNm", "bilgCustNm", "ordTypeNm",
        "custOrdOfcr", "custTel", "custExprYn", "clsExprYn",
        "retrngdYn", "ordStatNm", "ordCmptNm",

        // Grid Containers
        "itemGridContainer", "progressGridContainer"
    ]

    connect() {
        this.itemGridApi = null
        this.progressGridApi = null

        this.initItemGrid()
        this.initProgressGrid()
    }

    disconnect() {
        if (this.itemGridApi) {
            this.itemGridApi.destroy()
        }
        if (this.progressGridApi) {
            this.progressGridApi.destroy()
        }
    }

    // 아이템 그리드 초기화
    initItemGrid() {
        const gridOptions = {
            columnDefs: [
                { field: "div_dgr_cnt", headerName: "분배차수", width: 90 },
                { field: "item_cd", headerName: "아이템코드", width: 120 },
                { field: "item_nm", headerName: "아이템명", width: 160 },
                { field: "work_stat", headerName: "상태", width: 90 },
                { field: "basis_cd", headerName: "단위", width: 70 },
                {
                    headerName: "오더",
                    children: [
                        { field: "ord_qty", headerName: "수량", width: 80, type: "numericColumn", cellClass: "text-right bg-blue-50" },
                        { field: "ord_wgt", headerName: "중량", width: 80, type: "numericColumn", cellClass: "text-right bg-blue-50" },
                        { field: "ord_vol", headerName: "부피", width: 80, type: "numericColumn", cellClass: "text-right bg-blue-50" }
                    ]
                },
                {
                    headerName: "실적",
                    children: [
                        { field: "rslt_qty", headerName: "수량", width: 80, type: "numericColumn", cellClass: "text-right bg-green-50" },
                        { field: "rslt_wgt", headerName: "중량", width: 80, type: "numericColumn", cellClass: "text-right bg-green-50" },
                        { field: "rslt_vol", headerName: "부피", width: 80, type: "numericColumn", cellClass: "text-right bg-green-50" }
                    ]
                }
            ],
            defaultColDef: {
                sortable: true,
                resizable: true
            },
            rowData: []
        }

        this.itemGridApi = createGrid(this.itemGridContainerTarget, gridOptions)
    }

    // 작업진행상세 그리드 초기화
    initProgressGrid() {
        const gridOptions = {
            columnDefs: [
                { field: "car_no", headerName: "차량번호", width: 120 },
                { field: "dpt_ar_nm", headerName: "출발지", width: 130 },
                { field: "arv_ar_nm", headerName: "도착지", width: 130 },
                { field: "dpt_prar_date", headerName: "출발예정일시", width: 150 },
                { field: "dpt_date", headerName: "출발일시", width: 150, cellClass: "text-blue-600" },
                { field: "arv_prar_date", headerName: "도착예정일시", width: 150 },
                { field: "arv_date", headerName: "도착일시", width: 150, cellClass: "text-blue-600" },
                {
                    headerName: "상태 Tracker",
                    children: [
                        { field: "gi", headerName: "출고", width: 80 },
                        { field: "tran", headerName: "운송", width: 80 },
                        { field: "gr", headerName: "입고", width: 80 },
                        { field: "dpt", headerName: "출발", width: 80 },
                        { field: "arv", headerName: "도착", width: 80 }
                    ]
                }
            ],
            defaultColDef: {
                sortable: true,
                resizable: true
            },
            rowData: []
        }

        this.progressGridApi = createGrid(this.progressGridContainerTarget, gridOptions)
    }

    // 검색폼의 JSON 응답을 받아와 바인딩
    loadData(event) {
        if (!event.detail) return;

        // search_form_controller에서 JSON Response로 넘겨준 data 그대로를 받음 (Rendered JSon object)
        // 원래 resource_form은 배열 1개만 주는 경우도 있으나, 
        // 여기서는 커스텀 컨트롤러 구조(master, items, progresses)를 대응해야함.
        const response = event.detail

        if (response && response.master) {
            this.bindMaster(response.master)

            if (this.itemGridApi) {
                this.itemGridApi.setGridOption('rowData', response.items || [])
            }

            if (this.progressGridApi) {
                this.progressGridApi.setGridOption('rowData', response.progresses || [])
            }
        } else {
            // 0건일 때 초기화
            this.bindMaster({})
            if (this.itemGridApi) this.itemGridApi.setGridOption('rowData', [])
            if (this.progressGridApi) this.progressGridApi.setGridOption('rowData', [])

            if (response && response.length === 0) {
                alert("오더 번호를 정확히 넣고 검색하십시오.")
            }
        }
    }

    // 폼 필드 엘리먼트 값 세팅
    bindMaster(master) {
        this.custOrdNoTarget.value = master.cust_ord_no || ""
        this.ordNoTarget.value = master.ord_no || ""
        this.custOrdTypeNmTarget.value = master.cust_ord_type_nm || ""
        this.ordReqCustNmTarget.value = master.ord_req_cust_nm || ""

        this.ctrtNoTarget.value = master.ctrt_no || ""
        this.ctrtCustNmTarget.value = master.ctrt_cust_nm || ""
        this.bilgCustNmTarget.value = master.bilg_cust_nm || ""
        this.ordTypeNmTarget.value = master.ord_type_nm || ""

        this.custOrdOfcrTarget.value = master.cust_ord_ofcr || ""
        this.custTelTarget.value = master.cust_tel || ""
        this.custExprYnTarget.value = master.cust_expr_yn || ""
        this.clsExprYnTarget.value = master.cls_expr_yn || ""

        this.retrngdYnTarget.value = master.retrngd_yn || ""
        this.ordStatNmTarget.value = master.ord_stat_nm || ""
        this.ordCmptNmTarget.value = master.ord_cmpt_nm || ""
    }
}
