/**
 * code_grid_controller.js
 * 
 * [공통] BaseGridController를 상속하는 마스터-디테일(1:N) 구조의 투인원(2 in 1) 컨트롤러입니다.
 * - 좌측(혹은 위)엔 그룹코드(Master) 그리드, 우측엔 상세코드(Detail) 그리드가 공존합니다.
 * - 마스터 행을 클릭하면 하위 디테일 그리드가 Ajax로 재로딩됩니다.
 * - Master, Detail 각각 독립적인 C/U/D 행위를 할 수 있으며 저장 API도 각각 나뉩니다.
 */
import BaseGridController from "controllers/base_grid_controller"
import { showAlert, confirmAction } from "components/ui/alert"
import GridCrudManager from "controllers/grid/grid_crud_manager"
import { GridEventManager, resolveAgGridRegistration, rowDataFromGridEvent } from "controllers/grid/grid_event_manager"
import { isApiAlive, postJson, hasChanges, fetchJson, setManagerRowData, focusFirstRow, hasPendingChanges, blockIfPendingChanges, buildTemplateUrl, refreshSelectionLabel, registerGridInstance } from "controllers/grid/grid_utils"

export default class extends BaseGridController {
  // 타겟 확정 (2개의 거대한 그리드 컨테이너 및 텍스트 라벨)
  static targets = [...BaseGridController.targets, "masterGrid", "detailGrid", "selectedCodeLabel"]

  // 백엔드 엔드포인트 세팅
  static values = {
    ...BaseGridController.values,
    masterBatchUrl: String,             // 거시적인 1단계 그룹코드 저장 URL
    detailBatchUrlTemplate: String,     // 하위 상세코드 배열 저장 URL 템플릿 (':code' 가 치환됨)
    detailListUrlTemplate: String,      // 특정 부모를 선택했을때 긁어올 상세코드 조회 URL 템플릿
    selectedCode: String                // 현재 클릭되어 활성화중인 마스터 PK
  }

  connect() {
    super.connect()
    this.initialMasterSyncDone = false  // 화면 최초 진입 시, 맨 첫째 행을 강제로 포커싱하기 위한 락 
    this.masterGridEvents = new GridEventManager() // AG Grid의 각종 이벤트리스너 안전 해제 관리용
    this.detailGridController = null    // 디테일 쪽 네이티브 컨트롤러 캐싱용
    this.detailManager = null           // 디테일 쪽 독립 CRUD 매니저 캐싱용
  }

  disconnect() {
    this.masterGridEvents.unbindAll()

    if (this.detailManager) {
      this.detailManager.detach()
      this.detailManager = null
    }

    this.detailGridController = null
    super.disconnect()
  }

  // (오버라이드) 좌측 '그룹코드(Master)' 쪽의 CRUD 명세.
  configureManager() {
    return {
      pkFields: ["code"],
      fields: {
        code: "trim",
        code_name: "trim",
        sys_sctn_cd: "trimUpper",
        rmk: "trim",
        use_yn: "trimUpperDefault:Y"
      },
      defaultRow: { code: "", code_name: "", sys_sctn_cd: "", rmk: "", use_yn: "Y" },
      blankCheckFields: ["code", "code_name"],
      comparableFields: ["code_name", "sys_sctn_cd", "rmk", "use_yn"],
      firstEditCol: "code",
      pkLabels: { code: "코드" },
      // 마스터 그리드가 Ajax로 확 새로 그려졌을 때 진입되는 콜백
      onRowDataUpdated: () => {
        this.detailManager?.resetTracking()

        if (!this.initialMasterSyncDone && isApiAlive(this.detailManager?.api)) {
          this.initialMasterSyncDone = true
          this.syncMasterSelectionAfterLoad() // 최상단 행 오토 포커스 호출
        }
      }
    }
  }

