import { Controller } from "@hotwired/stimulus"
import { fetchJson, getCsrfToken, isApiAlive, setGridRowData } from "controllers/grid/grid_utils"

export default class extends Controller {
  static targets = ["masterGrid", "detailGrid", "fileInput"]

  static values = {
    reprocessUrl: String,
    itemsUrl: String,
    downloadUrl: String,
    uploadUrl: String
  }

  connect() {
    this.masterApi = null
    this.detailApi = null
  }

  registerGrid(event) {
    if (event.target === this.masterGridTarget) {
      this.masterApi = event.detail.api
      return
    }

    if (event.target === this.detailGridTarget) {
      this.detailApi = event.detail.api
    }
  }

  async handleSelectionChanged(event) {
    if (event.target !== this.masterGridTarget) {
      return
    }

    const selectedRows = event.detail?.api?.getSelectedRows?.() || []
    if (selectedRows.length === 0) {
      this.clearDetailRows()
      return
    }

    const selected = selectedRows[0]
    await this.loadDetailRows(selected.id)
  }

  async loadDetailRows(errorId) {
    if (!errorId) {
      this.clearDetailRows()
      return
    }

    try {
      const rows = await fetchJson(`${this.itemsUrlValue}?error_id=${encodeURIComponent(errorId)}`)
      this.setDetailRows(rows)
    } catch {
      alert("오류 상세를 불러오지 못했습니다.")
      this.clearDetailRows()
    }
  }

  clearDetailRows() {
    this.setDetailRows([])
  }

  setDetailRows(rows) {
    if (!isApiAlive(this.detailApi)) {
      return
    }
    setGridRowData(this.detailApi, rows)
  }

  async reprocess() {
    if (!isApiAlive(this.masterApi)) {
      return
    }

    const selectedRows = this.masterApi.getSelectedRows() || []
    if (selectedRows.length === 0) {
      alert("재처리할 오류를 선택해 주세요.")
      return
    }

    const errorIds = selectedRows
      .map((row) => Number(row.id))
      .filter((value) => Number.isInteger(value) && value > 0)

    if (errorIds.length === 0) {
      alert("재처리 대상 식별값이 없습니다.")
      return
    }

    if (!confirm(`${errorIds.length}건을 재처리하시겠습니까?`)) {
      return
    }

    try {
      const response = await fetch(this.reprocessUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": getCsrfToken()
        },
        body: JSON.stringify({ error_ids: errorIds })
      })
      const result = await response.json()

      if (!response.ok || !result.success) {
        alert(result.message || "재처리에 실패했습니다.")
        return
      }

      alert(result.message || "재처리가 완료되었습니다.")
      this.refreshMasterRows()
      this.clearDetailRows()
    } catch {
      alert("재처리 중 통신 오류가 발생했습니다.")
    }
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
    if (!file) {
      return
    }

    const payload = new FormData()
    payload.append("file", file)

    try {
      const response = await fetch(this.uploadUrlValue, {
        method: "POST",
        headers: {
          "X-CSRF-Token": getCsrfToken()
        },
        body: payload
      })
      const result = await response.json()

      if (!response.ok || !result.success) {
        alert(result.message || "오류 업로드에 실패했습니다.")
        return
      }

      alert(result.message || "오류 업로드가 완료되었습니다.")
      this.refreshMasterRows()
      this.clearDetailRows()
    } catch {
      alert("오류 업로드 중 통신 오류가 발생했습니다.")
    } finally {
      input.value = ""
    }
  }

  refreshMasterRows() {
    const controller = this.application.getControllerForElementAndIdentifier(this.masterGridTarget, "ag-grid")
    if (controller?.refresh) {
      controller.refresh()
    }
  }
}
