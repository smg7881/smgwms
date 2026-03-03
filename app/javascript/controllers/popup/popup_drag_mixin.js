/**
 * popup_drag_mixin.js
 *
 * 드래그 가능한 모달 쉘을 위한 드래그 로직 모음.
 * popup_manager.js에서 조회 팝업의 드래그에 사용합니다.
 *
 * modal_mixin.js의 startDrag/handleDragMove/endDrag 로직과 동일한 동작을
 * Stimulus 컨트롤러 외부에서도 사용할 수 있도록 순수 함수로 분리합니다.
 */

/**
 * dragEl을 handleEl의 mousedown으로 드래그 가능하게 연결합니다.
 *
 * @param {Element} dragEl   - 실제 이동할 요소 (app-modal-shell 등)
 * @param {Element} handleEl - 드래그를 시작하는 손잡이 요소 (헤더 등)
 * @returns {{ destroy(): void }} - 이벤트 정리 함수
 */
export function attachDrag(dragEl, handleEl) {
  let dragState = null

  function startDrag(event) {
    if (event.button !== 0) return
    if (!dragEl) return
    if (event.target.closest("button")) return

    const rect = dragEl.getBoundingClientRect()
    dragEl.style.position = "absolute"
    dragEl.style.left = `${rect.left}px`
    dragEl.style.top = `${rect.top}px`
    dragEl.style.margin = "0"

    dragState = {
      offsetX: event.clientX - rect.left,
      offsetY: event.clientY - rect.top
    }

    document.body.style.userSelect = "none"
    dragEl.style.cursor = "grabbing"
    event.preventDefault()
  }

  function handleDragMove(event) {
    if (!dragState || !dragEl) return

    const maxLeft = Math.max(0, window.innerWidth - dragEl.offsetWidth)
    const maxTop = Math.max(0, window.innerHeight - dragEl.offsetHeight)

    const clampedLeft = Math.min(Math.max(0, event.clientX - dragState.offsetX), maxLeft)
    const clampedTop = Math.min(Math.max(0, event.clientY - dragState.offsetY), maxTop)

    dragEl.style.left = `${clampedLeft}px`
    dragEl.style.top = `${clampedTop}px`
  }

  function endDrag() {
    dragState = null
    document.body.style.userSelect = ""
    if (dragEl) dragEl.style.cursor = ""
  }

  handleEl.addEventListener("mousedown", startDrag)
  window.addEventListener("mousemove", handleDragMove)
  window.addEventListener("mouseup", endDrag)

  return {
    destroy() {
      handleEl.removeEventListener("mousedown", startDrag)
      window.removeEventListener("mousemove", handleDragMove)
      window.removeEventListener("mouseup", endDrag)
      endDrag()
    }
  }
}