  // (자체추가) 우측 '상세코드(Detail)' 쪽의 CRUD 명세.
  configureDetailManager() {
    return {
      pkFields: ["detail_code"],
      fields: {
        detail_code: "trim",
        detail_code_name: "trim",
        short_name: "trim",
        upper_code: "trimUpper",
        upper_detail_code: "trimUpper",
        rmk: "trim",
        attr1: "trim",
        attr2: "trim",
        attr3: "trim",
        attr4: "trim",
        attr5: "trim",
        sort_order: "number",
        use_yn: "trimUpperDefault:Y"
      },
      defaultRow: {
        code: "", // 외래키로 마스터 코드 주입 필요
        detail_code: "",
        detail_code_name: "",
        short_name: "",
        upper_code: "",
        upper_detail_code: "",
        rmk: "",
        attr1: "",
        attr2: "",
        attr3: "",
        attr4: "",
        attr5: "",
        sort_order: 0,
        use_yn: "Y"
      },
      blankCheckFields: ["detail_code", "detail_code_name"],
      comparableFields: ["detail_code_name", "short_name", "upper_code", "upper_detail_code", "rmk", "attr1", "attr2", "attr3", "attr4", "attr5", "sort_order", "use_yn"],
      firstEditCol: "detail_code",
      pkLabels: { detail_code: "상세코드" }
    }
  }

  // Base의 DOM 연결 이벤트를 가로채서, 마스터냐 디테일이냐에 따라 관리자를 2가닥으로 물 물려줌
  registerGrid(event) {
    registerGridInstance(event, this, [
      { target: this.hasMasterGridTarget ? this.masterGridTarget : null, isMaster: true, setup: (e) => super.registerGrid(e) },
      { target: this.hasDetailGridTarget ? this.detailGridTarget : null, controllerKey: "detailGridController", managerKey: "detailManager", configMethod: "configureDetailManager" }
    ], () => {
      this.bindMasterGridEvents()
      if (!this.initialMasterSyncDone) {
        this.initialMasterSyncDone = true
        this.syncMasterSelectionAfterLoad()
      }
    })
  }

  // 마스터 행 쪼기(클릭)나 방향키 기반 셀 이동 시 항상 감지 
  bindMasterGridEvents() {
    this.masterGridEvents.unbindAll()
    this.masterGridEvents.bind(this.manager?.api, "rowClicked", this.handleMasterRowClicked)
    this.masterGridEvents.bind(this.manager?.api, "cellFocused", this.handleMasterCellFocused)
  }

  handleMasterRowClicked = async (event) => {
    const rowData = rowDataFromGridEvent(this.manager?.api, event)
    await this.handleMasterRowChange(rowData)
  }

  handleMasterCellFocused = async (event) => {
    const rowData = rowDataFromGridEvent(this.manager?.api, event)
    if (!rowData) return

    await this.handleMasterRowChange(rowData)
  }

  // 마스터 포커스가 바뀔 때 연쇄동작의 심볼
  async handleMasterRowChange(rowData) {
    if (!isApiAlive(this.detailManager?.api)) return

    const code = rowData?.code
    // 아직 작성중인 새 그룹이거나 삭제대기, 값이 없는 상태라면 
    // 하위조회가 불가능하므로 빈 디테일 그리드로 비워둠
    if (!code || rowData?.__is_deleted || rowData?.__is_new) {
      this.selectedCodeValue = code || ""
      this.refreshSelectedCodeLabel()
      this.clearDetailRows()
      return
    }

    // 정상적으로 DB기존재하는 코드를 짚었다면 디테일 비동기 조회
    this.selectedCodeValue = code
    this.refreshSelectedCodeLabel()
    await this.loadDetailRows(code)
  }

  // --- HTML 버튼 바인딩 파트 --- 

  addMasterRow() {
    if (!this.manager) return

    const txResult = this.manager.addRow()
    const addedNode = txResult?.add?.[0]
    if (addedNode?.data) {
      // 행 추가되자마자 포커스를 그쪽으로 옮기고, 내부적으로 디테일은 백지화 됨
      this.handleMasterRowChange(addedNode.data)
    }
  }

  deleteMasterRows() {
    if (!this.manager) return
    this.manager.deleteRows()
  }

