/**
 * tabs_controller.js
 * 
 * 애플리케이션의 메인 네비게이션 탭(다중 창 형태)을 관리하는 핵심 컨트롤러입니다.
 * - 탭 열기, 닫기, 활성화, 이동 등 사용자 액션을 가로채 백엔드(Turbo Stream)로 요청합니다.
 * - 우클릭 컨텍스트 메뉴(Context Menu) 표출 및 좌표 계산을 담당합니다.
 * - 활성화된 탭에 맞춰 좌측 사이드바(Sidebar) 메뉴 구조를 자동으로 펼치거나 활성 스타일을 동기화합니다.
 * - 상단 브레드크럼(Breadcrumb) 경로 텍스트를 현재 탭에 맞춰 갱신합니다.
 */
import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  // contextMenu: 우클릭 시 나타나는 팝업 메뉴 컨테이너
  // menuToggle: 팝업 햄버거 형태 등 메뉴 토글 버튼
  static targets = ["contextMenu", "menuToggle"]

  // HTML 속성으로 부터 주입받는 설정값
  static values = {
    tabsEndpoint: { type: String, default: "/tabs" }, // 백엔드 통신용 기준 URL (기본 /tabs)
    maxOpenTabs: { type: Number, default: 10 }        // 브라우저 과부하 방지를 위한 최대 탭 개수 제한
  }

  connect() {
    this.contextTabId = null // 현재 우클릭 메뉴가 열린 대상 탭의 ID 기록

    // 이벤트 리스너의 this 컨텍스트 바인딩 보존을 위한 캐싱
    this.boundDocumentClick = this.handleDocumentClick.bind(this)
    this.boundDocumentKeydown = this.handleDocumentKeydown.bind(this)

    // 컨텍스트 메뉴 바깥 클릭 감지용 전역 리스너 (캡처링 단계에서 잡기 위해 true)
    document.addEventListener("click", this.boundDocumentClick, true)
    // ESC 키로 메뉴 닫기용 전역 리스너
    document.addEventListener("keydown", this.boundDocumentKeydown)
  }

  disconnect() {
    document.removeEventListener("click", this.boundDocumentClick, true)
    document.removeEventListener("keydown", this.boundDocumentKeydown)
  }

  // --- 탭 기본 동작 ---

  // 좌측 사이드바 메뉴 클릭 시 신규 탭 생성 요청
  openTab(event) {
    event.preventDefault()
    const { tabId, label, url } = event.currentTarget.dataset // 클릭한 버튼의 data 속성 추출
    const isAlreadyOpen = this.tabIds.includes(tabId)

    // 신규 생성이고, 최대 개수 제한에 걸린다면 경고 후 중단
    if (!isAlreadyOpen && this.tabIds.length >= this.maxOpenTabsValue) {
      console.warn(`[tabs] maximum open tabs (${this.maxOpenTabsValue}) reached`)
      alert(`탭메뉴는 ${this.maxOpenTabsValue}개까지 가능합니다.`)
      return
    }

    // 서버로 해당 메뉴 데이터 전송 -> 응답으로 탭/내용물 HTML Turbo 처리 -> 처리 직후 사이드바 UI 동기화
    this.requestTurboStream("POST", this.tabsEndpointValue, {
      tab: { id: tabId, label, url }
    }).then(() => this.syncUI(tabId))
  }

  // 기존 열려있는 탭 클릭 시 활성화(전환) 요청
  activateTab(event) {
    const tabId = event.currentTarget.dataset.tabId
    if (event.currentTarget.classList.contains("active")) return // 이미 활성화 상태면 무시

    this.requestTurboStream("POST", `${this.tabsEndpointValue}/${tabId}/activation`)
      .then(() => this.syncUI(tabId))
  }

  // X 버튼 눌러서 탭 하나 닫을 때
  closeTab(event) {
    const tabId = event.currentTarget.dataset.tabId
    // 서버 Session/DB 에서 탭 제거 기록
    this.requestTurboStream("DELETE", `${this.tabsEndpointValue}/${tabId}`)
      .then(() => this.syncUIFromActiveTab()) // 닫힌 후 새롭게 활성화된 탭 기준으로 사이드바 동기화
  }

  // --- 컨텍스트 메뉴 (우클릭 등) 동작 ---

  openContextMenu(event) {
    event.preventDefault() // 브라우저 기본 우클릭 메뉴 방지
    const tabId = event.currentTarget.dataset.tabId
    // 마우스 커서 위치(clientX/Y) 기준으로 커스텀 메뉴 팝업 표출
    this.showContextMenu(tabId, { x: event.clientX, y: event.clientY })
  }

  // 드롭다운 단추 등 마우스 우클릭이 아닌 특정 버튼 기준으로 열 때
  openActionsMenu(event) {
    event.preventDefault()
    const activeTabId = this.activeTabId || "overview"

    // 이미 열려있는데 같은 버튼을 누르면 닻(Anchor)모드를 해제하며 숨김 (토글)
    if (this.isContextMenuVisible() && this.contextMenuTarget.classList.contains("is-anchor")) {
      this.hideContextMenu()
      return
    }

    // 마우스 좌표가 아닌, 버튼 DOM 기준 위치(Anchor)로 팝업 표출
    this.showContextMenu(activeTabId, { anchor: event.currentTarget })
  }

  // "모든 탭 닫기" 메뉴 클릭 시
  closeAllTabs(event) {
    if (this.isMenuItemDisabled(event.currentTarget)) return

    event.preventDefault()
    this.hideContextMenu()
    this.requestTurboStream("DELETE", `${this.tabsEndpointValue}/close_all`)
      .then(() => this.syncUI("overview")) // 다 지웠으니 메인 대시보드(overview)로 초기화
  }

  // "다른 탭 닫기" (오른쪽 클릭한 대상 빼고 다 닫기)
  closeOtherTabs(event) {
    if (this.isMenuItemDisabled(event.currentTarget)) return

    event.preventDefault()
    const tabId = this.currentContextTabId
    this.hideContextMenu()
    this.requestTurboStream("DELETE", `${this.tabsEndpointValue}/close_others?id=${encodeURIComponent(tabId)}`)
      .then(() => this.syncUI(tabId))
  }

  // "좌측으로 이동" (탭 순서 변경)
  moveTabLeft(event) {
    if (this.isMenuItemDisabled(event.currentTarget)) return

    event.preventDefault()
    const tabId = this.currentContextTabId
    this.hideContextMenu()
    this.requestTurboStream("PATCH", `${this.tabsEndpointValue}/${encodeURIComponent(tabId)}/move_left`)
      .then(() => this.syncUIFromActiveTab())
  }

  // "우측으로 이동" (탭 순서 변경)
  moveTabRight(event) {
    if (this.isMenuItemDisabled(event.currentTarget)) return

    event.preventDefault()
    const tabId = this.currentContextTabId
    this.hideContextMenu()
    this.requestTurboStream("PATCH", `${this.tabsEndpointValue}/${encodeURIComponent(tabId)}/move_right`)
      .then(() => this.syncUIFromActiveTab())
  }

  // 컨텍스트 메뉴 아이템에 포커스 갔을 때 엔터/스페이스 키로 선택 작동하게 함
  handleMenuItemKeydown(event) {
    if (event.key !== "Enter" && event.key !== " ") return
    if (this.isMenuItemDisabled(event.currentTarget)) return

    event.preventDefault()
    event.currentTarget.click() // 클릭 이벤트 위임 실행
  }

  // --- 사이드바 연동 ---

  // 헤더 햄버거 버튼 클릭 시 사이드바 접기/펼치기 토글
  toggleSidebar() {
    this.element.classList.toggle("sidebar-collapsed")
  }

  // --- 백엔드 통신 유틸 ---

  // Hotwire/Turbo Stream 응답 전용 커스텀 Fetch 래퍼 함수
  requestTurboStream(method, url, body = null) {
    const headers = {
      "X-CSRF-Token": this.csrfToken,            // Rails 보안용
      Accept: "text/vnd.turbo-stream.html"       // Turbo 명령어를 파싱하기 위해 필수인 Accept 타입
    }
    const options = { method, headers }

    if (body) {
      headers["Content-Type"] = "application/json"
      options.body = JSON.stringify(body)
    }

    return fetch(url, options)
      .then((response) => {
        if (!response.ok) throw new Error(`HTTP ${response.status}`)
        return response.text()
      })
      .then((html) => {
        // 백엔드에서 준 <turbo-stream> 태그 HTML을 추출하여 브라우저 강제 렌더링 호출
        Turbo.renderStreamMessage(html)
      })
      .catch((error) => {
        console.error("[tabs]", error)
        throw error
      })
  }

  // 메타 태그에서 CSRF 토큰 추출
  get csrfToken() {
    return document.querySelector("meta[name='csrf-token']")?.content || ""
  }

  // 특정 기준 메뉴에 맞춰 사이드바 및 브레드크럼 등 상태 동기화 통제 메소드
  syncUI(tabId) {
    this.updateSidebarActive(tabId) // 사이드바 활성 클래스 부여

    // 선택된 사이드바 버튼 DOM을 찾아 브레드크럼 배열 추출
    const button = document.querySelector(`[data-role='sidebar-menu-item'][data-tab-id='${tabId}']`)
    if (button) {
      if (button.dataset.breadcrumbs) {
        try {
          // JSON 배열 ["시스템", "메뉴 관리"] 파싱 및 렌더
          this.updateBreadcrumb(JSON.parse(button.dataset.breadcrumbs))
          return
        } catch (e) {
          console.error("Failed to parse breadcrumbs", e)
        }
      }
      this.updateBreadcrumb([button.dataset.label]) // 배열 해석 실패시 자신의 이름만 적용
    }
  }

  // 현재 DOM에 그려진 활성화된 탭을 읽어들여서 동기화 수행
  syncUIFromActiveTab() {
    queueMicrotask(() => { // UI 렌더링 스텝 완료된 후 실행되도록 큐 이관
      const activeTab = document.querySelector(".tab-item.active")
      const tabId = activeTab?.dataset?.tabId
      if (tabId) {
        this.updateSidebarActive(tabId)
        const button = document.querySelector(`[data-role='sidebar-menu-item'][data-tab-id='${tabId}']`)
        if (button && button.dataset.breadcrumbs) {
          try {
            this.updateBreadcrumb(JSON.parse(button.dataset.breadcrumbs))
            return
          } catch (e) {
            console.error("Failed to parse breadcrumbs", e)
          }
        }
        this.updateBreadcrumb([activeTab?.dataset?.tabLabel])
      }
    })
  }

  // 사이드바 엘리먼트를 순회하며 자신이 해당 Tab ID일 경우 파란색 하이라이트 부여 및 조상 폴더 펼치기
  updateSidebarActive(tabId) {
    document.querySelectorAll("[data-role='sidebar-menu-item']").forEach((button) => {
      const isActive = button.dataset.tabId === tabId
      button.classList.toggle("active", isActive)

      // 부모 트리를 거슬러 올라가면서 폴더를 열어주는 로직
      if (isActive) {
        let parentTree = button.closest(".nav-tree-children")
        while (parentTree) {
          parentTree.classList.add("open")
          const folderButton = parentTree.previousElementSibling
          if (folderButton && folderButton.classList.contains("has-children")) {
            folderButton.classList.add("expanded")
            folderButton.setAttribute("aria-expanded", "true")
          }
          parentTree = folderButton ? folderButton.closest(".nav-tree-children") : null
        }
      }
    })
  }

  // 상속 경로(Breadcrumb) 배열을 HTML 태그로 치환해 상단 앵커에 렌더링
  updateBreadcrumb(labels) {
    const element = document.getElementById("breadcrumb-current")
    if (!element || !labels) return

    if (!Array.isArray(labels)) {
      labels = [labels]
    }

    element.innerHTML = labels.map((label, index) => {
      if (index === labels.length - 1) {
        return `<span class="text-text-primary font-semibold">${label}</span>` // 최종 본인 이름
      }
      return `<span class="text-text-secondary">${label}</span><span class="text-text-muted ml-0.5 mr-0.5">/</span>` // 부모 경로 
    }).join("")
  }

  get activeTabId() {
    return document.querySelector(".tab-item.active")?.dataset?.tabId
  }

  get currentContextTabId() {
    if (this.contextTabId) {
      return this.contextTabId
    }
    return this.activeTabId || "overview"
  }

  // --- 컨텍스트 메뉴 표출 / 숨김 계산 로직 ---

  // 메뉴를 열기 위해 옵션 판별 및 클래스 컨트롤
  showContextMenu(tabId, options = {}) {
    if (!this.hasContextMenuTarget) return

    this.contextTabId = tabId
    this.syncContextMenuState(tabId) // 이 탭이 왼쪽/오른쪽으로 갈 수 있는지 유효성 검사 적용
    this.contextMenuTarget.classList.add("is-open")

    if (options.anchor) { // DOM 엘리먼트 기준 상대 위치 표출
      this.positionContextMenuAsAnchor()
      return
    }

    // 마우스 좌표 기준 절대 위치 설정
    this.contextMenuTarget.classList.remove("is-anchor")
    this.positionContextMenuByPoint(options.x, options.y)
  }

  // 화면에서 숨기기 및 스타일 캐시 제거
  hideContextMenu() {
    if (!this.hasContextMenuTarget) return

    this.contextMenuTarget.classList.remove("is-open")
    this.contextMenuTarget.classList.remove("is-anchor")
    this.contextMenuTarget.style.left = ""
    this.contextMenuTarget.style.top = ""
    this.contextTabId = null
  }

  // 화면 끝 범위를 넘기지 않도록 가로/세로 최적 좌표 산출하여 css Left, Top 주입
  positionContextMenuByPoint(x = 0, y = 0) {
    const menu = this.contextMenuTarget
    const viewportPadding = 8
    const width = menu.offsetWidth
    const height = menu.offsetHeight
    const left = Math.max(viewportPadding, Math.min(x, window.innerWidth - width - viewportPadding))
    const top = Math.max(viewportPadding, Math.min(y, window.innerHeight - height - viewportPadding))
    menu.style.left = `${left}px`
    menu.style.top = `${top}px`
  }

  // CSS 기준 Relative Box 형태로 부착되게 만듦 
  positionContextMenuAsAnchor() {
    this.contextMenuTarget.classList.add("is-anchor")
    this.contextMenuTarget.style.left = ""
    this.contextMenuTarget.style.top = ""
  }

  // 탭 목록 배열의 인덱스를 찾아, 첫 탭인지 마지막 탭인지 등을 판별해 메뉴 아이템(좌로 이동/우로 이동)의 비활성화를 토글함
  syncContextMenuState(tabId) {
    const tabIds = this.tabIds
    const index = tabIds.indexOf(tabId)
    const hasOtherClosableTabs = tabIds.some((id) => id !== "overview" && id !== tabId)

    // Overview(대시보드)는 항상 인덱스 0이므로 이동 불가, 1번(첫 실제 탭)부터 이동 따지기
    const canMoveLeft = index > 1
    const canMoveRight = index >= 1 && index < tabIds.length - 1

    this.toggleMenuAction("close-all", false) // 항상 활성화
    this.toggleMenuAction("close-others", !hasOtherClosableTabs) // 남은 탭이 1개면 비활성화
    this.toggleMenuAction("move-left", !canMoveLeft)
    this.toggleMenuAction("move-right", !canMoveRight)
  }

  // 특정 팝업 메뉴 요소에 disabled 속성을 주입/해제하여 스타일링과 키보드 포커스 제어
  toggleMenuAction(actionName, disabled) {
    if (!this.hasContextMenuTarget) return

    const action = this.contextMenuTarget.querySelector(`[data-menu-action='${actionName}']`)
    if (!action) return

    action.classList.toggle("is-disabled", disabled)
    action.setAttribute("aria-disabled", disabled ? "true" : "false")
    action.setAttribute("tabindex", disabled ? "-1" : "0")
  }

  // 열려있는 탭 전체 ID를 DOM 트레이싱 기반 배열 추출
  get tabIds() {
    return Array.from(document.querySelectorAll(".tab-item")).map((tab) => tab.dataset.tabId)
  }

  // 배경 아무데나 눌렀을 때 컨텍스트 메뉴 강제 종료
  handleDocumentClick(event) {
    if (!this.hasContextMenuTarget || !this.contextMenuTarget.classList.contains("is-open")) return

    const clickedOnMenu = this.contextMenuTarget.contains(event.target)
    const clickedOnToggle = this.hasMenuToggleTarget && this.menuToggleTarget.contains(event.target)

    if (!clickedOnMenu && !clickedOnToggle) {
      this.hideContextMenu()
    }
  }

  // ESC 키 메뉴 종류 
  handleDocumentKeydown(event) {
    if (event.key === "Escape") {
      this.hideContextMenu()
    }
  }

  isContextMenuVisible() {
    return this.hasContextMenuTarget && this.contextMenuTarget.classList.contains("is-open")
  }

  isMenuItemDisabled(element) {
    if (!element) return false
    return element.classList.contains("is-disabled") || element.getAttribute("aria-disabled") === "true"
  }
}
