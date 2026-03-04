import BaseGridController from "controllers/base_grid_controller"
import { showAlert } from "components/ui/alert"
import {
  collectRows,
  fetchJson,
  hasChanges,
  postJson,
  refreshSelectionLabel,
  setManagerRowData
} from "controllers/grid/grid_utils"
import { switchTab, activateTab } from "controllers/ui_utils"
import {
  bindDetailFieldEvents,
  unbindDetailFieldEvents,
  fillDetailForm as fillDetailFormUtil,
  clearDetailForm as clearDetailFormUtil,
  syncDetailField as syncDetailFieldUtil,
  toDateInputValue,
  markCurrentMasterRowUpdated,
  refreshMasterRowCells
} from "controllers/grid/grid_form_utils"

const CODE_FIELDS = [
  "ord_no",
  "ord_stat_cd",
  "ord_type_cd",
  "bilg_cust_cd",
  "ctrt_cust_cd",
  "ord_reason_cd",
  "ord_exec_dept_cd",
  "ord_exec_ofcr_cd",
  "dpt_type_cd",
  "dpt_cd",
  "arv_type_cd",
  "arv_cd"
]
const DATE_FIELDS = ["strt_req_ymd"]
const DATETIME_FIELDS = ["aptd_req_dtm"]
const MAX_ITEM_ROWS = 20

export default class extends BaseGridController {
  static targets = [
    ...BaseGridController.targets,
    "masterGrid",
    "itemsGrid",
    "selectedOrderLabel",
    "detailField",
    "tabButton",
    "tabPanel"
  ]

  static values = {
    ...BaseGridController.values,
    masterBatchUrl: String,
    itemListUrlTemplate: String,
    selectedOrder: String
  }

  connect() {
    super.connect()

    this.currentMasterRow = null
    this.activeTab = "location"
    this._registerGridRetryTimer = null

    bindDetailFieldEvents(this, null, (event) => {
      syncDetailFieldUtil(event, this)
    })

    this.registerExistingGrids()
    this._registerGridRetryTimer = setTimeout(() => {
      this.registerExistingGrids()
    }, 150)

    this.activateTab("location")
    this.clearDetailForm()
    this.clearItemRows()
    this.refreshSelectedOrderLabel()
  }

  disconnect() {
    if (this._registerGridRetryTimer) {
      clearTimeout(this._registerGridRetryTimer)
      this._registerGridRetryTimer = null
    }

    unbindDetailFieldEvents(this)
    this.currentMasterRow = null

    super.disconnect()
  }

  gridRoles() {
    return {
      master: {
        target: "masterGrid",
        manager: this.masterManagerConfig(),
        masterKeyField: "ord_no"
      },
      items: {
        target: "itemsGrid",
        manager: this.itemManagerConfig(),
        parentGrid: "master",
        onMasterRowChange: (rowData) => this.handleMasterRowChange(rowData),
        detailLoader: async (rowData) => this.fetchItemRows(rowData)
      }
    }
  }

