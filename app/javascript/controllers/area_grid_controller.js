/**
 * area_grid_controller.js
 * 
 * [공통] BaseGridController를 상속받아 "구역(Area)" 관리 화면의 특수 비즈니스 로직을 구현합니다.
 * 주요 확장 기능:
 * - 상단 조회조건(검색 폼) 영역에 선택된 '작업장(Workplace)' 코드를 가로채서 신규 행 추가 시 자동 세팅.
 * - 사용자가 그리드 상에서 작업장 코드를 변경했을 때, 서버나 Map을 참조하여 '작업장 명칭'을 즉결 동기화.
 */
import BaseGridController from "controllers/base_grid_controller"
import { showAlert, confirmAction } from "components/ui/alert"
import { resolveNameFromMap } from "controllers/grid/grid_utils"

export default class extends BaseGridController {
  static values = {
    ...BaseGridController.values,
    workplaceMap: Object // HTML data-workplace-map-value 로부터 주입되는 { "CD": "이름" } 형태의 JSON 객체
  }

  connect() {
    super.connect() // 부모(Base)의 초기화 로직 수행 보장
    // HTML 속성으로 작업장 매핑 객체가 넘어왔다면 저장, 아니면 빈 객체로 fallback
    this.workplaceNameMap = this.hasWorkplaceMapValue ? this.workplaceMapValue : {}
  }

  // 기반 클래스에서 호출하는 필수 인터페이스: 이 그리드의 CRUD 명세서 반환
  configureManager() {
    return {
      pkFields: ["workpl_cd", "area_cd"], // 복합키 (작업장코드 + 구역코드)
      fields: {
        workpl_cd: "trimUpper",
        area_cd: "trimUpper",
        area_nm: "trim",
        area_desc: "trim",
        use_yn: "trimUpperDefault:Y"
      },
      // 신규 행이 추가될 때 기본 뼈대가 될 row 객체 (workpl_cd/workpl_nm은 addRow()에서 동적으로 주입)
      defaultRow: { area_cd: "", area_nm: "", area_desc: "", use_yn: "Y" },
      // 이 세가지가 모두 빈칸이면, 사용자가 + 기호 누르고 입력안한 "빈 줄" 로 판별하여 DB 전송 안함
      blankCheckFields: ["workpl_cd", "area_cd", "area_nm"],
      comparableFields: ["area_nm", "area_desc", "use_yn"],
      firstEditCol: "area_cd", // 추가 완료 후 바로 에디터가 열릴 타겟 컬럼
      pkLabels: { workpl_cd: "작업장코드", area_cd: "AREA코드" }, // 에러 메세지용 한글
      onCellValueChanged: (event) => this.syncWorkplaceName(event) // 콜백 주입
    }
  }

  // "행 추가" 버튼 오버라이드: 호출 시점마다 검색 폼의 작업장 코드를 동적으로 읽어 주입
  //addRow() {
  //  const workplCd = this.selectedWorkplaceCodeFromSearch()
  //  const startCol = workplCd ? "area_cd" : "workpl_cd"
  //  this.manager.addRow(
  //    { workpl_cd: workplCd, workpl_nm: this.resolveWorkplaceName(workplCd) },
  //    { startCol }
  // )
  // }

  buildNewRowOverrides() {
    return {
      workpl_cd: this.selectedWorkplaceCodeFromSearch(),
      workpl_nm: this.resolveWorkplaceName(this.selectedWorkplaceCodeFromSearch())
    }
  }



  // 사용자가 엑셀 붙여넣기나 타이핑으로 그리드 셀(Cell)의 '작업장코드'를 변경 시 트리거됨
  syncWorkplaceName(event) {
    if (event?.colDef?.field !== "workpl_cd") return // 타겟 컬럼 검사
    if (!event?.node?.data) return

    const row = event.node.data
    row.workpl_cd = (row.workpl_cd || "").trim().toUpperCase()
    // 매핑 테이블에서 코드로 명칭을 찾아와 자동할당함
    row.workpl_nm = this.resolveWorkplaceName(row.workpl_cd)

    // 하드코딩된 유효성 체크: 만약 처음 쳐보는 신규 노드인데 매핑테이블에 없는 코드를 박았다면 강제 리셋시킴
    if (row.__is_new && row.workpl_cd && !row.workpl_nm) {
      row.workpl_cd = ""
      row.workpl_nm = ""
      showAlert("유효한 작업장코드를 선택해주세요.")
    }

    // 변경된 Name값을 사용자 눈에 보이게 그리드 갱신
    this.manager.api.refreshCells({
      rowNodes: [event.node],
      columns: ["workpl_cd", "workpl_nm"],
      force: true
    })
  }

  // 보조 헬퍼: JS 객체에서 코드-이름 검색
  resolveWorkplaceName(workplCd) {
    return resolveNameFromMap(this.workplaceNameMap, workplCd)
  }

  // 보조 헬퍼: HTML DOM 트리를 직접 뒤져서 <input name="q[workpl_cd]"> 등의 값을 빼냄
  selectedWorkplaceCodeFromSearch() {
    return this.getSearchFormValue("workpl_cd")
  }

  // 성공 시 사용자에게 노출될 토스트/얼럿 텍스트
  get saveMessage() {
    return "구역 데이터가 저장되었습니다."
  }
}
