/**
 * menu_crud_controller.js
 *
 * BaseGridController를 상속받아 메뉴 계층 CRUD 모달을 제어합니다.
 * - 최상위/하위 메뉴 추가 시 계층 정보 자동 세팅
 * - 그리드 액션 이벤트(menu-crud:*) 수신
 */
import BaseGridController from "controllers/base_grid_controller"

export default class extends BaseGridController {
  static resourceName = "adm_menu"
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
    this.connectModal({
      events: [
        { name: "menu-crud:add-child", handler: this.handleAddChild },
        { name: "menu-crud:edit",      handler: this.handleEdit },
        { name: "menu-crud:delete",    handler: this.handleDelete }
      ]
    })
  }

  disconnect() {
    this.disconnectModal()
    super.disconnect()
  }

  openCreate() {
    this.openCreateModal({
      title: "최상위 메뉴 추가",
      defaults: { parent_cd: "", menu_level: 1, menu_type: "FOLDER" },
      readWrite: [this.fieldMenuCdTarget]
    })
  }

  openAddTopLevel() {
    this.openCreate()
  }

  handleAddChild = (event) => {
    const { parentCd, parentLevel } = event.detail
    this.openCreateModal({
      title: "하위 메뉴 추가",
      defaults: {
        parent_cd: parentCd || "",
        menu_level: Number(parentLevel || 1) + 1,
        menu_type: "MENU"
      },
      readWrite: [this.fieldMenuCdTarget]
    })
  }

  handleEdit = (event) => {
    const data = event.detail.menuData
    this.openEditModal(data, {
      title: "메뉴 수정",
      readOnly: [this.fieldMenuCdTarget]
    })
  }

  resetForm() {
    this.resetFormBase({ defaults: { sort_order: 0, use_yn: "Y" } })
  }
}
