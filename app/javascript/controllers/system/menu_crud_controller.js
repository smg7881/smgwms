/**
 * menu_crud_controller.js
 *
 * BaseGridController를 상속받아 메뉴 계층 CRUD 모달을 제어합니다.
 * - 최상위/하위 메뉴 추가 시 계층 정보 자동 세팅
 * - 그리드 액션 이벤트(menu-crud:*) 수신
 */
import BaseGridController from "controllers/base_grid_controller"

export default class extends BaseGridController {
  static resourceName = "menu"
  static deleteConfirmKey = "menuCd"
  static entityLabel = "메뉴"

  static targets = [
    ...BaseGridController.targets,
    "overlay", "modal", "modalTitle", "form",
    "fieldId", "fieldMenuCd", "fieldMenuNm", "fieldParentCd",
    "fieldMenuUrl", "fieldMenuIcon", "fieldSortOrder",
    "fieldMenuLevel", "fieldMenuType", "fieldUseYn", "fieldTabId"
  ]

  static values = {
    ...BaseGridController.values,
    createUrl: String,
    updateUrl: String,
    deleteUrl: String
  }

  connect() {
    super.connect()
    this.handleDelete = this.handleDelete.bind(this)

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
    super.disconnect()
  }

  openCreate() {
    this.resetForm()
    this.modalTitleTarget.textContent = "최상위 메뉴 추가"
    this.setFieldValues({
      parent_cd: "",
      menu_level: 1,
      menu_type: "FOLDER"
    })
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

    this.setFieldValues({
      parent_cd: parentCd || "",
      menu_level: Number(parentLevel || 1) + 1,
      menu_type: "MENU"
    })
    this.fieldMenuCdTarget.readOnly = false
    this.mode = "create"
    this.openModal()
  }

  handleEdit = (event) => {
    const data = event.detail.menuData
    this.resetForm()
    this.modalTitleTarget.textContent = "메뉴 수정"

    this.fieldIdTarget.value = data.id ?? ""

    this.setFieldValues({
      menu_cd: data.menu_cd || "",
      menu_nm: data.menu_nm || "",
      parent_cd: data.parent_cd || "",
      menu_url: data.menu_url || "",
      menu_icon: data.menu_icon || "",
      sort_order: data.sort_order ?? 0,
      menu_level: data.menu_level || "",
      menu_type: data.menu_type || "MENU",
      use_yn: data.use_yn || "Y",
      tab_id: data.tab_id || ""
    })

    this.fieldMenuCdTarget.readOnly = true
    this.mode = "update"
    this.openModal()
  }

  resetForm() {
    this.formTarget.reset()
    this.fieldIdTarget.value = ""
    this.setFieldValues({
      sort_order: 0,
      use_yn: "Y"
    })
  }
}
