/**
 * ModalMixin
 *
 * 모달 기반 CRUD 화면에서 공통으로 사용하는 메서드 모음입니다.
 * BaseGridController.prototype에 Object.assign으로 합성하여 사용합니다.
 *
 * 포함 기능:
 * - 이벤트 등록/해제 (connectBase / disconnectBase)
 * - 모달 열기/닫기/드래그
 * - JSON 폼 페이로드 빌드
 * - 공통 삭제/저장/submit 핸들러
 * - 그리드 갱신 (_refreshModalGrid)
 */
import { showAlert, confirmAction } from "components/ui/alert"
import { requestJson as requestJsonCore } from "controllers/grid/core/http_client"
import { syncAllPopupDisplaysFromCodes } from "controllers/grid/grid_popup_utils"
import { PopupManager } from "controllers/popup/popup_manager"

export const ModalMixin = {
  // 공통 이벤트 등록:
  // - 화면별 커스텀 이벤트 바인딩
  // - 모달 취소 버튼 등 위임형 클릭 이벤트 등록
  // - 모달 드래그 이벤트 등록
  connectBase({ events = [] } = {}) {
    this.dragState = null // 드래그 상태를 관리하는 객체. { offsetX, offsetY } 등의 값을 가집니다.

    // 전달받은 커스텀 이벤트들을 실제 요소에 바인딩하고 추후 해제를 위해 배열에 저장합니다.
    this._eventSubscriptions = events.map(({ name, handler }) => {
      this.element.addEventListener(name, handler)
      return { name, handler }
    })

    // 콜백 함수 내부의 this 컨텍스트를 유지하기 위해 bind 처리한 함수를 변수에 저장합니다.
    this._boundDelegatedClick = this.handleDelegatedClick.bind(this)
    this._boundDragMove = this.handleDragMove.bind(this)
    this._boundEndDrag = this.endDrag.bind(this)

    // 문서 전체 또는 컨트롤러 내에서 발생하는 이벤트를 수신합니다.
    this.element.addEventListener("click", this._boundDelegatedClick)
    window.addEventListener("mousemove", this._boundDragMove)
    window.addEventListener("mouseup", this._boundEndDrag)
  },

  // connectBase에서 등록한 이벤트들을 일괄 해제합니다.
  // Stimulus 컨트롤러가 DOM에서 제거될 때(disconnect) 주로 호출됩니다.
  disconnectBase() {
    ;(this._eventSubscriptions || []).forEach(({ name, handler }) => {
      this.element.removeEventListener(name, handler)
    })
    this._eventSubscriptions = []

    // 미리 바인딩했던 이벤트 리스너들을 해제시켜 메모리 누수를 방지합니다.
    if (this._boundDelegatedClick) {
      this.element.removeEventListener("click", this._boundDelegatedClick)
    }
    if (this._boundDragMove) {
      window.removeEventListener("mousemove", this._boundDragMove)
    }
    if (this._boundEndDrag) {
      window.removeEventListener("mouseup", this._boundEndDrag)
    }
  },

  // 모달 내부의 특정 액션 버튼(예: 취소)을 위임 패턴으로 잡기 위한 선택자
  // data-[controller-name]-role="cancel" 형태로 HTML 요소에 지정합니다.
  get cancelRoleSelector() {
    return `[data-${this.identifier}-role='cancel']`
  },

  // 모달(dialog)을 화면에 표시합니다.
  // PopupManager._openInline()에 위임하여 일관된 dialog 처리를 보장합니다.
  openModal() {
    this._popupInstance = PopupManager.open({ dialogEl: this.overlayTarget })
  },

  // 모달을 닫고 진행 중이던 드래그 상태를 모두 초기화합니다.
  closeModal() {
    this._popupInstance?.close()
    this._popupInstance = null
    this.endDrag()
  },

  // backdrop 클릭 무시 — 팝업 외부 클릭으로 닫히지 않습니다.
  onBackdropClick(_event) {},

  // 이벤트 버블링을 방지하는 범용 유틸리티 함수. 특정 요소 클릭 시 부모로 이벤트가 전파되는 것을 막을 때 사용합니다.
  stopPropagation(event) {
    event.stopPropagation()
  },

  // 모달 외부 클릭이나 부모 컨테이너 내의 클릭 이벤트를 위임(Delegation) 받아서 처리합니다.
  handleDelegatedClick(event) {
    // 취소 버튼 (cancelRoleSelector에 해당하는 요소)을 클릭한 경우 모달을 닫습니다.
    const cancelButton = event.target.closest(this.cancelRoleSelector)
    if (cancelButton) {
      event.preventDefault() // 링크 이동 등의 기본 동작 차단
      this.closeModal()
    }
  },

  // 모달 헤더 등을 마우스로 클릭하여 드래그를 시작할 때 호출됩니다.
  startDrag(event) {
    if (event.button !== 0) return // 마우스 왼쪽 버튼 클릭인지 확인
    if (!this.hasModalTarget || !this.hasOverlayTarget) return // 필수 타겟 존재 여부 확인
    if (event.target.closest("button")) return // 버튼 클릭 시에는 드래그 동작 무시 (닫기 버튼 등 클릭 목적과 혼동 방지)

    // 마우스가 클릭된 시점의 모달 절대 위치를 가져옵니다.
    const modalRect = this.modalTarget.getBoundingClientRect()

    // 모달을 absolute로 변경하여 자유로운 이동이 가능하도록 스타일 세팅
    this.modalTarget.style.position = "absolute"
    this.modalTarget.style.left = `${modalRect.left}px`
    this.modalTarget.style.top = `${modalRect.top}px`
    this.modalTarget.style.margin = "0"

    // 모달 내부에서 마우스가 클릭된 상대 위치를 저장합니다.
    this.dragState = {
      offsetX: event.clientX - modalRect.left,
      offsetY: event.clientY - modalRect.top
    }

    // 마우스 이동 시 텍스트가 블록 지정되는 기본 동작을 방지하고 커서를 '잡는 중' 형태로 변경합니다.
    document.body.style.userSelect = "none"
    this.modalTarget.style.cursor = "grabbing"
    event.preventDefault()
  },

  // 모달을 드래그하여 마우스를 이동 중일 때 호출됩니다.
  // 뷰포트(브라우저 창) 바깥으로 모달이 완전히 벗어나지 않도록 보정(Clamp) 처리합니다.
  handleDragMove(event) {
    if (!this.dragState || !this.hasModalTarget) return

    // 이동 가능한 좌/상단의 최대값 제한 (창 너비/높이 - 모달 너비/높이)
    const maxLeft = Math.max(0, window.innerWidth - this.modalTarget.offsetWidth)
    const maxTop = Math.max(0, window.innerHeight - this.modalTarget.offsetHeight)

    // 계산된 이동 위치 (현재 마우스 위치 - 모달 내 드래그 시작 좌표)
    const nextLeft = event.clientX - this.dragState.offsetX
    const nextTop = event.clientY - this.dragState.offsetY

    // 왼쪽 위(0)와 한계값(max) 사이로 위치를 무조건 제한합니다.
    const clampedLeft = Math.min(Math.max(0, nextLeft), maxLeft)
    const clampedTop = Math.min(Math.max(0, nextTop), maxTop)

    // 모달 DOM의 left, top 스타일을 업데이트
    this.modalTarget.style.left = `${clampedLeft}px`
    this.modalTarget.style.top = `${clampedTop}px`
  },

  // 드래그가 끝났을 때 원상태로 텍스트 선택 및 커서 모양을 복구합니다.
  endDrag() {
    this.dragState = null
    document.body.style.userSelect = "" // 브라우저 텍스트 선택 가능상태 복구
    if (this.hasModalTarget) {
      this.modalTarget.style.cursor = ""
    }
  },

  // HTML <form> 요소 안의 정보(FormData)를 JSON 객체로 파싱합니다.
  // 폼 입력의 name 특성 중에서 대괄호([]) 안의 키만 추출하는 로직 적용. (Rails 규칙 반영)
  // 예: input name="user[email]" 의 값이 "admin" 이라면 => { email: "admin" } 생성
  buildJsonPayload() {
    const formData = new FormData(this.formTarget)
    const payload = {}

    // FormData.entries()로 각 키-값 순회
    for (const [rawKey, value] of formData.entries()) {
      // 대괄호로 감싸인 최종 키 추출 정규식
      const match = rawKey.match(/^[^\[]+\[([^\]]+)\]$/)
      const key = match ? match[1] : rawKey
      payload[key] = value
    }

    // 빈 문자열인 필드는 null로 바꾸어 백엔드 쿼리에 일관성을 유지
    Object.keys(payload).forEach((key) => {
      if (payload[key] === "") payload[key] = null
    })

    return payload
  },

  // 공통 목록 삭제 핸들러 (그리드의 삭제 버튼 클릭, 컨텍스트 메뉴 등을 통해 호출 전제)
  // 비동기 통신(async/await)과 커스텀 confirm 창으로 확인을 받습니다.
  async handleDelete(event) {
    // 트리거된 이벤트에서 레코드 id와 삭제 메시지 표시용(displayName) 키를 받아옵니다.
    const { id } = event.detail
    const displayName = event.detail[this.constructor.deleteConfirmKey] || id

    // 삭제 의도 확인 창
    if (!await confirmAction(`"${displayName}" ${this.constructor.entityLabel}를 삭제하시겠습니까?`)) return

    try {
      // deleteUrlValue에서 대상 레코드의 ':id' 텍스트를 실제 id 값으로 파싱해 요청
      const { response, result } = await this.requestJson(this.deleteUrlValue.replace(":id", id), {
        method: "DELETE"
      })

      // 정상 삭제 실패 시 에러 알림.
      if (!response.ok || !result.success) {
        showAlert("삭제 실패: " + (result.errors || ["요청 처리 실패"]).join(", "))
        return
      }

      // 정상 처리 시 알림 후 그리드 목록 자동 갱신
      showAlert(result.message || "삭제되었습니다")
      this._refreshModalGrid()
    } catch {
      showAlert("삭제 실패: 네트워크 오류")
    }
  },

  // 생성/수정 모달 등에서 '저장' 버튼을 눌렀을 때 공통적으로 호출되는 저장 처리 함수.
  // multipart/form-data 등 파일 업로드가 필요하다면 자식/서브 클래스에서 이 메서드를 오버라이드 해야 합니다.
  async save() {
    // buildJsonPayload를 통하여 생성된 폼 데이터 JSON 값
    const payload = this.buildJsonPayload()

    // 폼에 존재할 수 있는 fieldIdTarget.value (PK ID 값)를 payload에 포함
    if (this.hasFieldIdTarget && this.fieldIdTarget.value) payload.id = this.fieldIdTarget.value

    // 현재 컨트롤러가 관리하는 모드가 create(신규 생성)인지 수정/업데이트인지 구분
    const isCreate = this.mode === "create"
    const id = payload.id
    delete payload.id // 백엔드 컨트롤러에 맞는 파라미터 구조를 위해 내부 PK 삭제 (URL 라우팅 사용 때문)

    // 처리 상태별 URL과 HTTP Method 가변 적용
    const url = isCreate ? this.createUrlValue : this.updateUrlValue.replace(":id", id)
    const method = isCreate ? "POST" : "PATCH"

    try {
      // requestJson() 함수를 통해 데이터 전송
      // body는 `{ resourceName: { attribute: value, ... } }` 형태로 감쌉니다. (Rails Parameter 규칙 준수)
      const { response, result } = await this.requestJson(url, {
        method,
        body: { [this.constructor.resourceName]: payload }
      })

      if (!response.ok || !result.success) {
        showAlert("저장 실패: " + (result.errors || ["요청 처리 실패"]).join(", "))
        return
      }

      // 성공 시 알림, 모달창 끄기, 그리드 갱신 처리
      showAlert(result.message || "저장되었습니다")
      this.closeModal()
      this._refreshModalGrid()
    } catch {
      showAlert("저장 실패: 네트워크 오류")
    }
  },

  // 모달 폼 태그 등에서 기본적으로 전달되는 form submit 이벤트 리스너의 핸들러
  // 브라우저 기본 전송 기능(페이지 리로딩 방식)을 차단하고 비동기 save() 호출로 전환.
  submit(event) {
    event.preventDefault()
    this.save()
  },

  // HTTP 네트워크 리퀘스트 처리를 담당하는 공통 fetch 단위 함수 (유틸리티)
  // - Rails 보안 체계를 위한 CSRF 헤더를 자동 추가합니다.
  // - JSON 통신 모드와 multipart 방식(isMultipart 변수) 모두를 대응할 수 있도록 합니다.
  async requestJson(url, { method, body, isMultipart = false }) {
    return requestJsonCore(url, { method, body, isMultipart })
  },

  // 모달 닫기나 저장 이후 등, AG-Grid 목록을 다시 불러오는(refresh) 기능.
  // BaseGridController.refreshGrid(name)과 이름 충돌을 피하기 위해 별도 명칭 사용.
  setFieldValue(fieldName, value) {
    if (!this.hasFormTarget) return

    const resourceName = this.constructor.resourceName
    const input = this.findFieldInput(resourceName, fieldName)
    if (!input) return

    const normalizedValue = value == null ? "" : value

    if (input.type === "checkbox") {
      const truthy = normalizedValue === true || normalizedValue === "Y" || normalizedValue === "1" || normalizedValue === 1
      input.checked = truthy
      return
    }

    // Tom Select is bound to the original <select>; keep UI state in sync with programmatic updates.
    if (input.tomselect) {
      if (input.multiple) {
        const values = Array.isArray(normalizedValue) ? normalizedValue.map((v) => String(v)) : []
        input.tomselect.setValue(values, true)
      } else {
        input.tomselect.setValue(String(normalizedValue), true)
      }
      return
    }

    input.value = normalizedValue
  },

  setFieldValues(values = {}) {
    Object.entries(values).forEach(([fieldName, value]) => {
      this.setFieldValue(fieldName, value)
    })
  },

  findFieldInput(resourceName, fieldName) {
    let input = null

    if (resourceName) {
      input = this.formTarget.querySelector(`[name='${resourceName}[${fieldName}]']`)
    }

    if (!input) {
      input = this.formTarget.querySelector(`[name$='[${fieldName}]']`)
    }

    return input
  },

  syncPopupDisplaysFromCodes() {
    syncAllPopupDisplaysFromCodes(this.element)
  },

  formatDateTime(value) {
    if (!value) return ""

    const date = value instanceof Date ? value : new Date(value)
    if (Number.isNaN(date.getTime())) {
      return String(value)
    }

    const year = date.getFullYear()
    const month = String(date.getMonth() + 1).padStart(2, "0")
    const day = String(date.getDate()).padStart(2, "0")
    const hour = String(date.getHours()).padStart(2, "0")
    const minute = String(date.getMinutes()).padStart(2, "0")
    const second = String(date.getSeconds()).padStart(2, "0")
    return `${year}-${month}-${day} ${hour}:${minute}:${second}`
  },

  _refreshModalGrid() {
    const agGridEl = this.element.querySelector("[data-controller='ag-grid']")
    if (agGridEl) {
      this.application.getControllerForElementAndIdentifier(agGridEl, "ag-grid")?.refresh()
    }
  }
}
