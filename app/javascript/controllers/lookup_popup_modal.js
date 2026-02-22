const MODAL_ID = "search-popup-modal"
const FRAME_ID = "search_popup_frame"

let activeClose = null

function applyModalBaseStyle(modal) {
  modal.style.border = "none"
  modal.style.padding = "0"
  modal.style.background = "transparent"
  modal.style.width = "min(980px, calc(100vw - 24px))"
  modal.style.maxWidth = "min(980px, calc(100vw - 24px))"
  modal.style.position = "fixed"
  modal.style.inset = "0"
  modal.style.margin = "auto"
}

function escapeHtml(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
}

function normalizeSelection(detail) {
  if (!detail || typeof detail !== "object") return null

  const code = String(detail.code ?? "").trim()
  const name = String(detail.name ?? detail.display ?? "").trim()

  return {
    code,
    name,
    display: name
  }
}

function buildFrameSrc(baseUrl, keyword) {
  const url = new URL(baseUrl, window.location.origin)
  url.searchParams.set("frame", FRAME_ID)

  const text = String(keyword ?? "").trim()
  if (text.length > 0) {
    url.searchParams.set("q", text)
  }

  return `${url.pathname}${url.search}${url.hash}`
}

function ensureModal() {
  let modal = document.getElementById(MODAL_ID)
  if (modal) {
    applyModalBaseStyle(modal)
    return modal
  }

  modal = document.createElement("dialog")
  modal.id = MODAL_ID
  modal.className = "form-grid-modal"
  applyModalBaseStyle(modal)
  modal.addEventListener("click", (event) => {
    if (event.target === modal) {
      modal.close()
    }
  })
  document.body.appendChild(modal)
  return modal
}

function defaultTitle(type) {
  const label = String(type ?? "").trim()
  if (!label) {
    return "조회"
  }
  return `${label} 조회`
}

export function openLookupPopup({ type, url, keyword, title } = {}) {
  const popupType = String(type ?? "").trim()
  if (!popupType) {
    return Promise.resolve(null)
  }

  if (typeof activeClose === "function") {
    activeClose(null)
  }

  const modal = ensureModal()
  const baseUrl = String(url ?? "").trim() || `/search_popups/${encodeURIComponent(popupType)}`
  const frameSrc = buildFrameSrc(baseUrl, keyword)
  const heading = String(title ?? "").trim() || defaultTitle(popupType)

  modal.innerHTML = `
    <div class="form-grid-modal-content" style="display:flex;flex-direction:column;max-height:90vh;">
      <div class="form-grid-modal-header" style="display:flex;align-items:center;justify-content:space-between;">
        <h3>${escapeHtml(heading)}</h3>
        <button type="button" class="btn-close" data-role="lookup-popup-close">×</button>
      </div>
      <div class="form-grid-modal-body" style="overflow:auto;">
        <turbo-frame id="${FRAME_ID}" src="${escapeHtml(frameSrc)}" loading="lazy">
          <div class="form-grid-loading">로딩 중...</div>
        </turbo-frame>
      </div>
    </div>
  `

  return new Promise((resolve) => {
    let settled = false
    const finalize = (selection) => {
      if (settled) return
      settled = true
      activeClose = null
      modal.removeEventListener("search-popup:select", onSelect)
      modal.removeEventListener("close", onClose)
      resolve(selection)
    }

    const onSelect = (event) => {
      const selection = normalizeSelection(event.detail)
      if (!selection) return
      finalize(selection)
      if (modal.open) {
        modal.close()
      }
    }

    const onClose = () => {
      finalize(null)
    }

    activeClose = finalize

    modal.addEventListener("search-popup:select", onSelect)
    modal.addEventListener("close", onClose)

    const closeButton = modal.querySelector("[data-role='lookup-popup-close']")
    if (closeButton) {
      closeButton.addEventListener("click", () => modal.close(), { once: true })
    }

    if (modal.open) {
      modal.close()
    }
    modal.showModal()
  })
}
