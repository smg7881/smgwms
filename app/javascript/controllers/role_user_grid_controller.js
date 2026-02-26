/**
 * role_user_grid_controller.js
 * 
 * [공통] BaseGridController 상속: 좌우 2개의 양방향 대칭 그리드를 이용한 인터페이스.
 * 특정 권한(Role)에 대해 사용자를 <할당 안됨(좌측)> ↔ <할당됨(우측)> 사이로 넘나들게 제어하는 컨트롤러입니다.
 * - 버튼(또는 방향 화살표)을 눌러 좌측/우측 배열의 요소를 스왑(Swap) 합니다.
 * - 필터링(검색어) 기능을 자바스크립트 레벨에서 즉각(In-Memory) 지원합니다.
 */
import BaseGridController from "controllers/base_grid_controller"
import { showAlert, confirmAction } from "components/ui/alert"
import { resolveAgGridRegistration } from "controllers/grid/grid_event_manager"
import { isApiAlive, postJson, fetchJson, setGridRowData, registerGridInstance } from "controllers/grid/grid_utils"

export default class extends BaseGridController {
  static targets = [
    "leftGrid",           // (미할당) 사용 가능한 유저 그리드
    "rightGrid",          // (할당 됨) 맵핑된 유저 그리드
    "leftSearchInput",    // 좌측 자체검색창
    "rightSearchInput",   // 우측 자체검색창
    "selectedRoleCode"    // 상단 콤보박스 선택된 Role 값 들고있을 hidden 타겟
  ]

  static values = {
    availableUrl: String, // 특정 Role 기준 배정 안된 유저 목록 패치 엔드포인트
    assignedUrl: String,  // 특정 Role 기준 이미 배정된 유저 목록 패치 엔드포인트
    saveUrl: String       // 변경 내역 최종 서버 커밋 엔드포인트
  }

  connect() {
    super.connect()

    // 서버로 부터 받아온 전체 유니버스 데이터 저장용
    this.leftAllUsers = []
    this.rightAllUsers = []

    // 로컬 검색 필터링 텍스트버퍼
    this.leftSearchTerm = ""
    this.rightSearchTerm = ""

    // 양쪽 AG Grid API 객체들
    this.leftApi = null
    this.rightApi = null
    this.leftGridController = null
    this.rightGridController = null
  }

  disconnect() {
    this.leftApi = null
    this.rightApi = null
    this.leftGridController = null
    this.rightGridController = null
    super.disconnect()
  }

  // AG Grid 컨테이너들이 렌더링되면서 차례차례 dispatchEvent를 일으킬 때 캐치.
  registerGrid(event) {
    registerGridInstance(event, this, [
      { target: this.hasLeftGridTarget ? this.leftGridTarget : null, controllerKey: "leftGridController", managerKey: "leftApi" },
      { target: this.hasRightGridTarget ? this.rightGridTarget : null, controllerKey: "rightGridController", managerKey: "rightApi" }
    ], () => {
      // grid_utils의 registerGridInstance 특성상 managerKey 에 new GridCrudManager()를 넣으려 시도할 수 있는데,
      // 역할-사용자 화면은 자체 API만 필요하므로 예외적으로 controllerKey만 매핑하거나, 여기서 api만 직접 매핑.
      // (registerGridInstance는 Manager 를 생성하지만 configMethod가 없으면 api만 넣지 않으므로 수동할당)
    })

    // 수동 할당 보정
    const registration = resolveAgGridRegistration(event)
    if (!registration) return
    const { gridElement, api, controller } = registration

    if (gridElement === this.leftGridTarget) {
      this.leftGridController = controller
      this.leftApi = api
    } else if (gridElement === this.rightGridTarget) {
      this.rightGridController = controller
      this.rightApi = api
    }

    if (this.leftApi && this.rightApi) {
      this.loadUsers()
    }
  }

  // 상단 권한조건(콤보박스) 이 변경되었을 때 트리거
  changeRole() {
    this.selectedRoleCodeTarget.value = this.currentRoleCode
    this.resetSearch()  // 권한 그룹이 바뀌었으니 로컬검색어 초기화
    this.loadUsers()    // API 재호출
  }

  // 선택된 권한에 맞춰 비동기 병렬 요청으로 좌/우 데이터를 동시에 가져옴
  async loadUsers() {
    if (!isApiAlive(this.leftApi) || !isApiAlive(this.rightApi)) return

    const roleCd = this.currentRoleCode
    if (!roleCd) {
      // 권한이 미선택이면 양쪽 화면 백지화 및 렌더링 종료
      this.leftAllUsers = []
      this.rightAllUsers = []
      this.renderFilteredRows()
      return
    }

    try {
      // Promise.all로 네트워크 대기시간을 절반 단축
      const [availableUsers, assignedUsers] = await Promise.all([
        fetchJson(`${this.availableUrlValue}?role_cd=${encodeURIComponent(roleCd)}`),
        fetchJson(`${this.assignedUrlValue}?role_cd=${encodeURIComponent(roleCd)}`)
      ])

      this.leftAllUsers = availableUsers
      this.rightAllUsers = assignedUsers
      this.renderFilteredRows() // 가져온 배열을 AG Grid 에 밀어넣기
    } catch {
      showAlert("역할 사용자 조회에 실패했습니다.")
    }
  }

