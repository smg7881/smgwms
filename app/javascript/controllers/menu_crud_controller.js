import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "overlay", "modalTitle", "form",
    "fieldId", "fieldMenuCd", "fieldMenuNm", "fieldParentCd",
    "fieldMenuUrl", "fieldMenuIcon", "fieldSortOrder",
    "fieldMenuLevel", "fieldMenuType", "fieldUseYn", "fieldTabId"
  ]

  static values = {
    createUrl: String,
    updateUrl: String,
    deleteUrl: String
  }

  connect() {
    this.element.addEventListener("menu-crud:add-child", this.handleAddChild)
    this.element.addEventListener("menu-crud:edit", this.handleEdit)
    this.element.addEventListener("menu-crud:delete", this.handleDelete)
    this.element.addEventListener("click", this.handleDelegatedClick)
  }

  disconnect() {
    this.element.removeEventListener("menu-crud:add-child", this.handleAddChild)
    this.element.removeEventListener("menu-crud:edit", this.handleEdit)
    this.element.removeEventListener("menu-crud:delete", this.handleDelete)
    this.element.removeEventListener("click", this.handleDelegatedClick)
  }

  openAddTopLevel() {
    this.resetForm()
    this.modalTitleTarget.textContent = "최상위 메뉴 추가"
    this.fieldParentCdTarget.value = ""
    this.fieldMenuLevelTarget.value = 1
    this.fieldMenuTypeTarget.value = "FOLDER"
    this.fieldMenuCdTarget.readOnly = false
    this.mode = "create"
    this.openModal()
  }

  handleAddChild = (event) => {
    const { parentCd, parentLevel } = event.detail
    this.resetForm()
    this.modalTitleTarget.textContent = "하위 메뉴 추가"
    this.fieldParentCdTarget.value = parentCd
    this.fieldMenuLevelTarget.value = Number(parentLevel || 1) + 1
    this.fieldMenuTypeTarget.value = "MENU"
    this.fieldMenuCdTarget.readOnly = false
    this.mode = "create"
    this.openModal()
  }

  handleEdit = (event) => {
    const data = event.detail.menuData
    this.resetForm()
    this.modalTitleTarget.textContent = "메뉴 수정"
    this.fieldIdTarget.value = data.id
    this.fieldMenuCdTarget.value = data.menu_cd
    this.fieldMenuCdTarget.readOnly = true
    this.fieldMenuNmTarget.value = data.menu_nm
    this.fieldParentCdTarget.value = data.parent_cd || ""
    this.fieldMenuUrlTarget.value = data.menu_url || ""
    this.fieldMenuIconTarget.value = data.menu_icon || ""
    this.fieldSortOrderTarget.value = data.sort_order
    this.fieldMenuLevelTarget.value = data.menu_level
    this.fieldMenuTypeTarget.value = data.menu_type
    this.fieldUseYnTarget.value = data.use_yn
    this.fieldTabIdTarget.value = data.tab_id || ""
    this.mode = "update"
    this.openModal()
  }

  handleDelete = async (event) => {
    const { id, menuCd } = event.detail
    if (!confirm(`"${menuCd}" 메뉴를 삭제하시겠습니까?`)) return

    try {
      const response = await fetch(this.deleteUrlValue.replace(":id", id), {
        method: "DELETE",
        headers: { "X-CSRF-Token": this.csrfToken }
      })
      const result = await response.json()
      if (!response.ok || !result.success) {
        alert("삭제 실패: " + (result.errors || ["요청 처리 실패"]).join(", "))
        return
      }

      alert(result.message || "삭제되었습니다.")
      this.refreshGrid()
    } catch {
      alert("삭제 실패: 네트워크 오류")
    }
  }

  async saveMenu() {
    const formData = new FormData(this.formTarget)
    const menu = Object.fromEntries(formData)
    Object.keys(menu).forEach((key) => {
      if (menu[key] === "") menu[key] = null
    })

    let url
    let method
    if (this.mode === "create") {
      url = this.createUrlValue
      method = "POST"
      delete menu.id
    } else {
      url = this.updateUrlValue.replace(":id", menu.id)
      method = "PATCH"
      delete menu.id
    }

    try {
      const response = await fetch(url, {
        method,
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfToken
        },
        body: JSON.stringify({ menu })
      })

      const result = await response.json()
      if (!response.ok || !result.success) {
        alert("저장 실패: " + (result.errors || ["요청 처리 실패"]).join(", "))
        return
      }

      alert(result.message || "저장되었습니다.")
      this.closeModal()
      this.refreshGrid()
    } catch {
      alert("저장 실패: 네트워크 오류")
    }
  }

  submitMenu(event) {
    event.preventDefault()
    this.saveMenu()
  }

  closeModal() {
    this.overlayTarget.hidden = true
  }

  stopPropagation(event) {
    event.stopPropagation()
  }

  get csrfToken() {
    return document.querySelector("[name='csrf-token']")?.content || ""
  }

  openModal() {
    this.overlayTarget.hidden = false
  }

  resetForm() {
    this.formTarget.reset()
    this.fieldIdTarget.value = ""
    this.fieldSortOrderTarget.value = 0
    this.fieldUseYnTarget.value = "Y"
  }

  refreshGrid() {
    const agGridEl = this.element.querySelector("[data-controller='ag-grid']")
    const agGridController = this.application.getControllerForElementAndIdentifier(agGridEl, "ag-grid")
    agGridController?.refresh()
  }

  handleDelegatedClick = (event) => {
    const cancelButton = event.target.closest("[data-menu-crud-role='cancel']")
    if (cancelButton) {
      event.preventDefault()
      this.closeModal()
    }
  }
}
