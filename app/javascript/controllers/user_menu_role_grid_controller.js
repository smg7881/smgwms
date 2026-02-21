import { Controller } from "@hotwired/stimulus"
import { isApiAlive } from "controllers/grid/grid_utils"

export default class extends Controller {
  static targets = ["userGrid", "roleGrid", "menuGrid"]

  static values = {
    rolesUrl: String,
    menusUrl: String
  }

  connect() {
    this.selectedUserIdCode = ""
    this.userApi = null
    this.roleApi = null
    this.menuApi = null
    this.userGridController = null
    this.roleGridController = null
    this.menuGridController = null
    this.rolesRequestId = 0
    this.menusRequestId = 0
    this.rolesAbortController = null
    this.menusAbortController = null
  }

  registerGrid(event) {
    const gridElement = event.target.closest("[data-controller='ag-grid']")
    if (!gridElement) return

    const { api, controller } = event.detail

    if (gridElement === this.userGridTarget) {
      this.userGridController = controller
      this.userApi = api
    } else if (gridElement === this.roleGridTarget) {
      this.roleGridController = controller
      this.roleApi = api
    } else if (gridElement === this.menuGridTarget) {
      this.menuGridController = controller
      this.menuApi = api
    }

    if (this.userApi && this.roleApi && this.menuApi) {
      this.bindGridEvents()
      this.handleUserGridDataLoaded()
    }
  }

  disconnect() {
    this.unbindGridEvents()
    this.cancelPendingRequests()
    this.userApi = null
    this.roleApi = null
    this.menuApi = null
    this.userGridController = null
    this.roleGridController = null
    this.menuGridController = null
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
    if (isApiAlive(this.userApi) && this._onUserSelectionChanged) {
      this.userApi.removeEventListener("selectionChanged", this._onUserSelectionChanged)
    }
    if (isApiAlive(this.userApi) && this._onUserRowDataUpdated) {
      this.userApi.removeEventListener("rowDataUpdated", this._onUserRowDataUpdated)
    }
    if (isApiAlive(this.roleApi) && this._onRoleSelectionChanged) {
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
    if (!isApiAlive(this.roleApi) || !isApiAlive(this.menuApi)) return

    this.selectedUserIdCode = userIdCode || ""
    this.roleApi.setGridOption("rowData", [])
    this.menuApi.setGridOption("rowData", [])

    if (!this.selectedUserIdCode) return

    const requestId = ++this.rolesRequestId
    this.cancelRolesRequest()
    this.rolesAbortController = new AbortController()

    try {
      const url = `${this.rolesUrlValue}?user_id_code=${encodeURIComponent(this.selectedUserIdCode)}`
      const roles = await this.fetchJson(url, { signal: this.rolesAbortController.signal })

      if (!this.isLatestRolesRequest(requestId) || !isApiAlive(this.roleApi) || !isApiAlive(this.menuApi)) {
        return
      }

      this.roleApi.setGridOption("rowData", roles)

      const selectedRole = this.selectFirstRow(this.roleApi, "role_cd")
      if (selectedRole) {
        this.loadMenusByUserAndRole(this.selectedUserIdCode, selectedRole.role_cd)
      }
    } catch (error) {
      if (this.isAbortError(error) || !this.isLatestRolesRequest(requestId)) return
      alert("사용자 역할 조회에 실패했습니다.")
    } finally {
      if (this.isLatestRolesRequest(requestId)) {
        this.rolesAbortController = null
      }
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
    if (!isApiAlive(this.menuApi)) return

    this.menuApi.setGridOption("rowData", [])

    if (!userIdCode || !roleCd) return

    const requestId = ++this.menusRequestId
    this.cancelMenusRequest()
    this.menusAbortController = new AbortController()

    try {
      const query = new URLSearchParams({
        user_id_code: userIdCode,
        role_cd: roleCd
      })
      const menus = await this.fetchJson(`${this.menusUrlValue}?${query.toString()}`, {
        signal: this.menusAbortController.signal
      })

      if (!this.isLatestMenusRequest(requestId) || !isApiAlive(this.menuApi)) {
        return
      }

      this.menuApi.setGridOption("rowData", menus)
    } catch (error) {
      if (this.isAbortError(error) || !this.isLatestMenusRequest(requestId)) return
      alert("메뉴 조회에 실패했습니다.")
    } finally {
      if (this.isLatestMenusRequest(requestId)) {
        this.menusAbortController = null
      }
    }
  }

  clearRoleAndMenu() {
    this.cancelPendingRequests()
    this.selectedUserIdCode = ""
    if (isApiAlive(this.roleApi)) {
      this.roleApi.setGridOption("rowData", [])
    }
    if (isApiAlive(this.menuApi)) {
      this.menuApi.setGridOption("rowData", [])
    }
  }

  selectFirstRow(api, focusField) {
    if (!isApiAlive(api) || api.getDisplayedRowCount() === 0) return null

    const firstRowNode = api.getDisplayedRowAtIndex(0)
    if (!firstRowNode) return null

    api.ensureIndexVisible(0)
    api.setFocusedCell(0, focusField, null)
    firstRowNode.setSelected(true, true)
    return firstRowNode.data
  }

  async fetchJson(url, options = {}) {
    const response = await fetch(url, {
      headers: { Accept: "application/json" },
      signal: options.signal
    })
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`)
    }
    return response.json()
  }

  cancelPendingRequests() {
    this.rolesRequestId += 1
    this.menusRequestId += 1
    this.cancelRolesRequest()
    this.cancelMenusRequest()
  }

  cancelRolesRequest() {
    if (!this.rolesAbortController) return
    this.rolesAbortController.abort()
    this.rolesAbortController = null
  }

  cancelMenusRequest() {
    if (!this.menusAbortController) return
    this.menusAbortController.abort()
    this.menusAbortController = null
  }

  isLatestRolesRequest(requestId) {
    return requestId === this.rolesRequestId
  }

  isLatestMenusRequest(requestId) {
    return requestId === this.menusRequestId
  }

  isAbortError(error) {
    return error && error.name === "AbortError"
  }
}
