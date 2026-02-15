import BaseCrudController from "controllers/base_crud_controller"

export default class extends BaseCrudController {
  static targets = [
    "overlay", "modal", "modalTitle", "form",
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
    this.connectBase({
      events: [
        { name: "menu-crud:add-child", handler: this.handleAddChild },
        { name: "menu-crud:edit", handler: this.handleEdit },
        { name: "menu-crud:delete", handler: this.handleDelete }
      ]
    })
  }

  disconnect() {
    this.disconnectBase()
  }

  openCreate() {
    this.resetForm()
    this.modalTitleTarget.textContent = "최상위 메뉴 추가"
    this.fieldParentCdTarget.value = ""
    this.fieldMenuLevelTarget.value = 1
    this.fieldMenuTypeTarget.value = "FOLDER"
    this.fieldMenuCdTarget.readOnly = false
    this.mode = "create"
    this.openModal()
  }

  openAddTopLevel() {
    this.openCreate()
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
      const { response, result } = await this.requestJson(this.deleteUrlValue.replace(":id", id), {
        method: "DELETE"
      })
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
    const menu = this.buildJsonPayload()
    if (this.hasFieldIdTarget && this.fieldIdTarget.value) menu.id = this.fieldIdTarget.value

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
      const { response, result } = await this.requestJson(url, {
        method,
        body: { menu }
      })

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

  resetForm() {
    this.formTarget.reset()
    this.fieldIdTarget.value = ""
    this.fieldSortOrderTarget.value = 0
    this.fieldUseYnTarget.value = "Y"
  }
}
