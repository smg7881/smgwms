/**
 * ModalMixin
 *
 * Stimulus 컨트롤러에 모달(다이얼로그) 관련 공통 기능을 추가하는 믹스인입니다.
 * PopupManager 기반 열기/닫기, 드래그, 폼 페이로드 빌드, CRUD 공통 핸들러를 제공합니다.
 *
 * 적용 방법:
 *   import { ModalMixin } from "controllers/concerns/modal_mixin"
 *   Object.defineProperties(MyController.prototype, Object.getOwnPropertyDescriptors(ModalMixin))
 *
 * Object.assign 대신 Object.defineProperties를 사용하는 이유:
 *   cancelRoleSelector 같은 getter를 올바르게 복사하려면 프로퍼티 디스크립터 복사가 필요합니다.
 *
 * 컨트롤러 static targets에 반드시 포함해야 할 항목 (모달 사용 시):
 *   - "overlay" : <dialog class="app-modal-dialog"> 요소
 *   - "modal"   : 드래그 가능한 모달 내부 .app-modal-shell 요소 (선택)
 */
import { showAlert, confirmAction } from "components/ui/alert"
import { PopupManager } from "controllers/popup/popup_manager"
import { attachDrag } from "controllers/popup/popup_drag_mixin"
import { requestJson as requestJsonCore } from "controllers/grid/core/http_client"
import { syncAllPopupDisplaysFromCodes } from "controllers/grid/grid_popup_utils"

