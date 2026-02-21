/**
 * user_menu_role_grid_controller.js
 * 
 * [공통] BaseGridController 상속: 한 화면에 그리드가 "3개(사용자/권한/메뉴)"인 다중(3 Tiered) 조망 뷰의 사령탑.
 * [사용자 그리드]에서 1명을 선택하면 -> 중간 [권한 그리드]가 해당 사용자의 배정권한을 열람하고 -> 그중 [권한 행] 하나를 선택하면 -> 마지막 [메뉴 그리드]가 메뉴 열람권한을 펼쳐줌.
 * 
 * 이 컨트롤러는 CRUD 저장이 없이 오직 순수한 "다단계 관측(View/Search)" 로직과, 
 * 연속 빠른 클릭/조회에 의한 'Race Condition(API 교차충돌)' 방지를 위한 Request Tracker 통제를 핵심으로 합니다.
 */
import BaseGridController from "controllers/base_grid_controller"
import { GridEventManager, resolveAgGridRegistration } from "controllers/grid/grid_event_manager"
import { AbortableRequestTracker, isAbortError } from "controllers/grid/request_tracker"
import { isApiAlive, fetchJson, setGridRowData } from "controllers/grid/grid_utils"

export default class extends BaseGridController {
  // 타겟 뷰: 1단User, 2단Role, 3단Menu 그리드 DOM
  static targets = ["userGrid", "roleGrid", "menuGrid"]

  static values = {
    rolesUrl: String,
    menusUrl: String
  }

  connect() {
    super.connect()
    this.selectedUserIdCode = "" // 활성 유저 트래킹 기록용
    // 3가지 API 독립 관리자
    this.userApi = null
    this.roleApi = null
    this.menuApi = null
    this.userGridController = null
    this.roleGridController = null
    this.menuGridController = null
    this.gridEvents = new GridEventManager() // 그리드 이벤트 안전 해지기

    // AbortableRequestTracker: 유저1 클릭 후 다 로딩되기도 전에 유저2를 클릭했을 시,
    // 유저1의 늦은 엉뚱한 응답 데이터가 덮어씌워지는 네트워크 오염 현상을 막아주는 생명주기 관리자
    this.rolesRequestTracker = new AbortableRequestTracker()
    this.menusRequestTracker = new AbortableRequestTracker()
  }

  disconnect() {
    this.gridEvents.unbindAll()
    this.cancelPendingRequests() // 페이지 탈주 시 모든 진행중인 비동기 HTTP Cancel
    this.userApi = null
    this.roleApi = null
    this.menuApi = null
    this.userGridController = null
    this.roleGridController = null
    this.menuGridController = null
    super.disconnect()
  }

  // 3가지 그리드가 하나하나 생명력을 얻을 때마다 호출되며 등록을 체크
  registerGrid(event) {
    const registration = resolveAgGridRegistration(event)
    if (!registration) return

    const { gridElement, api, controller } = registration

    // DOM Target을 분별하여 객체에 바인딩
    if (gridElement === this.userGridTarget) {
      this.userGridController = controller
      this.userApi = api
    } else if (gridElement === this.roleGridTarget) {
      this.roleGridController = controller
      this.roleApi = api
    } else if (gridElement === this.menuGridTarget) {
      this.menuGridController = controller
      this.menuApi = api
    }

    // 3가지 장군이 모두 준비완료 되었을 때 드디어 막을 올림 (초기 연계 세팅 시작)
    if (this.userApi && this.roleApi && this.menuApi) {
      this.bindGridEvents()
      this.handleUserGridDataLoaded()
    }
  }

  // 유저와 권한쪽의 셀렉션(선택/포커스) 변화 이벤트를 관제소에 등록함
  bindGridEvents() {
    this.gridEvents.unbindAll()
    this.gridEvents.bind(this.userApi, "selectionChanged", this.handleUserSelectionChanged)
    this.gridEvents.bind(this.userApi, "rowDataUpdated", this.handleUserGridDataLoaded)    // 유저 그리드 데이터 싹 갱신시 발생
    this.gridEvents.bind(this.roleApi, "selectionChanged", this.handleRoleSelectionChanged)
  }

  // 초기 / 혹은 유저 검색 필터로 유저 배열이 확정될 시: 자동으로 최상단 0번째 랭크된 유저를 AutoClick
  handleUserGridDataLoaded = () => {
    // 0번째 Row 강제선택 헬퍼 호출
    const selectedUser = this.selectFirstRow(this.userApi, "user_id_code")
    if (selectedUser) {
      this.loadRolesByUser(selectedUser.user_id_code) // 하위 발동!
    } else {
      // 아무도 검색결과가 없다면 Role/Menu 싹 정리
      this.clearRoleAndMenu()
    }
  }

  // 유저 그리드에서 마우스/키보드로 콕 찝어 선택행이 바뀔 경우의 연계동작
  handleUserSelectionChanged = () => {
    const selectedUser = this.userApi?.getSelectedRows?.()[0]
    if (!selectedUser) {
      this.clearRoleAndMenu()
      return
    }

    // 하위(권한) 호출
    this.loadRolesByUser(selectedUser.user_id_code)
  }

