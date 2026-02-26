/**
 * zone_grid_controller.js
 * 
 * [공통] BaseGridController 상속: 좌-우 화면 분할 방식의 "마스터-디테일(Area -> Zone)" 관리를 다룹니다.
 * - 좌측(마스터): AreaGrid (이 그리드는 본 컨트롤러에서 값을 '읽기'만 하고 이벤트를 추적함)
 * - 우측(디테일): ZoneGrid (독자적인 CRUD 매니저를 생성하여 할당하고, Area에 종속된 Zone을 저장함)
 */
import BaseGridController from "controllers/base_grid_controller"
import { showAlert, confirmAction } from "components/ui/alert"
import GridCrudManager from "controllers/grid/grid_crud_manager"
import { GridEventManager, resolveAgGridRegistration, rowDataFromGridEvent } from "controllers/grid/grid_event_manager"
import { isApiAlive, postJson, hasChanges, hideNoRowsOverlay, fetchJson, setManagerRowData, setGridRowData, refreshSelectionLabel, buildCompositeKey } from "controllers/grid/grid_utils"

export default class extends BaseGridController {
  static targets = ["areaGrid", "zoneGrid", "selectedAreaLabel"]

  static values = {
    zonesUrl: String, // 특정 Area에 속해있는 Zone 목록을 불러오는 API 엔드포인트
    batchUrl: String  // Zone C/U/D 변경사항을 한방에 서버로 커밋하는 API 엔드포인트
  }

  connect() {
    super.connect()
    this.selectedArea = null // 현재 선택된 부모(Area) 행의 데이터 캐싱 객체
    this.areaApi = null      // 마스터 그리드 API
    this.zoneApi = null      // 디테일 그리드 API
    this.areaGridController = null
    this.zoneGridController = null
    this.zoneManager = null // 디테일 그리드를 독자적으로 통제할 관리자
    this.areaGridEvents = new GridEventManager()
  }

  disconnect() {
    // 메모리 누수 방지 이벤트 파괴 및 DOM 종속성 클리닝
    this.areaGridEvents.unbindAll()

    if (this.zoneManager) {
      this.zoneManager.detach()
      this.zoneManager = null
    }

    this.selectedArea = null
    this.areaApi = null
    this.zoneApi = null
    this.areaGridController = null
    this.zoneGridController = null
    super.disconnect()
  }

  // 양쪽 그리드가 DOM에 렌더링되면서 차례차례 이벤트를 발사할때 식별해서 할당함
  registerGrid(event) {
    const registration = resolveAgGridRegistration(event)
    if (!registration) return

    const { gridElement, api, controller } = registration

    if (gridElement === this.areaGridTarget) {
      this.areaApi = api
      this.areaGridController = controller
    } else if (gridElement === this.zoneGridTarget) {
      // Zone 쪽에는 별도의 매니저 인스턴스를 주입시켜줘야 CRUD 연산이 가능함
      if (this.zoneManager) {
        this.zoneManager.detach()
      }
      this.zoneApi = api
      this.zoneGridController = controller

      // Zone의 CRUD 규격 정의
      this.zoneManager = new GridCrudManager({
        pkFields: ["workpl_cd", "area_cd", "zone_cd"], // 부모 복합키 + 자기키
        fields: {
          workpl_cd: "trimUpper",
          area_cd: "trimUpper",
          zone_cd: "trimUpper",
          zone_nm: "trim",
          zone_desc: "trim",
          use_yn: "trimUpperDefault:Y"
        },
        defaultRow: { workpl_cd: "", area_cd: "", zone_cd: "", zone_nm: "", zone_desc: "", use_yn: "Y" },
        blankCheckFields: ["zone_cd", "zone_nm"],
        comparableFields: ["zone_nm", "zone_desc", "use_yn"],
        firstEditCol: "zone_cd",
        pkLabels: { zone_cd: "Zone 코드" }
      })
      this.zoneManager.attach(api) // Grid 와 Manager 결합
    }

    // 초기화 완료 시 양측 이벤트 릴레이 바인딩 시작
    if (this.areaApi && this.zoneApi) {
      this.bindGridEvents()
      this.refreshSelectedAreaLabel()
    }
  }

  bindGridEvents() {
    this.areaGridEvents.unbindAll()
    // 부모(Area) 쪽에서 선택이 넘어갈 때의 트리거들
    this.areaGridEvents.bind(this.areaApi, "rowClicked", this.handleAreaRowClicked)
    this.areaGridEvents.bind(this.areaApi, "cellFocused", this.handleAreaCellFocused)
    // 부모(Area) 그리드 자체가 완전히 데이터가 바뀌었을 때 (예: 검색, 초기조회 등)
    this.areaGridEvents.bind(this.areaApi, "rowDataUpdated", this.handleAreaRowDataUpdated)
  }

  // Row 클릭
  handleAreaRowClicked = (event) => {
    this.selectArea(rowDataFromGridEvent(this.areaApi, event))
  }

  // 키보드 등으로 커서 이동 포커스
  handleAreaCellFocused = (event) => {
    this.selectArea(rowDataFromGridEvent(this.areaApi, event))
  }

