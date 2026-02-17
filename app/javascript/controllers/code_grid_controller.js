import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["masterGrid", "detailGrid", "selectedCodeLabel"]

  static values = {
    masterBatchUrl: String,
    detailBatchUrlTemplate: String,
    detailListUrlTemplate: String,
    selectedCode: String
  }

  connect() {
    this.masterDeletedCodes = []
    this.detailDeletedCodes = []
    this.initialMasterSyncDone = false

    this.bindGridControllers()
  }

  bindGridControllers() {
    this.masterGridController = this.application.getControllerForElementAndIdentifier(this.masterGridTarget, "ag-grid")
    this.detailGridController = this.application.getControllerForElementAndIdentifier(this.detailGridTarget, "ag-grid")

    if (!this.masterGridController || !this.detailGridController) {
      setTimeout(() => this.bindGridControllers(), 60)
      return
    }

    this.masterApi = this.masterGridController.api
    this.detailApi = this.detailGridController.api

    if (!this.masterApi || !this.detailApi) {
      setTimeout(() => this.bindGridControllers(), 60)
      return
    }

    this.masterApi.addEventListener("rowClicked", this.handleMasterRowClicked)
    this.masterApi.addEventListener("cellFocused", this.handleMasterCellFocused)
    this.masterApi.addEventListener("cellValueChanged", this.handleMasterCellValueChanged)
    this.detailApi.addEventListener("cellValueChanged", this.handleDetailCellValueChanged)

    setTimeout(() => {
      this.resetMasterTracking()
      this.resetDetailTracking()
      this.syncInitialMasterSelection()
    }, 120)
  }

  disconnect() {
    if (this.masterApi) {
      this.masterApi.removeEventListener("rowClicked", this.handleMasterRowClicked)
      this.masterApi.removeEventListener("cellFocused", this.handleMasterCellFocused)
      this.masterApi.removeEventListener("cellValueChanged", this.handleMasterCellValueChanged)
    }
    if (this.detailApi) {
      this.detailApi.removeEventListener("cellValueChanged", this.handleDetailCellValueChanged)
    }
  }

  handleMasterRowClicked = async (event) => {
    await this.handleMasterRowChange(event.data)
  }

  handleMasterCellFocused = async (event) => {
    if (event.rowIndex == null || event.rowIndex < 0) return

    const rowNode = this.masterApi.getDisplayedRowAtIndex(event.rowIndex)
    if (!rowNode?.data) return

    await this.handleMasterRowChange(rowNode.data)
  }

  async handleMasterRowChange(rowData) {
    const code = rowData?.code
    if (!code || rowData?.__is_deleted) {
      this.selectedCodeValue = ""
      this.refreshSelectedCodeLabel()
      this.detailApi.setGridOption("rowData", [])
      this.resetDetailTracking()
      return
    }

    if (rowData?.__is_new) {
      this.selectedCodeValue = code
      this.refreshSelectedCodeLabel()
      this.detailApi.setGridOption("rowData", [])
      this.resetDetailTracking()
      return
    }

    this.selectedCodeValue = code
    this.refreshSelectedCodeLabel()
    await this.loadDetailRows(code)
  }

  addMasterRow() {
    const newRow = {
      code: "",
      code_name: "",
      use_yn: "Y",
      __is_new: true,
      __temp_id: this.uuid()
    }

    const txResult = this.masterApi.applyTransaction({
      add: [
        newRow
      ],
      addIndex: 0
    })

    const addedNode = txResult?.add?.[0]
    if (addedNode?.data) {
      this.handleMasterRowChange(addedNode.data)
    }

    this.masterApi.startEditingCell({ rowIndex: 0, colKey: "code" })
  }

  deleteMasterRows() {
    const selectedNodes = this.masterApi.getSelectedNodes()
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

      if (row.code) this.masterDeletedCodes.push(row.code)
      row.__is_deleted = true
      delete row.__is_updated
      nodesToRefresh.push(node)
    })

    if (rowsToRemove.length > 0) {
      this.masterApi.applyTransaction({ remove: rowsToRemove })
    }
    if (nodesToRefresh.length > 0) {
      this.refreshStatusCells(this.masterApi, nodesToRefresh)
    }
  }

  async saveMasterRows() {
    const operations = this.buildMasterOperations()
    if (!this.hasChanges(operations)) {
      alert("변경된 데이터가 없습니다.")
      return
    }

    const ok = await this.postJson(this.masterBatchUrlValue, operations)
    if (!ok) return

    alert("코드 저장이 완료되었습니다.")
    await this.reloadMasterRows()
  }

  addDetailRow() {
    if (!this.selectedCodeValue) {
      alert("코드를 먼저 선택하세요.")
      return
    }

    this.detailApi.applyTransaction({
      add: [
        {
          code: this.selectedCodeValue,
          detail_code: "",
          detail_code_name: "",
          short_name: "",
          ref_code: "",
          sort_order: 0,
          use_yn: "Y",
          __is_new: true,
          __temp_id: this.uuid()
        }
      ],
      addIndex: 0
    })

    this.detailApi.startEditingCell({ rowIndex: 0, colKey: "detail_code" })
  }

  deleteDetailRows() {
    const selectedNodes = this.detailApi.getSelectedNodes()
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

      if (row.detail_code) this.detailDeletedCodes.push(row.detail_code)
      row.__is_deleted = true
      delete row.__is_updated
      nodesToRefresh.push(node)
    })

    if (rowsToRemove.length > 0) {
      this.detailApi.applyTransaction({ remove: rowsToRemove })
    }
    if (nodesToRefresh.length > 0) {
      this.refreshStatusCells(this.detailApi, nodesToRefresh)
    }
  }

  async saveDetailRows() {
    if (!this.selectedCodeValue) {
      alert("코드를 먼저 선택하세요.")
      return
    }

    const operations = this.buildDetailOperations()
    if (!this.hasChanges(operations)) {
      alert("변경된 데이터가 없습니다.")
      return
    }

    const batchUrl = this.detailBatchUrlTemplateValue.replace(":code", encodeURIComponent(this.selectedCodeValue))
    const ok = await this.postJson(batchUrl, operations)
    if (!ok) return

    alert("상세코드 저장이 완료되었습니다.")
    await this.loadDetailRows(this.selectedCodeValue)
  }

  buildMasterOperations() {
    const rows = this.collectRows(this.masterApi)

    const rowsToInsert = rows
      .filter((row) => row.__is_new && !row.__is_deleted)
      .map((row) => this.pickMasterFields(row))

    const rowsToUpdate = rows
      .filter((row) => !row.__is_new && !row.__is_deleted && this.masterRowChanged(row))
      .map((row) => this.pickMasterFields(row))

    const rowsToDelete = [
      ...this.masterDeletedCodes,
      ...rows.filter((row) => row.__is_deleted && row.code).map((row) => row.code)
    ]

    return {
      rowsToInsert,
      rowsToUpdate,
      rowsToDelete: [...new Set(rowsToDelete)]
    }
  }

  buildDetailOperations() {
    const rows = this.collectRows(this.detailApi)

    const rowsToInsert = rows
      .filter((row) => row.__is_new && !row.__is_deleted)
      .map((row) => this.pickDetailFields(row))

    const rowsToUpdate = rows
      .filter((row) => !row.__is_new && !row.__is_deleted && this.detailRowChanged(row))
      .map((row) => this.pickDetailFields(row))

    const rowsToDelete = [
      ...this.detailDeletedCodes,
      ...rows.filter((row) => row.__is_deleted && row.detail_code).map((row) => row.detail_code)
    ]

    return {
      rowsToInsert,
      rowsToUpdate,
      rowsToDelete: [...new Set(rowsToDelete)]
    }
  }

  pickMasterFields(row) {
    return {
      code: (row.code || "").trim(),
      code_name: (row.code_name || "").trim(),
      use_yn: (row.use_yn || "Y").trim().toUpperCase()
    }
  }

  pickDetailFields(row) {
    return {
      detail_code: (row.detail_code || "").trim(),
      detail_code_name: (row.detail_code_name || "").trim(),
      short_name: (row.short_name || "").trim(),
      ref_code: (row.ref_code || "").trim(),
      sort_order: Number(row.sort_order || 0),
      use_yn: (row.use_yn || "Y").trim().toUpperCase()
    }
  }

  masterRowChanged(row) {
    const original = this.masterOriginalMap.get(row.code)
    if (!original) return true

    return (
      (row.code_name || "") !== (original.code_name || "") ||
      (row.use_yn || "") !== (original.use_yn || "")
    )
  }

  detailRowChanged(row) {
    const original = this.detailOriginalMap.get(row.detail_code)
    if (!original) return true

    return (
      (row.detail_code_name || "") !== (original.detail_code_name || "") ||
      (row.short_name || "") !== (original.short_name || "") ||
      (row.ref_code || "") !== (original.ref_code || "") ||
      Number(row.sort_order || 0) !== Number(original.sort_order || 0) ||
      (row.use_yn || "") !== (original.use_yn || "")
    )
  }

  collectRows(api) {
    const rows = []
    api.forEachNode((node) => {
      if (node.data) rows.push(node.data)
    })
    return rows
  }

  async reloadMasterRows() {
    const response = await fetch(this.masterGridController.urlValue, { headers: { Accept: "application/json" } })
    const data = await response.json()
    this.masterApi.setGridOption("rowData", data)
    this.resetMasterTracking()
    await this.syncMasterSelectionAfterLoad()
  }

  syncInitialMasterSelection(retryCount = 40) {
    if (this.initialMasterSyncDone) return

    const firstRowNode = this.masterApi.getDisplayedRowAtIndex(0)
    if (firstRowNode?.data) {
      this.initialMasterSyncDone = true
      this.syncMasterSelectionAfterLoad()
      return
    }

    if (retryCount <= 0) {
      this.initialMasterSyncDone = true
      this.syncMasterSelectionAfterLoad()
      return
    }

    setTimeout(() => this.syncInitialMasterSelection(retryCount - 1), 100)
  }

  async syncMasterSelectionAfterLoad() {
    const firstRowNode = this.masterApi.getDisplayedRowAtIndex(0)

    if (!firstRowNode?.data) {
      this.selectedCodeValue = ""
      this.refreshSelectedCodeLabel()
      this.detailApi.setGridOption("rowData", [])
      this.resetDetailTracking()
      return
    }

    const firstCol = this.masterApi.getAllDisplayedColumns()?.[0]
    if (firstCol) {
      this.masterApi.setFocusedCell(0, firstCol.getColId())
    }

    await this.handleMasterRowChange(firstRowNode.data)
  }

  async loadDetailRows(code) {
    if (!code) {
      this.detailApi.setGridOption("rowData", [])
      this.resetDetailTracking()
      return
    }

    const url = this.detailListUrlTemplateValue.replace(":code", encodeURIComponent(code))
    const response = await fetch(url, { headers: { Accept: "application/json" } })
    if (!response.ok) {
      alert("상세코드 조회에 실패했습니다.")
      return
    }

    const data = await response.json()
    this.detailApi.setGridOption("rowData", data)
    this.resetDetailTracking()
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

  resetMasterTracking() {
    this.masterDeletedCodes = []
    this.masterOriginalMap = new Map()
    this.collectRows(this.masterApi).forEach((row) => {
      if (row.code) this.masterOriginalMap.set(row.code, { ...row })
      delete row.__is_new
      delete row.__is_updated
      delete row.__is_deleted
      delete row.__temp_id
    })
  }

  resetDetailTracking() {
    this.detailDeletedCodes = []
    this.detailOriginalMap = new Map()
    this.collectRows(this.detailApi).forEach((row) => {
      if (row.detail_code) this.detailOriginalMap.set(row.detail_code, { ...row })
      delete row.__is_new
      delete row.__is_updated
      delete row.__is_deleted
      delete row.__temp_id
    })
  }

  handleMasterCellValueChanged = (event) => {
    this.markRowUpdated(this.masterApi, event)
  }

  handleDetailCellValueChanged = (event) => {
    this.markRowUpdated(this.detailApi, event)
  }

  markRowUpdated(api, event) {
    if (!event?.node?.data) return
    if (event.colDef?.field === "__row_status") return
    if (event.newValue === event.oldValue) return

    const row = event.node.data
    if (row.__is_new || row.__is_deleted) return

    row.__is_updated = true
    this.refreshStatusCells(api, [event.node])
  }

  refreshStatusCells(api, rowNodes) {
    api.refreshCells({
      rowNodes,
      columns: ["__row_status"],
      force: true
    })
  }

  refreshSelectedCodeLabel() {
    if (!this.hasSelectedCodeLabelTarget) return

    if (this.selectedCodeValue) {
      this.selectedCodeLabelTarget.textContent = `선택 코드: ${this.selectedCodeValue}`
    } else {
      this.selectedCodeLabelTarget.textContent = "코드를 먼저 선택하세요."
    }
  }

  hasChanges(operations) {
    return (
      operations.rowsToInsert.length > 0 ||
      operations.rowsToUpdate.length > 0 ||
      operations.rowsToDelete.length > 0
    )
  }

  get csrfToken() {
    return document.querySelector("[name='csrf-token']")?.content || ""
  }

  uuid() {
    return `${Date.now()}_${Math.random().toString(36).slice(2, 8)}`
  }
}