  async saveMasterRows() {
    if (!this.manager) return

    this.manager.stopEditing()
    const operations = this.manager.buildOperations()
    if (!hasChanges(operations)) {
      showAlert("변경된 데이터가 없습니다.")
      return
    }

    const ok = await postJson(this.masterBatchUrlValue, operations)
    if (!ok) return

    showAlert("코드 데이터가 저장되었습니다.")
    await this.reloadMasterRows()
  }

  // 마스터 저장 성공시 화면 리셋 후 첫줄 오토포커스
  async reloadMasterRows() {
    if (!isApiAlive(this.manager?.api)) return
    if (!this.gridController?.urlValue) return

    try {
      const rows = await fetchJson(this.gridController.urlValue)
      setManagerRowData(this.manager, rows)
      await this.syncMasterSelectionAfterLoad()
    } catch {
      showAlert("코드 목록 조회에 실패했습니다.")
    }
  }

  // 0번째 행 강제 포커스
  async syncMasterSelectionAfterLoad() {
    if (!isApiAlive(this.manager?.api) || !isApiAlive(this.detailManager?.api)) return

    const firstData = focusFirstRow(this.manager.api)
    if (!firstData) {
      this.selectedCodeValue = ""
      this.refreshSelectedCodeLabel()
      this.clearDetailRows()
      return
    }

    await this.handleMasterRowChange(firstData)
  }

  // ===================== [Detail Area] =========================

  addDetailRow() {
    if (!this.detailManager) return
    if (this.blockDetailActionIfMasterChanged()) return // 마스터가 저장되어 결함없는 상태인지 확인

    if (!this.selectedCodeValue) {
      showAlert("코드를 먼저 선택해주세요.")
      return
    }

    // 그룹코드를 강제할당하여 추가
    this.detailManager.addRow({ code: this.selectedCodeValue })
  }

  deleteDetailRows() {
    if (!this.detailManager) return
    if (this.blockDetailActionIfMasterChanged()) return

    this.detailManager.deleteRows()
  }

  async saveDetailRows() {
    if (!this.detailManager) return
    if (this.blockDetailActionIfMasterChanged()) return

    if (!this.selectedCodeValue) {
      showAlert("코드를 먼저 선택해주세요.")
      return
    }

    this.detailManager.stopEditing()
    const operations = this.detailManager.buildOperations()
    if (!hasChanges(operations)) {
      showAlert("변경된 데이터가 없습니다.")
      return
    }

    // /codes/:code/details 형식 치환
    const batchUrl = buildTemplateUrl(this.detailBatchUrlTemplateValue, ":code", this.selectedCodeValue)
    const ok = await postJson(batchUrl, operations)
    if (!ok) return

    showAlert("상세코드 데이터가 저장되었습니다.")
    await this.loadDetailRows(this.selectedCodeValue)
  }

  async loadDetailRows(code) {
    if (!isApiAlive(this.detailManager?.api)) return

    if (!code) {
      this.clearDetailRows()
      return
    }

    try {
      const url = buildTemplateUrl(this.detailListUrlTemplateValue, ":code", code)
      const rows = await fetchJson(url)
      setManagerRowData(this.detailManager, rows)
    } catch {
      showAlert("상세코드 목록 조회에 실패했습니다.")
    }
  }

  clearDetailRows() {
    setManagerRowData(this.detailManager, [])
  }

  // 상단 부제목 영역에 가시화용
  refreshSelectedCodeLabel() {
    if (!this.hasSelectedCodeLabelTarget) return
    refreshSelectionLabel(this.selectedCodeLabelTarget, this.selectedCodeValue, "코드", "코드를 먼저 선택해주세요.")
  }

  // 마스터쪽에 C/U/D가 발생한 상태인지 체크 (종속성 무결성 보호장치용)
  hasMasterPendingChanges() {
    return hasPendingChanges(this.manager)
  }

  blockDetailActionIfMasterChanged() {
    return blockIfPendingChanges(this.manager, "마스터 코드")
  }
}
