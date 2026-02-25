import BaseGridController from "controllers/base_grid_controller"
import { fetchJson } from "controllers/grid/grid_utils"

// 오더수정이력 화면 (마스터-디테일 읽기 전용)
export default class extends BaseGridController {
  static targets = [
    ...BaseGridController.targets,
    "masterGridContainer",
    "detailGridContainer",
    // Tabs
    "tabButton", "tabPanel"
  ]

  gridRoles() {
    return {
      master: { target: "masterGridContainer" },
      detail: { target: "detailGridContainer" }
    }
  }

  // 검색 폼 성공 시 마스터 그리드 바인딩
  loadMasterData(event) {
    if (!event.detail) return

    this.setRows("master", event.detail || [])
    this.setRows("detail", [])
  }

  // 마스터 행 클릭 시 상세 조회
  async onMasterRowClicked(event) {
    if (!event.detail) return

    const row = event.detail.data
    if (!row || !row.id) return

    try {
      const body = await fetchJson(`/om/order_modification_histories/${row.id}`)
      this.setRows("detail", body.items || [])
    } catch (e) {
      console.error("이력 상세 정보 조회 오류", e)
    }
  }

  // --- Tab methods ---
  switchTab(event) {
    event.preventDefault()
    const tabId = event.currentTarget?.dataset?.tab
    if (!tabId) return

    this.activateTab(tabId)
  }

  activateTab(tabId) {
    // 탭 버튼 스타일 변경
    this.tabButtonTargets.forEach((btn) => {
      const isActive = btn.dataset.tab === tabId
      btn.classList.toggle("is-active", isActive)
      btn.setAttribute("aria-selected", isActive ? "true" : "false")
    })

    // 탭 컨텐츠 표시/숨김
    this.tabPanelTargets.forEach((pane) => {
      const isActive = pane.dataset.tabPanel === tabId
      pane.classList.toggle("is-active", isActive)
      pane.hidden = !isActive
    })

    // 숨겨져 있던 그리드가 표시될 때 크기 재조정 필요
    setTimeout(() => {
      if (tabId === "master" && this.grids.master) {
        this.resizeGridIfNecessary(this.grids.master)
      } else if (tabId === "detail" && this.grids.detail) {
        this.resizeGridIfNecessary(this.grids.detail)
      }
    }, 10)
  }

  resizeGridIfNecessary(grid) {
    if (grid && grid.api) {
      grid.api.sizeColumnsToFit()
    }
  }
}
