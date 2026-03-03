import BaseGridController from "controllers/base_grid_controller"
import { showAlert, confirmAction } from "components/ui/alert"
import { fetchJson, getCsrfToken } from "controllers/grid/grid_utils"

// 사전오더접수오류 화면 (마스터-디테일 + 재처리/업로드 액션)
export default class extends BaseGridController {
  static targets = [
    ...BaseGridController.targets,
    "masterGrid",
    "detailGrid",
    "fileInput"
  ]

  static values = {
    ...BaseGridController.values,
    reprocessUrl: String,
    itemsUrl: String,
    downloadUrl: String,
    uploadUrl: String
  }

  gridRoles() {
    return {
      master: { target: "masterGrid" },
      detail: { target: "detailGrid" }
    }
  }

  async handleSelectionChanged(event) {
    if (event.target !== this.masterGridTarget) return

    const selected = event.detail?.api?.getSelectedRows?.() || []
    if (selected.length === 0) {
      this.setRows("detail", [])
      return
    }

    await this.#loadDetailRows(selected[0].id)
  }

  async reprocess() {
    const selected = this.selectedRows("master")
    if (selected.length === 0) {
      showAlert("재처리할 오류를 선택해 주세요.")
      return
    }

    const errorIds = selected
      .map((row) => Number(row.id))
      .filter((value) => Number.isInteger(value) && value > 0)

    if (errorIds.length === 0) {
      showAlert("재처리 대상 식별값이 없습니다.")
      return
    }

    await this.postAction(
      this.reprocessUrlValue,
      { error_ids: errorIds },
      {
        confirmMessage: `${errorIds.length}건을 재처리하시겠습니까?`,
        onSuccess: (result) => {
          showAlert(result.message || "재처리가 완료되었습니다.")
          this.refreshGrid("master")
          this.setRows("detail", [])
        },
        onFail: (result) => {
          showAlert(result.message || "재처리에 실패했습니다.")
        }
      }
    )
  }

  downloadTemplate() {
    window.location.href = this.downloadUrlValue
  }

  openUploadDialog() {
    if (this.hasFileInputTarget) {
      this.fileInputTarget.click()
    }
  }

  async uploadFile(event) {
    const input = event.target
    const file = input.files?.[0]
    if (!file) return

    const payload = new FormData()
    payload.append("file", file)

    try {
      const response = await fetch(this.uploadUrlValue, {
        method: "POST",
        headers: { "X-CSRF-Token": getCsrfToken() },
        body: payload
      })
      const result = await response.json()

      if (!response.ok || !result.success) {
        showAlert(result.message || "오류 업로드에 실패했습니다.")
        return
      }

      showAlert(result.message || "오류 업로드가 완료되었습니다.")
      this.refreshGrid("master")
      this.setRows("detail", [])
    } catch {
      showAlert("오류 업로드 중 통신 오류가 발생했습니다.")
    } finally {
      input.value = ""
    }
  }

  // ─── Private ───

  async #loadDetailRows(errorId) {
    if (!errorId) {
      this.setRows("detail", [])
      return
    }

    try {
      const rows = await fetchJson(`${this.itemsUrlValue}?error_id=${encodeURIComponent(errorId)}`)
      this.setRows("detail", rows)
    } catch {
      showAlert("오류 상세를 불러오지 못했습니다.")
      this.setRows("detail", [])
    }
  }
}
