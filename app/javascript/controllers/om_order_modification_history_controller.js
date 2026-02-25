import BaseGridController from "controllers/base_grid_controller"
import { fetchJson } from "controllers/grid/grid_utils"

// 오더수정이력 화면 (마스터-디테일 읽기 전용)
export default class extends BaseGridController {
  static targets = [
    ...BaseGridController.targets,
    "masterGridContainer",
    "detailGridContainer"
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
}
