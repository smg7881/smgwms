import BaseGridController from "controllers/base_grid_controller"
import { fetchJson } from "controllers/grid/grid_utils"

// 오더조회 화면 (마스터-디테일 읽기 전용)
export default class extends BaseGridController {
  static targets = [
    ...BaseGridController.targets,
    "masterGridContainer",
    "detailGridContainer",
    "detailHeaderLabel"
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
    this.resetDetail()
  }

  // 마스터 행 클릭 시 상세 아이템 조회
  async onMasterRowClicked(event) {
    if (!event.detail) return

    const row = event.detail.data
    if (!row || !row.id) return

    try {
      const body = await fetchJson(`/om/order_inquiries/${row.id}`)
      this.setRows("detail", body || [])

      if (this.hasDetailHeaderLabelTarget) {
        this.detailHeaderLabelTarget.textContent = `[${row.ord_no}] 상세 항목 리스트`
        this.detailHeaderLabelTarget.classList.remove("text-gray-500")
        this.detailHeaderLabelTarget.classList.add("text-blue-600")
      }
    } catch (e) {
      console.error("아이템 상세 조회 오류", e)
    }
  }

  // ─── Private ───

  resetDetail() {
    this.setRows("detail", [])
    if (this.hasDetailHeaderLabelTarget) {
      this.detailHeaderLabelTarget.textContent = "오더를 선택해주세요."
      this.detailHeaderLabelTarget.classList.remove("text-blue-600")
      this.detailHeaderLabelTarget.classList.add("text-gray-500")
    }
  }
}
