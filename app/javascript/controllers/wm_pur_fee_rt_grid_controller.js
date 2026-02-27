import MasterDetailGridController from "controllers/master_detail_grid_controller"
import { rowDataFromGridEvent } from "controllers/grid/grid_event_manager"
import { isApiAlive, postJson, hasChanges, setManagerRowData, focusFirstRow, hasPendingChanges, blockIfPendingChanges, buildTemplateUrl } from "controllers/grid/grid_utils"
import { showAlert } from "components/ui/alert"

export default class extends MasterDetailGridController {
    static targets = [...MasterDetailGridController.targets, "masterGrid", "detailGrid", "selectedMasterLabel"]

    static values = {
        ...MasterDetailGridController.values,
        masterBatchUrl: String,
        detailBatchUrlTemplate: String,
        detailListUrlTemplate: String,
        selectedMaster: String
    }

    connect() {
        super.connect()
        this.detailGridController = null
        this.detailManager = null
    }

    disconnect() {
        if (this.detailManager) {
            this.detailManager.detach()
            this.detailManager = null
        }
        this.detailGridController = null
        super.disconnect()
    }

    // 마스터 그리드 설정
    configureManager() {
        return {
            pkFields: ["wrhs_exca_fee_rt_no"],
            fields: {
                work_pl_cd: "trimUpper",
                ctrt_cprtco_cd: "trimUpper",
                sell_buy_attr_cd: "trimUpper",
                pur_dept_cd: "trimUpper",
                pur_item_type: "trim",
                pur_item_cd: "trimUpper",
                pur_unit_clas_cd: "trim",
                pur_unit_cd: "trimUpper",
                use_yn: "trimUpperDefault:Y",
                auto_yn: "trimUpperDefault:N",
                rmk: "trim"
            },
            defaultRow: {
                wrhs_exca_fee_rt_no: "",
                work_pl_cd: "",
                ctrt_cprtco_cd: "",
                sell_buy_attr_cd: "",
                pur_dept_cd: "",
                pur_item_type: "",
                pur_item_cd: "",
                pur_unit_clas_cd: "",
                pur_unit_cd: "",
                use_yn: "Y",
                auto_yn: "N",
                rmk: ""
            },
            blankCheckFields: ["work_pl_cd", "ctrt_cprtco_cd", "sell_buy_attr_cd", "pur_dept_cd", "pur_item_type", "pur_item_cd", "pur_unit_clas_cd", "pur_unit_cd"],
            comparableFields: ["pur_item_type", "pur_item_cd", "pur_unit_clas_cd", "pur_unit_cd", "use_yn", "auto_yn", "rmk"],
            firstEditCol: "pur_item_type",
            pkLabels: { wrhs_exca_fee_rt_no: "창고정산요율번호" },
            onRowDataUpdated: () => {
                this.handleMasterRowDataUpdated({ resetTrackingManagers: [this.detailManager] })
            }
        }
    }

    // 디테일 그리드 설정
    configureDetailManager() {
        return {
            pkFields: ["lineno"],
            fields: {
                dcsn_yn: "trimUpperDefault:N",
                aply_strt_ymd: "trim",
                aply_end_ymd: "trim",
                aply_uprice: "number",
                cur_cd: "trim",
                std_work_qty: "number",
                aply_strt_qty: "number",
                aply_end_qty: "number",
                rmk: "trim"
            },
            defaultRow: {
                lineno: null,
                dcsn_yn: "N",
                aply_strt_ymd: new Date().toISOString().split('T')[0],
                aply_end_ymd: "9999-12-31",
                aply_uprice: 0,
                cur_cd: "KRW",
                std_work_qty: 0,
                aply_strt_qty: 0,
                aply_end_qty: 0,
                rmk: ""
            },
            blankCheckFields: ["aply_strt_ymd", "aply_end_ymd", "cur_cd", "aply_uprice", "std_work_qty"],
            comparableFields: ["dcsn_yn", "aply_strt_ymd", "aply_end_ymd", "aply_uprice", "cur_cd", "std_work_qty", "aply_strt_qty", "aply_end_qty", "rmk"],
            firstEditCol: "dcsn_yn",
            pkLabels: { lineno: "라인번호" }
        }
    }