  masterManagerConfig() {
    return {
      pkFields: ["ord_no"],
      fields: {
        ord_no: "trimUpper",
        ord_stat_cd: "trimUpperDefault:WAIT",
        ctrt_no: "trim",
        ord_type_cd: "trimUpper",
        bilg_cust_cd: "trimUpper",
        ctrt_cust_cd: "trimUpper",
        ord_reason_cd: "trimUpper",
        ord_exec_dept_cd: "trimUpper",
        ord_exec_dept_nm: "trim",
        ord_exec_ofcr_cd: "trimUpper",
        ord_exec_ofcr_nm: "trim",
        remk: "trim",
        dpt_type_cd: "trimUpper",
        dpt_cd: "trimUpper",
        dpt_zip_cd: "trim",
        dpt_addr: "trim",
        strt_req_ymd: "trim",
        arv_type_cd: "trimUpper",
        arv_cd: "trimUpper",
        arv_zip_cd: "trim",
        arv_addr: "trim",
        aptd_req_dtm: "trim",
        wait_ord_internal_yn: "trimUpperDefault:N",
        cancel_yn: "trimUpperDefault:N"
      },
      defaultRow: {
        ord_no: "",
        ord_stat_cd: "WAIT",
        ctrt_no: "",
        ord_type_cd: "",
        bilg_cust_cd: "",
        ctrt_cust_cd: "",
        ord_reason_cd: "",
        ord_exec_dept_cd: "",
        ord_exec_dept_nm: "",
        ord_exec_ofcr_cd: "",
        ord_exec_ofcr_nm: "",
        remk: "",
        dpt_type_cd: "",
        dpt_cd: "",
        dpt_zip_cd: "",
        dpt_addr: "",
        strt_req_ymd: "",
        arv_type_cd: "",
        arv_cd: "",
        arv_zip_cd: "",
        arv_addr: "",
        aptd_req_dtm: "",
        wait_ord_internal_yn: "N",
        cancel_yn: "N",
        items: []
      },
      blankCheckFields: ["ctrt_no", "bilg_cust_cd", "ctrt_cust_cd"],
      comparableFields: [
        "ctrt_no",
        "ord_type_cd",
        "bilg_cust_cd",
        "ctrt_cust_cd",
        "ord_reason_cd",
        "ord_exec_dept_cd",
        "ord_exec_dept_nm",
        "ord_exec_ofcr_cd",
        "ord_exec_ofcr_nm",
        "remk",
        "dpt_type_cd",
        "dpt_cd",
        "dpt_zip_cd",
        "dpt_addr",
        "strt_req_ymd",
        "arv_type_cd",
        "arv_cd",
        "arv_zip_cd",
        "arv_addr",
        "aptd_req_dtm"
      ],
      validationRules: {
        requiredFields: ["ord_type_cd", "bilg_cust_cd", "ctrt_cust_cd", "dpt_type_cd", "dpt_cd", "arv_type_cd", "arv_cd"],
        fieldLabels: {
          ord_type_cd: "오더유형",
          bilg_cust_cd: "청구고객",
          ctrt_cust_cd: "계약고객",
          dpt_type_cd: "출발지 유형",
          dpt_cd: "출발지 코드",
          arv_type_cd: "도착지 유형",
          arv_cd: "도착지 코드"
        }
      },
      firstEditCol: "ctrt_no",
      pkLabels: { ord_no: "오더번호" },
      onCellValueChanged: (event) => this.normalizeMasterField(event)
    }
  }

  itemManagerConfig() {
    return {
      pkFields: ["seq_no"],
      fields: {
        seq_no: "number",
        item_cd: "trimUpper",
        item_nm: "trim",
        basis_unit_cd: "trimUpper",
        ord_qty: "number",
        qty_unit_cd: "trimUpper",
        ord_wgt: "number",
        wgt_unit_cd: "trimUpper",
        ord_vol: "number",
        vol_unit_cd: "trimUpper"
      },
      defaultRow: {
        seq_no: null,
        item_cd: "",
        item_nm: "",
        basis_unit_cd: "",
        ord_qty: 0,
        qty_unit_cd: "",
        ord_wgt: 0,
        wgt_unit_cd: "",
        ord_vol: 0,
        vol_unit_cd: ""
      },
      blankCheckFields: ["item_cd", "item_nm"],
      comparableFields: [
        "item_cd",
        "item_nm",
        "basis_unit_cd",
        "ord_qty",
        "qty_unit_cd",
        "ord_wgt",
        "wgt_unit_cd",
        "ord_vol",
        "vol_unit_cd"
      ],
      validationRules: {
        requiredFields: ["item_cd"],
        fieldLabels: { item_cd: "아이템코드" }
      },
      firstEditCol: "item_cd",
      onCellValueChanged: (event) => this.handleItemCellChanged(event)
    }
  }

