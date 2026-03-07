import BaseGridController from "controllers/base_grid_controller"
import { fetchJson } from "controllers/grid/grid_utils"

// 오더조회 화면 (마스터-디테일 자동 연동)
export default class extends BaseGridController {
  static targets = [
    ...BaseGridController.targets,
    "masterGridContainer",
    "detailGridContainer",
    "detailHeaderLabel"
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
        onMasterRowChange: (rowData) => this.updateDetailHeader(rowData),
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

  beforeSearchReset() {
    this.updateDetailHeader(null)
  }

  async fetchDetailRows(rowData) {
    const rowId = rowData?.id
    if (!rowId) return []

    try {
      const body = await fetchJson(`/om/order_inquiries/${rowId}`)
      return Array.isArray(body) ? body : []
    } catch (error) {
      console.error("아이템 상세 조회 오류", error)
      return []
    }
  }

  updateDetailHeader(rowData) {
    if (!this.hasDetailHeaderLabelTarget) return

    if (rowData?.ord_no) {
      this.detailHeaderLabelTarget.textContent = `[${rowData.ord_no}] 상세 항목 리스트`
      this.detailHeaderLabelTarget.classList.remove("text-gray-500")
      this.detailHeaderLabelTarget.classList.add("text-blue-600")
    } else {
      this.detailHeaderLabelTarget.textContent = "오더를 선택해주세요."
      this.detailHeaderLabelTarget.classList.remove("text-blue-600")
      this.detailHeaderLabelTarget.classList.add("text-gray-500")
    }
  }
}