  // ===================== [로컬(Client-only) 검색, 필터링 파트] =========================

  searchLeft() {
    this.leftSearchTerm = this.leftSearchInputTarget.value.toLowerCase().trim()
    this.renderFilteredRows()
  }

  searchRight() {
    this.rightSearchTerm = this.rightSearchInputTarget.value.toLowerCase().trim()
    this.renderFilteredRows()
  }

  // ===================== [좌우 이동 스와핑 파트] =========================

  moveToRight() {
    if (!isApiAlive(this.leftApi)) return

    // 좌측 미할당 그리드에서 체크박스 켜둔 항목 리스트 추출
    const selectedRows = this.leftApi.getSelectedRows()
    if (!selectedRows.length) return

    // PK 발췌용 임시 Set
    const selectedIds = new Set(selectedRows.map((row) => row.user_id_code))

    // 우측 할당 리스트에 항목 가산
    this.rightAllUsers = [...this.rightAllUsers, ...selectedRows]
    // 좌측 미할당 리스트에서 가산된 애들을 제외(Filter)
    this.leftAllUsers = this.leftAllUsers.filter((row) => !selectedIds.has(row.user_id_code))

    this.renderFilteredRows() // 변경된 전역 배열을 타겟으로 다시 렌더링시킴
  }

  moveToLeft() {
    if (!isApiAlive(this.rightApi)) return

    // 위 로직의 정확히 대칭 리버스 버전
    const selectedRows = this.rightApi.getSelectedRows()
    if (!selectedRows.length) return

    const selectedIds = new Set(selectedRows.map((row) => row.user_id_code))
    this.leftAllUsers = [...this.leftAllUsers, ...selectedRows]
    this.rightAllUsers = this.rightAllUsers.filter((row) => !selectedIds.has(row.user_id_code))

    this.renderFilteredRows()
  }

  // ===================== [데이터 최종 커밋 퍼블리싱 로직] =========================

  async save() {
    const roleCd = this.currentRoleCode
    if (!roleCd) {
      showAlert("역할을 먼저 선택해주세요")
      return
    }

    // 우측 그리드(현재 배정 완료칸)에 남아있는 모든 사용자 ID를 매핑해 뽑아냄.
    // ※ 백엔드에서는 기존 권한과 상관없이, 여기에 주어진 배열을 해당 Role의 '100% 최신' 상태로 간주(Snapshot)하고 전부 갈아끼우는 트랜잭션을 하거나 비교병합을 칠것임.
    const userIds = this.rightAllUsers.map((user) => user.user_id_code).filter((id) => id)

    const result = await postJson(this.saveUrlValue, {
      role_cd: roleCd,
      user_ids: userIds // 배열 채로 전송
    })
    if (!result) return

    showAlert(result.message || "저장되었습니다.")
    this.loadUsers() // 성공 시 서버 최신화를 위해 재조회
  }

  // 좌우 통합 렌더링 트리거 함수
  renderFilteredRows() {
    if (!isApiAlive(this.leftApi) || !isApiAlive(this.rightApi)) return

    // 검색어가 있다면 필터링 걸친 배열만 도출
    const leftRows = this.filterRows(this.leftAllUsers, this.leftSearchTerm)
    const rightRows = this.filterRows(this.rightAllUsers, this.rightSearchTerm)

    setGridRowData(this.leftApi, leftRows)
    setGridRowData(this.rightApi, rightRows)
  }

  // 이름 또는 소속 팀명칭 풀스캔 Like '%A%' 필터 서치 함수
  filterRows(rows, term) {
    if (!term) return rows

    return rows.filter((row) => {
      const userNm = (row.user_nm || "").toLowerCase()
      const deptNm = (row.dept_nm || "").toLowerCase()
      return userNm.includes(term) || deptNm.includes(term)
    })
  }

  resetSearch() {
    this.leftSearchInputTarget.value = ""
    this.rightSearchInputTarget.value = ""
    this.leftSearchTerm = ""
    this.rightSearchTerm = ""
  }

  // 현재 View에서 조회 조건으로 쓰일 타겟 Role 추적
  get currentRoleCode() {
    const select = this.element.querySelector("#q_role_cd")
    return select?.value?.toString().trim().toUpperCase() || this.selectedRoleCodeTarget.value
  }
}
