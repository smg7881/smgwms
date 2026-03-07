/**
 * user_menu_role_grid_controller.js
 *
 * 사용자 -> 역할 -> 메뉴 3단계 조회 화면을 제어합니다.
 */
import BaseGridController from "controllers/base_grid_controller"
import { showAlert } from "components/ui/alert"
import { AbortableRequestTracker, isAbortError } from "controllers/grid/request_tracker"
import { fetchJson } from "controllers/grid/core/http_client"

export default class extends BaseGridController {
  static targets = [...BaseGridController.targets, "userGrid", "roleGrid", "menuGrid"]

  static values = {
    ...BaseGridController.values,
    rolesUrl: String,
    menusUrl: String
  }

  connect() {
    super.connect()
    this.selectedUserIdCode = ""
    this.rolesRequestTracker = new AbortableRequestTracker()
    this.menusRequestTracker = new AbortableRequestTracker()
  }

  disconnect() {
    this.cancelPendingRequests()
    super.disconnect()
  }

  beforeSearchReset() {
    this.cancelPendingRequests()
    this.selectedUserIdCode = ""
  }

  gridRoles() {
    return {
      user: {
        target: "userGrid",
        masterKeyField: "user_id_code"
      },
      role: {
        target: "roleGrid",
        parentGrid: "user",
        masterKeyField: "role_cd",
        onMasterRowChange: (rowData) => this.onUserRowChanged(rowData),
        detailLoader: (rowData) => this.loadRolesByUser(rowData)
      },
      menu: {
        target: "menuGrid",
        parentGrid: "role",
        onMasterRowChange: (rowData) => this.onRoleRowChanged(rowData),
        detailLoader: (rowData) => this.loadMenusByUserAndRole(rowData)
      }
    }
  }

  async onAllGridsReady() {
    const selectedUser = this.selectFirstMasterRow("user")
    if (!selectedUser) return

    const roles = await this.loadRolesByUser(selectedUser)
    this.setRows("role", roles)
  }

  onUserRowChanged(rowData) {
    this.selectedUserIdCode = rowData?.user_id_code?.toString().trim() || ""
    this.menusRequestTracker.cancelAll()

    if (!this.selectedUserIdCode) {
      this.rolesRequestTracker.cancelAll()
    }
  }

  onRoleRowChanged(rowData) {
    if (!rowData?.role_cd) {
      this.menusRequestTracker.cancelAll()
    }
  }

  async loadRolesByUser(rowData) {
    const userIdCode = rowData?.user_id_code?.toString().trim()
    this.selectedUserIdCode = userIdCode || ""
    if (!userIdCode) return []

    const { requestId, signal } = this.rolesRequestTracker.begin()

    try {
      const url = `${this.rolesUrlValue}?user_id_code=${encodeURIComponent(userIdCode)}`
      const roles = await fetchJson(url, { signal })

      if (!this.rolesRequestTracker.isLatest(requestId)) return []
      return Array.isArray(roles) ? roles : []
    } catch (error) {
      if (isAbortError(error) || !this.rolesRequestTracker.isLatest(requestId)) return []
      showAlert("사용자 역할 조회에 실패했습니다.")
      return []
    } finally {
      this.rolesRequestTracker.finish(requestId)
    }
  }

  async loadMenusByUserAndRole(rowData) {
    const roleCd = rowData?.role_cd?.toString().trim()
    const userIdCode = this.selectedUserIdCode
    if (!userIdCode || !roleCd) return []

    const { requestId, signal } = this.menusRequestTracker.begin()

    try {
      const query = new URLSearchParams({
        user_id_code: userIdCode,
        role_cd: roleCd
      })
      const menus = await fetchJson(`${this.menusUrlValue}?${query.toString()}`, { signal })

      if (!this.menusRequestTracker.isLatest(requestId)) return []
      return Array.isArray(menus) ? menus : []
    } catch (error) {
      if (isAbortError(error) || !this.menusRequestTracker.isLatest(requestId)) return []
      showAlert("메뉴 조회에 실패했습니다.")
      return []
    } finally {
      this.menusRequestTracker.finish(requestId)
    }
  }

  cancelPendingRequests() {
    this.rolesRequestTracker?.cancelAll()
    this.menusRequestTracker?.cancelAll()
  }
}
