import { emit, createActionButton } from "controllers/ag_grid/renderers/common"

export const ACTION_RENDERER_REGISTRY = {
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

  stdWorkplaceActionCellRenderer: (params) => {
    const container = document.createElement("div")
    container.classList.add("grid-action-buttons")

    container.appendChild(createActionButton({
      text: "✎",
      title: "수정",
      onClick: () => emit(container, "std-workplace-crud:edit", { workplaceData: params.data })
    }))
    container.appendChild(createActionButton({
      text: "X",
      title: "삭제",
      classes: ["grid-action-btn--danger"],
      onClick: () => emit(container, "std-workplace-crud:delete", {
        id: params.data.id || params.data.workpl_cd,
        workplNm: params.data.workpl_nm || params.data.workpl_cd
      })
    }))

    return container
  },

  stdSellbuyAttrActionCellRenderer: (params) => {
    const container = document.createElement("div")
    container.classList.add("grid-action-buttons")

    container.appendChild(createActionButton({
      text: "✎",
      title: "수정",
      onClick: () => emit(container, "std-sellbuy-attribute-crud:edit", { sellbuyAttrData: params.data })
    }))
    container.appendChild(createActionButton({
      text: "X",
      title: "삭제",
      classes: ["grid-action-btn--danger"],
      onClick: () => emit(container, "std-sellbuy-attribute-crud:delete", {
        id: params.data.id || params.data.sellbuy_attr_cd,
        sellbuyAttrNm: params.data.sellbuy_attr_nm || params.data.sellbuy_attr_cd
      })
    }))

    return container
  },

  stdClientItemCodeActionCellRenderer: (params) => {
    const container = document.createElement("div")
    container.classList.add("grid-action-buttons")

    container.appendChild(createActionButton({
      text: "✎",
      title: "수정",
      onClick: () => emit(container, "std-client-item-code-crud:edit", { clientItemCodeData: params.data })
    }))
    container.appendChild(createActionButton({
      text: "X",
      title: "삭제",
      classes: ["grid-action-btn--danger"],
      onClick: () => emit(container, "std-client-item-code-crud:delete", {
        id: params.data.id,
        itemCd: params.data.item_cd || params.data.id
      })
    }))

    return container
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

  noticeActionCellRenderer: (params) => {
    const container = document.createElement("div")
    container.classList.add("grid-action-buttons")

    container.appendChild(createActionButton({
      text: "✎",
      title: "수정",
      onClick: () => emit(container, "notice-crud:edit", { id: params.data.id })
    }))
    container.appendChild(createActionButton({
      text: "X",
      title: "삭제",
      classes: ["grid-action-btn--danger"],
      onClick: () => emit(container, "notice-crud:delete", { id: params.data.id, title: params.data.title })
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