  get masterManager() {
    return this.gridManager("master")
  }

  get manager() {
    return this.masterManager
  }

  set manager(_v) {
    // BaseGridController 단일 그리드 호환 대입 흡수
  }

  get itemManager() {
    return this.gridManager("items")
  }

  beforeSearchReset() {
    this.selectedOrderValue = ""
    this.currentMasterRow = null
    this.refreshSelectedOrderLabel()
    this.clearDetailForm()
    this.clearItemRows()
  }

  handleMasterRowChange(rowData) {
    this.syncCurrentItemsToMaster()

    this.currentMasterRow = rowData || null
    this.selectedOrderValue = rowData?.ord_no || ""
    this.refreshSelectedOrderLabel()

    if (!rowData) {
      this.clearDetailForm()
      return
    }

    this.fillDetailForm(rowData)
  }

  addMasterRow() {
    this.addRow({
      manager: this.masterManager,
      config: { startCol: "ctrt_no" },
      onAdded: (rowData) => {
        this.activateTab("location")
        this.handleMasterRowChange(rowData)
      }
    })
  }

  deleteMasterRows() {
    this.deleteRows({ manager: this.masterManager })
  }

  async saveMasterRows() {
    if (!this.masterManager) return
    if (!this.masterBatchUrlValue) {
      showAlert("저장 URL이 설정되지 않았습니다.")
      return
    }

    this.masterManager.stopEditing?.()
    this.itemManager?.stopEditing?.()
    this.syncCurrentItemsToMaster()

    const validationResult = this.masterManager.validateRows()
    if (!validationResult.valid) {
      const summary = this.masterManager.formatValidationSummary(validationResult.errors, { maxItems: 3 })
      if (validationResult.firstError) {
        this.masterManager.focusValidationError(validationResult.firstError)
      }
      showAlert("Validation", summary, "warning")
      return
    }

    const operations = this.buildMasterOperations()
    if (!hasChanges(operations)) {
      showAlert("변경된 데이터가 없습니다.")
      return
    }

    const result = await postJson(this.masterBatchUrlValue, operations)
    if (!result) return

    showAlert(result.message || "내부오더 데이터가 저장되었습니다.")
    this.refreshGrid("master")
  }

  addItemRow() {
    if (!this.itemManager?.api) return
    if (!this.currentMasterRow) {
      showAlert("내부오더를 먼저 선택하세요.")
      return
    }

    const rows = this.collectItemRowsFromGrid()
    if (rows.length >= MAX_ITEM_ROWS) {
      showAlert("아이템은 최대 20건까지 등록 가능합니다.")
      return
    }

    const nextSeq = this.nextItemSeq(rows)
    this.itemManager.api.applyTransaction({
      add: [{
        seq_no: nextSeq,
        item_cd: "",
        item_nm: "",
        basis_unit_cd: "",
        ord_qty: 0,
        qty_unit_cd: "",
        ord_wgt: 0,
        wgt_unit_cd: "",
        ord_vol: 0,
        vol_unit_cd: ""
      }]
    })

    const rowIndex = this.itemManager.api.getDisplayedRowCount() - 1
    if (rowIndex >= 0) {
      this.itemManager.api.startEditingCell({ rowIndex, colKey: "item_cd" })
    }

    this.syncCurrentItemsToMaster()
    this.markCurrentMasterAsUpdated()
  }

  deleteItemRows() {
    if (!this.itemManager?.api) return

    const selected = this.itemManager.api.getSelectedRows()
    if (selected.length === 0) {
      showAlert("삭제할 아이템 행을 선택하세요.")
      return
    }

    this.itemManager.api.applyTransaction({ remove: selected })
    this.renumberItems()
    this.syncCurrentItemsToMaster()
    this.markCurrentMasterAsUpdated()
  }

