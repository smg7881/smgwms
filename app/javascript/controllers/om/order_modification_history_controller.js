import BaseGridController from "controllers/base_grid_controller"
import { fetchJson } from "controllers/grid/core/http_client"
import { switchTab, activateTab } from "controllers/ui_utils"

// 오더수정이력 화면 (마스터-디테일 + 탭)
export default class extends BaseGridController {
  static targets = [
    ...BaseGridController.targets,
    "masterGridContainer",
    "detailGridContainer",
    "tabButton",
    "tabPanel"
  ]

  gridRoles() {
    return {
      master: {
        target: "masterGridContainer",
        masterKeyField: "id"
      },
      detail: {
        target: "detailGridContainer",
        parentGrid: "master",
        detailLoader: (rowData) => this.fetchDetailRows(rowData)
      }
    }
  }

  loadMasterData(event) {
    if (!event.detail) return
    this.setRows("master", event.detail || [])
  }

  // 기존 callback:onRowClicked 바인딩 호환용
  onMasterRowClicked() { }

  async fetchDetailRows(rowData) {
    const rowId = rowData?.id
    if (!rowId) return []

    try {
      const body = await fetchJson(`/om/order_modification_histories/${rowId}`)
      return Array.isArray(body?.items) ? body.items : []
    } catch (error) {
      console.error("이력 상세 정보 조회 오류", error)
      return []
    }
  }

  switchTab(event) {
    switchTab(event, this)
    this.resizeGridForTab(this.activeTab)
  }

  activateTab(tabId) {
    activateTab(tabId, this)
    this.resizeGridForTab(tabId)
  }

  resizeGridForTab(tabId) {
    setTimeout(() => {
      if (tabId === "master") {
        this.gridApi("master")?.sizeColumnsToFit?.()
      } else if (tabId === "detail") {
        this.gridApi("detail")?.sizeColumnsToFit?.()
      }
    }, 10)
  }
}
