/**
 * TrixMixin
 *
 * Stimulus 컨트롤러에 Trix 에디터(ActionText) 제어 기능을 추가하는 믹스인입니다.
 *
 * 적용 방법:
 *   import { TrixMixin } from "controllers/concerns/trix_mixin"
 *   Object.assign(MyController.prototype, TrixMixin)
 *
 * 컨트롤러 static targets에 반드시 포함해야 할 항목:
 *   - "fieldContent" : trix-editor 또는 textarea 요소
 *
 * HTML 액션 연결 예시:
 *   data-action="trix-initialize->my-crud#configureContentEditor"
 *   data-action="trix-file-accept->my-crud#preventTrixFileAttach"
 *
 * 의존 조건:
 *   - formTarget이 컨트롤러에 정의되어 있어야 합니다.
 */
import { showAlert } from "components/ui/alert"

export const TrixMixin = {
  // Trix 에디터(또는 textarea)에 HTML 내용을 주입하는 헬퍼
  setContentValue(value) {
    if (!this.hasFieldContentTarget) return

    const content = value || ""
    const field = this.fieldContentTarget

    if (field.tagName === "TEXTAREA") {
      field.value = content
      return
    }

    // Trix 태그일 때 Editor 객체 직접 제어
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

    // 에디터 마운팅되기 전 히든 인풋일 때 예외 대응
    field.value = content
    if (!field.id) return

    const editor = this.formTarget.querySelector(`trix-editor[input="${field.id}"]`)
    if (editor && editor.editor && typeof editor.editor.loadHTML === "function") {
      editor.editor.loadHTML(content)
    }
  },

  // trix-initialize 이벤트 핸들러 — data-disable-file-attachments="true" 명시 시 툴바 파일첨부 버튼 숨김
  configureContentEditor(event) {
    const editor = event.target
    if (!(editor instanceof HTMLElement)) return

    if (editor.dataset.disableFileAttachments !== "true") return

    const toolbarId = editor.getAttribute("toolbar")
    if (!toolbarId) return

    const toolbar = this.formTarget.querySelector(`#${toolbarId}`) || document.getElementById(toolbarId)
    if (!toolbar) return

    // Trix 툴바 내 기본 내장 파일선택 클립버튼 등을 Hidden 처리
    toolbar.querySelectorAll(".trix-button-group--file-tools, .trix-button--icon-attach").forEach((element) => {
      element.setAttribute("hidden", "hidden")
    })
  },

  // trix-file-accept 이벤트 핸들러 — 본문 직접 드래그앤드랍 파일 첨부 차단
  preventTrixFileAttach(event) {
    event.preventDefault()
    showAlert("본문에는 파일을 첨부할 수 없습니다. 하단 첨부파일 영역을 사용해주세요.")
  }
}