export const ModalMixin = {
  /**
   * 믹스인이 컨트롤러에 연결될 때 호출해야 하는 초기화 헬퍼입니다.
   * 지정된 이벤트 배열을 리스닝하고, 모달 내부의 취소(cancel) 액션을 위한 델리게이트 클릭 이벤트를 바인딩합니다.
   * @param {Object} options 이벤트 배열 등 설정 객체
   */
  connectBase({ events = [] } = {}) {
    this._eventSubscriptions = events.map(({ name, handler }) => {
      this.element.addEventListener(name, handler)
      return { name, handler }
    })

    this._boundDelegatedClick = this.handleDelegatedClick.bind(this)
    this.element.addEventListener("click", this._boundDelegatedClick)
  },

  /**
   * 믹스인이 컨트롤러에서 해제될 때 호출해야 하는 정리 헬퍼입니다.
   * `connectBase`에서 등록했던 모든 커스텀 이벤트와 델리게이트 클릭 리스너를 DOM에서 제거해 메모리 누수를 방지합니다.
   */
  disconnectBase() {
    ; (this._eventSubscriptions || []).forEach(({ name, handler }) => {
      this.element.removeEventListener(name, handler)
    })
    this._eventSubscriptions = []

    if (this._boundDelegatedClick) {
      this.element.removeEventListener("click", this._boundDelegatedClick)
    }
  },

  /**
   * 현재 컨트롤러의 identifier를 기반으로 취소(cancel) 역할이 부여된 버튼을 찾기 위한 CSS 선택자를 동적으로 반환합니다.
   * @returns {string} 취소 버튼 CSS 선택자
   */
  get cancelRoleSelector() {
    return `[data-${this.identifier}-role='cancel']`
  },

  /**
   * HTML의 `<dialog>`(overlayTarget) 요소를 활용하여 실제 모달 화면을 엽니다.
   * 모달 내부에 헤더(.app-modal-header)가 존재한다면 마우스 드래그 이동 기능도 함께 활성화합니다.
   */
  openModal() {
    this._popupInstance = PopupManager.open({ dialogEl: this.overlayTarget })
    if (this.hasModalTarget) {
      const header = this.modalTarget.querySelector(".app-modal-header")
      if (header) this._dragInstance = attachDrag(this.modalTarget, header)
    }
  },

  /**
   * 열려있는 다이얼로그 모달을 닫고, 드래그 인스턴스 등 관련 메모리를 파기(초기화)합니다.
   */
  closeModal() {
    this._dragInstance?.destroy()
    this._dragInstance = null
    this._popupInstance?.close()
    this._popupInstance = null
  },

  /**
   * 모달의 바깥쪽(배경) 영역 클릭 시 호출될 수 있는 빈 플레이스홀더 함수입니다.
   * 서브클래스에서 필요 시 오버라이드하여 창 닫기 등의 로직을 구현합니다.
   * @param {Event} _event 마우스 이벤트
   */
  onBackdropClick(_event) { },

  /**
   * 이벤트의 상위 전파(Bubbling)를 중단시키는 간단한 유틸리티 메서드입니다.
   * HTML의 data-action 에서 `click->controller#stopPropagation` 형태로 자주 활용됩니다.
   * @param {Event} event 중단할 이벤트 객체
   */
  stopPropagation(event) {
    event.stopPropagation()
  },

  /**
   * 컨트롤러 루트 엘리먼트에 바인딩된 글로벌 클릭 핸들러입니다.
   * 클릭된 대상이 취소 버튼(cancelRoleSelector)일 경우 모달을 자동으로 닫습니다.
   * @param {Event} event 마우스 클릭 이벤트
   */
  handleDelegatedClick(event) {
    const cancelButton = event.target.closest(this.cancelRoleSelector)
    if (cancelButton) {
      event.preventDefault()
      this.closeModal()
    }
  },

  /**
   * formTarget에 입력된 값들을 기반으로 순수 JSON(Key-Value) 객체를 빌드해냅니다.
   * 배열형 파라미터나 빈 문자열을 null로 치환하는 등의 전처리를 포함합니다.
   * @returns {Object} JSON 페이로드 객체
   */
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
  },

  /**
   * 목록(그리드) 등에서 삭제 액션 이벤트가 발생했을 때 연동되는 공용 핸들러입니다.
   * Confirm 안내창을 띄워 사용자 확인을 받은 뒤, 백엔드에 DELETE 요청을 날립니다.
   * @param {CustomEvent} event 삭제 정보(id 등)를 담은 이벤트
   */
  async handleDelete(event) {
    const { id } = event.detail
    const displayName = event.detail[this.constructor.deleteConfirmKey] || id

    if (!await confirmAction(`"${displayName}" ${this.constructor.entityLabel}를 삭제하시겠습니까?`)) return

    try {
      const { response, result } = await this.requestJson(this.deleteUrlValue.replace(":id", id), {
        method: "DELETE"
      })

      if (!response.ok || !result.success) {
        showAlert("삭제 실패: " + (result.errors || ["요청 처리 실패"]).join(", "))
        return
      }

      showAlert(result.message || "삭제되었습니다")
      this._refreshModalGrid()
    } catch {
      showAlert("삭제 실패: 네트워크 오류")
    }
  },

  /**
   * 입력된 폼 정보를 JSON 페이로드로 묶어 서버로 저장(Create/Update) 요청을 보냅니다.
   * 현재 모달이 신규 생성(create) 상태인지, 기존 항목 수정 상태인지에 따라 HTTP Method(POST/PATCH)와 URL을 변환합니다.
   */
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
        showAlert("저장 실패: " + (result.errors || ["요청 처리 실패"]).join(", "))
        return
      }

      showAlert(result.message || "저장되었습니다")
      this.closeModal()
      this._refreshModalGrid()
    } catch {
      showAlert("저장 실패: 네트워크 오류")
    }
  },

  /**
   * 폼 기본 제출(submit) 동작을 가로채고(preventDefault), 내부의 JSON 기반 비동기 `save` 로직을 태웁니다.
   * @param {Event} event 폼 submit 이벤트
   */
  submit(event) {
    event.preventDefault()
    this.save()
  },

  /**
   * fetch 기반 비동기 네트워크 코어 로직(requestJsonCore)을 래핑 호출합니다.
   * @param {string} url 요청 URL
   * @param {Object} options 메서드, 본문(body), Multipart 전송 여부 등
   * @returns {Promise<Object>} Fetch 응답 객체
   */
  async requestJson(url, { method, body, isMultipart = false }) {
    return requestJsonCore(url, { method, body, isMultipart })
  },

  /**
   * 모달 내 폼(formTarget)의 특정 필드 입력 요소에 원하는 값을 프로그래밍 방식으로 밀어넣습니다.
   * 체크박스(boolean/YN), 톰셀렉트(TomSelect 다중/단일) 등 UI 라이브러리 특성에 맞춰 값을 적절히 주입합니다.
   * @param {string} fieldName 필드명
   * @param {any} value 채워넣을 값
   */
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

  /**
   * 객체(Key-Value) 형태로 전달된 여러 필드 데이터들을 순회하며 동시에 폼에 값을 채워넣습니다.
   * @param {Object} values `{ name: "홍길동", age: 20 }` 형태의 객체 데이터
   */
  setFieldValues(values = {}) {
    Object.entries(values).forEach(([fieldName, value]) => {
      this.setFieldValue(fieldName, value)
    })
  },

  /**
   * 폼 태그의 내부를 탐색하여 넘겨받은 필드명과 일치하는 실제 HTML Input Element 노드를 찾아냅니다.
   * @param {string} resourceName 모델 네임스페이스 (예: 'user')
   * @param {string} fieldName 실제 단일 필드 네임 (예: 'phone')
   * @returns {HTMLElement|null} 찾은 DOM 엘리먼트
   */
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

  /**
   * 폼 내부에 존재하는 룩업(검색/팝업) 컴포넌트들의 디스플레이용 명칭을 코드를 기반으로 서버에서 불러와 동기화시킵니다.
   */
  syncPopupDisplaysFromCodes() {
    syncAllPopupDisplaysFromCodes(this.element)
  },

  /**
   * Date 객체 혹은 날짜 문자열을 "YYYY-MM-DD HH:mm:ss" 형식의 문자열로 변환합니다.
   * 유효하지 않은 값이면 원본을 그대로 텍스트로 치환해 반환합니다.
   * @param {any} value 날짜값 포맷 대상
   * @returns {string} 포맷팅된 일시 문자열
   */
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

  /**
   * 모달과 연결된 내부 혹은 바닥 화면에 위치한 AG-Grid(목록 영역)의 데이터를 강제 새로고침(Refresh)합니다.
   * 데이터의 생성/삭제/수정 완료 직후 최신 상태 반영을 위해 쓰입니다.
   */
  _refreshModalGrid() {
    const agGridEl = this.element.querySelector("[data-controller='ag-grid']")
    if (agGridEl) {
      this.application.getControllerForElementAndIdentifier(agGridEl, "ag-grid")?.refresh()
    }
  }
}