    // 그리드 등록 분기
    detailGridConfigs() {
        return [
            {
                target: this.hasDetailGridTarget ? this.detailGridTarget : null,
                controllerKey: "detailGridController",
                managerKey: "detailManager",
                configMethod: "configureDetailManager"
            }
        ]
    }

    bindMasterGridEvents() {
        this.masterGridEvents.unbindAll()
        this.masterGridEvents.bind(this.manager?.api, "rowClicked", this.handleMasterRowClicked)
    }

    handleMasterRowClicked = (event) => {
        const rowData = rowDataFromGridEvent(this.manager?.api, event)
        if (!rowData || rowData.wrhs_exca_fee_rt_no === this.selectedMasterValue) return

        if (hasPendingChanges(this.detailManager)) {
            blockIfPendingChanges(() => this.selectMaster(rowData.wrhs_exca_fee_rt_no))
        } else {
            this.selectMaster(rowData.wrhs_exca_fee_rt_no)
        }
    }

    syncMasterSelectionAfterLoad() {
        if (!this.manager?.api) return

        if (this.manager.api.getDisplayedRowCount() === 0) {
            this.clearMasterSelection()
            return
        }

        let nodeToSelect = null
        if (this.selectedMasterValue) {
            this.manager.api.forEachNode(node => {
                if (node.data.wrhs_exca_fee_rt_no === this.selectedMasterValue) {
                    nodeToSelect = node
                }
            })
        }

        if (!nodeToSelect) {
            nodeToSelect = this.manager.api.getDisplayedRowAtIndex(0)
        }

        if (nodeToSelect) {
            nodeToSelect.setSelected(true)
            this.selectMaster(nodeToSelect.data.wrhs_exca_fee_rt_no)
        } else {
            this.clearMasterSelection()
        }
    }

    selectMaster(wrhs_exca_fee_rt_no) {
        if (!wrhs_exca_fee_rt_no) {
            this.clearMasterSelection()
            return
        }

        this.selectedMasterValue = wrhs_exca_fee_rt_no
        this.updateSelectedMasterLabel()
        this.loadDetailData(wrhs_exca_fee_rt_no)

        this.manager?.api?.forEachNode(node => {
            node.setSelected(node.data.wrhs_exca_fee_rt_no === wrhs_exca_fee_rt_no)
        })
    }

    clearMasterSelection() {
        this.selectedMasterValue = ""
        this.updateSelectedMasterLabel()
        if (this.detailManager?.api) {
            setManagerRowData(this.detailManager, [])
        }
    }

    updateSelectedMasterLabel() {
        if (this.hasSelectedMasterLabelTarget) {
            this.selectedMasterLabelTarget.textContent = this.selectedMasterValue
                ? `선택 정산요율: ${this.selectedMasterValue}`
                : "요율을 먼저 선택하세요."
        }
    }

    async loadDetailData(wrhsExcaFeeRtNo) {
        if (!this.detailGridController || !isApiAlive(this.detailGridController.api)) return

        if (!wrhsExcaFeeRtNo || wrhsExcaFeeRtNo.trim() === "") {
            setManagerRowData(this.detailManager, [])
            return
        }

        const url = buildTemplateUrl(this.detailListUrlTemplateValue, { pur_fee_rt_mng_id: wrhsExcaFeeRtNo })
        await this.detailGridController.loadData(url)
        this.detailManager?.resetTracking()
    }

    // --- Master CRUD Actions ---

