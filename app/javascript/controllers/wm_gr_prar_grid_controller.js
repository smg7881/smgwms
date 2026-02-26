import BaseGridController from "controllers/base_grid_controller"
import { GridEventManager, resolveAgGridRegistration, rowDataFromGridEvent } from "controllers/grid/grid_event_manager"
import { isApiAlive, postJson, setManagerRowData, buildTemplateUrl } from "controllers/grid/grid_utils"
import { showAlert, confirmAction } from "components/ui/alert"
import { switchTab, activateTab } from "controllers/ui_utils"
export default class extends BaseGridController {
    static targets = [
        ...BaseGridController.targets,
        "masterGrid", "detailGrid", "execRsltGrid",
        "selectedMasterLabel",
        "tabButton", "tabPanel"
    ]

    static values = {
        ...BaseGridController.values,
        detailListUrlTemplate: String,
        execResultUrlTemplate: String,
        saveUrlTemplate: String,
        confirmUrlTemplate: String,
        cancelUrlTemplate: String,
        stagedLocationsUrl: String,
        selectedMaster: String
    }

    connect() {
        super.connect()
        this.activeTab = "detail"
        this.#masterGridEvents = new GridEventManager()
        this.#detailGridController = null
        this.#execRsltGridController = null
        this.#stagedLocations = []
        this.#selectedMasterData = null
        this.#loadStagedLocations()
        this.activateTab("detail")
    }

    disconnect() {
        this.#masterGridEvents.unbindAll()
        this.#detailGridController = null
        this.#execRsltGridController = null
        super.disconnect()
    }

    // --- 그리드 설정 ---

    configureManager() {
        return {
            pkFields: ["gr_prar_no"],
            fields: {
                car_no: "trim",
                driver_telno: "trim",
                rmk: "trim"
            },
            defaultRow: {},
            blankCheckFields: [],
            comparableFields: ["car_no", "driver_telno", "rmk"],
            firstEditCol: "car_no",
            pkLabels: { gr_prar_no: "입고예정번호" }
        }
    }

    // --- 그리드 등록 분기 ---

    registerGrid(event) {
        const registration = resolveAgGridRegistration(event)
        if (!registration) return

        const { gridElement, api, controller } = registration

        if (gridElement === this.masterGridTarget) {
            super.registerGrid(event)
            this.#bindMasterRowClick()
            this.#syncMasterSelectionAfterLoad()
        } else if (gridElement === this.detailGridTarget) {
            this.#detailGridController = controller
        } else if (gridElement === this.execRsltGridTarget) {
            this.#execRsltGridController = controller
        }
    }

    // --- 마스터 행 선택 ---

