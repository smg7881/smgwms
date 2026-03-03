/**
 * popup_manager.js
 *
 * 단일 <dialog> 기반 통합 팝업 엔진.
 *
 * 두 가지 모드를 지원합니다:
 *   - lookup  : url 제공 시 → <dialog> + <turbo-frame> 으로 검색 팝업 로드
 *   - inline  : dialogEl 제공 시 → 기존 <dialog> 요소를 showModal()로 열기 (CRUD 모달)
 *
 * iframe + postMessage 방식을 완전히 대체합니다.
 * 검색 팝업은 turbo-frame으로 로드되며, 선택 결과는 CustomEvent(popup:select)로 수신합니다.
 */

import { attachDrag } from "controllers/popup/popup_drag_mixin"

const POPUP_DIALOG_ID = "popup-manager-dialog"
const POPUP_FRAME_ID = "popup-frame"

function escapeHtml(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
}

function buildFrameSrc(baseUrl, keyword) {
  const url = new URL(baseUrl, window.location.origin)
  const text = String(keyword ?? "").trim()
  if (text.length > 0) url.searchParams.set("q", text)
  url.searchParams.set("frame", POPUP_FRAME_ID)
  return `${url.pathname}${url.search}${url.hash}`
}

function defaultTitle(type) {
  const label = String(type ?? "").trim()
  return label ? `${label} 조회` : "조회"
}

// 현재 열려 있는 lookup 팝업 정리 함수 (전역 싱글턴)
let _activeFinalize = null

// lookup 팝업 dialog의 ::backdrop을 투명하게 설정 (부모 모달이 보이도록)
// CSS 파일 컴파일에 의존하지 않고 JS로 직접 주입합니다.
;(function injectPopupManagerStyle() {
  const styleId = "popup-manager-backdrop-style"
  if (document.getElementById(styleId)) return
  const style = document.createElement("style")
  style.id = styleId
  style.textContent = `dialog#${POPUP_DIALOG_ID}::backdrop { background: transparent !important; }`
  document.head.appendChild(style)
})()