  preventDetailSubmit(event) {
    event.preventDefault()
  }

  switchTab(event) {
    switchTab(event, this)
    this.resizeItemsGridWhenVisible()
  }

  activateTab(tab) {
    activateTab(tab, this)
    this.resizeItemsGridWhenVisible()
  }

  fillDetailForm(rowData) {
    fillDetailFormUtil(this, rowData)
  }

  clearDetailForm() {
    clearDetailFormUtil(this)
  }

  clearItemRows() {
    setManagerRowData(this.itemManager, [])
  }

  refreshSelectedOrderLabel() {
    if (!this.hasSelectedOrderLabelTarget) return

    refreshSelectionLabel(this.selectedOrderLabelTarget, this.selectedOrderValue, "내부오더", "내부오더를 먼저 선택하세요.")
  }

  normalizeValueForInput(fieldName, rawValue) {
    if (rawValue == null) return ""

    if (DATE_FIELDS.includes(fieldName)) {
      return toDateInputValue(rawValue)
    }

    if (DATETIME_FIELDS.includes(fieldName)) {
      return this.formatDateTimeForInput(rawValue)
    }

    return rawValue.toString()
  }

  normalizeDetailFieldValue(fieldName, rawValue) {
    const value = (rawValue || "").toString()

    if (CODE_FIELDS.includes(fieldName)) {
      return value.trim().toUpperCase()
    }

    if (DATE_FIELDS.includes(fieldName)) {
      return this.normalizeDateStoreValue(value)
    }

    if (DATETIME_FIELDS.includes(fieldName)) {
      return this.normalizeDateTimeStoreValue(value)
    }

    if (fieldName === "remk") {
      return value
    }

    return value.trim()
  }

  async fetchItemRows(rowData) {
    if (!rowData || rowData.__is_deleted) return []

    if (Array.isArray(rowData.items)) {
      return rowData.items.map((row) => ({ ...row }))
    }

    const ordNo = (rowData.ord_no || "").toString().trim()
    if (ordNo === "" || rowData.__is_new) {
      return []
    }

    try {
      const url = this.itemListUrlTemplateValue.replace(":id", encodeURIComponent(ordNo))
      const rows = await fetchJson(url)
      const normalized = Array.isArray(rows) ? rows : []
      rowData.items = normalized.map((row) => ({ ...row }))
      return normalized
    } catch {
      showAlert("아이템 목록 조회에 실패했습니다.")
      return []
    }
  }

  handleItemCellChanged(event) {
    const field = event?.colDef?.field
    const row = event?.node?.data
    if (!field || !row) return

    if (field === "item_cd" || field.endsWith("_cd")) {
      row[field] = (row[field] || "").toString().trim().toUpperCase()
    }

    if (field === "item_nm") {
      row[field] = (row[field] || "").toString().trim()
    }

    this.syncCurrentItemsToMaster()
    this.markCurrentMasterAsUpdated()

    this.itemManager.api?.refreshCells({
      rowNodes: [event.node],
      columns: [field],
      force: true
    })
  }

  normalizeMasterField(event) {
    const field = event?.colDef?.field
    if (!field || !event?.node?.data) return

    const row = event.node.data
    if (CODE_FIELDS.includes(field)) {
      row[field] = (row[field] || "").toString().trim().toUpperCase()
    } else if (DATE_FIELDS.includes(field)) {
      row[field] = this.normalizeDateStoreValue(row[field])
    } else if (DATETIME_FIELDS.includes(field)) {
      row[field] = this.normalizeDateTimeStoreValue(row[field])
    }

    const api = this.masterManager?.api
    if (!api) return

    api.refreshCells({
      rowNodes: [event.node],
      columns: [field],
      force: true
    })
  }

