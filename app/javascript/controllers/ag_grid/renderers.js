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

export const RENDERER_REGISTRY = {
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
    const icon = isFolder ? "[D]" : "[M]"

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

  userActionCellRenderer: (params) => {
    const container = document.createElement("div")
    container.classList.add("grid-action-buttons")

    container.appendChild(createActionButton({
      text: "✎",
      title: "수정",
      onClick: () => emit(container, "user-crud:edit", { userData: params.data })
    }))
    container.appendChild(createActionButton({
      text: "X",
      title: "삭제",
      classes: ["grid-action-btn--danger"],
      onClick: () => emit(container, "user-crud:delete", { id: params.data.id, userNm: params.data.user_nm })
    }))
    return container
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

  deptActionCellRenderer: (params) => {
    const container = document.createElement("div")
    container.classList.add("grid-action-buttons")

    container.appendChild(createActionButton({
      text: "+",
      title: "하위부서추가",
      onClick: () => emit(container, "dept-crud:add-child", { parentCode: params.data.dept_code })
    }))
    container.appendChild(createActionButton({
      text: "✎",
      title: "수정",
      onClick: () => emit(container, "dept-crud:edit", { deptData: params.data })
    }))
    container.appendChild(createActionButton({
      text: "X",
      title: "삭제",
      classes: ["grid-action-btn--danger"],
      onClick: () => emit(container, "dept-crud:delete", { id: params.data.id, deptNm: params.data.dept_nm })
    }))
    return container
  },

  actionCellRenderer: (params) => {
    const container = document.createElement("div")
    container.classList.add("grid-action-buttons")

    container.appendChild(createActionButton({
      text: "+",
      title: "하위메뉴추가",
      onClick: () => emit(container, "menu-crud:add-child", {
        parentCd: params.data.menu_cd,
        parentLevel: params.data.menu_level
      })
    }))
    container.appendChild(createActionButton({
      text: "✎",
      title: "수정",
      onClick: () => emit(container, "menu-crud:edit", { menuData: params.data })
    }))
    container.appendChild(createActionButton({
      text: "X",
      title: "삭제",
      classes: ["grid-action-btn--danger"],
      onClick: () => emit(container, "menu-crud:delete", {
        id: params.data.id,
        menuCd: params.data.menu_cd
      })
    }))
    return container
  }
}