  // [트리 2단계 로딩] 유저 아이디를 무기로 권한 배열 Request
  async loadRolesByUser(userIdCode) {
    if (!isApiAlive(this.roleApi) || !isApiAlive(this.menuApi)) return

    this.selectedUserIdCode = userIdCode || ""

    // 로딩 시작하자마자 일단 하위단들의 화면을 완전히 비워줌 
    setGridRowData(this.roleApi, [])
    setGridRowData(this.menuApi, [])

    if (!this.selectedUserIdCode) return

    // 트래커에게 신규 토큰 발급 & 구식 요청 Abort() 명령 발행
    const { requestId, signal } = this.rolesRequestTracker.begin()

    try {
      const url = `${this.rolesUrlValue}?user_id_code=${encodeURIComponent(this.selectedUserIdCode)}`
      // Fetch 에 AbortSignal 주입 (네트워크 지연 중 타 요청으로 인해 증발 시 자동 취소 발생됨)
      const roles = await fetchJson(url, { signal })

      // 네트워크 응답 직후 검증: 만약 내가 보낸 RequestID가 가장 최근의 것이 아니거나 API가 죽었다면? 유기시킴 (무시)
      if (!this.rolesRequestTracker.isLatest(requestId) || !isApiAlive(this.roleApi) || !isApiAlive(this.menuApi)) {
        return
      }

      // 안전통과: 중간단 데이터 삽입
      setGridRowData(this.roleApi, roles)

      // 방금 넣은 역할들 중에서 또 다시 최상위 0번째 행을 AutoClick (연쇄) 해서 메뉴를 띄움
      const selectedRole = this.selectFirstRow(this.roleApi, "role_cd")
      if (selectedRole) {
        this.loadMenusByUserAndRole(this.selectedUserIdCode, selectedRole.role_cd)
      }
    } catch (error) {
      // Aborter 에 의해 강제로 Connection Drop 된 에러는 조용히 무시함. (에러가 아님)
      if (isAbortError(error) || !this.rolesRequestTracker.isLatest(requestId)) return
      alert("사용자 역할 조회에 실패했습니다.") // 진짜배기 500에러 등
    } finally {
      this.rolesRequestTracker.finish(requestId) // 상태 종결
    }
  }

  // 권한 그리드에서 사용자가 강제로 다른 Role을 찝어서 선택 변경 수행 시
  handleRoleSelectionChanged = () => {
    const selectedRole = this.roleApi?.getSelectedRows?.()[0]
    if (!selectedRole || !this.selectedUserIdCode) {
      setGridRowData(this.menuApi, []) // 메뉴 비우기
      return
    }

    // 하위(메뉴) 단 호출
    this.loadMenusByUserAndRole(this.selectedUserIdCode, selectedRole.role_cd)
  }

  // [트리 3단계 로딩] (유저 고유키 + 롤 고유키) 복합 파라미터로 최종 접근권한 매트릭스 Request
  async loadMenusByUserAndRole(userIdCode, roleCd) {
    if (!isApiAlive(this.menuApi)) return

    setGridRowData(this.menuApi, [])
    if (!userIdCode || !roleCd) return

    // 트래커 적용 동일 구조
    const { requestId, signal } = this.menusRequestTracker.begin()

    try {
      const query = new URLSearchParams({ user_id_code: userIdCode, role_cd: roleCd })
      const menus = await fetchJson(`${this.menusUrlValue}?${query.toString()}`, { signal })

      if (!this.menusRequestTracker.isLatest(requestId) || !isApiAlive(this.menuApi)) {
        return
      }

      setGridRowData(this.menuApi, menus)
    } catch (error) {
      if (isAbortError(error) || !this.menusRequestTracker.isLatest(requestId)) return
      alert("메뉴 조회에 실패했습니다.")
    } finally {
      this.menusRequestTracker.finish(requestId)
    }
  }

  // 초기화 유틸리티
  clearRoleAndMenu() {
    this.cancelPendingRequests()
    this.selectedUserIdCode = ""
    setGridRowData(this.roleApi, [])
    setGridRowData(this.menuApi, [])
  }

  // 그리드에 존재하는 최상단 데이터 0번째 인덱스를 강제로 하이라이팅+선택(Select) 처리하는 API 컨트롤 로직
  selectFirstRow(api, focusField) {
    if (!isApiAlive(api) || api.getDisplayedRowCount() === 0) return null

    const firstRowNode = api.getDisplayedRowAtIndex(0)
    if (!firstRowNode) return null

    api.ensureIndexVisible(0) // 스크롤바 조절 쫓아가기
    api.setFocusedCell(0, focusField, null) // 셀 단위 파란색 테두리 포커스
    firstRowNode.setSelected(true, true) // 시스템 전역 체크드(Selection) 이벤트 개방
    return firstRowNode.data
  }

  // 타 뷰로 넘어갈때 Abort() 호출
  cancelPendingRequests() {
    this.rolesRequestTracker.cancelAll()
    this.menusRequestTracker.cancelAll()
  }
}