export const PopupManager = {
  /**
   * 팝업을 엽니다.
   *
   * @param {object} options
   * @param {string}  [options.url]       - lookup 모드: turbo-frame으로 로드할 URL
   * @param {string}  [options.keyword]   - lookup 모드: 초기 검색어
   * @param {string}  [options.title]     - 팝업 제목
   * @param {string}  [options.width]     - lookup 모드: 팝업 너비 (CSS 값)
   * @param {boolean} [options.draggable] - 드래그 활성화 여부 (기본 true)
   * @param {Element} [options.dialogEl]  - inline 모드: 기존 <dialog> 요소
   *
   * @returns {Promise<object|null>|{ close(): void }}
   *   - lookup 모드: Promise<selection|null>
   *   - inline 모드: { close() } 객체
   */
  open({ url, keyword, title, width = "min(980px, calc(100vw - 24px))", draggable = true, dialogEl } = {}) {
    if (url) {
      return this._openLookup({ url, keyword, title, width, draggable })
    }

    if (dialogEl) {
      return this._openInline({ dialogEl })
    }

    return Promise.resolve(null)
  },

  // ── Lookup 모드 (turbo-frame 기반 검색 팝업) ──────────────────────────

  _openLookup({ url, keyword, title, width, draggable }) {
    const popupType = String(url ?? "").trim()
    if (!popupType) return Promise.resolve(null)

    // 이미 열려 있는 lookup 팝업 닫기
    if (typeof _activeFinalize === "function") {
      _activeFinalize(null)
    }

    let dialog = document.getElementById(POPUP_DIALOG_ID)
    if (!dialog) {
      dialog = document.createElement("dialog")
      dialog.id = POPUP_DIALOG_ID
      dialog.className = "app-modal-dialog"
      document.body.appendChild(dialog)
    }

    const frameSrc = buildFrameSrc(url, keyword)
    const heading = String(title ?? "").trim() || defaultTitle(url)

    dialog.innerHTML = `
      <div class="app-modal-shell bg-bg-primary border border-border rounded-lg max-w-[calc(100vw-32px)] max-h-[90vh] flex flex-col overflow-hidden shadow-2xl"
           style="width:${escapeHtml(width)};">
        <div class="app-modal-header flex justify-between items-center px-5 py-4 border-b border-border sticky top-0 z-[2] bg-bg-primary cursor-grab">
          <h3 class="app-modal-title m-0 text-base">${escapeHtml(heading)}</h3>
          <button type="button"
                  class="app-modal-close bg-transparent border-none text-xl cursor-pointer text-text-secondary"
                  data-role="popup-close">&times;</button>
        </div>
        <div class="app-modal-body modal-body" style="padding:0;overflow:hidden;flex:1;">
          <turbo-frame id="${POPUP_FRAME_ID}"
                       src="${escapeHtml(frameSrc)}"
                       style="display:block;width:100%;height:min(72vh,700px);">
          </turbo-frame>
        </div>
        <div class="app-modal-footer flex gap-2 justify-end px-5 py-3 border-t border-border sticky bottom-0 z-[2] bg-bg-primary">
          <button type="button" class="btn btn-sm btn-primary" data-role="popup-select">선택</button>
          <button type="button" class="btn btn-sm btn-secondary" data-role="popup-close">닫기</button>
        </div>
      </div>
    `

    return new Promise((resolve) => {
      let dragInstance = null
      // AbortController로 모든 이벤트 리스너를 한 번에 정리 (누적 방지)
      const listenerAbort = new AbortController()
      const { signal } = listenerAbort

      const finalize = (selection) => {
        if (signal.aborted) return
        _activeFinalize = null
        listenerAbort.abort()
        dragInstance?.destroy()
        dialog.style.display = ""
        dialog.close()
        dialog.innerHTML = ""
        resolve(selection)
      }

      _activeFinalize = finalize

      // search_popup_grid_controller.js에서 버블링되는 CustomEvent 수신
      dialog.addEventListener("popup:select", (event) => {
        finalize(event.detail || null)
      }, { signal })

      dialog.addEventListener("popup:close", () => {
        finalize(null)
      }, { signal })

      // 버튼 클릭 위임
      dialog.addEventListener("click", (event) => {
        if (event.target.closest("[data-role='popup-close']")) {
          finalize(null)
          return
        }

        // 선택 버튼: search_popup_grid_controller에 현재 선택 행 제출 요청
        if (event.target.closest("[data-role='popup-select']")) {
          const gridEl = dialog.querySelector("[data-controller~='search-popup-grid']")
          gridEl?.dispatchEvent(new CustomEvent("popup:request-select"))
          return
        }

        // backdrop 클릭은 무시 (팝업 외부 클릭으로 닫히지 않음)
      }, { signal })

      // ESC 키 닫기
      dialog.addEventListener("cancel", (event) => {
        event.preventDefault()
        finalize(null)
      }, { signal })

      // 드래그 연결
      if (draggable) {
        const shell = dialog.querySelector(".app-modal-shell")
        const header = dialog.querySelector(".app-modal-header")
        if (shell && header) dragInstance = attachDrag(shell, header)
      }

      // showModal() 후 display:flex → align-items/justify-content 중앙 정렬 활성화
      dialog.showModal()
      dialog.style.display = "flex"
    })
  },

  // ── Inline 모드 (기존 <dialog> 재사용 CRUD 모달) ──────────────────────

  _openInline({ dialogEl }) {
    // CSS(dialog.app-modal-dialog)에서 position/inset/size를 담당.
    // showModal() 후 display를 flex로 설정해 app-modal-shell을 중앙 정렬합니다.
    dialogEl.showModal()
    dialogEl.style.display = "flex"

    return {
      close() {
        dialogEl.close()
        dialogEl.style.display = ""
      }
    }
  }
}
