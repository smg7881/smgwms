import BaseGridController from "controllers/base_grid_controller"
import { GridEventManager, rowDataFromGridEvent } from "controllers/grid/grid_event_manager"
import { isApiAlive, focusFirstRow, setManagerRowData } from "controllers/grid/grid_utils"
import { registerGridInstance } from "controllers/grid/core/grid_registration"

/**
 * MasterDetailGridController
 *
 * 마스터-디테일 구조 화면의 공통 베이스 컨트롤러입니다.
 *
 * 핵심 동작:
 * 1. 조회 버튼 클릭 시 → 마스터/디테일 그리드 clear
 *    → 서버 조회 후 마스터 데이터 로드
 *    → onRowDataUpdated 콜백에서 첫 행 선택 + 디테일 조회
 * 2. 마스터 행 클릭/이동/키보드 → 해당 행으로 디테일 조회
 *
 * 하위 컨트롤러 오버라이드 포인트:
 * - detailGridConfigs()   디테일 그리드 등록 설정
 * - isDetailReady()       디테일 영역 준비 상태 확인
 * - handleMasterRowChange(rowData) 마스터 행 변경 시 디테일 처리
 * - clearAllDetails()     상세 그리드 데이터 전체 비우기
 */
export default class MasterDetailGridController extends BaseGridController {

  connect() {
    super.connect()
    this.masterGridEvents = new GridEventManager()
    // 조회 직전 clear를 위해 search_form_controller가 발행하는 이벤트를 수신합니다.
    this._beforeSearchHandler = () => this.handleBeforeSearch()
    document.addEventListener("grid:before-search", this._beforeSearchHandler)
  }

  disconnect() {
    document.removeEventListener("grid:before-search", this._beforeSearchHandler)
    this._beforeSearchHandler = null
    this.masterGridEvents?.unbindAll()
    super.disconnect()
  }

  // ─── 그리드 등록 ───

  registerGrid(event) {
    registerGridInstance(event, this, this.masterDetailGridConfigs(), () => {
      this.onMasterDetailGridsReady()
    })
  }

  masterDetailGridConfigs() {
    return [
      {
        target: this.hasMasterGridTarget ? this.masterGridTarget : null,
        isMaster: true,
        setup: (event) => super.registerGrid(event)
      },
      ...this.detailGridConfigs()
    ]
  }

  // 하위 클래스 훅: 디테일 그리드 등록 설정을 반환합니다.
  detailGridConfigs() {
    return []
  }

  // ─── 마스터/디테일 준비 완료 ───

  onMasterDetailGridsReady() {
    this.bindMasterGridEvents()
    // 그리드에 이미 데이터가 있으면 첫 행으로 디테일 조회
    this.selectFirstMasterRow()
  }

  // ─── 마스터 이벤트 바인딩 ───

  bindMasterGridEvents() {
    this.masterGridEvents.unbindAll()
    this.masterGridEvents.bind(this.manager?.api, "rowClicked", this.handleMasterGridEvent)
    this.masterGridEvents.bind(this.manager?.api, "cellFocused", this.handleMasterGridEvent)
  }

  // 마스터 그리드 이벤트(rowClicked, cellFocused)를 처리합니다.
  handleMasterGridEvent = async (event) => {
    const rowData = rowDataFromGridEvent(this.manager?.api, event)
    if (!rowData) return
    await this.handleMasterRowChange(rowData)
  }

  // ─── 핵심 로직 ───

  // 마스터 그리드에서 첫 번째 행을 선택하고 디테일을 조회합니다.
  // onRowDataUpdated 콜백, 그리드 준비 완료 시점에서 호출합니다.
  selectFirstMasterRow() {
    if (!isApiAlive(this.manager?.api) || !this.isDetailReady()) return

    const firstData = focusFirstRow(this.manager.api, { ensureVisible: true, select: false })
    if (!firstData) {
      // 마스터가 비어 있으면 디테일도 비웁니다.
      this.handleMasterRowChange(null)
      return
    }
    this.handleMasterRowChange(firstData)
  }

  // 하위 클래스 훅: 마스터 행 변경 시 디테일 처리를 구현합니다.
  // rowData가 null이면 디테일을 비워야 합니다.
  async handleMasterRowChange(rowData) {
    // 하위 컨트롤러에서 오버라이드
  }

  // ─── 조회 직전 clear ───

  // 조회 버튼 클릭 직전(grid:before-search) 이벤트 처리
  handleBeforeSearch() {
    this.clearMasterGrid()
    this.clearAllDetails()
  }

  // 마스터 그리드 데이터를 비웁니다.
  clearMasterGrid() {
    if (isApiAlive(this.manager?.api)) {
      setManagerRowData(this.manager, [])
    }
  }

  // 하위 클래스 훅: 모든 상세 그리드 데이터를 비웁니다.
  clearAllDetails() { }

  // ─── 하위 클래스 오버라이드 포인트 ───

  // 디테일 영역 준비 상태 확인 (기본값: 항상 준비됨)
  isDetailReady() {
    return true
  }
}