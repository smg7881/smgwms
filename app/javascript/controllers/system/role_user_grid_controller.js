/**
 * role_user_grid_controller.js
 *
 * 역할별 사용자 할당(미할당 <-> 할당) 화면을 제어합니다.
 */
import BaseGridController from "controllers/base_grid_controller"
import { showAlert } from "components/ui/alert"
import { postJson } from "controllers/grid/grid_utils"
import { fetchJson } from "controllers/grid/core/http_client"

export default class extends BaseGridController {
  static targets = [
    ...BaseGridController.targets,
    "leftGrid",
    "rightGrid",
    "leftSearchInput",
    "rightSearchInput",
    "selectedRoleCode"
  ]

  static values = {
    ...BaseGridController.values,
    availableUrl: String,
    assignedUrl: String,
    saveUrl: String
  }

  gridRoles() {
    return {
      left: { target: "leftGrid" },
      right: { target: "rightGrid" }
    }
  }

  connect() {
    super.connect()
    this.leftAllUsers = []
    this.rightAllUsers = []
    this.leftSearchTerm = ""
    this.rightSearchTerm = ""
  }

  onAllGridsReady() {
    this.loadUsers()
  }

  changeRole() {
    this.selectedRoleCodeTarget.value = this.currentRoleCode
    this.resetSearch()
    this.loadUsers()
  }

  async loadUsers() {
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

      this.leftAllUsers = Array.isArray(availableUsers) ? availableUsers : []
      this.rightAllUsers = Array.isArray(assignedUsers) ? assignedUsers : []
      this.renderFilteredRows()
    } catch {
      showAlert("역할 사용자 조회에 실패했습니다.")
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
    const selectedRows = this.selectedRows("left")
    if (!selectedRows.length) return

    const selectedIds = new Set(selectedRows.map((row) => row.user_id_code))
    this.rightAllUsers = [...this.rightAllUsers, ...selectedRows]
    this.leftAllUsers = this.leftAllUsers.filter((row) => !selectedIds.has(row.user_id_code))

    this.renderFilteredRows()
  }

  moveToLeft() {
    const selectedRows = this.selectedRows("right")
    if (!selectedRows.length) return

    const selectedIds = new Set(selectedRows.map((row) => row.user_id_code))
    this.leftAllUsers = [...this.leftAllUsers, ...selectedRows]
    this.rightAllUsers = this.rightAllUsers.filter((row) => !selectedIds.has(row.user_id_code))

    this.renderFilteredRows()
  }

  async save() {
    const roleCd = this.currentRoleCode
    if (!roleCd) {
      showAlert("역할을 먼저 선택해주세요")
      return
    }

    const userIds = [...new Set(
      this.rightAllUsers.map((user) => user.user_id_code).filter((id) => Boolean(id))
    )]

    const result = await postJson(this.saveUrlValue, {
      role_cd: roleCd,
      user_ids: userIds
    })
    if (!result) return

    showAlert(result.message || "저장되었습니다.")
    this.loadUsers()
  }

  renderFilteredRows() {
    const leftRows = this.filterRows(this.leftAllUsers, this.leftSearchTerm)
    const rightRows = this.filterRows(this.rightAllUsers, this.rightSearchTerm)

    this.setRows("left", leftRows)
    this.setRows("right", rightRows)
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
    const formValue = this.getSearchFormValue("role_cd", { toUpperCase: true })
    if (formValue) return formValue

    const select = this.element.querySelector("#q_role_cd")
    const selectValue = select?.value?.toString().trim().toUpperCase()
    if (selectValue) return selectValue

    return this.selectedRoleCodeTarget.value?.toString().trim().toUpperCase() || ""
  }
}