  // 데이터 전체 리다이렉트
  handleAreaRowDataUpdated = () => {
    this.selectedArea = null
    this.refreshSelectedAreaLabel()
    this.clearZoneGrid() // 부모 정보가 날아갔으니 자식은 무조건 초기화
  }

  // 마스터 행이 지정되었을때 핵심 State 갱신 및 조회 릴레이
  selectArea(areaRow) {
    const workplCd = areaRow?.workpl_cd
    const areaCd = areaRow?.area_cd

    // 아직 DB 반영안된 더미 Area를 눌렀거나 코드가 없다면 조회 중지
    if (!workplCd || !areaCd) {
      this.selectedArea = null
      this.refreshSelectedAreaLabel()
      this.clearZoneGrid()
      return
    }

    // 동일한 Area를 다시 눌렀으면 API 중복낭비 방지 (디바운싱/최적화 체킹)
    const nextKey = buildCompositeKey([workplCd, areaCd])
    const currentKey = this.selectedArea ? buildCompositeKey([this.selectedArea.workpl_cd, this.selectedArea.area_cd]) : ""
    if (nextKey === currentKey) return

    // 새롭게 포커싱 된 Area로 전역 멤버변수 대체
    this.selectedArea = {
      workpl_cd: workplCd,
      area_cd: areaCd,
      area_nm: areaRow.area_nm
    }

    this.refreshSelectedAreaLabel() // "선택 구역: ~" 텍스트 업데이트
    this.loadZoneRows()             // API 콜 발사
  }

  // Zone API 요청 및 데이터 주입
  async loadZoneRows() {
    if (!isApiAlive(this.zoneApi)) return

    if (!this.selectedArea) {
      this.clearZoneGrid()
      return
    }

    // 복합키(검색조건) 병합
    const query = new URLSearchParams({
      workpl_cd: this.selectedArea.workpl_cd,
      area_cd: this.selectedArea.area_cd
    })

    // 혹시라도 Area -> Zone 구조 외에, 우측 상단 등에 Zone 코드 자체검색 인풋이 있다면 값을 빼옴
    const zoneKeyword = this.zoneKeywordFromSearch()
    if (zoneKeyword) query.set("zone_cd", zoneKeyword)

    const useYn = this.useYnFromSearch()
    if (useYn) query.set("use_yn", useYn)

    try {
      const rows = await fetchJson(`${this.zonesUrlValue}?${query.toString()}`)

      // 조회해온 List를 단순 배열이 아니라, 변경점(CRUD Tracking) 관리자에 위임시켜 렌더링시킴
      setManagerRowData(this.zoneManager, rows)
      hideNoRowsOverlay(this.zoneApi)
    } catch {
      showAlert("보관 Zone 조회에 실패했습니다.")
    }
  }

  addZoneRow() {
    if (!this.zoneManager) return
    if (!this.ensureSelectedArea()) return

    // 행 추가 시, 현재 활성화된 마스터(Area)의 복합 프라이머리키를 미리 강제로 주입해줌
    this.zoneManager.addRow({
      workpl_cd: this.selectedArea.workpl_cd,
      area_cd: this.selectedArea.area_cd
    })
  }

  deleteZoneRows() {
    if (!this.zoneManager) return
    if (!this.ensureSelectedArea()) return

    this.zoneManager.deleteRows()
  }

  async saveZoneRows() {
    if (!this.zoneManager) return
    if (!this.ensureSelectedArea()) return // 부모 무결성 검증

    this.zoneManager.stopEditing() // 수정창 닫기
    const operations = this.zoneManager.buildOperations() // C/U/D 커밋 뭉치 추출

    // 바뀐게 있는지 확인
    if (!hasChanges(operations)) {
      showAlert("변경된 데이터가 없습니다.")
      return
    }

    const ok = await postJson(this.batchUrlValue, operations)
    if (!ok) return

    showAlert("보관 Zone 데이터가 저장되었습니다.")
    await this.loadZoneRows() // 성공 시 신규 PK/상태 갱신을 위해 데이터 통째로 리프레시
  }

  // 자식 Data Clear
  clearZoneGrid() {
    // 매니저를 통해 초기화 성공시 True, 실패나 의존성 부재시 단순 배열 비우기
    if (!setManagerRowData(this.zoneManager, [])) {
      setGridRowData(this.zoneApi, [])
    }
  }

  // 작업 전 무결성 보호용 헬퍼 함수
  ensureSelectedArea() {
    if (this.selectedArea) return true

    showAlert("좌측 목록에서 구역을 먼저 선택해주세요")
    return false
  }

  // 우측 상단 타겟에 사용자가 현재 뭘 찍고 작업하고 있는지 시각적 안내
  refreshSelectedAreaLabel() {
    if (!this.hasSelectedAreaLabelTarget) return

    const value = this.selectedArea
      ? `${this.selectedArea.area_cd} / ${this.selectedArea.area_nm || ""}`
      : ""
    refreshSelectionLabel(this.selectedAreaLabelTarget, value, "구역", "구역을 먼저 선택해주세요")
  }

  // 기타 조회조건 필드값 빼오기 유틸 체인
  zoneKeywordFromSearch() {
    return this.getSearchFormValue("zone_cd", { toUpperCase: false })
  }

  useYnFromSearch() {
    return this.getSearchFormValue("use_yn")
  }
}
