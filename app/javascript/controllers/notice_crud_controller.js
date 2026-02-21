/**
 * notice_crud_controller.js
 * 
 * [공통] BaseCrudController 상속체로서 "공지사항(Notice)" 게시판의 작성/수정 모달을 제어합니다.
 * 주요 확장 사양:
 * - 첨부파일(Attachments) 멀티 업로드 및 UI 상호작용 (Drag & Drop, 미리보기, 개별 삭제 등)
 * - Trix 에디터(ActionText)와의 연동 및 파일 첨부 금지 설정 (파일은 하단 전용 첨부영역 사용 유도)
 * - 기존 첨부파일 목록 렌더링 및 삭제 대기열(removedAttachmentIds) 상태 관리
 * - 그리드 다중 선택을 통한 일괄 삭제(Bulk Delete) 기능 지원
 */
import BaseCrudController from "controllers/base_crud_controller"

export default class extends BaseCrudController {
  static resourceName = "notice"      // 폼 데이터 생성 시 네임스페이스 (ex: notice[title])
  static deleteConfirmKey = "title"   // 삭제 확인 창에 띄울 필드 키맵
  static entityLabel = "공지사항"     // 얼럿 노출 텍스트

  // 공지사항 폼에서 통제하는 다양한 DOM 요소들
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
    bulkDeleteUrl: String // 일괄 삭제 전용 엔드포인트
  }

  connect() {
    this.removedAttachmentIds = new Set() // 기 등록된 첨부파일 중 삭제키를 누른 ID들의 집합 (저장 시 전송됨)
    this.selectedFilesBuffer = []         // 새로 업로드 하려고 올려둔(선택한) 파일 객체들의 임시 배열

    // 이벤트 리스너 파이프라인 등록
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

  // 신규 등록 모달 열기
  openCreate() {
    this.resetForm()
    this.modalTitleTarget.textContent = "공지사항 등록"
    this.mode = "create"
    this.openModal()
  }

  // 수정 버튼 클릭 시 비동기 조회 및 모달 열기
  handleEdit = async (event) => {
    const { id } = event.detail
    if (!id) return

    this.resetForm()
    this.modalTitleTarget.textContent = "공지사항 수정"

    const url = this.updateUrlValue.replace(":id", id)
    try {
      // 공지사항은 내용(content)이 크기 때문에, 그리드 셀 데이터에 안 넣고 서버에서 상세 Data를 별도로 Fetch 함.
      const response = await fetch(url, { headers: { Accept: "application/json" } })
      if (!response.ok) {
        alert("상세 조회에 실패했습니다.")
        return
      }

      const data = await response.json()
      // 받아온 JSON으로 폼 필드들을 채움
      this.fillForm(data)
      this.mode = "update"
      this.openModal()
    } catch {
      alert("상세 조회에 실패했습니다.")
    }
  }

  // 서버에서 받은 JSON 데이터를 기반으로 HTML 인풋 Value 세팅
  fillForm(data) {
    this.fieldIdTarget.value = data.id || ""
    this.fieldCategoryCodeTarget.value = data.category_code || ""
    this.fieldTitleTarget.value = data.title || ""
    this.fieldStartDateTarget.value = data.start_date || ""
    this.fieldEndDateTarget.value = data.end_date || ""

    // Trix 본문 에디터 내용 주입
    this.setContentValue(data.content || "")

    // 상단고정, 게시여부 라디오 버튼 UI 동기화
    this.setRadioValue("is_top_fixed", data.is_top_fixed || "N")
    this.setRadioValue("is_published", data.is_published || "Y")

    // 첨부파일 영역 UI 동기화
    this.renderExistingFiles(data.attachments || []) // 서버에 이미 있는 파일 뱃지 렌더
    this.renderSelectedFiles() // 혹시 남아있을 임시저장 파일 뱃지 렌더 (보통 비어있음)
  }

  // 네임스페이스 기반으로 라디오 버튼 그룹 중에 일치하는 value를 찾아 체크함
  setRadioValue(field, value) {
    const scope = this.formScopeKey()
    this.formTarget.querySelectorAll(`input[type='radio'][name='${scope}[${field}]']`).forEach((radio) => {
      radio.checked = radio.value === value
    })
  }

  // notice[title] 같이 감싸인 폼 Prefix 문자열 추출 로직
  formScopeKey() {
    const candidateName = this.hasFieldCategoryCodeTarget
      ? this.fieldCategoryCodeTarget.name
      : this.formTarget.querySelector("[name*='[']")?.name

    const match = String(candidateName || "").match(/^([^\[]+)\[/)
    return match ? match[1] : this.constructor.resourceName
  }

  // ===================== [첨부파일 제어 파트] =========================

  // "파일 추가" 버튼 클릭 시 진짜 input[type=file] 을 대리 클릭함 (디자인 목적)
  triggerAttachmentSelect() {
    if (!this.hasFieldAttachmentsTarget) return
    this.fieldAttachmentsTarget.click()
  }

  // input[type=file] 값 변동 혹은 드래그앤드랍 시 트리거됨
  handleFileInputChange() {
    if (!this.hasFieldAttachmentsTarget) return

    const incomingFiles = Array.from(this.fieldAttachmentsTarget.files || [])
    this.addIncomingFiles(incomingFiles)
  }

  // Drag & Drop UI 효과
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
    this.setDropzoneState(event.currentTarget, false) // 놔뒀으니 하일라이팅 제거

    // 드롭된 파일들을 배열로 뽑아 병합 로직으로 넘김
    const incomingFiles = Array.from(event.dataTransfer?.files || [])
    this.addIncomingFiles(incomingFiles)
  }

  // 드롭존 시각적 피드백 토글 
  setDropzoneState(dropzoneElement, isActive) {
    if (!dropzoneElement) return
    dropzoneElement.classList.toggle("is-dragover", isActive)
  }

  // 파일 중복 검사, 용량 제한, 갯수 제한 등을 수행 후 버퍼에 담음
  addIncomingFiles(incomingFiles) {
    if (!Array.isArray(incomingFiles) || incomingFiles.length === 0) return

    let files = this.mergeSelectedFiles(incomingFiles) // 중복 쳐내기 결합
    // HTML Data 속성에서 설정된 제약사항 파싱
    const maxFiles = Number.parseInt(this.fieldAttachmentsTarget.dataset.maxFiles || "0", 10)
    const maxSizeMb = Number.parseInt(this.fieldAttachmentsTarget.dataset.maxSizeMb || "0", 10)

    // 파일 갯수 초과 커트
    if (Number.isFinite(maxFiles) && maxFiles > 0 && files.length > maxFiles) {
      alert(`첨부 파일은 최대 ${maxFiles}개까지 업로드할 수 있습니다.`)
      files = files.slice(0, maxFiles)
    }

    // 파일 용량 초과 커트
    if (Number.isFinite(maxSizeMb) && maxSizeMb > 0) {
      const maxBytes = maxSizeMb * 1024 * 1024
      const oversizedFiles = files.filter((file) => file.size > maxBytes)

      if (oversizedFiles.length > 0) {
        alert(`파일 최대 용량은 ${maxSizeMb}MB입니다.`)
        files = files.filter((file) => file.size <= maxBytes)
      }
    }

    // 최종 통과된 파일들을 전역 버퍼에 등록하고 화면에 그림
    this.selectedFilesBuffer = files
    this.syncSelectedFiles()
    this.renderSelectedFiles()
  }

  // 기존 파일 목록(selectedFilesBuffer)과 새로 들어온 목록을 유니크 기준으로 합침
  mergeSelectedFiles(incomingFiles) {
    const fileMap = new Map()
      ;[...this.selectedFilesBuffer, ...incomingFiles].forEach((file) => {
        // 파일명, 크기, 최종수정일시간 등을 합쳐서 고유 키로 활용
        const key = `${file.name}:${file.size}:${file.lastModified}:${file.type}`
        if (!fileMap.has(key)) {
          fileMap.set(key, file)
        }
      })
    return Array.from(fileMap.values())
  }

  // JS File 객체 배열 -> 진짜 HTML input[type=file] 의 FileList로 DataTransfer 씌워치기
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

  // 화면에 렌더링된 업로드 '대기열' 파일 중 X표 눌러서 지우기
  removeSelectedFile(index) {
    if (!this.hasFieldAttachmentsTarget) return

    if (index < 0 || index >= this.selectedFilesBuffer.length) return

    this.selectedFilesBuffer.splice(index, 1) // 배열에서 축출
    this.syncSelectedFiles()                  // 인풋 동기화
    this.renderSelectedFiles()                // 화면 갱신
  }

  // 이미 서버 DB에 기록되어있는 파일(Existing)을 렌더링함
  renderExistingFiles(files) {
    if (!this.hasExistingFilesTarget) return

    this.existingFilesTarget.innerHTML = ""
    if (!Array.isArray(files) || files.length === 0) {
      return
    }

    files.forEach((file) => {
      // 다운로드 링크(URL) 가 내포된 Row UI 생성
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
  }

  // 이제 막 추가해서 서버로 올라가기 위해 '대기 중'인 파일 렌더링
  renderSelectedFiles() {
    if (!this.hasSelectedFilesTarget) return

    this.selectedFilesTarget.innerHTML = ""
    if (!this.hasFieldAttachmentsTarget) return

    const files = this.selectedFilesBuffer
    if (files.length === 0) {
      return
    }

    files.forEach((file, index) => {
      // 링크가 없이 이름만 뜸
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

  // 기존 파일 비동기 삭제 랙 걸기
  markAttachmentForRemoval(attachmentId, rowElement) {
    if (!attachmentId) return

    this.removedAttachmentIds.add(String(attachmentId)) // Set 에 추가
    rowElement.remove() // 화면에선 즉시 감춤 (Save 시 반영됨)
  }

  // 파일 업로드가 포함된 오버라이드 폼 전송 액션
  async save() {
    const formData = new FormData(this.formTarget)
    const scope = this.formScopeKey()

    // 삭데 대상으로 마킹된 기존 첨부파일 ID들을 싹싹 긁어서 FormData에 배열로 투척
    this.removedAttachmentIds.forEach((attachmentId) => {
      formData.append(`${scope}[remove_attachment_ids][]`, attachmentId)
    })

    const id = this.hasFieldIdTarget && this.fieldIdTarget.value ? this.fieldIdTarget.value : null
    const isCreate = this.mode === "create"
    const url = isCreate ? this.createUrlValue : this.updateUrlValue.replace(":id", id)
    const method = isCreate ? "POST" : "PATCH"

    try {
      // BaseCrudController의 요청 래퍼 사용 (Multipart 활성화 = 첨부파일 전송 허가)
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

  // ===================== [그리드 연계 액션] =========================

  // 메인 그리드에서 다중 체크박스로 여럿을 집어서 한방에 날릴때 사용
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
        body: { ids } // id 배열 전송
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
    const api = this.getAgGridController()?.api
    if (!api || typeof api.getSelectedRows !== "function") {
      return []
    }

    return api.getSelectedRows() || []
  }

  // 모달 데이터 백지화
  resetForm() {
    this.formTarget.reset()
    this.fieldIdTarget.value = ""
    this.removedAttachmentIds = new Set()
    this.setRadioValue("is_top_fixed", "N")
    this.setRadioValue("is_published", "Y")

    // 첨부 영역 비우기
    this.renderExistingFiles([])

    // Trix 비우기
    this.setContentValue("")

    if (this.hasFieldAttachmentsTarget) {
      this.fieldAttachmentsTarget.value = ""
    }
    this.selectedFilesBuffer = []
    this.syncSelectedFiles()

    this.renderSelectedFiles()
  }

  // Trix 라이브러리 (RichText) 내부에 DOM으로 접근해 HTML 우겨넣는 헬퍼
  setContentValue(value) {
    if (!this.hasFieldContentTarget) return

    const content = value || ""
    const field = this.fieldContentTarget

    if (field.tagName === "TEXTAREA") {
      field.value = content
      return
    }

    // Trix 태그일 때 Editor 객체 제어
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

    // 에디터 마운팅되기 전 히든 인풋일때 예외 대응
    field.value = content
    if (!field.id) return

    const editor = this.formTarget.querySelector(`trix-editor[input="${field.id}"]`)
    if (editor && editor.editor && typeof editor.editor.loadHTML === "function") {
      editor.editor.loadHTML(content)
    }
  }

  // 에디터 커스텀
  configureContentEditor(event) {
    const editor = event.target
    if (!(editor instanceof HTMLElement)) return

    // HTML에 액션텍스트 기본 파일첨부를 끄겠다고 명시되어 있을 때 설정
    if (editor.dataset.disableFileAttachments !== "true") return

    const toolbarId = editor.getAttribute("toolbar")
    if (!toolbarId) return

    const toolbar = this.formTarget.querySelector(`#${toolbarId}`) || document.getElementById(toolbarId)
    if (!toolbar) return

    // Trix 툴바 내에 기본 내장된 파일선택 클립버튼 등을 캡처 후 Hidden 처리함.
    toolbar.querySelectorAll(".trix-button-group--file-tools, .trix-button--icon-attach").forEach((element) => {
      element.setAttribute("hidden", "hidden")
    })
  }

  // 사용자가 Trix 본문으로 직접 드래그앤드랍 시 가로채서 못하게 막음
  preventTrixFileAttach(event) {
    event.preventDefault()
    alert("본문에는 파일을 첨부할 수 없습니다. 하단 첨부파일 영역을 사용해주세요.")
  }

  // ===================== [UI 렌더링용 헬퍼 구역] =========================

  // 첨부파일을 이쁘게 꾸민 뱃지 <li> 컴포넌트 HTML 노드 펙토리
  buildFileRow({ name, sizeLabel, tone, url = null }) {
    const rowElement = document.createElement("li")
    rowElement.classList.add("rf-multi-file-item")

    const iconElement = document.createElement("div")
    iconElement.classList.add("rf-multi-file-item-icon", `rf-multi-file-item-icon--${tone}`) // 확장자 테마

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
      nameElement.dataset.turboFrame = "_top" // 터보 드라이브 무시
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
  }

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
  }

  fileExtension(filename) {
    const fileName = String(filename || "")
    const parts = fileName.split(".")
    if (parts.length < 2) return "FILE" // 확장자 없음

    return parts.at(-1).toUpperCase().slice(0, 4) // ZIP, XLSX 같이 맨 뒤 글자
  }

  // 4096000 바이트 단위등을 4MB 단위로 휴먼러더블 컨버팅
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