  buildMasterOperations() {
    const api = this.masterManager?.api
    if (!api) {
      return { rowsToInsert: [], rowsToUpdate: [], rowsToDelete: [] }
    }

    const rowsToInsert = []
    const rowsToUpdate = []
    const rowsToDelete = []
    const rows = collectRows(api)

    rows.forEach((row) => {
      if (row.__is_deleted) {
        if (!row.__is_new && row.ord_no) {
          rowsToDelete.push(row.ord_no.toString().trim().toUpperCase())
        }
        return
      }

      if (row.__is_new) {
        if (this.isBlankMasterRow(row)) return
        rowsToInsert.push(this.serializeMasterRow(row))
        return
      }

      if (row.__is_updated) {
        rowsToUpdate.push(this.serializeMasterRow(row))
      }
    })

    return {
      rowsToInsert,
      rowsToUpdate,
      rowsToDelete: [...new Set(rowsToDelete)]
    }
  }

  serializeMasterRow(row) {
    const items = Array.isArray(row.items) ? row.items : []

    return {
      ord_no: (row.ord_no || "").toString().trim().toUpperCase(),
      ord_stat_cd: (row.ord_stat_cd || "WAIT").toString().trim().toUpperCase(),
      ctrt_no: (row.ctrt_no || "").toString().trim(),
      ord_type_cd: (row.ord_type_cd || "").toString().trim().toUpperCase(),
      bilg_cust_cd: (row.bilg_cust_cd || "").toString().trim().toUpperCase(),
      ctrt_cust_cd: (row.ctrt_cust_cd || "").toString().trim().toUpperCase(),
      ord_reason_cd: (row.ord_reason_cd || "").toString().trim().toUpperCase(),
      ord_exec_dept_cd: (row.ord_exec_dept_cd || "").toString().trim().toUpperCase(),
      ord_exec_dept_nm: (row.ord_exec_dept_nm || "").toString().trim(),
      ord_exec_ofcr_cd: (row.ord_exec_ofcr_cd || "").toString().trim().toUpperCase(),
      ord_exec_ofcr_nm: (row.ord_exec_ofcr_nm || "").toString().trim(),
      remk: (row.remk || "").toString(),
      dpt_type_cd: (row.dpt_type_cd || "").toString().trim().toUpperCase(),
      dpt_cd: (row.dpt_cd || "").toString().trim().toUpperCase(),
      dpt_zip_cd: (row.dpt_zip_cd || "").toString().trim(),
      dpt_addr: (row.dpt_addr || "").toString().trim(),
      strt_req_ymd: this.normalizeDateStoreValue(row.strt_req_ymd),
      arv_type_cd: (row.arv_type_cd || "").toString().trim().toUpperCase(),
      arv_cd: (row.arv_cd || "").toString().trim().toUpperCase(),
      arv_zip_cd: (row.arv_zip_cd || "").toString().trim(),
      arv_addr: (row.arv_addr || "").toString().trim(),
      aptd_req_dtm: this.normalizeDateTimeStoreValue(row.aptd_req_dtm),
      wait_ord_internal_yn: "N",
      cancel_yn: (row.cancel_yn || "N").toString().trim().toUpperCase() || "N",
      items: items.slice(0, MAX_ITEM_ROWS).map((item, index) => this.normalizeItemRow(item, index + 1))
    }
  }

  normalizeItemRow(item, seqNo) {
    const safeItem = item || {}
    return {
      seq_no: Number(safeItem.seq_no) > 0 ? Number(safeItem.seq_no) : seqNo,
      item_cd: (safeItem.item_cd || "").toString().trim().toUpperCase(),
      item_nm: (safeItem.item_nm || "").toString().trim(),
      basis_unit_cd: (safeItem.basis_unit_cd || "").toString().trim().toUpperCase(),
      ord_qty: this.numberOrZero(safeItem.ord_qty),
      qty_unit_cd: (safeItem.qty_unit_cd || "").toString().trim().toUpperCase(),
      ord_wgt: this.numberOrZero(safeItem.ord_wgt),
      wgt_unit_cd: (safeItem.wgt_unit_cd || "").toString().trim().toUpperCase(),
      ord_vol: this.numberOrZero(safeItem.ord_vol),
      vol_unit_cd: (safeItem.vol_unit_cd || "").toString().trim().toUpperCase()
    }
  }

