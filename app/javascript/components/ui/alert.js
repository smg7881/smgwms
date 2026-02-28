/**
 * UI Alert / Confirm 유틸리티 (Toast + 커스텀 Confirm 모달)
 *
 * showAlert  : 우하단 Toast 알림 (3초 자동소멸)
 * confirmAction : Promise 반환 커스텀 Confirm 모달
 *
 * 기존 시그니처 완전 유지:
 *   showAlert(titleOrMessage, message?, type?)
 *   confirmAction(titleOrMessage, message?) → Promise<boolean>
 */

const TOAST_DURATION = 3000

const TYPE_CONFIG = {
  success: { bg: "#0d2818", border: "#3fb950", icon: "✓", iconColor: "#3fb950" },
  error:   { bg: "#2d1012", border: "#f85149", icon: "✕", iconColor: "#f85149" },
  warning: { bg: "#2d1f04", border: "#d29922", icon: "⚠", iconColor: "#d29922" },
  info:    { bg: "#0c1d35", border: "#58a6ff", icon: "ℹ", iconColor: "#58a6ff" },
}

function getToastContainer() {
  let container = document.getElementById("wms-toast-container")
  if (!container) {
    container = document.createElement("div")
    container.id = "wms-toast-container"
    Object.assign(container.style, {
      position: "fixed",
      bottom: "24px",
      right: "24px",
      zIndex: "9999",
      display: "flex",
      flexDirection: "column",
      gap: "8px",
      pointerEvents: "none",
    })
    document.body.appendChild(container)
  }
  return container
}

/**
 * Toast 알림 메시지를 우하단에 표시합니다.
 *
 * @param {string} titleOrMessage - 제목 또는 메시지 (두 번째 인자가 없으면 메시지로 처리)
 * @param {string} [message]      - 메시지 (두 번째 인자가 있는 경우)
 * @param {string} [type]         - "success" | "error" | "warning" | "info"
 */
export function showAlert(titleOrMessage, message, type = "info") {
  let title, text
  if (message === undefined || message === null) {
    title = null
    text = titleOrMessage
  } else {
    title = titleOrMessage
    text = message
  }

  const cfg = TYPE_CONFIG[type] || TYPE_CONFIG.info
  const container = getToastContainer()

  const toast = document.createElement("div")
  Object.assign(toast.style, {
    background: cfg.bg,
    border: `1px solid ${cfg.border}`,
    borderRadius: "8px",
    padding: "12px 16px",
    minWidth: "280px",
    maxWidth: "420px",
    display: "flex",
    alignItems: "flex-start",
    gap: "10px",
    boxShadow: "0 4px 20px rgba(0,0,0,0.5)",
    pointerEvents: "auto",
    opacity: "0",
    transform: "translateX(16px)",
    transition: "opacity 0.25s ease, transform 0.25s ease",
    fontFamily: "-apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif",
  })

  const iconEl = document.createElement("span")
  iconEl.textContent = cfg.icon
  Object.assign(iconEl.style, {
    color: cfg.iconColor,
    fontWeight: "bold",
    fontSize: "14px",
    lineHeight: "1.5",
    flexShrink: "0",
  })

  const contentEl = document.createElement("div")
  contentEl.style.flex = "1"

  if (title) {
    const titleEl = document.createElement("div")
    titleEl.textContent = title
    Object.assign(titleEl.style, {
      color: cfg.iconColor,
      fontWeight: "700",
      fontSize: "13px",
      marginBottom: "2px",
    })
    contentEl.appendChild(titleEl)
  }

  const textEl = document.createElement("div")
  textEl.textContent = text
  Object.assign(textEl.style, {
    color: "#e6edf3",
    fontSize: "13px",
    lineHeight: "1.4",
  })
  contentEl.appendChild(textEl)

  toast.appendChild(iconEl)
  toast.appendChild(contentEl)
  container.appendChild(toast)

  requestAnimationFrame(() => {
    toast.style.opacity = "1"
    toast.style.transform = "translateX(0)"
  })

  setTimeout(() => {
    toast.style.opacity = "0"
    toast.style.transform = "translateX(16px)"
    setTimeout(() => toast.remove(), 300)
  }, TOAST_DURATION)
}

/**
 * 커스텀 확인 모달을 표시하고 사용자 선택을 Promise로 반환합니다.
 *
 * @param {string} titleOrMessage - 제목 또는 메시지
 * @param {string} [message]      - 메시지 (두 번째 인자가 있는 경우)
 * @returns {Promise<boolean>} 확인 시 true, 취소 시 false
 */
export function confirmAction(titleOrMessage, message) {
  let title, text
  if (message === undefined || message === null) {
    title = null
    text = titleOrMessage
  } else {
    title = titleOrMessage
    text = message
  }

  return new Promise((resolve) => {
    const overlay = document.createElement("div")
    Object.assign(overlay.style, {
      position: "fixed",
      inset: "0",
      background: "rgba(0,0,0,0.55)",
      zIndex: "10000",
      display: "flex",
      alignItems: "center",
      justifyContent: "center",
      fontFamily: "-apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif",
    })

    const dialog = document.createElement("div")
    Object.assign(dialog.style, {
      background: "#161b22",
      border: "1px solid #30363d",
      borderRadius: "12px",
      padding: "24px",
      minWidth: "320px",
      maxWidth: "440px",
      boxShadow: "0 8px 32px rgba(0,0,0,0.5)",
    })

    if (title) {
      const titleEl = document.createElement("h3")
      titleEl.textContent = title
      Object.assign(titleEl.style, {
        margin: "0 0 8px",
        color: "#e6edf3",
        fontSize: "15px",
        fontWeight: "700",
      })
      dialog.appendChild(titleEl)
    }

    const textEl = document.createElement("p")
    textEl.textContent = text
    Object.assign(textEl.style, {
      margin: "0 0 20px",
      color: "#8b949e",
      fontSize: "13px",
      lineHeight: "1.5",
    })
    dialog.appendChild(textEl)

    const btnRow = document.createElement("div")
    Object.assign(btnRow.style, {
      display: "flex",
      justifyContent: "flex-end",
      gap: "8px",
    })

    const cancelBtn = document.createElement("button")
    cancelBtn.textContent = "취소"
    Object.assign(cancelBtn.style, {
      padding: "6px 16px",
      borderRadius: "6px",
      border: "1px solid #374151",
      background: "transparent",
      color: "#d1d5db",
      fontSize: "13px",
      fontWeight: "600",
      cursor: "pointer",
    })

    const confirmBtn = document.createElement("button")
    confirmBtn.textContent = "확인"
    Object.assign(confirmBtn.style, {
      padding: "6px 16px",
      borderRadius: "6px",
      border: "none",
      background: "#3b82f6",
      color: "white",
      fontSize: "13px",
      fontWeight: "600",
      cursor: "pointer",
    })

    btnRow.appendChild(cancelBtn)
    btnRow.appendChild(confirmBtn)
    dialog.appendChild(btnRow)
    overlay.appendChild(dialog)
    document.body.appendChild(overlay)

    const close = (result) => {
      document.removeEventListener("keydown", onKeydown)
      overlay.remove()
      resolve(result)
    }

    cancelBtn.addEventListener("click", () => close(false))
    confirmBtn.addEventListener("click", () => close(true))

    const onKeydown = (e) => {
      if (e.key === "Escape") close(false)
    }
    document.addEventListener("keydown", onKeydown)

    overlay.addEventListener("click", (e) => {
      if (e.target === overlay) close(false)
    })

    confirmBtn.focus()
  })
}
