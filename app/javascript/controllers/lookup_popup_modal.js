const MODAL_ID = "search-popup-modal"

let activeClose = null

function closeModalElement(modal) {
  if (!modal) return
  modal.style.display = "none"
  modal.removeAttribute("data-open")
}

function openModalElement(modal) {
  if (!modal) return
  modal.style.display = "flex"
  modal.setAttribute("data-open", "true")
}

function applyModalBaseStyle(modal) {
  modal.className = "app-modal-overlay search-popup-overlay"
  modal.style.display = "none"
  modal.style.padding = "12px"
  modal.style.zIndex = "2147483000"
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

  const code = String(detail.code ?? detail.corp_cd ?? detail.fnc_or_cd ?? "").trim()
  const name = String(detail.name ?? detail.corp_nm ?? detail.fnc_or_nm ?? detail.display ?? "").trim()

  return {
    ...detail,
    code,
    name,
    display: name
  }
}

function buildFrameSrc(baseUrl, keyword) {
  const url = new URL(baseUrl, window.location.origin)
  url.searchParams.set("popup", "1")

  const text = String(keyword ?? "").trim()
  if (text.length > 0) {
    url.searchParams.set("q", text)
  }

  return `${url.pathname}${url.search}${url.hash}`
}

function buildOverlayElement() {
  const modal = document.createElement("div")
  modal.id = MODAL_ID
  modal.setAttribute("role", "dialog")
  modal.setAttribute("aria-modal", "true")
  applyModalBaseStyle(modal)

  modal.addEventListener("click", (event) => {
    if (event.target === modal) {
      modal.dispatchEvent(new CustomEvent("search-popup:close"))
    }
  })

  return modal
}

function ensureModal() {
  let modal = document.getElementById(MODAL_ID)
  if (modal && modal.tagName === "DIV") {
    applyModalBaseStyle(modal)
    return modal
  }

  const nextModal = buildOverlayElement()
  if (modal?.parentNode) {
    modal.parentNode.replaceChild(nextModal, modal)
  } else {
    document.body.appendChild(nextModal)
  }
  modal = nextModal

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
    <div class="app-modal-shell" style="width:min(980px, calc(100vw - 24px));max-width:min(980px, calc(100vw - 24px));">
      <div class="app-modal-header">
        <h3 class="app-modal-title">${escapeHtml(heading)}</h3>
        <button type="button" class="app-modal-close" data-role="lookup-popup-close">&times;</button>
      </div>
      <div class="app-modal-body modal-body" style="padding:0;">
        <iframe
          title="${escapeHtml(heading)}"
          src="${escapeHtml(frameSrc)}"
          style="width:100%;height:min(72vh,700px);border:0;background:transparent;display:block;"
          loading="eager"></iframe>
      </div>
      <div class="app-modal-footer">
        <button type="button" class="btn btn-sm btn-secondary" data-role="lookup-popup-cancel">닫기</button>
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
      modal.removeEventListener("search-popup:close", onRequestClose)
      window.removeEventListener("message", onMessage)
      resolve(selection)
    }

    const onSelect = (event) => {
      const selection = normalizeSelection(event.detail)
      if (!selection) return
      closeModalElement(modal)
      finalize(selection)
    }

    const onRequestClose = () => {
      closeModalElement(modal)
      finalize(null)
    }

    const onMessage = (event) => {
      if (event.origin !== window.location.origin) return

      const data = event.data || {}
      if (data.source !== "search-popup-iframe") return

      if (data.type === "search-popup-select") {
        const selection = normalizeSelection(data.detail)
        if (!selection) return
        closeModalElement(modal)
        finalize(selection)
        return
      }

      if (data.type === "search-popup-close") {
        closeModalElement(modal)
        finalize(null)
      }
    }

    activeClose = (selection = null) => {
      closeModalElement(modal)
      finalize(selection)
    }

    modal.addEventListener("search-popup:select", onSelect)
    modal.addEventListener("search-popup:close", onRequestClose)
    window.addEventListener("message", onMessage)

    const closeButtons = modal.querySelectorAll("[data-role='lookup-popup-close'], [data-role='lookup-popup-cancel']")
    closeButtons.forEach((button) => {
      button.addEventListener("click", () => {
        modal.dispatchEvent(new CustomEvent("search-popup:close"))
      })
    })

    openModalElement(modal)
  })
}
