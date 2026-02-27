/**
 * AttachmentMixin
 *
 * Stimulus 컨트롤러에 멀티 파일 첨부 기능을 추가하는 믹스인입니다.
 * notice_crud_controller 등 첨부파일이 필요한 컨트롤러에서 재사용합니다.
 *
 * 적용 방법:
 *   import { AttachmentMixin } from "controllers/concerns/attachment_mixin"
 *   Object.assign(MyController.prototype, AttachmentMixin)
 *
 * 컨트롤러 static targets에 반드시 포함해야 할 항목:
 *   - "fieldAttachments" : input[type=file] 숨겨진 파일 입력 요소
 *   - "existingFiles"    : 기존 첨부파일(서버 저장분) 렌더 영역
 *   - "selectedFiles"    : 업로드 대기 중인 파일 렌더 영역
 *
 * 컨트롤러 생명주기 훅에서 호출해야 할 메서드:
 *   - connect()    → this.initAttachment()
 *   - resetForm()  → this.resetAttachment()
 *   - save()       → this.appendRemovedAttachmentIds(formData, scope)
 */
import { showAlert } from "components/ui/alert"

export const AttachmentMixin = {
  // ===================== [상태 초기화 헬퍼] =========================

  // 첨부파일 상태 초기화 (connect()에서 호출)
  initAttachment() {
    this.removedAttachmentIds = new Set() // 삭제 대기 중인 기존 첨부파일 ID 집합
    this.selectedFilesBuffer = []         // 업로드 대기 중인 File 객체 배열
  },

  // 첨부파일 영역 전체 리셋 (resetForm()에서 호출)
  resetAttachment() {
    this.removedAttachmentIds = new Set()
    this.renderExistingFiles([])

    if (this.hasFieldAttachmentsTarget) {
      this.fieldAttachmentsTarget.value = ""
    }
    this.selectedFilesBuffer = []
    this.syncSelectedFiles()
    this.renderSelectedFiles()
  },

  // 삭제 대기 중인 첨부파일 ID들을 FormData에 추가 (save()에서 호출)
  appendRemovedAttachmentIds(formData, scope) {
    this.removedAttachmentIds.forEach((attachmentId) => {
      formData.append(`${scope}[remove_attachment_ids][]`, attachmentId)
    })
  },

  // ===================== [첨부파일 입력 제어] =========================

  // "파일 추가" 버튼 클릭 시 진짜 input[type=file]을 대리 클릭함 (디자인 목적)
  triggerAttachmentSelect() {
    if (!this.hasFieldAttachmentsTarget) return
    this.fieldAttachmentsTarget.click()
  },

  // input[type=file] 값 변동 시 트리거됨
  handleFileInputChange() {
    if (!this.hasFieldAttachmentsTarget) return

    const incomingFiles = Array.from(this.fieldAttachmentsTarget.files || [])
    this.addIncomingFiles(incomingFiles)
  },

  // ===================== [Drag & Drop] =========================

  handleAttachmentDragEnter(event) {
    event.preventDefault()
    this.setDropzoneState(event.currentTarget, true)
  },

  handleAttachmentDragOver(event) {
    event.preventDefault()
    if (event.dataTransfer) {
      event.dataTransfer.dropEffect = "copy"
    }
    this.setDropzoneState(event.currentTarget, true)
  },

  handleAttachmentDragLeave(event) {
    event.preventDefault()
    if (event.currentTarget.contains(event.relatedTarget)) {
      return
    }
    this.setDropzoneState(event.currentTarget, false)
  },

  handleAttachmentDrop(event) {
    event.preventDefault()
    this.setDropzoneState(event.currentTarget, false) // 놔뒀으니 하이라이팅 제거

    const incomingFiles = Array.from(event.dataTransfer?.files || [])
    this.addIncomingFiles(incomingFiles)
  },

  // 드롭존 시각적 피드백 토글
  setDropzoneState(dropzoneElement, isActive) {
    if (!dropzoneElement) return
    dropzoneElement.classList.toggle("is-dragover", isActive)
  },

  // ===================== [파일 버퍼 관리] =========================

  // 파일 중복 검사, 용량 제한, 갯수 제한 수행 후 버퍼에 담음
  addIncomingFiles(incomingFiles) {
    if (!Array.isArray(incomingFiles) || incomingFiles.length === 0) return

    let files = this.mergeSelectedFiles(incomingFiles)
    // HTML Data 속성에서 설정된 제약사항 파싱
    const maxFiles = Number.parseInt(this.fieldAttachmentsTarget.dataset.maxFiles || "0", 10)
    const maxSizeMb = Number.parseInt(this.fieldAttachmentsTarget.dataset.maxSizeMb || "0", 10)

    // 파일 갯수 초과 커트
    if (Number.isFinite(maxFiles) && maxFiles > 0 && files.length > maxFiles) {
      showAlert(`첨부 파일은 최대 ${maxFiles}개까지 업로드할 수 있습니다.`)
      files = files.slice(0, maxFiles)
    }

    // 파일 용량 초과 커트
    if (Number.isFinite(maxSizeMb) && maxSizeMb > 0) {
      const maxBytes = maxSizeMb * 1024 * 1024
      const oversizedFiles = files.filter((file) => file.size > maxBytes)

      if (oversizedFiles.length > 0) {
        showAlert(`파일 최대 용량은 ${maxSizeMb}MB입니다.`)
        files = files.filter((file) => file.size <= maxBytes)
      }
    }

    // 최종 통과된 파일들을 버퍼에 등록하고 화면에 그림
    this.selectedFilesBuffer = files
    this.syncSelectedFiles()
    this.renderSelectedFiles()
  },

  // 기존 버퍼와 새로 들어온 파일 목록을 유니크 기준으로 합침
  mergeSelectedFiles(incomingFiles) {
    const fileMap = new Map()
      ;[...this.selectedFilesBuffer, ...incomingFiles].forEach((file) => {
        // 파일명, 크기, 최종수정일시를 합쳐서 고유 키로 활용
        const key = `${file.name}:${file.size}:${file.lastModified}:${file.type}`
        if (!fileMap.has(key)) {
          fileMap.set(key, file)
        }
      })
    return Array.from(fileMap.values())
  },

  // JS File 객체 배열 → 진짜 HTML input[type=file]의 FileList로 DataTransfer 씌워치기
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
  },

  // 업로드 대기열 파일 중 X버튼으로 개별 제거
  removeSelectedFile(index) {
    if (!this.hasFieldAttachmentsTarget) return
    if (index < 0 || index >= this.selectedFilesBuffer.length) return

    this.selectedFilesBuffer.splice(index, 1)
    this.syncSelectedFiles()
    this.renderSelectedFiles()
  },

  // ===================== [파일 목록 렌더링] =========================

  // 이미 서버 DB에 기록되어 있는 파일(Existing)을 렌더링함
  renderExistingFiles(files) {
    if (!this.hasExistingFilesTarget) return

    this.existingFilesTarget.innerHTML = ""
    if (!Array.isArray(files) || files.length === 0) {
      return
    }

    files.forEach((file) => {
      // 다운로드 링크(URL)가 내포된 Row UI 생성
      const rowElement = this.buildFileRow({
        name: file.filename,
        sizeLabel: this.formatFileSize(file.byte_size),
        tone: this.fileTone(file.filename, file.content_type),
        url: file.url
      })

      // X버튼 누르면 삭제 대기열(removedAttachmentIds Set)에 식별자 추가
      const removeButton = rowElement.querySelector("[data-role='remove']")
      removeButton.addEventListener("click", () => {
        this.markAttachmentForRemoval(file.id, rowElement)
      })

      this.existingFilesTarget.appendChild(rowElement)
    })
  },

  // 업로드 대기 중인 파일 렌더링
  renderSelectedFiles() {
    if (!this.hasSelectedFilesTarget) return

    this.selectedFilesTarget.innerHTML = ""
    if (!this.hasFieldAttachmentsTarget) return

    const files = this.selectedFilesBuffer
    if (files.length === 0) {
      return
    }

    files.forEach((file, index) => {
      // 링크 없이 이름만 표시
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
  },

  // 기존 파일 삭제 대기열에 추가 (화면에서는 즉시 숨김, Save 시 서버에 반영)
  markAttachmentForRemoval(attachmentId, rowElement) {
    if (!attachmentId) return

    this.removedAttachmentIds.add(String(attachmentId))
    rowElement.remove()
  },

  // ===================== [UI 렌더링 헬퍼] =========================

  // 첨부파일 뱃지 <li> 컴포넌트 HTML 노드 팩토리
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

    if (url) {
      nameElement.href = url
      nameElement.dataset.turboFrame = "_top" // Turbo Drive 무시
      nameElement.target = "_blank"
      nameElement.rel = "noopener noreferrer"
    }

    const fileLabel = sizeLabel ? `${name} (${sizeLabel})` : name
    nameElement.textContent = fileLabel

    contentElement.appendChild(nameElement)

    const removeButton = document.createElement("button")
    removeButton.type = "button"
    removeButton.classList.add("rf-multi-file-remove")
    removeButton.textContent = "횞"
    removeButton.setAttribute("aria-label", `${name} 삭제`)
    removeButton.setAttribute("data-role", "remove")

    rowElement.appendChild(iconElement)
    rowElement.appendChild(contentElement)
    rowElement.appendChild(removeButton)

    return rowElement
  },

  // 확장자에 따른 CSS 색상 토큰 결정
  fileTone(filename, contentType) {
    const extension = this.fileExtension(filename).toLowerCase()
    const normalizedType = String(contentType || "").toLowerCase()

    if (["xlsx", "xls", "csv"].includes(extension) || normalizedType.includes("sheet")) {
      return "green" // 엑셀
    }

    if (extension === "pdf" || normalizedType.includes("pdf")) {
      return "blue"  // PDF
    }

    if (["jpg", "jpeg", "png", "gif", "webp", "svg"].includes(extension) || normalizedType.startsWith("image/")) {
      return "amber" // 이미지
    }

    return "slate"   // 기타 기본
  },

  fileExtension(filename) {
    const fileName = String(filename || "")
    const parts = fileName.split(".")
    if (parts.length < 2) return "FILE"

    return parts.at(-1).toUpperCase().slice(0, 4) // ZIP, XLSX 같이 맨 뒤 4글자
  },

  // 바이트 단위를 사람이 읽기 좋은 단위로 변환 (예: 4096000 → "4 MB")
  formatFileSize(bytes) {
    const size = Number(bytes)
    if (!Number.isFinite(size) || size <= 0) return "0 B"

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
