/**
 * zone_grid_controller.js
 * 
 * [공통] BaseGridController 상속: 좌-우 화면 분할 방식의 "마스터-디테일(Area -> Zone)" 관리를 다룹니다.
 * - 좌측(마스터): AreaGrid (이 그리드는 본 컨트롤러에서 값을 '읽기'만 하고 이벤트를 추적함)
 * - 우측(디테일): ZoneGrid (독자적인 CRUD 매니저를 생성하여 할당하고, Area에 종속된 Zone을 저장함)
 */
import BaseGridController from "controllers/base_grid_controller"
import { showAlert, confirmAction } from "components/ui/alert"
import { isApiAlive, hideNoRowsOverlay, fetchJson, setManagerRowData, setGridRowData, refreshSelectionLabel, buildCompositeKey } from "controllers/grid/grid_utils"

export default class extends BaseGridController {
  static targets = ["areaGrid", "zoneGrid", "selectedAreaLabel"]

  static values = {
    zonesUrl: String, // 특정 Area에 속해있는 Zone 목록을 불러오는 API 엔드포인트
    batchUrl: String  // Zone C/U/D 변경사항을 한방에 서버로 커밋하는 API 엔드포인트
  }

  gridRoles() {
    return {
      area: { target: "areaGrid" },
      zone: {
        target: "zoneGrid",
        manager: "zoneConfig",
        parentGrid: "area",
        onMasterRowChange: (rowData) => this.selectArea(rowData)
      }
    }
  }

  connect() {
    super.connect()
    this.selectedArea = null // 현재 선택된 부모(Area) 행의 데이터 캐싱 객체
    this.areaApi = null      // 마스터 그리드 API
    this.zoneApi = null      // 디테일 그리드 API
    this.areaGridController = null
    this.zoneGridController = null
    this.zoneManager = null // 디테일 그리드를 독자적으로 통제할 관리자
  }

  disconnect() {
    this.selectedArea = null
    this.areaApi = null
    this.zoneApi = null
    this.areaGridController = null
    this.zoneGridController = null
    super.disconnect()
  }

  onAllGridsReady() {
    this.areaApi = this.gridApi("area")
    this.zoneApi = this.gridApi("zone")
    this.areaGridController = this.gridCtrl("area")
    this.zoneGridController = this.gridCtrl("zone")
    this.zoneManager = this.gridManager("zone")
    this.refreshSelectedAreaLabel()
  }

  zoneConfig() {
    return {
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
    }
  }

  beforeSearchReset() {
    this.selectedArea = null
    this.refreshSelectedAreaLabel()
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
    this.addRow({
      manager: this.zoneManager,
      overrides: {
        workpl_cd: this.selectedArea.workpl_cd,
        area_cd: this.selectedArea.area_cd
      }
    })
  }

  deleteZoneRows() {
    if (!this.zoneManager) return
    if (!this.ensureSelectedArea()) return

    this.deleteRows({ manager: this.zoneManager })
  }

  async saveZoneRows() {
    if (!this.zoneManager) return
    if (!this.ensureSelectedArea()) return // 부모 무결성 검증

    const batchUrl = this.batchUrlValue
    await this.saveRowsWith({
      manager: this.zoneManager,
      batchUrl,
      saveMessage: "보관 Zone 데이터가 저장되었습니다.",
      onSuccess: () => this.loadZoneRows()
    }) // 성공 후 최신 PK/상태 갱신을 위해 데이터 재조회
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
