import BaseGridController from "controllers/base_grid_controller"
import { GridEventManager, resolveAgGridRegistration } from "controllers/grid/grid_event_manager"
import { AbortableRequestTracker, isAbortError } from "controllers/grid/request_tracker"
import { isApiAlive, fetchJson, setGridRowData } from "controllers/grid/grid_utils"

// BaseGridController 상속: 사용자-역할-메뉴 3단 그리드 연쇄 조회를 처리합니다.

export default class extends BaseGridController {
  static targets = ["userGrid", "roleGrid", "menuGrid"]

  static values = {
    rolesUrl: String,
    menusUrl: String
  }

  connect() {
    super.connect()
    this.selectedUserIdCode = ""
    this.userApi = null
    this.roleApi = null
    this.menuApi = null
    this.userGridController = null
    this.roleGridController = null
    this.menuGridController = null
    this.gridEvents = new GridEventManager()
    this.rolesRequestTracker = new AbortableRequestTracker()
    this.menusRequestTracker = new AbortableRequestTracker()
  }

  disconnect() {
    this.gridEvents.unbindAll()
    this.cancelPendingRequests()
    this.userApi = null
    this.roleApi = null
    this.menuApi = null
    this.userGridController = null
    this.roleGridController = null
    this.menuGridController = null
    super.disconnect()
  }

  registerGrid(event) {
    const registration = resolveAgGridRegistration(event)
    if (!registration) return

    const { gridElement, api, controller } = registration

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

  bindGridEvents() {
    this.gridEvents.unbindAll()
    this.gridEvents.bind(this.userApi, "selectionChanged", this.handleUserSelectionChanged)
    this.gridEvents.bind(this.userApi, "rowDataUpdated", this.handleUserGridDataLoaded)
    this.gridEvents.bind(this.roleApi, "selectionChanged", this.handleRoleSelectionChanged)
  }

  handleUserGridDataLoaded = () => {
    const selectedUser = this.selectFirstRow(this.userApi, "user_id_code")
    if (selectedUser) {
      this.loadRolesByUser(selectedUser.user_id_code)
    } else {
      this.clearRoleAndMenu()
    }
  }

  handleUserSelectionChanged = () => {
    const selectedUser = this.userApi?.getSelectedRows?.()[0]
    if (!selectedUser) {
      this.clearRoleAndMenu()
      return
    }

    this.loadRolesByUser(selectedUser.user_id_code)
  }

  async loadRolesByUser(userIdCode) {
    if (!isApiAlive(this.roleApi) || !isApiAlive(this.menuApi)) return

    this.selectedUserIdCode = userIdCode || ""
    setGridRowData(this.roleApi, [])
    setGridRowData(this.menuApi, [])

    if (!this.selectedUserIdCode) return

    const { requestId, signal } = this.rolesRequestTracker.begin()

    try {
      const url = `${this.rolesUrlValue}?user_id_code=${encodeURIComponent(this.selectedUserIdCode)}`
      const roles = await fetchJson(url, { signal })

      if (!this.rolesRequestTracker.isLatest(requestId) || !isApiAlive(this.roleApi) || !isApiAlive(this.menuApi)) {
        return
      }

      setGridRowData(this.roleApi, roles)

      const selectedRole = this.selectFirstRow(this.roleApi, "role_cd")
      if (selectedRole) {
        this.loadMenusByUserAndRole(this.selectedUserIdCode, selectedRole.role_cd)
      }
    } catch (error) {
      if (isAbortError(error) || !this.rolesRequestTracker.isLatest(requestId)) return
      alert("사용자 역할 조회에 실패했습니다.")
    } finally {
      this.rolesRequestTracker.finish(requestId)
    }
  }

  handleRoleSelectionChanged = () => {
    const selectedRole = this.roleApi?.getSelectedRows?.()[0]
    if (!selectedRole || !this.selectedUserIdCode) {
      setGridRowData(this.menuApi, [])
      return
    }

    this.loadMenusByUserAndRole(this.selectedUserIdCode, selectedRole.role_cd)
  }

  async loadMenusByUserAndRole(userIdCode, roleCd) {
    if (!isApiAlive(this.menuApi)) return

    setGridRowData(this.menuApi, [])
    if (!userIdCode || !roleCd) return

    const { requestId, signal } = this.menusRequestTracker.begin()

    try {
      const query = new URLSearchParams({ user_id_code: userIdCode, role_cd: roleCd })
      const menus = await fetchJson(`${this.menusUrlValue}?${query.toString()}`, { signal })

      if (!this.menusRequestTracker.isLatest(requestId) || !isApiAlive(this.menuApi)) {
        return
      }

      setGridRowData(this.menuApi, menus)
    } catch (error) {
      if (isAbortError(error) || !this.menusRequestTracker.isLatest(requestId)) return
      alert("메뉴 조회에 실패했습니다.")
    } finally {
      this.menusRequestTracker.finish(requestId)
    }
  }

  clearRoleAndMenu() {
    this.cancelPendingRequests()
    this.selectedUserIdCode = ""
    setGridRowData(this.roleApi, [])
    setGridRowData(this.menuApi, [])
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

  cancelPendingRequests() {
    this.rolesRequestTracker.cancelAll()
    this.menusRequestTracker.cancelAll()
  }
}
