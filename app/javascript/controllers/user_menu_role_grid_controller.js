import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["userGrid", "roleGrid", "menuGrid"]

  static values = {
    rolesUrl: String,
    menusUrl: String
  }

  connect() {
    this.selectedUserIdCode = ""
    this.bindRetryTimer = null
    this.bindGridControllers()
  }

  disconnect() {
    this.unbindGridEvents()
    if (this.bindRetryTimer) clearTimeout(this.bindRetryTimer)

    this.userApi = null
    this.roleApi = null
    this.menuApi = null
  }

  bindGridControllers() {
    this.userGridController = this.application.getControllerForElementAndIdentifier(this.userGridTarget, "ag-grid")
    this.roleGridController = this.application.getControllerForElementAndIdentifier(this.roleGridTarget, "ag-grid")
    this.menuGridController = this.application.getControllerForElementAndIdentifier(this.menuGridTarget, "ag-grid")

    this.userApi = this.userGridController?.api
    this.roleApi = this.roleGridController?.api
    this.menuApi = this.menuGridController?.api

    if (!this.isApiAlive(this.userApi) || !this.isApiAlive(this.roleApi) || !this.isApiAlive(this.menuApi)) {
      this.bindRetryTimer = setTimeout(() => this.bindGridControllers(), 60)
      return
    }

    this.bindGridEvents()
    this.handleUserGridDataLoaded()
  }

  bindGridEvents() {
    this.unbindGridEvents()

    this._onUserSelectionChanged = () => this.handleUserSelectionChanged()
    this._onUserRowDataUpdated = () => this.handleUserGridDataLoaded()
    this._onRoleSelectionChanged = () => this.handleRoleSelectionChanged()

    this.userApi.addEventListener("selectionChanged", this._onUserSelectionChanged)
    this.userApi.addEventListener("rowDataUpdated", this._onUserRowDataUpdated)
    this.roleApi.addEventListener("selectionChanged", this._onRoleSelectionChanged)
  }

  unbindGridEvents() {
    if (this.isApiAlive(this.userApi) && this._onUserSelectionChanged) {
      this.userApi.removeEventListener("selectionChanged", this._onUserSelectionChanged)
    }
    if (this.isApiAlive(this.userApi) && this._onUserRowDataUpdated) {
      this.userApi.removeEventListener("rowDataUpdated", this._onUserRowDataUpdated)
    }
    if (this.isApiAlive(this.roleApi) && this._onRoleSelectionChanged) {
      this.roleApi.removeEventListener("selectionChanged", this._onRoleSelectionChanged)
    }
  }

  handleUserGridDataLoaded() {
    const selectedUser = this.selectFirstRow(this.userApi, "user_id_code")
    if (selectedUser) {
      this.loadRolesByUser(selectedUser.user_id_code)
    } else {
      this.clearRoleAndMenu()
    }
  }

  handleUserSelectionChanged() {
    const selectedUser = this.userApi.getSelectedRows()[0]
    if (!selectedUser) {
      this.clearRoleAndMenu()
      return
    }

    this.loadRolesByUser(selectedUser.user_id_code)
  }

  async loadRolesByUser(userIdCode) {
    this.selectedUserIdCode = userIdCode || ""
    this.roleApi.setGridOption("rowData", [])
    this.menuApi.setGridOption("rowData", [])

    if (!this.selectedUserIdCode) return

    try {
      const url = `${this.rolesUrlValue}?user_id_code=${encodeURIComponent(this.selectedUserIdCode)}`
      const roles = await this.fetchJson(url)
      this.roleApi.setGridOption("rowData", roles)

      const selectedRole = this.selectFirstRow(this.roleApi, "role_cd")
      if (selectedRole) {
        this.loadMenusByUserAndRole(this.selectedUserIdCode, selectedRole.role_cd)
      }
    } catch {
      alert("사용자 역할 조회에 실패했습니다.")
    }
  }

  handleRoleSelectionChanged() {
    const selectedRole = this.roleApi.getSelectedRows()[0]
    if (!selectedRole || !this.selectedUserIdCode) {
      this.menuApi.setGridOption("rowData", [])
      return
    }

    this.loadMenusByUserAndRole(this.selectedUserIdCode, selectedRole.role_cd)
  }

  async loadMenusByUserAndRole(userIdCode, roleCd) {
    this.menuApi.setGridOption("rowData", [])

    if (!userIdCode || !roleCd) return

    try {
      const query = new URLSearchParams({
        user_id_code: userIdCode,
        role_cd: roleCd
      })
      const menus = await this.fetchJson(`${this.menusUrlValue}?${query.toString()}`)
      this.menuApi.setGridOption("rowData", menus)
    } catch {
      alert("메뉴 조회에 실패했습니다.")
    }
  }

  clearRoleAndMenu() {
    this.selectedUserIdCode = ""
    this.roleApi.setGridOption("rowData", [])
    this.menuApi.setGridOption("rowData", [])
  }

  selectFirstRow(api, focusField) {
    if (!this.isApiAlive(api) || api.getDisplayedRowCount() === 0) return null

    const firstRowNode = api.getDisplayedRowAtIndex(0)
    if (!firstRowNode) return null

    api.ensureIndexVisible(0)
    api.setFocusedCell(0, focusField, null)
    firstRowNode.setSelected(true, true)
    return firstRowNode.data
  }

  async fetchJson(url) {
    const response = await fetch(url, { headers: { Accept: "application/json" } })
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`)
    }
    return response.json()
  }

  isApiAlive(api) {
    return Boolean(api) && !(typeof api.isDestroyed === "function" && api.isDestroyed())
  }
}
