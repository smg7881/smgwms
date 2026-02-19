import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
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
    this.leftAllUsers = []
    this.rightAllUsers = []
    this.leftSearchTerm = ""
    this.rightSearchTerm = ""
    this.bindRetryTimer = null
    this.bindGridControllers()
  }

  disconnect() {
    if (this.bindRetryTimer) clearTimeout(this.bindRetryTimer)
    this.leftApi = null
    this.rightApi = null
  }

  bindGridControllers() {
    this.leftGridController = this.application.getControllerForElementAndIdentifier(this.leftGridTarget, "ag-grid")
    this.rightGridController = this.application.getControllerForElementAndIdentifier(this.rightGridTarget, "ag-grid")
    this.leftApi = this.leftGridController?.api
    this.rightApi = this.rightGridController?.api

    if (!this.isApiAlive(this.leftApi) || !this.isApiAlive(this.rightApi)) {
      this.bindRetryTimer = setTimeout(() => this.bindGridControllers(), 60)
      return
    }

    this.loadUsers()
  }

  changeRole() {
    const roleCd = this.currentRoleCode
    this.selectedRoleCodeTarget.value = roleCd
    this.leftSearchInputTarget.value = ""
    this.rightSearchInputTarget.value = ""
    this.leftSearchTerm = ""
    this.rightSearchTerm = ""
    this.loadUsers()
  }

  async loadUsers() {
    if (!this.isApiAlive(this.leftApi) || !this.isApiAlive(this.rightApi)) return

    const roleCd = this.currentRoleCode
    if (!roleCd) {
      this.leftAllUsers = []
      this.rightAllUsers = []
      this.renderFilteredRows()
      return
    }

    try {
      const [availableResponse, assignedResponse] = await Promise.all([
        fetch(`${this.availableUrlValue}?role_cd=${encodeURIComponent(roleCd)}`, { headers: { Accept: "application/json" } }),
        fetch(`${this.assignedUrlValue}?role_cd=${encodeURIComponent(roleCd)}`, { headers: { Accept: "application/json" } })
      ])

      if (!availableResponse.ok || !assignedResponse.ok) {
        throw new Error("load failed")
      }

      this.leftAllUsers = await availableResponse.json()
      this.rightAllUsers = await assignedResponse.json()
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
    if (!this.isApiAlive(this.leftApi)) return

    const selectedRows = this.leftApi.getSelectedRows()
    if (!selectedRows.length) return

    const selectedIds = new Set(selectedRows.map((row) => row.user_id_code))
    this.rightAllUsers = [...this.rightAllUsers, ...selectedRows]
    this.leftAllUsers = this.leftAllUsers.filter((row) => !selectedIds.has(row.user_id_code))
    this.renderFilteredRows()
  }

  moveToLeft() {
    if (!this.isApiAlive(this.rightApi)) return

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
      alert("역할을 먼저 선택하세요.")
      return
    }

    const userIds = this.rightAllUsers.map((user) => user.user_id_code).filter((id) => id)

    try {
      const response = await fetch(this.saveUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfToken
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
    if (!this.isApiAlive(this.leftApi) || !this.isApiAlive(this.rightApi)) return

    const leftRows = this.filterRows(this.leftAllUsers, this.leftSearchTerm)
    const rightRows = this.filterRows(this.rightAllUsers, this.rightSearchTerm)

    this.leftApi.setGridOption("rowData", leftRows)
    this.rightApi.setGridOption("rowData", rightRows)
  }

  filterRows(rows, term) {
    if (!term) return rows

    return rows.filter((row) => {
      const userNm = (row.user_nm || "").toLowerCase()
      const deptNm = (row.dept_nm || "").toLowerCase()
      return userNm.includes(term) || deptNm.includes(term)
    })
  }

  get currentRoleCode() {
    const select = this.element.querySelector("#q_role_cd")
    return select?.value?.toString().trim().toUpperCase() || this.selectedRoleCodeTarget.value
  }

  get csrfToken() {
    return document.querySelector("[name='csrf-token']")?.content || ""
  }

  isApiAlive(api) {
    return Boolean(api) && !(typeof api.isDestroyed === "function" && api.isDestroyed())
  }
}
