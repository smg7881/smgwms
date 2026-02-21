import { Controller } from "@hotwired/stimulus"

/**
 * BaseCrudController
 *
 * 모달 기반 CRUD 화면에서 공통으로 사용하는 Stimulus 베이스 컨트롤러입니다.
 *
 * 언제 사용하나:
 * - AG Grid 목록 + 모달 폼으로 등록/수정/삭제를 처리하는 관리 화면
 * - 리소스별 필드/URL만 다르고, 저장/삭제/모달 제어 로직은 재사용하고 싶은 경우
 *
 * 서브 클래스에서 주로 하는 일:
 * - static resourceName/deleteConfirmKey/entityLabel 지정
 * - static targets/values 지정
 * - connect()에서 connectBase({ events }) 호출
 * - 필요 시 openCreate, handleEdit, resetForm, save 오버라이드
 */
export default class extends Controller {
  static resourceName = ""
  static deleteConfirmKey = ""
  static entityLabel = ""

  // 공통 이벤트 등록:
  // - 화면별 커스텀 이벤트 바인딩
  // - 모달 취소 클릭 위임
  // - 모달 드래그 이벤트 등록
  connectBase({ events = [] } = {}) {
    this.dragState = null
    this._eventSubscriptions = events.map(({ name, handler }) => {
      this.element.addEventListener(name, handler)
      return { name, handler }
    })

    this._boundDelegatedClick = this.handleDelegatedClick.bind(this)
    this._boundDragMove = this.handleDragMove.bind(this)
    this._boundEndDrag = this.endDrag.bind(this)

    this.element.addEventListener("click", this._boundDelegatedClick)
    window.addEventListener("mousemove", this._boundDragMove)
    window.addEventListener("mouseup", this._boundEndDrag)
  }

  // connectBase에서 등록한 이벤트들을 해제합니다.
  disconnectBase() {
    ;(this._eventSubscriptions || []).forEach(({ name, handler }) => {
      this.element.removeEventListener(name, handler)
    })
    this._eventSubscriptions = []

    if (this._boundDelegatedClick) {
      this.element.removeEventListener("click", this._boundDelegatedClick)
    }
    if (this._boundDragMove) {
      window.removeEventListener("mousemove", this._boundDragMove)
    }
    if (this._boundEndDrag) {
      window.removeEventListener("mouseup", this._boundEndDrag)
    }
  }

  // CSRF 토큰
  get csrfToken() {
    return document.querySelector("[name='csrf-token']")?.content || ""
  }

  // data-<controller>-role='cancel' 셀렉터
  get cancelRoleSelector() {
    return `[data-${this.identifier}-role='cancel']`
  }

  // 모달 열기/닫기
  openModal() {
    this.overlayTarget.hidden = false
  }

  closeModal() {
    this.overlayTarget.hidden = true
    this.endDrag()
  }

  stopPropagation(event) {
    event.stopPropagation()
  }

  // 모달 내부 취소 버튼을 위임 방식으로 처리
  handleDelegatedClick(event) {
    const cancelButton = event.target.closest(this.cancelRoleSelector)
    if (cancelButton) {
      event.preventDefault()
      this.closeModal()
    }
  }

  // 모달 드래그 시작
  startDrag(event) {
    if (event.button !== 0) return
    if (!this.hasModalTarget || !this.hasOverlayTarget) return
    if (event.target.closest("button")) return

    const modalRect = this.modalTarget.getBoundingClientRect()
    this.modalTarget.style.position = "absolute"
    this.modalTarget.style.left = `${modalRect.left}px`
    this.modalTarget.style.top = `${modalRect.top}px`
    this.modalTarget.style.margin = "0"

    this.dragState = {
      offsetX: event.clientX - modalRect.left,
      offsetY: event.clientY - modalRect.top
    }

    document.body.style.userSelect = "none"
    this.modalTarget.style.cursor = "grabbing"
    event.preventDefault()
  }

  // 모달 드래그 이동(뷰포트 내부로 보정)
  handleDragMove(event) {
    if (!this.dragState || !this.hasModalTarget) return

    const maxLeft = Math.max(0, window.innerWidth - this.modalTarget.offsetWidth)
    const maxTop = Math.max(0, window.innerHeight - this.modalTarget.offsetHeight)
    const nextLeft = event.clientX - this.dragState.offsetX
    const nextTop = event.clientY - this.dragState.offsetY
    const clampedLeft = Math.min(Math.max(0, nextLeft), maxLeft)
    const clampedTop = Math.min(Math.max(0, nextTop), maxTop)

    this.modalTarget.style.left = `${clampedLeft}px`
    this.modalTarget.style.top = `${clampedTop}px`
  }

