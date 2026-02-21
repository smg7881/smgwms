import BaseGridController from "controllers/base_grid_controller"
import { resolveAgGridRegistration } from "controllers/grid/grid_event_manager"
import { isApiAlive, getCsrfToken, fetchJson, setGridRowData } from "controllers/grid/grid_utils"

// BaseGridController 상속: 좌우 2개 그리드 간 사용자 할당 이동/검색/저장 흐름을 담당합니다.

export default class extends BaseGridController {
  static targets = [
    "leftGrid",
    "rightGrid",
    "leftSearchInput",
    "rightSearchInput",
    "selectedRoleCode"
  ]

  static values = {
    availableUrl: String,
    assignedUrl: String,
    saveUrl: String
  }

  connect() {
    super.connect()
    this.leftAllUsers = []
    this.rightAllUsers = []
    this.leftSearchTerm = ""
    this.rightSearchTerm = ""
    this.leftApi = null
    this.rightApi = null
    this.leftGridController = null
    this.rightGridController = null
  }

  disconnect() {
    this.leftApi = null
    this.rightApi = null
    this.leftGridController = null
    this.rightGridController = null
    super.disconnect()
  }

  registerGrid(event) {
    const registration = resolveAgGridRegistration(event)
    if (!registration) return

    const { gridElement, api, controller } = registration

    if (gridElement === this.leftGridTarget) {
      this.leftGridController = controller
      this.leftApi = api
    } else if (gridElement === this.rightGridTarget) {
      this.rightGridController = controller
      this.rightApi = api
    }

    if (this.leftApi && this.rightApi) {
      this.loadUsers()
    }
  }

  changeRole() {
    this.selectedRoleCodeTarget.value = this.currentRoleCode
    this.resetSearch()
    this.loadUsers()
  }

  async loadUsers() {
    if (!isApiAlive(this.leftApi) || !isApiAlive(this.rightApi)) return

    const roleCd = this.currentRoleCode
    if (!roleCd) {
      this.leftAllUsers = []
      this.rightAllUsers = []
      this.renderFilteredRows()
      return
    }

    try {
      const [availableUsers, assignedUsers] = await Promise.all([
        fetchJson(`${this.availableUrlValue}?role_cd=${encodeURIComponent(roleCd)}`),
        fetchJson(`${this.assignedUrlValue}?role_cd=${encodeURIComponent(roleCd)}`)
      ])

      this.leftAllUsers = availableUsers
      this.rightAllUsers = assignedUsers
      this.renderFilteredRows()
    } catch {
      alert("역할 사용자 조회에 실패했습니다.")
    }
  }

  searchLeft() {
    this.leftSearchTerm = this.leftSearchInputTarget.value.toLowerCase().trim()
    this.renderFilteredRows()
  }

  searchRight() {
    this.rightSearchTerm = this.rightSearchInputTarget.value.toLowerCase().trim()
    this.renderFilteredRows()
  }

  moveToRight() {
    if (!isApiAlive(this.leftApi)) return

    const selectedRows = this.leftApi.getSelectedRows()
    if (!selectedRows.length) return

    const selectedIds = new Set(selectedRows.map((row) => row.user_id_code))
    this.rightAllUsers = [...this.rightAllUsers, ...selectedRows]
    this.leftAllUsers = this.leftAllUsers.filter((row) => !selectedIds.has(row.user_id_code))
    this.renderFilteredRows()
  }

  moveToLeft() {
    if (!isApiAlive(this.rightApi)) return

    const selectedRows = this.rightApi.getSelectedRows()
    if (!selectedRows.length) return

    const selectedIds = new Set(selectedRows.map((row) => row.user_id_code))
    this.leftAllUsers = [...this.leftAllUsers, ...selectedRows]
    this.rightAllUsers = this.rightAllUsers.filter((row) => !selectedIds.has(row.user_id_code))
    this.renderFilteredRows()
  }

  async save() {
    const roleCd = this.currentRoleCode
    if (!roleCd) {
      alert("역할을 먼저 선택해주세요")
      return
    }

    const userIds = this.rightAllUsers.map((user) => user.user_id_code).filter((id) => id)

    try {
      const response = await fetch(this.saveUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": getCsrfToken()
        },
        body: JSON.stringify({
          role_cd: roleCd,
          user_ids: userIds
        })
      })

      const result = await response.json()
      if (!response.ok || !result.success) {
        alert("저장 실패: " + (result.errors || ["요청 처리 실패"]).join(", "))
        return
      }

      alert(result.message || "저장되었습니다.")
      this.loadUsers()
    } catch {
      alert("저장 실패: 네트워크 오류")
    }
  }

  renderFilteredRows() {
    if (!isApiAlive(this.leftApi) || !isApiAlive(this.rightApi)) return

    const leftRows = this.filterRows(this.leftAllUsers, this.leftSearchTerm)
    const rightRows = this.filterRows(this.rightAllUsers, this.rightSearchTerm)

    setGridRowData(this.leftApi, leftRows)
    setGridRowData(this.rightApi, rightRows)
  }

  filterRows(rows, term) {
    if (!term) return rows

    return rows.filter((row) => {
      const userNm = (row.user_nm || "").toLowerCase()
      const deptNm = (row.dept_nm || "").toLowerCase()
      return userNm.includes(term) || deptNm.includes(term)
    })
  }

  resetSearch() {
    this.leftSearchInputTarget.value = ""
    this.rightSearchInputTarget.value = ""
    this.leftSearchTerm = ""
    this.rightSearchTerm = ""
  }

  get currentRoleCode() {
    const select = this.element.querySelector("#q_role_cd")
    return select?.value?.toString().trim().toUpperCase() || this.selectedRoleCodeTarget.value
  }
}
