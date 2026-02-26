/**
 * location_grid_controller.js
 *
 * [공통] BaseGridController 상속체로서 "로케이션(Location, 창고 셀) 관리"를 담당합니다.
 * 주요 확장 사양:
 * - 작업장 -> AREA -> ZONE 이라는 3Depth 계층형 물리 구조를 가지고 있어,
 *   조회 필터단(검색폼 영역)에 위치한 Select 박스들의 변경 이벤트(change)를 가로채
 *   동적으로 하위 Select의 옵션을 Fetch해옵니다(hydrateDependentSelects).
 * - "재고가 존재하는 로케이션(has_stock: Y)"의 경우 삭제 트랜잭션 진행 전에 방어(block) 시킵니다.
 */
import BaseGridController from "controllers/base_grid_controller"
import { showAlert } from "components/ui/alert"
import { setSelectOptions as setSelectOptionsUtil, clearSelectOptions } from "controllers/grid/grid_utils"
import { bindDependentSelects, unbindDependentSelects, loadSelectOptions } from "controllers/grid/grid_dependent_select_utils"

export default class extends BaseGridController {
  static values = {
    ...BaseGridController.values,
    areasUrl: String,  // 작업장에 종속된 area 정보들을 fetch 해올 URL
    zonesUrl: String   // area에 종속된 zone 정보들을 fetch 해올 URL
  }

  connect() {
    super.connect()
    // 연결 후 상단의 조회 조건(검색폼) 영역에 있는 <select> 들과 이벤트 바인딩
    this.bindSearchFields()
  }

  disconnect() {
    this.unbindSearchFields()
    super.disconnect()
  }

  // CRUD 기반 매니저 구축 설정 포맷 반환
  configureManager() {
    return {
      pkFields: ["workpl_cd", "area_cd", "zone_cd", "loc_cd"], // 무려 4개의 컬럼이 묶여 유일성을 담보하는 거대 복합키
      fields: {
        workpl_cd: "trimUpper",
        area_cd: "trimUpper",
        zone_cd: "trimUpper",
        loc_cd: "trimUpper",
        loc_nm: "trim",
        loc_class_cd: "trimUpper",
        loc_type_cd: "trimUpper",
        width_len: "number",
        vert_len: "number",
        height_len: "number",
        max_weight: "number",
        max_cbm: "number",
        has_stock: "trimUpperDefault:N", // 재고 보유 플래그 (일반적으론 DB View/Logic에서 주입됨)
        use_yn: "trimUpperDefault:Y"
      },
      defaultRow: {
        workpl_cd: "",
        area_cd: "",
        zone_cd: "",
        loc_cd: "",
        loc_nm: "",
        loc_class_cd: "STORAGE",
        loc_type_cd: "NORMAL",
        width_len: null,
        vert_len: null,
        height_len: null,
        max_weight: null,
        max_cbm: null,
        has_stock: "N", // 신규 생성 시 재고는 무조건 없음
        use_yn: "Y"
      },
      blankCheckFields: ["loc_cd", "loc_nm"],
      comparableFields: [
        "loc_nm",
        "loc_class_cd",
        "loc_type_cd",
        "width_len",
        "vert_len",
        "height_len",
        "max_weight",
        "max_cbm",
        "use_yn"
      ],
      firstEditCol: "loc_cd",
      pkLabels: {
        workpl_cd: "작업장 코드",
        area_cd: "AREA 코드",
        zone_cd: "ZONE 코드",
        loc_cd: "로케이션 코드"
      },
      onCellValueChanged: (event) => this.normalizeCodeField(event)
    }
  }

  // [+] 줄 추가하기 버튼 재정의
  addRow() {
    if (!this.manager?.api) return

    const workplCd = this.workplKeywordFromSearch()
    const areaCd = this.areaKeywordFromSearch()
    const zoneCd = this.zoneKeywordFromSearch()

    // 최말단인 Loc(셀 단위)을 만드려면 상위계층 3가지가 미리 지정되어야 함 (복합 PK 방지)
    if (!workplCd || !areaCd || !zoneCd) {
      showAlert("작업장, AREA, ZONE을 모두 선택해야 입력할 수 있습니다.")
      return
    }

    super.addRow()
  }

  buildNewRowOverrides() {
    return {
      workpl_cd: this.workplKeywordFromSearch(),
      area_cd: this.areaKeywordFromSearch(),
      zone_cd: this.zoneKeywordFromSearch()
    }
  }

  buildAddRowConfig() {
    return { startCol: "loc_cd" }
  }