  numberOrZero(value) {
    const number = Number(value)
    if (Number.isNaN(number)) return 0
    return number
  }

  isBlankMasterRow(row) {
    const keys = ["ctrt_no", "ord_type_cd", "bilg_cust_cd", "ctrt_cust_cd", "dpt_cd", "arv_cd"]
    return keys.every((key) => (row[key] || "").toString().trim() === "")
  }

  isBlankItemRow(row) {
    const itemCd = (row.item_cd || "").toString().trim()
    const itemNm = (row.item_nm || "").toString().trim()
    return itemCd === "" && itemNm === ""
  }

  syncCurrentItemsToMaster() {
    if (!this.currentMasterRow) return

    this.currentMasterRow.items = this.collectItemRowsFromGrid()
  }

  collectItemRowsFromGrid() {
    const api = this.itemManager?.api
    if (!api) return []

    const rows = []
    api.forEachNode((node) => {
      if (!node?.data || node.data.__is_deleted) return
      if (this.isBlankItemRow(node.data)) return
      rows.push(this.normalizeItemRow(node.data, rows.length + 1))
    })
    return rows
  }

  nextItemSeq(rows) {
    if (!Array.isArray(rows) || rows.length === 0) return 1
    return rows.reduce((max, row) => Math.max(max, Number(row.seq_no) || 0), 0) + 1
  }

  renumberItems() {
    const api = this.itemManager?.api
    if (!api) return

    let seq = 1
    api.forEachNode((node) => {
      if (!node?.data || node.data.__is_deleted) return
      node.setDataValue("seq_no", seq)
      seq += 1
    })
  }

  markCurrentMasterAsUpdated() {
    markCurrentMasterRowUpdated(this)
    refreshMasterRowCells(this, ["__row_status"])
  }

  resizeItemsGridWhenVisible() {
    if (this.activeTab !== "items") return
    const api = this.itemManager?.api
    if (!api) return

    setTimeout(() => {
      api.sizeColumnsToFit?.()
    }, 50)
  }

  formatDateTimeForInput(rawValue) {
    const value = (rawValue || "").toString().trim()
    if (value === "") return ""

    const compact = value.replace(/[^0-9]/g, "")
    if (compact.length >= 12) {
      const yyyy = compact.slice(0, 4)
      const mm = compact.slice(4, 6)
      const dd = compact.slice(6, 8)
      const hh = compact.slice(8, 10)
      const mi = compact.slice(10, 12)
      return `${yyyy}-${mm}-${dd}T${hh}:${mi}`
    }

    return value
  }

  normalizeDateStoreValue(rawValue) {
    const normalized = toDateInputValue(rawValue)
    if (normalized === "") return ""
    return normalized.replace(/-/g, "")
  }

  normalizeDateTimeStoreValue(rawValue) {
    const source = (rawValue || "").toString().trim()
    if (source === "") return ""

    const compact = source.replace(/[^0-9]/g, "")
    if (compact.length >= 14) {
      return compact.slice(0, 14)
    }
    if (compact.length >= 12) {
      return `${compact.slice(0, 12)}00`
    }
    return compact
  }

  registerExistingGrids() {
    const gridElements = this.element.querySelectorAll("[data-controller='ag-grid']")
    gridElements.forEach((gridElement) => {
      const gridController = this.application.getControllerForElementAndIdentifier(gridElement, "ag-grid")
      const api = gridController?.api || gridController?.gridApi || gridController?.gridOptions?.api
      if (!api) return

      this.registerGrid({
        target: gridElement,
        detail: { api, controller: gridController }
      })
    })
  }
}

