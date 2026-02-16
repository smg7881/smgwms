import BaseCrudController from "controllers/base_crud_controller"

export default class extends BaseCrudController {
  static resourceName = "menu"
  static deleteConfirmKey = "menuCd"
  static entityLabel = "메뉴"

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

  resetForm() {
    this.formTarget.reset()
    this.fieldIdTarget.value = ""
    this.fieldSortOrderTarget.value = 0
    this.fieldUseYnTarget.value = "Y"
  }
}
