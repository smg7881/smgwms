import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["grid"]

  static values = {
    batchUrl: String
  }

  connect() {
    this.deletedWorkplaceCodes = []
    this.gridApi = null
    this.gridController = null
  }

  registerGrid(event) {
    const { api, controller } = event.detail
    this.gridController = controller
    this.gridApi = api
    this.gridApi.addEventListener("cellValueChanged", this.handleCellValueChanged)
    this.gridApi.addEventListener("rowDataUpdated", this.handleRowDataUpdated)
  }

  disconnect() {
    if (this.isApiAlive(this.gridApi)) {
      this.gridApi.removeEventListener("cellValueChanged", this.handleCellValueChanged)
      this.gridApi.removeEventListener("rowDataUpdated", this.handleRowDataUpdated)
    }
    this.gridApi = null
    this.gridController = null
    this.originalMap = null
  }

  addRow() {
    if (!this.isApiAlive(this.gridApi)) return

    const newRow = {
      workpl_cd: "",
      workpl_nm: "",
      workpl_type: "",
      nation_cd: "",
      zip_cd: "",
      addr: "",
      addr_dtl: "",
      tel_no: "",
      use_yn: "Y",
      __is_new: true,
      __temp_id: this.uuid()
    }

    this.gridApi.applyTransaction({
      add: [newRow],
      addIndex: 0
    })
    this.hideNoRowsOverlay()
    this.gridApi.startEditingCell({ rowIndex: 0, colKey: "workpl_cd" })
  }

  deleteRows() {
    if (!this.isApiAlive(this.gridApi)) return

    const selectedNodes = this.gridApi.getSelectedNodes()
    if (!selectedNodes.length) {
      alert("삭제할 행을 선택하세요.")
      return
    }

    const rowsToRemove = []
    const nodesToRefresh = []

    selectedNodes.forEach((node) => {
      const row = node.data
      if (!row) return

      if (row.__is_new) {
        rowsToRemove.push(row)
        return
      }

      if (row.workpl_cd) this.deletedWorkplaceCodes.push(row.workpl_cd)
      row.__is_deleted = true
      delete row.__is_updated
      nodesToRefresh.push(node)
    })

    if (rowsToRemove.length > 0) {
      this.gridApi.applyTransaction({ remove: rowsToRemove })
    }
    if (nodesToRefresh.length > 0) {
      this.refreshStatusCells(nodesToRefresh)
    }
  }

  async saveRows() {
    if (!this.isApiAlive(this.gridApi)) return

    this.gridApi.stopEditing()
    const operations = this.buildOperations()
    if (!this.hasChanges(operations)) {
      alert("변경된 데이터가 없습니다.")
      return
    }

    const ok = await this.postJson(this.batchUrlValue, operations)
    if (!ok) return

    alert("작업장 데이터가 저장되었습니다.")
    this.reloadRows()
  }

  reloadRows() {
    if (this.gridController?.refresh) {
      this.gridController.refresh()
    }
  }

  resetGridState() {
    if (!this.isApiAlive(this.gridApi)) return
    this.gridApi.resetColumnState()
  }

  buildOperations() {
    const rows = this.collectRows()

    const rowsToInsert = rows
      .filter((row) => row.__is_new && !row.__is_deleted && !this.isBlankRow(row))
      .map((row) => this.pickFields(row))

    const rowsToUpdate = rows
      .filter((row) => !row.__is_new && !row.__is_deleted && this.rowChanged(row))
      .map((row) => this.pickFields(row))

    const rowsToDelete = [
      ...this.deletedWorkplaceCodes,
      ...rows.filter((row) => row.__is_deleted && row.workpl_cd).map((row) => row.workpl_cd)
    ]

    return {
      rowsToInsert,
      rowsToUpdate,
      rowsToDelete: [...new Set(rowsToDelete)]
    }
  }

  pickFields(row) {
    return {
      workpl_cd: (row.workpl_cd || "").trim().toUpperCase(),
      workpl_nm: (row.workpl_nm || "").trim(),
      workpl_type: (row.workpl_type || "").trim().toUpperCase(),
      nation_cd: (row.nation_cd || "").trim().toUpperCase(),
      zip_cd: (row.zip_cd || "").trim(),
      addr: (row.addr || "").trim(),
      addr_dtl: (row.addr_dtl || "").trim(),
      tel_no: (row.tel_no || "").trim(),
      use_yn: (row.use_yn || "Y").trim().toUpperCase()
    }
  }

  collectRows() {
    if (!this.isApiAlive(this.gridApi)) return []

    const rows = []
    this.gridApi.forEachNode((node) => {
      if (node.data) rows.push(node.data)
    })
    return rows
  }

  rowChanged(row) {
    const original = this.originalMap.get(row.workpl_cd)
    if (!original) return true

    return (
      (row.workpl_nm || "") !== (original.workpl_nm || "") ||
      (row.workpl_type || "") !== (original.workpl_type || "") ||
      (row.nation_cd || "") !== (original.nation_cd || "") ||
      (row.zip_cd || "") !== (original.zip_cd || "") ||
      (row.addr || "") !== (original.addr || "") ||
      (row.addr_dtl || "") !== (original.addr_dtl || "") ||
      (row.tel_no || "") !== (original.tel_no || "") ||
      (row.use_yn || "") !== (original.use_yn || "")
    )
  }

  resetTracking() {
    this.deletedWorkplaceCodes = []
    this.originalMap = new Map()

    this.collectRows().forEach((row) => {
      if (row.workpl_cd) this.originalMap.set(row.workpl_cd, { ...row })
      delete row.__is_new
      delete row.__is_updated
      delete row.__is_deleted
      delete row.__temp_id
    })
  }

  handleRowDataUpdated = () => {
    this.resetTracking()
  }

  handleCellValueChanged = (event) => {
    if (this.preventInvalidWorkplaceCodeEdit(event)) return
    this.markRowUpdated(event)
  }

  preventInvalidWorkplaceCodeEdit(event) {
    if (event?.colDef?.field !== "workpl_cd") return false
    if (!event?.node?.data) return false

    const row = event.node.data
    if (row.__is_new) return false

    row.workpl_cd = event.oldValue || ""
    this.gridApi.refreshCells({
      rowNodes: [event.node],
      columns: ["workpl_cd"],
      force: true
    })
    alert("기존 작업장코드는 수정할 수 없습니다.")
    return true
  }

  markRowUpdated(event) {
    if (!event?.node?.data) return
    if (event.colDef?.field === "__row_status") return
    if (event.newValue === event.oldValue) return

    const row = event.node.data
    if (row.__is_new || row.__is_deleted) return

    row.__is_updated = true
    this.refreshStatusCells([event.node])
  }

  refreshStatusCells(rowNodes) {
    this.gridApi.refreshCells({
      rowNodes,
      columns: ["__row_status"],
      force: true
    })
  }

  hasChanges(operations) {
    return (
      operations.rowsToInsert.length > 0 ||
      operations.rowsToUpdate.length > 0 ||
      operations.rowsToDelete.length > 0
    )
  }

  isBlankRow(row) {
    return (row.workpl_cd || "").trim() === "" && (row.workpl_nm || "").trim() === ""
  }

  hideNoRowsOverlay() {
    if (!this.isApiAlive(this.gridApi)) return

    const rowCount = this.gridApi.getDisplayedRowCount?.() || 0
    if (rowCount > 0) {
      this.gridApi.hideOverlay?.()
    }
  }

  async postJson(url, body) {
    try {
      const response = await fetch(url, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfToken
        },
        body: JSON.stringify(body)
      })

      const result = await response.json()
      if (!response.ok || !result.success) {
        alert("저장 실패: " + (result.errors || ["요청 처리 실패"]).join(", "))
        return false
      }

      return true
    } catch {
      alert("저장 실패: 네트워크 오류")
      return false
    }
  }

  get csrfToken() {
    return document.querySelector("[name='csrf-token']")?.content || ""
  }

  uuid() {
    return `${Date.now()}_${Math.random().toString(36).slice(2, 8)}`
  }

  isApiAlive(api) {
    return Boolean(api) && !(typeof api.isDestroyed === "function" && api.isDestroyed())
  }
}
