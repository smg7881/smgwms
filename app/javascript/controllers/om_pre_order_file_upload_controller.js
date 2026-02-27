import { Controller } from "@hotwired/stimulus"
import { showAlert, confirmAction } from "components/ui/alert"
import { registerGridInstance } from "controllers/grid/core/grid_registration"

export default class extends Controller {
  static targets = ["grid", "summary", "uploadFileInput"]

  static values = {
    previewUrl: String,
    validateUrl: String,
    saveUrl: String,
    templateUrl: String
  }

  connect() {
    this.gridController = null
    this.canSave = false
    this.updateSaveButtonState()
  }

  registerGrid(event) {
    registerGridInstance(event, this, [
      { target: this.hasGridTarget ? this.gridTarget : null, controllerKey: "gridController" }
    ])
  }

  preview(event) {
    event.preventDefault()
    this.submitFile(this.previewUrlValue, "preview")
  }

  validate(event) {
    event.preventDefault()
    this.submitFile(this.validateUrlValue, "validate")
  }

  save(event) {
    event.preventDefault()
    if (!this.canSave) {
      showAlert("필수항목체크를 먼저 완료해주세요.")
      return
    }

    this.submitFile(this.saveUrlValue, "save")
  }

  downloadTemplate(event) {
    event.preventDefault()
    if (!this.templateUrlValue) return

    window.location.href = this.templateUrlValue
  }

  async submitFile(url, actionName) {
    const fileInput = this.fileInputElement()
    if (!fileInput || fileInput.files.length === 0) {
      showAlert("업로드 파일을 선택해주세요.")
      return
    }

    const formData = this.buildFormData(fileInput)
    this.setSummaryText("처리 중입니다...")

    try {
      const response = await fetch(url, {
        method: "POST",
        headers: this.requestHeaders(),
        body: formData
      })
      const data = await response.json()

      this.applyRows(data.rows || [])
      this.applySummary(data, response.ok)

      if (actionName === "save" && response.ok && data.success) {
        this.canSave = false
        fileInput.value = ""
      } else {
        this.canSave = Boolean(data.can_save) && response.ok
      }
      this.updateSaveButtonState()

      if (!response.ok && data.message) {
        showAlert(data.message)
      } else if (actionName === "save" && data.message) {
        showAlert(data.message)
      }
    } catch (_error) {
      this.canSave = false
      this.updateSaveButtonState()
      this.setSummaryText("요청 처리 중 오류가 발생했습니다.")
      showAlert("요청 처리 중 오류가 발생했습니다.")
    }
  }

  buildFormData(fileInput) {
    const form = this.element.querySelector("form")
    if (form) {
      const formData = new FormData(form)
      if (!formData.has("q[upload_file]")) {
        formData.append("q[upload_file]", fileInput.files[0])
      }
      return formData
    }

    const fallback = new FormData()
    fallback.append("q[upload_file]", fileInput.files[0])
    return fallback
  }

  requestHeaders() {
    const headers = { Accept: "application/json" }
    const csrf = document.querySelector("meta[name='csrf-token']")?.getAttribute("content")
    if (csrf) {
      headers["X-CSRF-Token"] = csrf
    }
    return headers
  }

  applyRows(rows) {
    if (!this.gridController?.api) return

    this.gridController.api.setGridOption("rowData", rows)
  }

  applySummary(data, isOk) {
    const summary = data.summary || {}
    const total = Number(summary.total_count || 0)
    const success = Number(summary.success_count || 0)
    const error = Number(summary.error_count || 0)
    const statusPrefix = isOk ? "처리결과" : "오류"
    const message = data.message || ""
    this.setSummaryText(`${statusPrefix}: 총 ${total}건 / 성공 ${success}건 / 오류 ${error}건${message ? ` - ${message}` : ""}`)
  }

  setSummaryText(text) {
    if (!this.hasSummaryTarget) return

    this.summaryTarget.textContent = text
  }

  updateSaveButtonState() {
    const saveButton = this.element.querySelector('[data-action*="om-pre-order-file-upload#save"]')
    if (!saveButton) return

    saveButton.disabled = !this.canSave
  }

  fileInputElement() {
    if (this.hasUploadFileInputTarget) {
      return this.uploadFileInputTarget
    }

    return this.element.querySelector('input[type="file"][name="q[upload_file]"]')
  }
}