  // Base Controller에서 구현되었던 '삭제 전 검사(Hook)' 실행
  beforeDeleteRows(selectedNodes) {
    // 삭제 요청된 노드들 중 재고 유무 Flag가 "Y" 인 노드만 발췌
    const hasStockRows = selectedNodes.filter(
      (node) => (node?.data?.has_stock || "").toString().trim().toUpperCase() === "Y"
    )

    if (hasStockRows.length > 0) {
      // Alert 브레이크 (무결성 및 치명적 에러 방지)
      showAlert(`재고가 있는 로케이션은 삭제할 수 없습니다. (${hasStockRows.length}건)`)
      return true // True면 작업 스탑
    }

    return false
  }

  // 코드 속성의 셀인 경우 알파벳을 무조건 대문자로 올려 시각적 통일성을 맞춤
  normalizeCodeField(event) {
    const field = event?.colDef?.field
    const codeFields = ["workpl_cd", "area_cd", "zone_cd", "loc_cd", "loc_class_cd", "loc_type_cd", "use_yn", "has_stock"]
    if (!codeFields.includes(field)) return
    if (!event?.node?.data) return

    const row = event.node.data
    row[field] = (row[field] || "").toString().trim().toUpperCase()
    this.manager.api.refreshCells({
      rowNodes: [event.node],
      columns: [field],
      force: true
    })
  }

  get saveMessage() {
    return "로케이션 데이터가 저장되었습니다."
  }

  // ----------------------------------------------------
  // 다단계 의존 콤보박스(Select) 제어 코어부
  // ----------------------------------------------------

  async bindSearchFields() {
    await bindDependentSelects(this, this.#dependentSelectConfig())
  }

  unbindSearchFields() {
    unbindDependentSelects(this)
  }

  // 백엔드 API (areasUrl) 호출 및 드롭다운 HTML 렌더
  async loadAreaOptions(workplCd, selectedAreaCd) {
    if (!this.hasAreasUrlValue) return
    const areaField = this.getSearchFieldElement("area_cd")
    if (!areaField) return

    const rows = await loadSelectOptions(
      this,
      this.areasUrlValue,
      { workpl_cd: workplCd },
      "AREA 목록 조회에 실패했습니다."
    )
    if (!rows) return

    const options = rows.map((row) => ({
      value: row.area_cd,
      label: `${row.area_cd} - ${row.area_nm || ""}`
    }))

    setSelectOptionsUtil(areaField, options, selectedAreaCd)
  }

  // 백엔드 API (zonesUrl) 호출 및 드롭다운 HTML 렌더
  async loadZoneOptions(workplCd, areaCd, selectedZoneCd) {
    if (!this.hasZonesUrlValue) return
    const zoneField = this.getSearchFieldElement("zone_cd")
    if (!zoneField) return

    const rows = await loadSelectOptions(
      this,
      this.zonesUrlValue,
      { workpl_cd: workplCd, area_cd: areaCd, use_yn: "Y" },
      "ZONE 목록 조회에 실패했습니다."
    )
    if (!rows) return

    const options = rows.map((row) => ({
      value: row.zone_cd,
      label: `${row.zone_cd} - ${row.zone_nm || ""}`
    }))

    setSelectOptionsUtil(zoneField, options, selectedZoneCd)
  }

  // Value getter 헬퍼 삼자
  workplKeywordFromSearch() {
    return this.getSearchFormValue("workpl_cd")
  }

  areaKeywordFromSearch() {
    return this.getSearchFormValue("area_cd")
  }

  zoneKeywordFromSearch() {
    return this.getSearchFormValue("zone_cd")
  }

  // --- Private ---

  #dependentSelectConfig() {
    return {
      fields: ["workpl_cd", "area_cd", "zone_cd"],
      onChange: [
        // 작업장 변경 시: area/zone 초기화 후 area 재조회
        async (controller, fields) => {
          const workplCd = controller.workplKeywordFromSearch()
          clearSelectOptions(fields[1])
          clearSelectOptions(fields[2])
          if (!workplCd) return
          await controller.loadAreaOptions(workplCd, "")
        },
        // area 변경 시: zone 초기화 후 zone 재조회
        async (controller, fields) => {
          const workplCd = controller.workplKeywordFromSearch()
          const areaCd = controller.areaKeywordFromSearch()
          clearSelectOptions(fields[2])
          if (!workplCd || !areaCd) return
          await controller.loadZoneOptions(workplCd, areaCd, "")
        }
      ],
      hydrate: async (controller, fields) => {
        const workplCd = controller.workplKeywordFromSearch()
        const areaCd = controller.areaKeywordFromSearch()
        const zoneCd = controller.zoneKeywordFromSearch()

        if (!workplCd) {
          clearSelectOptions(fields[1])
          clearSelectOptions(fields[2])
          return
        }

        await controller.loadAreaOptions(workplCd, areaCd)

        if (controller.areaKeywordFromSearch()) {
          await controller.loadZoneOptions(workplCd, controller.areaKeywordFromSearch(), zoneCd)
        } else {
          clearSelectOptions(fields[2])
        }
      }
    }
  }
}
