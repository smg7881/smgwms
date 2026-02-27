/**
 * code_grid_controller.js
 * 
 * [공통] BaseGridController를 상속하는 마스터-디테일(1:N) 구조의 투인원(2 in 1) 컨트롤러입니다.
 * - 좌측(혹은 위)엔 그룹코드(Master) 그리드, 우측엔 상세코드(Detail) 그리드가 공존합니다.
 * - 마스터 행을 클릭하면 하위 디테일 그리드가 Ajax로 재로딩됩니다.
 * - Master, Detail 각각 독립적인 C/U/D 행위를 할 수 있으며 저장 API도 각각 나뉩니다.
 */
import MasterDetailGridController from "controllers/master_detail_grid_controller"
import { showAlert } from "components/ui/alert"
import { isApiAlive, fetchJson, setManagerRowData, hasPendingChanges, blockIfPendingChanges, buildTemplateUrl, refreshSelectionLabel } from "controllers/grid/grid_utils"

export default class extends MasterDetailGridController {
  // 타겟 확정 (2개의 거대한 그리드 컨테이너 및 텍스트 라벨)
  static targets = [...MasterDetailGridController.targets, "masterGrid", "detailGrid", "selectedCodeLabel"]

  // 백엔드 엔드포인트 세팅
  static values = {
    ...MasterDetailGridController.values,
    masterBatchUrl: String,             // 거시적인 1단계 그룹코드 저장 URL
    detailBatchUrlTemplate: String,     // 하위 상세코드 배열 저장 URL 템플릿 (':code' 가 치환됨)
    detailListUrlTemplate: String,      // 특정 부모를 선택했을때 긁어올 상세코드 조회 URL 템플릿
    selectedCode: String                // 현재 클릭되어 활성화중인 마스터 PK
  }

  connect() {
    super.connect()
    this.detailGridController = null    // 디테일 쪽 네이티브 컨트롤러 캐싱용
    this.detailManager = null           // 디테일 쪽 독립 CRUD 매니저 캐싱용
  }

  disconnect() {
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
        this.handleMasterRowDataUpdated({ resetTrackingManagers: [this.detailManager] })
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

  isDetailReady() {
    return isApiAlive(this.detailManager?.api)
  }

  // 마스터 포커스가 바뀔 때 연쇄동작의 심볼
  async handleMasterRowChange(rowData) {
    await this.syncMasterDetailByCode(rowData, {
      codeField: "code",
      setSelectedCode: (code) => { this.selectedCodeValue = code },
      refreshLabel: () => this.refreshSelectedCodeLabel(),
      clearDetails: () => this.clearDetailRows(),
      loadDetails: (code) => this.loadDetailRows(code)
    })
  }

  // --- HTML 버튼 바인딩 파트 --- 

  addMasterRow() {
    if (!this.manager) return

    const txResult = this.manager.addRow()
    const addedNode = txResult?.add?.[0]
    if (addedNode?.data) {
      // 행 추가되자마자 포커스를 그쪽으로 옮기고, 내부적으로 디테일은 백지화 됨
      this.handleMasterRowChangeOnce(addedNode.data, { force: true })
    }
  }

  deleteMasterRows() {
    if (!this.manager) return
    this.manager.deleteRows()
  }

  async saveMasterRows() {
    await this.saveRowsWith({
      manager: this.manager,
      batchUrl: this.batchUrlValue,
      saveMessage: this.saveMessage,
      onSuccess: () => this.afterSaveSuccess()
    })
  }

  get batchUrlValue() {
    return this.masterBatchUrlValue
  }

  get saveMessage() {
    return "코드 데이터가 저장되었습니다."
  }

  async afterSaveSuccess() {
    await this.reloadMasterRows()
  }

  // 마스터 저장 성공시 화면 리셋 후 첫줄 오토포커스
  async reloadMasterRows() {
    await super.reloadMasterRows({ errorMessage: "코드 목록 조회에 실패했습니다." })
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

    const batchUrl = buildTemplateUrl(this.detailBatchUrlTemplateValue, ":code", this.selectedCodeValue)
    await this.saveRowsWith({
      manager: this.detailManager,
      batchUrl,
      saveMessage: "상세코드 데이터가 저장되었습니다.",
      onSuccess: () => this.loadDetailRows(this.selectedCodeValue)
    })
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
