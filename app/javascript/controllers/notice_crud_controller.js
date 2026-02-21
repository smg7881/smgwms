import BaseCrudController from "controllers/base_crud_controller"

export default class extends BaseCrudController {
  static resourceName = "notice"
  static deleteConfirmKey = "title"
  static entityLabel = "공지사항"

  static targets = [
    "overlay", "modal", "modalTitle", "form",
    "fieldId", "fieldCategoryCode", "fieldTitle",
    "fieldStartDate", "fieldEndDate", "fieldContent",
    "fieldAttachments", "existingFiles", "selectedFiles"
  ]

  static values = {
    createUrl: String,
    updateUrl: String,
    deleteUrl: String,
    bulkDeleteUrl: String
  }

  connect() {
    this.removedAttachmentIds = new Set()
    this.selectedFilesBuffer = []

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
    this.renderSelectedFiles()
  }

  setRadioValue(field, value) {
    const scope = this.formScopeKey()
    this.formTarget.querySelectorAll(`input[type='radio'][name='${scope}[${field}]']`).forEach((radio) => {
      radio.checked = radio.value === value
    })
  }

  formScopeKey() {
    const candidateName = this.hasFieldCategoryCodeTarget
      ? this.fieldCategoryCodeTarget.name
      : this.formTarget.querySelector("[name*='[']")?.name

    const match = String(candidateName || "").match(/^([^\[]+)\[/)
    return match ? match[1] : this.constructor.resourceName
  }

  triggerAttachmentSelect() {
    if (!this.hasFieldAttachmentsTarget) return

    this.fieldAttachmentsTarget.click()
  }

  handleFileInputChange() {
    if (!this.hasFieldAttachmentsTarget) return

    const incomingFiles = Array.from(this.fieldAttachmentsTarget.files || [])
    this.addIncomingFiles(incomingFiles)
  }

  handleAttachmentDragEnter(event) {
    event.preventDefault()
    this.setDropzoneState(event.currentTarget, true)
  }

  handleAttachmentDragOver(event) {
    event.preventDefault()
    if (event.dataTransfer) {
      event.dataTransfer.dropEffect = "copy"
    }
    this.setDropzoneState(event.currentTarget, true)
  }

  handleAttachmentDragLeave(event) {
    event.preventDefault()

    if (event.currentTarget.contains(event.relatedTarget)) {
      return
    }

    this.setDropzoneState(event.currentTarget, false)
  }

  handleAttachmentDrop(event) {
    event.preventDefault()
    this.setDropzoneState(event.currentTarget, false)

    const incomingFiles = Array.from(event.dataTransfer?.files || [])
    this.addIncomingFiles(incomingFiles)
  }

  setDropzoneState(dropzoneElement, isActive) {
    if (!dropzoneElement) return

    dropzoneElement.classList.toggle("is-dragover", isActive)
  }

  addIncomingFiles(incomingFiles) {
    if (!Array.isArray(incomingFiles) || incomingFiles.length === 0) return

    let files = this.mergeSelectedFiles(incomingFiles)
    const maxFiles = Number.parseInt(this.fieldAttachmentsTarget.dataset.maxFiles || "0", 10)
    const maxSizeMb = Number.parseInt(this.fieldAttachmentsTarget.dataset.maxSizeMb || "0", 10)

    if (Number.isFinite(maxFiles) && maxFiles > 0 && files.length > maxFiles) {
      alert(`첨부파일은 최대 ${maxFiles}개까지 업로드할 수 있습니다.`)
      files = files.slice(0, maxFiles)
    }

    if (Number.isFinite(maxSizeMb) && maxSizeMb > 0) {
      const maxBytes = maxSizeMb * 1024 * 1024
      const oversizedFiles = files.filter((file) => file.size > maxBytes)

      if (oversizedFiles.length > 0) {
        alert(`파일당 최대 용량은 ${maxSizeMb}MB입니다.`)
        files = files.filter((file) => file.size <= maxBytes)
      }
    }

    this.selectedFilesBuffer = files
    this.syncSelectedFiles()
    this.renderSelectedFiles()
  }

  mergeSelectedFiles(incomingFiles) {
    const fileMap = new Map()
    ;[...this.selectedFilesBuffer, ...incomingFiles].forEach((file) => {
      const key = `${file.name}:${file.size}:${file.lastModified}:${file.type}`
      if (!fileMap.has(key)) {
        fileMap.set(key, file)
      }
    })
    return Array.from(fileMap.values())
  }

  syncSelectedFiles() {
    if (!this.hasFieldAttachmentsTarget) return

    if (typeof DataTransfer === "undefined") {
      if (this.selectedFilesBuffer.length === 0) {
        this.fieldAttachmentsTarget.value = ""
      }
      return
    }

    const dataTransfer = new DataTransfer()
    this.selectedFilesBuffer.forEach((file) => dataTransfer.items.add(file))
    this.fieldAttachmentsTarget.files = dataTransfer.files
  }

  removeSelectedFile(index) {
    if (!this.hasFieldAttachmentsTarget) return

    if (index < 0 || index >= this.selectedFilesBuffer.length) return

    this.selectedFilesBuffer.splice(index, 1)
    this.syncSelectedFiles()
    this.renderSelectedFiles()
  }

  renderExistingFiles(files) {
    if (!this.hasExistingFilesTarget) return

    this.existingFilesTarget.innerHTML = ""
    if (!Array.isArray(files) || files.length === 0) {
      return
    }

    files.forEach((file) => {
      const rowElement = this.buildFileRow({
        name: file.filename,
        sizeLabel: this.formatFileSize(file.byte_size),
        tone: this.fileTone(file.filename, file.content_type),
        url: file.url
      })

      const removeButton = rowElement.querySelector("[data-role='remove']")
      removeButton.addEventListener("click", () => {
        this.markAttachmentForRemoval(file.id, rowElement)
      })

      this.existingFilesTarget.appendChild(rowElement)
    })
  }

  renderSelectedFiles() {
    if (!this.hasSelectedFilesTarget) return

    this.selectedFilesTarget.innerHTML = ""
    if (!this.hasFieldAttachmentsTarget) return

    const files = this.selectedFilesBuffer
    if (files.length === 0) {
      return
    }

    files.forEach((file, index) => {
      const rowElement = this.buildFileRow({
        name: file.name,
        sizeLabel: this.formatFileSize(file.size),
        tone: this.fileTone(file.name, file.type)
      })

      const removeButton = rowElement.querySelector("[data-role='remove']")
      removeButton.addEventListener("click", () => {
        this.removeSelectedFile(index)
      })

      this.selectedFilesTarget.appendChild(rowElement)
    })
  }

  markAttachmentForRemoval(attachmentId, rowElement) {
    if (!attachmentId) return

    this.removedAttachmentIds.add(String(attachmentId))
    rowElement.remove()
  }

  async save() {
    const formData = new FormData(this.formTarget)
    const scope = this.formScopeKey()

    this.removedAttachmentIds.forEach((attachmentId) => {
      formData.append(`${scope}[remove_attachment_ids][]`, attachmentId)
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
    this.selectedFilesBuffer = []
    this.syncSelectedFiles()

    this.renderSelectedFiles()
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

  configureContentEditor(event) {
    const editor = event.target
    if (!(editor instanceof HTMLElement)) return
    if (editor.dataset.disableFileAttachments !== "true") return

    const toolbarId = editor.getAttribute("toolbar")
    if (!toolbarId) return

    const toolbar = this.formTarget.querySelector(`#${toolbarId}`) || document.getElementById(toolbarId)
    if (!toolbar) return

    toolbar.querySelectorAll(".trix-button-group--file-tools, .trix-button--icon-attach").forEach((element) => {
      element.setAttribute("hidden", "hidden")
    })
  }

  preventTrixFileAttach(event) {
    event.preventDefault()
    alert("본문에는 파일을 첨부할 수 없습니다. 하단 첨부파일 영역을 사용해주세요.")
  }

  buildFileRow({ name, sizeLabel, tone, url = null }) {
    const rowElement = document.createElement("li")
    rowElement.classList.add("rf-multi-file-item")

    const iconElement = document.createElement("div")
    iconElement.classList.add("rf-multi-file-item-icon", `rf-multi-file-item-icon--${tone}`)

    const extElement = document.createElement("span")
    extElement.classList.add("rf-multi-file-item-ext")
    extElement.textContent = this.fileExtension(name)
    iconElement.appendChild(extElement)

    const contentElement = document.createElement("div")
    contentElement.classList.add("rf-multi-file-item-body")

    const nameElement = url ? document.createElement("a") : document.createElement("span")
    nameElement.classList.add("rf-multi-file-item-name")
    nameElement.textContent = name

    if (url) {
      nameElement.href = url
      nameElement.dataset.turboFrame = "_top"
      nameElement.target = "_blank"
      nameElement.rel = "noopener noreferrer"
    }

    const fileLabel = sizeLabel ? `${name} (${sizeLabel})` : name
    nameElement.textContent = fileLabel

    contentElement.appendChild(nameElement)

    const removeButton = document.createElement("button")
    removeButton.type = "button"
    removeButton.classList.add("rf-multi-file-remove")
    removeButton.textContent = "×"
    removeButton.setAttribute("aria-label", `${name} 삭제`)
    removeButton.setAttribute("data-role", "remove")

    rowElement.appendChild(iconElement)
    rowElement.appendChild(contentElement)
    rowElement.appendChild(removeButton)

    return rowElement
  }

  fileTone(filename, contentType) {
    const extension = this.fileExtension(filename).toLowerCase()
    const normalizedType = String(contentType || "").toLowerCase()

    if (["xlsx", "xls", "csv"].includes(extension) || normalizedType.includes("sheet")) {
      return "green"
    }

    if (extension === "pdf" || normalizedType.includes("pdf")) {
      return "blue"
    }

    if (["jpg", "jpeg", "png", "gif", "webp", "svg"].includes(extension) || normalizedType.startsWith("image/")) {
      return "amber"
    }

    return "slate"
  }

  fileExtension(filename) {
    const fileName = String(filename || "")
    const parts = fileName.split(".")

    if (parts.length < 2) {
      return "FILE"
    }

    return parts.at(-1).toUpperCase().slice(0, 4)
  }

  formatFileSize(bytes) {
    const size = Number(bytes)
    if (!Number.isFinite(size) || size <= 0) {
      return "0 B"
    }

    const units = ["B", "KB", "MB", "GB"]
    let value = size
    let unitIndex = 0

    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024
      unitIndex += 1
    }

    const rounded = value >= 10 || unitIndex === 0 ? Math.round(value) : value.toFixed(1)
    return `${rounded} ${units[unitIndex]}`
  }
}