    addMasterRow(event) {
        event?.preventDefault()
        if (!this.manager) return

        const searchForm = document.querySelector('[data-controller="search-form"]')
        const workPlCd = searchForm?.querySelector('[name="q[work_pl_cd]"]')?.value || ""
        const ctrtCprtcoCd = searchForm?.querySelector('[name="q[ctrt_cprtco_cd]"]')?.value || ""
        const sellBuyAttrCd = searchForm?.querySelector('[name="q[sell_buy_attr_cd]"]')?.value || ""

        const newRow = {
            ...this.manager.defaultRow,
            work_pl_cd: workPlCd,
            ctrt_cprtco_cd: ctrtCprtcoCd,
            sell_buy_attr_cd: sellBuyAttrCd,
            _id: `NEW_${Date.now()}`
        }

        this.manager.api.applyTransaction({ add: [newRow], addIndex: 0 })
        focusFirstRow(this.manager.api, "work_pl_cd")

        // 신규 행 선택
        this.selectMaster(newRow.wrhs_exca_fee_rt_no)
    }

    deleteMasterRows(event) {
        event?.preventDefault()
        if (!this.manager) return
        this.manager.deleteSelectedRows("매입요율")
    }

    async saveMasterRows(event) {
        event?.preventDefault()
        if (!this.manager) return

        // Master 저장 시 Detail 이 하나라도 있어야만 저장이 가능한지 여부는 UI/UX 편의에 따라 
        // 서버 Validation으로 떨어지도록 하거나 (현재 서버로직상 그렇지만)
        // Master-Detail 폼이 하나의 화면이므로 우선 Master 변경사항을 서버로 전파.

        const result = this.manager.getChanges()
        if (!hasChanges(result)) {
            showAlert("Info", "저장할 매입요율 변경사항이 없습니다.", "info")
            return
        }

        // 서버로 일괄 저장
        const response = await postJson(this.masterBatchUrlValue, result)
        if (response) {
            if (response.success) {
                showAlert("Success", "매입요율이 성공적으로 저장되었습니다.", "success")
                this.manager.resetTracking()
                this.dispatch("search", { target: document.querySelector('[data-controller="search-form"]') })
            } else {
                showAlert("Error", response.errors?.join("\n") || "저장 중 오류가 발생했습니다.", "error")
            }
        }
    }

    // --- Detail CRUD Actions ---

    addDetailRow(event) {
        event?.preventDefault()
        if (!this.detailManager?.api) return
        if (!this.selectedMasterValue) {
            showAlert("Warning", "매입요율을 먼저 선택해주세요.", "warning")
            return
        }

        const newRow = { ...this.detailManager.defaultRow, _id: `NEW_${Date.now()}` }
        this.detailManager.api.applyTransaction({ add: [newRow], addIndex: 0 })
        focusFirstRow(this.detailManager.api, this.detailManager.firstEditCol)
    }

    deleteDetailRows(event) {
        event?.preventDefault()
        if (!this.detailManager) return
        this.detailManager.deleteSelectedRows("매입요율 상세정보")
    }

    async saveDetailRows(event) {
        event?.preventDefault()
        if (!this.detailManager) return
        if (!this.selectedMasterValue) {
            showAlert("Warning", "매입요율을 먼저 선택해주세요.", "warning")
            return
        }

        const result = this.detailManager.getChanges()
        if (!hasChanges(result)) {
            showAlert("Info", "저장할 매입요율 상세 변경사항이 없습니다.", "info")
            return
        }

        const url = buildTemplateUrl(this.detailBatchUrlTemplateValue, { pur_fee_rt_mng_id: this.selectedMasterValue })
        const response = await postJson(url, result)

        if (response) {
            if (response.success) {
                showAlert("Success", "매입요율 상세가 성공적으로 저장되었습니다.", "success")
                this.detailManager.resetTracking()
                this.loadDetailData(this.selectedMasterValue)
            } else {
                showAlert("Error", response.errors?.join("\n") || "상세 저장 중 오류가 발생했습니다.", "error")
            }
        }
    }
}