  // 모달 드래그 종료
  endDrag() {
    this.dragState = null
    document.body.style.userSelect = ""
    if (this.hasModalTarget) {
      this.modalTarget.style.cursor = ""
    }
  }

  // ag-grid 목록 새로고침
  refreshGrid() {
    this.getAgGridController()?.refresh()
  }

  // ag-grid CSV export
  exportCsv() {
    this.getAgGridController()?.exportCsv()
  }

  // 현재 화면의 ag-grid Stimulus 컨트롤러 조회
  getAgGridController() {
    const agGridEl = this.element.querySelector("[data-controller='ag-grid']")
    if (!agGridEl) return null

    return this.application.getControllerForElementAndIdentifier(agGridEl, "ag-grid")
  }

  // 엑셀/이력 공통 액션
  downloadExcel() {
    if (this.hasExcelExportUrlValue) {
      window.location.href = this.excelExportUrlValue
    }
  }

  downloadExcelTemplate() {
    if (this.hasExcelTemplateUrlValue) {
      window.location.href = this.excelTemplateUrlValue
    }
  }

  openImportHistory() {
    if (this.hasImportHistoryUrlValue) {
      window.location.href = this.importHistoryUrlValue
    }
  }

  openExcelImport() {
    const fileInput = this.element.querySelector("[data-excel-import-input]")
    if (fileInput) {
      fileInput.click()
    }
  }

  // 파일 선택 즉시 업로드 form submit
  submitExcelImport(event) {
    const input = event.target
    if (input.files.length === 0) return

    const form = input.closest("form")
    form?.requestSubmit()
    input.value = ""
  }

  // FormData -> JSON payload 변환
  // 예: user[name] => { name: "..." }
  buildJsonPayload() {
    const formData = new FormData(this.formTarget)
    const payload = {}
    for (const [rawKey, value] of formData.entries()) {
      const match = rawKey.match(/^[^\[]+\[([^\]]+)\]$/)
      const key = match ? match[1] : rawKey
      payload[key] = value
    }

    Object.keys(payload).forEach((key) => {
      if (payload[key] === "") payload[key] = null
    })

    return payload
  }

  // 공통 삭제 처리
  handleDelete = async (event) => {
    const { id } = event.detail
    const displayName = event.detail[this.constructor.deleteConfirmKey] || id
    if (!confirm(`"${displayName}" ${this.constructor.entityLabel}를 삭제하시겠습니까?`)) return

    try {
      const { response, result } = await this.requestJson(this.deleteUrlValue.replace(":id", id), {
        method: "DELETE"
      })

      if (!response.ok || !result.success) {
        alert("삭제 실패: " + (result.errors || ["요청 처리 실패"]).join(", "))
        return
      }

      alert(result.message || "삭제되었습니다")
      this.refreshGrid()
    } catch {
      alert("삭제 실패: 네트워크 오류")
    }
  }

  // 공통 저장 처리(JSON 기반)
  // 파일 업로드가 필요한 화면은 save() 오버라이드를 권장
  async save() {
    const payload = this.buildJsonPayload()
    if (this.hasFieldIdTarget && this.fieldIdTarget.value) payload.id = this.fieldIdTarget.value

    const isCreate = this.mode === "create"
    const id = payload.id
    delete payload.id
    const url = isCreate ? this.createUrlValue : this.updateUrlValue.replace(":id", id)
    const method = isCreate ? "POST" : "PATCH"

    try {
      const { response, result } = await this.requestJson(url, {
        method,
        body: { [this.constructor.resourceName]: payload }
      })

      if (!response.ok || !result.success) {
        alert("저장 실패: " + (result.errors || ["요청 처리 실패"]).join(", "))
        return
      }

      alert(result.message || "저장되었습니다")
      this.closeModal()
      this.refreshGrid()
    } catch {
      alert("저장 실패: 네트워크 오류")
    }
  }

  // form submit 핸들러
  submit(event) {
    event.preventDefault()
    this.save()
  }

  // 공통 fetch 래퍼:
  // - CSRF 헤더 자동 추가
  // - JSON / multipart body 모두 지원
  async requestJson(url, { method, body, isMultipart = false }) {
    const headers = { "X-CSRF-Token": this.csrfToken }
    if (!isMultipart) headers["Content-Type"] = "application/json"

    const response = await fetch(url, {
      method,
      headers,
      body: isMultipart ? body : JSON.stringify(body)
    })

    const result = await response.json()
    return { response, result }
  }
}