    #bindMasterRowClick() {
        this.#masterGridEvents.unbindAll()
        this.#masterGridEvents.bind(this.manager?.api, "rowClicked", this.#handleMasterRowClicked)
    }

    #handleMasterRowClicked = (event) => {
        const rowData = rowDataFromGridEvent(event)
        if (!rowData || rowData.gr_prar_no === this.selectedMasterValue) return
        this.#selectMaster(rowData)
    }

    #syncMasterSelectionAfterLoad() {
        if (!this.manager?.api) return

        const displayedCount = this.manager.api.getDisplayedRowCount()
        if (displayedCount === 0) {
            this.#clearMasterSelection()
            return
        }

        let nodeToSelect = null
        if (this.selectedMasterValue) {
            this.manager.api.forEachNode(node => {
                if (node.data?.gr_prar_no === this.selectedMasterValue) {
                    nodeToSelect = node
                }
            })
        }

        if (!nodeToSelect) {
            nodeToSelect = this.manager.api.getDisplayedRowAtIndex(0)
        }

        if (nodeToSelect) {
            nodeToSelect.setSelected(true)
            this.#selectMaster(nodeToSelect.data)
        } else {
            this.#clearMasterSelection()
        }
    }

    #selectMaster(rowData) {
        if (!rowData?.gr_prar_no) {
            this.#clearMasterSelection()
            return
        }

        this.selectedMasterValue = rowData.gr_prar_no
        this.#selectedMasterData = rowData
        this.#updateSelectedMasterLabel()
        this.#loadDetailData(rowData.gr_prar_no)
        this.#loadExecResultData(rowData.gr_prar_no)

        // 마스터 행 하이라이트
        this.manager?.api?.forEachNode(node => {
            node.setSelected(node.data?.gr_prar_no === rowData.gr_prar_no)
        })
    }

    #clearMasterSelection() {
        this.selectedMasterValue = ""
        this.#selectedMasterData = null
        this.#updateSelectedMasterLabel()
        this.#setDetailRowData([])
        this.#setExecRsltRowData([])
    }

    #updateSelectedMasterLabel() {
        if (this.hasSelectedMasterLabelTarget) {
            this.selectedMasterLabelTarget.textContent = this.selectedMasterValue
                ? `선택 입고예정: ${this.selectedMasterValue}`
                : "입고예정을 먼저 선택하세요."
        }
    }

    // --- 상세 데이터 로드 ---

    async #loadDetailData(grPrarNo) {
        if (!grPrarNo || !this.#detailGridController) return

        const url = buildTemplateUrl(this.detailListUrlTemplateValue, { gr_prar_id: grPrarNo })
        try {
            await this.#detailGridController.loadData(url)
            // 로케이션 컬럼 옵션 업데이트
            this.#updateLocationColumn()
        } catch (e) {
            console.error("[입고예정상세] 로드 오류:", e)
        }
    }

    async #loadExecResultData(grPrarNo) {
        if (!grPrarNo || !this.#execRsltGridController) return

        const url = buildTemplateUrl(this.execResultUrlTemplateValue, { gr_prar_id: grPrarNo })
        try {
            await this.#execRsltGridController.loadData(url)
        } catch (e) {
            console.error("[입고처리내역] 로드 오류:", e)
        }
    }

    #setDetailRowData(rows) {
        if (isApiAlive(this.#detailGridController?.api)) {
            this.#detailGridController.api.setGridOption("rowData", rows)
        }
    }

    #setExecRsltRowData(rows) {
        if (isApiAlive(this.#execRsltGridController?.api)) {
            this.#execRsltGridController.api.setGridOption("rowData", rows)
        }
    }

    // --- STAGED 로케이션 로드 ---

    async #loadStagedLocations() {
        const workplCd = document.querySelector('[name="q[workpl_cd]"]')?.value || ""
        if (!workplCd) return

        try {
            const resp = await fetch(`${this.stagedLocationsUrlValue}&workpl_cd=${encodeURIComponent(workplCd)}`)
            if (resp.ok) {
                const data = await resp.json()
                this.#stagedLocations = data.map(d => d.value)
                this.#updateLocationColumn()
            }
        } catch (e) {
            console.error("[STAGED 로케이션] 로드 오류:", e)
        }
    }

    #updateLocationColumn() {
        const api = this.#detailGridController?.api
        if (!isApiAlive(api) || this.#stagedLocations.length === 0) return

        const colDef = api.getColumnDefs()?.find(c => c.field === "gr_loc_cd")
        if (colDef) {
            colDef.cellEditorParams = { values: this.#stagedLocations }
            api.setGridOption("columnDefs", api.getColumnDefs())
        }
    }

    // --- 탭 전환 ---

    switchTab(event) {
        switchTab(event, this)
        const tab = this.activeTab

        // AG Grid resize (숨겨진 상태에서 나타날 때 필요)
        setTimeout(() => {
            if (tab === "detail") {
                this.#detailGridController?.api?.sizeColumnsToFit()
            } else if (tab === "exec") {
                this.#execRsltGridController?.api?.sizeColumnsToFit()
            }
        }, 50)
    }

    activateTab(tab) {
        activateTab(tab, this)

        // AG Grid resize (숨겨진 상태에서 나타날 때 필요)
        setTimeout(() => {
            if (tab === "detail") {
                this.#detailGridController?.api?.sizeColumnsToFit()
            } else if (tab === "exec") {
                this.#execRsltGridController?.api?.sizeColumnsToFit()
            }
        }, 50)
    }

    // --- 저장 버튼 (입고내역저장) ---

    async saveGr(event) {
        event?.preventDefault()

        if (!this.selectedMasterValue) {
            showAlert("Warning", "입고예정을 먼저 선택해주세요.", "warning")
            return
        }

        const api = this.#detailGridController?.api
        if (!isApiAlive(api)) return

        // 그리드에서 편집 중인 셀 종료
        api.stopEditing()

        // 모든 행 데이터 수집
        const rows = []
        api.forEachNode(node => {
            if (node.data) rows.push(node.data)
        })

        const hasInput = rows.some(r => parseFloat(r.gr_qty) > 0)
        if (!hasInput) {
            showAlert("Warning", "입고물량이 입력된 행이 없습니다.", "warning")
            return
        }

        // 음수 검증
        const negRow = rows.find(r => parseFloat(r.gr_qty) < 0)
        if (negRow) {
            showAlert("Error", `라인 ${negRow.lineno}: 입고물량은 음수를 입력할 수 없습니다.`, "error")
            return
        }

        const url = buildTemplateUrl(this.saveUrlTemplateValue, { gr_prar_id: this.selectedMasterValue })
        const response = await postJson(url, { rows: rows })

        if (response?.success) {
            showAlert("Success", "입고내역이 저장되었습니다.", "success")
            this.#loadDetailData(this.selectedMasterValue)
            this.#loadExecResultData(this.selectedMasterValue)
            // 마스터 그리드 갱신
            this.dispatch("search", { target: document.querySelector('[data-controller="search-form"]') })
        } else {
            showAlert("Error", response?.errors?.join("\n") || "저장 중 오류가 발생했습니다.", "error")
        }
    }

    // --- 입고확정 버튼 ---

    async confirmGr(event) {
        event?.preventDefault()

        if (!this.selectedMasterValue) {
            showAlert("Warning", "입고예정을 먼저 선택해주세요.", "warning")
            return
        }

        const masterData = this.#selectedMasterData
        if (masterData?.gr_stat_cd !== "20") {
            showAlert("Warning", "입고확정불가: 입고상태가 '입고처리(20)' 상태일 때만 확정이 가능합니다.", "warning")
            return
        }

        const ok = await confirmAction("입고확정", `입고예정번호 [${this.selectedMasterValue}]을 확정 처리하시겠습니까?`)
        if (!ok) return

        const url = buildTemplateUrl(this.confirmUrlTemplateValue, { gr_prar_id: this.selectedMasterValue })
        const response = await postJson(url, { gr_prar_no: this.selectedMasterValue })

        if (response?.success) {
            showAlert("Success", "입고확정 처리가 완료되었습니다.", "success")
            this.dispatch("search", { target: document.querySelector('[data-controller="search-form"]') })
        } else {
            showAlert("Error", response?.errors?.join("\n") || "입고확정 처리 중 오류가 발생했습니다.", "error")
        }
    }

    // --- 입고취소 버튼 ---

    async cancelGr(event) {
        event?.preventDefault()

        if (!this.selectedMasterValue) {
            showAlert("Warning", "입고예정을 먼저 선택해주세요.", "warning")
            return
        }

        const ok = await confirmAction("입고취소", `입고예정번호 [${this.selectedMasterValue}]를 취소 처리하시겠습니까?\n취소 시 생성된 재고가 차감됩니다.`)
        if (!ok) return

        const url = buildTemplateUrl(this.cancelUrlTemplateValue, { gr_prar_id: this.selectedMasterValue })
        const response = await postJson(url, { gr_prar_no: this.selectedMasterValue })

        if (response?.success) {
            showAlert("Success", "입고취소 처리가 완료되었습니다.", "success")
            this.#clearMasterSelection()
            this.dispatch("search", { target: document.querySelector('[data-controller="search-form"]') })
        } else {
            showAlert("Error", response?.errors?.join("\n") || "입고취소 처리 중 오류가 발생했습니다.", "error")
        }
    }

    // --- Private fields ---
    activeTab = "detail"
    #masterGridEvents = null
    #detailGridController = null
    #execRsltGridController = null
    #stagedLocations = []
    #selectedMasterData = null
}
