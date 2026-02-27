function emit(container, eventName, detail) {
  const event = new CustomEvent(eventName, { detail, bubbles: true })
  container.dispatchEvent(event)
}

function createActionButton({ text, title, classes = [], onClick }) {
  const button = document.createElement("button")
  button.type = "button"
  button.innerHTML = text
  button.title = title
  button.classList.add("grid-action-btn", ...classes)
  button.addEventListener("click", onClick)
  return button
}

const SEARCH_ICON_SVG = `
  <svg
    xmlns="http://www.w3.org/2000/svg"
    width="24"
    height="24"
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    stroke-width="2"
    stroke-linecap="round"
    stroke-linejoin="round"
    class="lucide-icon w-4 h-4"
    aria-hidden="true">
    <circle cx="11" cy="11" r="8"></circle>
    <path d="m21 21-4.3-4.3"></path>
  </svg>
`.trim()

export const COMMON_RENDERER_REGISTRY = {
  link: (params) => {
    if (params.value == null) return ""

    const pathTemplate = params.colDef.cellRendererParams?.path
    if (!pathTemplate) return String(params.value)

    const href = pathTemplate.replace(/\${(\w+)}/g, (_, key) => {
      const value = params.data?.[key]
      return encodeURIComponent(value ?? "")
    })

    const anchor = document.createElement("a")
    anchor.className = "ag-grid-link"
    anchor.dataset.turboFrame = "_top"
    anchor.href = href
    anchor.textContent = String(params.value)
    return anchor
  },

  treeMenuCellRenderer: (params) => {
    const level = Number(params.data?.menu_level || 1)
    const indent = Math.max(level - 1, 0) * 20
    const isFolder = params.data?.menu_type === "FOLDER"
    const icon = isFolder ? "[+]" : "[-]"

    const span = document.createElement("span")
    span.style.paddingLeft = `${indent}px`
    span.textContent = `${icon} ${params.value ?? ""}`
    if (isFolder) span.classList.add("tree-menu-folder")
    return span
  },

  workStatusCellRenderer: (params) => {
    const span = document.createElement("span")
    span.style.fontWeight = "bold"
    if (params.value === "ACTIVE") {
      span.style.color = "#18a058"
      span.textContent = "ACTIVE"
    } else {
      span.style.color = "#d03050"
      span.textContent = "RESIGNED"
    }
    return span
  },

  deptTreeCellRenderer: (params) => {
    const level = Number(params.data?.dept_level || 1)
    const indent = Math.max(level - 1, 0) * 20
    const icon = level === 1 ? "[+]" : "[-]"

    const span = document.createElement("span")
    span.style.paddingLeft = `${indent}px`
    span.textContent = `${icon} ${params.value ?? ""}`
    return span
  },

  loginSuccessCellRenderer: (params) => {
    const span = document.createElement("span")
    span.style.fontWeight = "bold"
    if (params.value === true) {
      span.style.color = "#18a058"
      span.textContent = "성공"
    } else {
      span.style.color = "#d03050"
      span.textContent = "실패"
    }
    return span
  },

  deptUseYnCellRenderer: (params) => {
    const span = document.createElement("span")
    span.style.fontWeight = "bold"
    if (params.value === "Y") {
      span.style.color = "#18a058"
      span.textContent = "Y"
    } else {
      span.style.color = "#d03050"
      span.textContent = "N"
    }
    return span
  },

  codeUseYnCellRenderer: (params) => {
    const span = document.createElement("span")
    span.style.fontWeight = "bold"
    if (params.value === "Y") {
      span.style.color = "#18a058"
      span.textContent = "Y"
    } else {
      span.style.color = "#d03050"
      span.textContent = "N"
    }
    return span
  },

  stockYnCellRenderer: (params) => {
    const span = document.createElement("span")
    const value = (params.value || "").toString().toUpperCase()
    span.style.fontWeight = "bold"

    if (value === "Y") {
      span.style.color = "#d03050"
      span.textContent = "Y"
    } else {
      span.style.color = "#18a058"
      span.textContent = "N"
    }

    return span
  },

  rowStatusCellRenderer: (params) => {
    const row = params.data || {}
    const span = document.createElement("span")
    span.className = "row-status-icon"

    if (row.__is_deleted) {
      span.textContent = "−"
      span.title = "행삭제"
      span.classList.add("is-delete")
      return span
    }

    if (row.__is_new) {
      span.textContent = "+"
      span.title = "행추가"
      span.classList.add("is-add")
      return span
    }

    if (row.__is_updated) {
      span.textContent = "✎"
      span.title = "행수정"
      span.classList.add("is-edit")
      return span
    }

    span.textContent = ""
    span.title = ""
    return span
  },

  popupSelectCellRenderer: (params) => {
    const container = document.createElement("div")
    container.classList.add("grid-action-buttons")

    container.appendChild(createActionButton({
      text: "선택",
      title: "선택",
      onClick: () => emit(container, "search-popup-grid:select", { row: params.data })
    }))
    return container
  },

  lookupPopupCellRenderer: (params) => {
    const container = document.createElement("div")
    container.classList.add("ag-lookup-cell")
    container.style.position = "relative"
    container.style.width = "100%"
    container.style.height = "100%"

    const field = params.colDef?.field
    const rowData = params.data || {}
    const input = document.createElement("input")
    input.type = "text"
    input.classList.add("ag-lookup-cell__input")
    input.value = params.value == null ? "" : String(params.value)
    input.disabled = Boolean(rowData.__is_deleted)
    input.style.width = "100%"
    input.style.height = "26px"
    input.style.paddingRight = "34px"

    const syncValue = () => {
      if (!field || !params.node) return
      const next = input.value ?? ""
      if (String(rowData[field] ?? "") === String(next)) return
      params.node.setDataValue(field, next)
    }

    const stopBubble = (event) => {
      event.stopPropagation()
    }

    input.addEventListener("mousedown", stopBubble)
    input.addEventListener("click", stopBubble)
    input.addEventListener("dblclick", stopBubble)
    input.addEventListener("input", () => {
      if (!field) return
      rowData[field] = input.value ?? ""
    })
    input.addEventListener("keydown", (event) => {
      if (event.key === "Enter") {
        event.preventDefault()
        event.stopPropagation()
        syncValue()
        emit(container, "ag-grid:lookup-open", {
          rowNode: params.node,
          rowIndex: params.rowIndex,
          colId: params.column?.getColId?.(),
          keyword: input.value,
          colDef: params.colDef
        })
        return
      }

      if (event.key !== "Tab") {
        event.stopPropagation()
      }
    })
    input.addEventListener("blur", syncValue)

    container.appendChild(input)

    const button = createActionButton({
      text: SEARCH_ICON_SVG,
      title: "찾기",
      classes: ["ag-lookup-cell__btn"],
      onClick: (event) => {
        event.preventDefault()
        event.stopPropagation()
        syncValue()

        emit(container, "ag-grid:lookup-open", {
          rowNode: params.node,
          rowIndex: params.rowIndex,
          colId: params.column?.getColId?.(),
          keyword: input.value,
          colDef: params.colDef
        })
      }
    })
    button.setAttribute("aria-label", "찾기")
    button.disabled = Boolean(rowData.__is_deleted)
    button.style.position = "absolute"
    button.style.right = "2px"
    button.style.top = "50%"
    button.style.transform = "translateY(-50%)"
    button.style.zIndex = "2"
    button.style.width = "28px"
    button.style.minWidth = "28px"
    button.style.height = "24px"
    button.style.display = "inline-flex"
    button.style.alignItems = "center"
    button.style.justifyContent = "center"
    button.style.visibility = "visible"
    button.style.opacity = "1"
    container.appendChild(button)

    return container
  },

  noticeTopFixedCellRenderer: (params) => {
    const span = document.createElement("span")
    span.style.fontWeight = "bold"
    span.style.fontSize = "12px"
    if (params.value === "Y") {
      span.style.color = "#d03050"
      span.textContent = "공지"
    } else {
      span.style.color = "#8b949e"
      span.textContent = "일반"
    }
    return span
  },

  noticePublishedCellRenderer: (params) => {
    const span = document.createElement("span")
    span.style.fontWeight = "bold"
    if (params.value === "Y") {
      span.style.color = "#18a058"
      span.textContent = "게시"
    } else {
      span.style.color = "#d08700"
      span.textContent = "미게시"
    }
    return span
  },

  noticeTitleCellRenderer: (params) => {
    const button = document.createElement("button")
    button.type = "button"
    button.classList.add("ag-grid-link")
    button.textContent = params.value ?? ""
    button.style.cursor = "pointer"
    button.style.background = "transparent"
    button.style.border = "0"
    button.style.padding = "0"
    button.style.textAlign = "left"
    button.addEventListener("click", () => emit(button, "notice-crud:edit", { id: params.data.id }))
    return button
  }
}

export { emit, createActionButton }

