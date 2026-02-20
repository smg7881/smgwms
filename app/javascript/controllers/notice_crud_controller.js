import BaseCrudController from "controllers/base_crud_controller"

export default class extends BaseCrudController {
  static resourceName = "notice"
  static deleteConfirmKey = "title"
  static entityLabel = "공지사항"

  static targets = [
    "overlay", "modal", "modalTitle", "form",
    "fieldId", "fieldCategoryCode", "fieldTitle",
    "fieldStartDate", "fieldEndDate", "fieldContent",
    "fieldAttachments", "existingFiles"
  ]

  static values = {
    createUrl: String,
    updateUrl: String,
    deleteUrl: String,
    bulkDeleteUrl: String
  }

  connect() {
    this.removedAttachmentIds = new Set()

    this.connectBase({
      events: [
        { name: "notice-crud:edit", handler: this.handleEdit },
        { name: "notice-crud:delete", handler: this.handleDelete }
      ]
    })
  }

  disconnect() {
    this.disconnectBase()
  }

  openCreate() {
    this.resetForm()
    this.modalTitleTarget.textContent = "공지사항 등록"
    this.mode = "create"
    this.openModal()
  }

  handleEdit = async (event) => {
    const { id } = event.detail
    if (!id) return

    this.resetForm()
    this.modalTitleTarget.textContent = "공지사항 수정"

    const url = this.updateUrlValue.replace(":id", id)
    try {
      const response = await fetch(url, { headers: { Accept: "application/json" } })
      if (!response.ok) {
        alert("상세 조회에 실패했습니다.")
        return
      }

      const data = await response.json()
      this.fillForm(data)
      this.mode = "update"
      this.openModal()
    } catch {
      alert("상세 조회에 실패했습니다.")
    }
  }

  fillForm(data) {
    this.fieldIdTarget.value = data.id || ""
    this.fieldCategoryCodeTarget.value = data.category_code || ""
    this.fieldTitleTarget.value = data.title || ""
    this.fieldStartDateTarget.value = data.start_date || ""
    this.fieldEndDateTarget.value = data.end_date || ""
    this.setContentValue(data.content || "")
    this.setRadioValue("is_top_fixed", data.is_top_fixed || "N")
    this.setRadioValue("is_published", data.is_published || "Y")
    this.renderExistingFiles(data.attachments || [])
  }

  setRadioValue(field, value) {
    this.formTarget.querySelectorAll(`input[type='radio'][name='notice[${field}]']`).forEach((radio) => {
      radio.checked = radio.value === value
    })
  }

  renderExistingFiles(files) {
    if (!this.hasExistingFilesTarget) return

    this.existingFilesTarget.innerHTML = ""
    if (!Array.isArray(files) || files.length === 0) {
      return
    }

    files.forEach((file) => {
      const li = document.createElement("li")
      const link = document.createElement("a")
      link.href = file.url
      link.dataset.turboFrame = "_top"
      link.target = "_blank"
      link.rel = "noopener noreferrer"
      link.textContent = file.filename

      const removeButton = document.createElement("button")
      removeButton.type = "button"
      removeButton.classList.add("btn", "btn-sm", "btn-secondary", "ml-2")
      removeButton.textContent = "삭제"
      removeButton.addEventListener("click", () => {
        this.markAttachmentForRemoval(file.id, li)
      })

      li.appendChild(link)
      li.appendChild(removeButton)
      this.existingFilesTarget.appendChild(li)
    })
  }

  markAttachmentForRemoval(attachmentId, rowElement) {
    if (!attachmentId) return

    this.removedAttachmentIds.add(String(attachmentId))
    rowElement.remove()
  }

  handleFileInputChange() {
    // no-op: target only used for progressive enhancement and future validation
  }

  async save() {
    const formData = new FormData(this.formTarget)

    if (this.hasFieldAttachmentsTarget && this.fieldAttachmentsTarget.files.length > 0) {
      Array.from(this.fieldAttachmentsTarget.files).forEach((file) => {
        formData.append("notice[attachments][]", file)
      })
    }

    this.removedAttachmentIds.forEach((attachmentId) => {
      formData.append("notice[remove_attachment_ids][]", attachmentId)
    })

    const id = this.hasFieldIdTarget && this.fieldIdTarget.value ? this.fieldIdTarget.value : null
    const isCreate = this.mode === "create"
    const url = isCreate ? this.createUrlValue : this.updateUrlValue.replace(":id", id)
    const method = isCreate ? "POST" : "PATCH"

    try {
      const { response, result } = await this.requestJson(url, {
        method,
        body: formData,
        isMultipart: true
      })

      if (!response.ok || !result.success) {
        alert("저장 실패: " + (result.errors || ["요청 처리 실패"]).join(", "))
        return
      }

      alert(result.message || "저장되었습니다.")
      this.closeModal()
      this.refreshGrid()
    } catch {
      alert("저장 실패: 네트워크 오류")
    }
  }

  async deleteSelected() {
    const selectedRows = this.selectedRows()
    if (selectedRows.length === 0) {
      alert("삭제할 공지사항을 선택해주세요.")
      return
    }

    if (!confirm(`선택한 ${selectedRows.length}건을 삭제하시겠습니까?`)) {
      return
    }

    const ids = selectedRows.map((row) => row.id).filter((id) => Boolean(id))
    if (ids.length === 0) {
      alert("삭제할 공지사항을 선택해주세요.")
      return
    }

    try {
      const { response, result } = await this.requestJson(this.bulkDeleteUrlValue, {
        method: "DELETE",
        body: { ids }
      })

      if (!response.ok || !result.success) {
        alert("삭제 실패: " + (result.errors || ["요청 처리 실패"]).join(", "))
        return
      }

      alert(result.message || "삭제되었습니다.")
      this.refreshGrid()
    } catch {
      alert("삭제 실패: 네트워크 오류")
    }
  }

  selectedRows() {
    const agGridEl = this.element.querySelector("[data-controller='ag-grid']")
    if (!agGridEl) {
      return []
    }

    const agGridController = this.application.getControllerForElementAndIdentifier(agGridEl, "ag-grid")
    const api = agGridController?.api
    if (!api || typeof api.getSelectedRows !== "function") {
      return []
    }

    return api.getSelectedRows() || []
  }

  resetForm() {
    this.formTarget.reset()
    this.fieldIdTarget.value = ""
    this.removedAttachmentIds = new Set()
    this.setRadioValue("is_top_fixed", "N")
    this.setRadioValue("is_published", "Y")
    this.renderExistingFiles([])
    this.setContentValue("")

    if (this.hasFieldAttachmentsTarget) {
      this.fieldAttachmentsTarget.value = ""
    }
  }

  setContentValue(value) {
    if (!this.hasFieldContentTarget) return

    const content = value || ""
    const field = this.fieldContentTarget

    // Plain textarea fallback
    if (field.tagName === "TEXTAREA") {
      field.value = content
      return
    }

    // rich_textarea (trix-editor target)
    if (field.tagName === "TRIX-EDITOR") {
      if (field.editor && typeof field.editor.loadHTML === "function") {
        field.editor.loadHTML(content)
      }

      const inputId = field.getAttribute("input")
      if (inputId) {
        const hiddenInput = this.formTarget.querySelector(`#${inputId}`)
        if (hiddenInput) {
          hiddenInput.value = content
        }
      }
      return
    }

    // hidden input fallback
    field.value = content
    if (!field.id) return

    const editor = this.formTarget.querySelector(`trix-editor[input="${field.id}"]`)
    if (editor && editor.editor && typeof editor.editor.loadHTML === "function") {
      editor.editor.loadHTML(content)
    }
  }
}
