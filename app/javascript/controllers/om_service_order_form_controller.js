import { Controller } from "@hotwired/stimulus"
import { get, post, put } from "@rails/request.js"

export default class extends Controller {
    static values = {
        url: String
    }

    static targets = [
        "grid", "form", "methodInput", "idInput",
        "ctrtNo", "ordTypeCd", "custCd", "custNm", "bilgCustCd", "reqCustCd", "ctrtCustCd",
        "custOfcrNm", "custOfcrTel", "tranDivCd", "remark",
        "dptTypeCd", "dptCd", "dptAddr", "reqStartDt",
        "arvTypeCd", "arvCd", "arvAddr", "aptdReqYmd",
        "ordNoDisplay", "reasonGroup", "changeReason"
    ]

    connect() {
        this.agGridController = null
        this.newOrder() // 기본 모드는 신규
    }

    onGridReady(event) {
        this.agGridController = this.application.getControllerForElementAndIdentifier(
            this.gridTarget,
            "ag-grid"
        )

        // Ag Grid의 cell value change event를 가로채서 환산 적용
        const gridOptions = this.agGridController.gridOptions
        gridOptions.onCellValueChanged = this.onCellValueChanged.bind(this)
    }

    // 검색 성공 시 상세에 데이터를 불러오는 Mockup (배열의 1번 데이터 클릭이라 가정)
    loadDetail(event) {
        if (!event.detail || !event.detail[0]) return;

        // 이 코드에서는 목록을 별도 검색 그리드가 아니라 
        // "조회 시 가장 최신 1개를 불러오거나" 등으로 제어해야 하나 
        // PRD 컨셉상 Form에 데이터를 바인딩합니다.
        const data = event.detail[0]
        this.setFormData(data)
    }

    setFormData(data) {
        this.formTarget.reset()

        this.methodInputTarget.value = "put"
        this.idInputTarget.value = data.ord_no

        this.ctrtNoTarget.value = data.ctrt_no || ""
        this.ordTypeCdTarget.value = data.ord_type_cd || ""

        // 주요 키 값 수정 비활성화 제어
        this.ctrtNoTarget.readOnly = true
        this.ordTypeCdTarget.disabled = true
        this.dptTypeCdTarget.disabled = true
        this.arvTypeCdTarget.disabled = true

        this.custCdTarget.value = data.cust_cd || ""
        this.reqStartDtTarget.value = data.req_start_dt || ""

        this.dptTypeCdTarget.value = data.dpt_type_cd || ""
        this.dptCdTarget.value = data.dpt_cd || ""
        this.arvTypeCdTarget.value = data.arv_type_cd || ""
        this.arvCdTarget.value = data.arv_cd || ""

        this.ordNoDisplayTarget.value = data.ord_no || ""

        // 수정 모드이므로 사유란 노출
        this.reasonGroupTarget.classList.remove("hidden")
    }

    newOrder() {
        this.formTarget.reset()

        this.methodInputTarget.value = "post"
        this.idInputTarget.value = ""
        this.ordNoDisplayTarget.value = ""

        // 수정 비활성화된 항목들 활성화
        this.ctrtNoTarget.readOnly = false
        this.ordTypeCdTarget.disabled = false
        this.dptTypeCdTarget.disabled = false
        this.arvTypeCdTarget.disabled = false

        // 사유란 숨김
        this.reasonGroupTarget.classList.add("hidden")
        this.changeReasonTarget.value = ""

        if (this.agGridController) {
            this.agGridController.gridOptions.api.setRowData([]) // 아이템 초기화
        }
    }

    async saveOrder() {
        const formData = new FormData(this.formTarget)
        const method = this.methodInputTarget.value

        let submitUrl = this.urlValue
        if (method === "put") {
            submitUrl = `${this.urlValue}/${this.idInputTarget.value}`
            if (!this.changeReasonTarget.value) {
                alert("수정 사유를 기입해주세요.")
                this.changeReasonTarget.focus()
                return
            }
        }

        try {
            const response = await (method === "put" ? put(submitUrl, { body: formData }) : post(submitUrl, { body: formData }))
            const data = await response.json()

            if (response.ok && data.success) {
                alert(data.message)
                if (method === "post") {
                    this.ordNoDisplayTarget.value = data.ord_no // 채번된 번호 매핑
                    this.methodInputTarget.value = "put"
                    this.idInputTarget.value = data.ord_no
                    this.reasonGroupTarget.classList.remove("hidden")
                }
            } else {
                alert(data.message || "오류가 발생했습니다.")
            }
        } catch (error) {
            console.error(error)
            alert("서버 연결에 실패했습니다.")
        }
    }

    async cancelOrder() {
        const ordNo = this.idInputTarget.value
        if (!ordNo) {
            alert("취소할 오더가 선택되지 않았습니다.")
            return
        }

        const cancelReason = prompt("오더 취소 사유를 입력해주세요:")
        if (!cancelReason) {
            return
        }

        try {
            const cancelUrl = `${this.urlValue}/${ordNo}/cancel`
            const response = await post(cancelUrl, {
                body: JSON.stringify({ order: { cancel_reason: cancelReason } })
            })

            const data = await response.json()
            if (response.ok && data.success) {
                alert(data.message)
            } else {
                alert(data.message || "취소에 실패했습니다.")
            }
        } catch (e) {
            console.error(e)
            alert("오류가 발생했습니다.")
        }
    }

    // AG Grid Events
    addRow() {
        if (this.agGridController) {
            this.agGridController.gridOptions.api.applyTransaction({ add: [{}] })
        }
    }

    removeRow() {
        if (this.agGridController) {
            const selected = this.agGridController.gridOptions.api.getSelectedRows()
            if (selected.length === 0) {
                alert("삭제할 대상을 선택해주세요.")
                return
            }
            this.agGridController.gridOptions.api.applyTransaction({ remove: selected })
        }
    }

    // 수량 입력시 중량/부피 환산 Mock Logic
    onCellValueChanged(params) {
        if (params.colDef.field === "qty") {
            const qty = Number(params.newValue) || 0

            // 실제로는 DB에서 총중량, CBM을 가져와야 하나, 여기서는 
            // 아이템코드 길이나 임의 값 기반으로 생성한다고 Mocking 함.
            const mockTotWgt = 1.5
            const mockCbm = 2.0

            params.node.setDataValue("wgt", parseFloat((qty * mockTotWgt).toFixed(2)))
            params.node.setDataValue("vol", parseFloat((qty * mockCbm).toFixed(2)))
        }
    }
}
