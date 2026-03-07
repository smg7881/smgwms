import BaseGridController from "controllers/base_grid_controller"
import { showAlert } from "components/ui/alert"
import { postJson } from "controllers/grid/grid_utils"
import { hasChanges } from "controllers/grid/grid_state_utils"

const YES_NO_VALUES = ["Y", "N"]

export default class extends BaseGridController {
  static targets = [...BaseGridController.targets, "masterGrid", "detailGrid", "selectedMasterLabel"]

  static values = {
    ...BaseGridController.values,
    masterBatchUrl: String,
    detailListUrlTemplate: String,
    selectedMaster: String
  }

  connect() {
    super.connect()
    this.currentMasterRef = this.selectedMasterValue || ""
    this.selectedMasterTempId = ""
    this.refreshSelectedLabel()
  }

  masterConfig() {
    return {
      role: "master",
      pendingEntityLabel: "매입요율",
      key: {
        field: "wrhs_exca_fee_rt_no",
        stateProperty: "selectedMasterValue",
        labelTarget: "selectedMasterLabel",
        entityLabel: "정산요율",
        emptyMessage: "요율을 먼저 선택하세요."
      },
      onRowChange: {
        trackCurrentRow: false,
        syncForm: false
      },
      beforeSearch: {
        clearValidation: false,
        clearForm: false
      }
    }
  }

  detailGrids() {
    return [{
      role: "detail",
      methodBaseName: "detail",
      masterKeyField: "wrhs_exca_fee_rt_no",
      placeholder: ":pur_fee_rt_mng_id",
      listUrlTemplate: "detailListUrlTemplateValue",
      entityLabel: "매입요율",
      selectionMessage: "매입요율을 먼저 선택하세요.",
      fetchErrorMessage: "요율상세 조회에 실패했습니다."
    }]
  }

  gridRoles() {
    return {
      master: {
        target: "masterGrid",
        manager: this.masterManagerConfig(),
        isMaster: true
      },
      detail: {
        target: "detailGrid",
        manager: this.detailManagerConfig(),
        parentGrid: "master",
        onMasterRowChange: (rowData) => this.handleMasterRowChange(rowData),
        detailLoader: (rowData) => this.loadDetailRows("detail", rowData)
      }
    }
  }

  onAllGridsReady() {
    this.refreshSelectedLabel()
  }

  masterManagerConfig() {
    return {
      pkFields: ["wrhs_exca_fee_rt_no"],
      fields: {
        client_temp_id: "trim",
        work_pl_cd: "trimUpper",
        ctrt_cprtco_cd: "trimUpper",
        sell_buy_attr_cd: "trimUpper",
        pur_dept_cd: "trimUpper",
        pur_item_type: "trimUpper",
        pur_item_cd: "trimUpper",
        pur_unit_clas_cd: "trimUpper",
        pur_unit_cd: "trimUpper",
        use_yn: "trimUpperDefault:Y",
        auto_yn: "trimUpperDefault:N",
        rmk: "trim"
      },
      defaultRow: {
        wrhs_exca_fee_rt_no: "",
        client_temp_id: "",
        work_pl_cd: "",
        ctrt_cprtco_cd: "",
        sell_buy_attr_cd: "",
        pur_dept_cd: "",
        pur_item_type: "",
        pur_item_cd: "",
        pur_unit_clas_cd: "",
        pur_unit_cd: "",
        use_yn: "Y",
        auto_yn: "N",
        rmk: ""
      },
      blankCheckFields: ["work_pl_cd", "ctrt_cprtco_cd", "sell_buy_attr_cd"],
      comparableFields: [
        "work_pl_cd",
        "ctrt_cprtco_cd",
        "sell_buy_attr_cd",
        "pur_dept_cd",
        "pur_item_type",
        "pur_item_cd",
        "pur_unit_clas_cd",
        "pur_unit_cd",
        "use_yn",
        "auto_yn",
        "rmk"
      ],
      validationRules: {
        requiredFields: [
          "work_pl_cd",
          "ctrt_cprtco_cd",
          "sell_buy_attr_cd",
          "pur_dept_cd",
          "pur_item_type",
          "pur_item_cd",
          "pur_unit_clas_cd",
          "pur_unit_cd",
          "use_yn",
          "auto_yn"
        ],
        fieldRules: {
          use_yn: [{ type: "enum", values: YES_NO_VALUES }],
          auto_yn: [{ type: "enum", values: YES_NO_VALUES }]
        }
      },
      firstEditCol: "pur_dept_cd",
      pkLabels: { wrhs_exca_fee_rt_no: "창고정산요율번호" }
    }
  }

  detailManagerConfig() {
    return {
      pkFields: ["lineno"],
      fields: {
        dcsn_yn: "trimUpperDefault:N",
        aply_strt_ymd: "trim",
        aply_end_ymd: "trim",
        aply_uprice: "number",
        cur_cd: "trimUpper",
        std_work_qty: "number",
        aply_strt_qty: "number",
        aply_end_qty: "number",
        rmk: "trim"
      },
      defaultRow: {
        lineno: null,
        dcsn_yn: "N",
        aply_strt_ymd: this.todayYmd(),
        aply_end_ymd: this.todayYmd(),
        aply_uprice: 0,
        cur_cd: "KRW",
        std_work_qty: 0,
        aply_strt_qty: 0,
        aply_end_qty: 0,
        rmk: ""
      },
      blankCheckFields: ["aply_strt_ymd", "aply_end_ymd", "cur_cd"],
      comparableFields: [
        "dcsn_yn",
        "aply_strt_ymd",
        "aply_end_ymd",
        "aply_uprice",
        "cur_cd",
        "std_work_qty",
        "aply_strt_qty",
        "aply_end_qty",
        "rmk"
      ],
      validationRules: {
        requiredFields: ["dcsn_yn", "aply_strt_ymd", "aply_end_ymd", "aply_uprice", "cur_cd"],
        fieldRules: {
          dcsn_yn: [{ type: "enum", values: YES_NO_VALUES }]
        },
        rowRules: [
          ({ row }) => {
            const start = this.normalizeDateText(row.aply_strt_ymd)
            const end = this.normalizeDateText(row.aply_end_ymd)
            if (start && end && start > end) {
              return { field: "aply_end_ymd", message: "적용종료일자는 적용시작일자보다 빠를 수 없습니다." }
            }
            return null
          }
        ]
      },
      firstEditCol: "dcsn_yn",
      pkLabels: { lineno: "라인번호" }
    }
  }

  get masterManager() {
    return this.gridManager("master")
  }

  get detailManager() {
    return this.gridManager("detail")
  }

  beforeSearchReset() {
    this.clearMasterSelection()
  }

  selectFirstMasterRow() {
    const api = this.masterManager?.api
    if (!api) {
      return null
    }

    if (api.getDisplayedRowCount() === 0) {
      this.clearMasterSelection()
      return null
    }

    const preferredRef = this.currentMasterRef || this.selectedMasterValue
    let selectedNode = null

    if (preferredRef) {
      api.forEachNode((node) => {
        if (!selectedNode && this.masterRef(node?.data) === preferredRef) {
          selectedNode = node
        }
      })
    }

    if (!selectedNode) {
      selectedNode = api.getDisplayedRowAtIndex(0)
    }

    if (selectedNode?.data) {
      selectedNode.setSelected(true, true)
      return selectedNode.data
    }

    this.clearMasterSelection()
    return null
  }

  async handleMasterRowChange(rowData) {
    if (this.shouldBlockMasterChange(rowData)) {
      this.restorePreviousMasterSelection()
      return
    }

    this.applyMasterSelection(rowData)
  }

  shouldBlockMasterChange(rowData) {
    const nextRef = this.masterRef(rowData)
    if (!this.currentMasterRef) {
      return false
    }
    if (nextRef === this.currentMasterRef) {
      return false
    }
    if (!this.detailHasPendingChanges()) {
      return false
    }

    showAlert("저장되지 않은 상세 변경사항이 있습니다. 먼저 저장하세요.")
    return true
  }

  restorePreviousMasterSelection() {
    const api = this.masterManager?.api
    if (!api || !this.currentMasterRef) {
      return
    }

    api.forEachNode((node) => {
      if (this.masterRef(node?.data) === this.currentMasterRef) {
        node.setSelected(true, true)
      }
    })
  }

  applyMasterSelection(rowData) {
    if (!rowData) {
      this.clearMasterSelection()
      return
    }

    this.currentMasterRef = this.masterRef(rowData)
    this.selectedMasterValue = rowData.wrhs_exca_fee_rt_no?.toString().trim() || ""
    this.selectedMasterTempId = rowData.client_temp_id?.toString().trim() || rowData.__temp_id?.toString().trim() || ""
    this.refreshSelectedLabel()
  }

  clearMasterSelection() {
    this.currentMasterRef = ""
    this.selectedMasterValue = ""
    this.selectedMasterTempId = ""
    this.refreshSelectedLabel()
    this.clearDetailRows?.()
  }

  addMasterRow() {
    const tempId = this.newTempId()
    const rowOverrides = {
      client_temp_id: tempId,
      work_pl_cd: this.getSearchFormValue("work_pl_cd"),
      ctrt_cprtco_cd: this.getSearchFormValue("ctrt_cprtco_cd"),
      sell_buy_attr_cd: this.getSearchFormValue("sell_buy_attr_cd")
    }

    this.addRow({
      manager: this.masterManager,
      overrides: rowOverrides,
      onAdded: (rowData, { addedNode }) => {
        if (addedNode) {
          addedNode.setSelected(true, true)
        }
        this.applyMasterSelection(rowData)
        this.clearDetailRows?.()
      }
    })
  }

  deleteMasterRows() {
    this.deleteRows({ manager: this.masterManager, deleteLabel: "매입요율" })
  }

  async saveAllRows() {
    if (!this.masterManager || !this.detailManager) {
      return
    }

    this.masterManager.stopEditing?.()
    this.detailManager.stopEditing?.()

    if (!this.validateManager(this.masterManager, "마스터")) {
      return
    }
    if (!this.validateManager(this.detailManager, "상세")) {
      return
    }

    const masterOps = this.masterManager.buildOperations()
    const detailOps = this.detailManager.buildOperations()
    if (!hasChanges(masterOps) && !hasChanges(detailOps)) {
      showAlert("변경된 데이터가 없습니다.")
      return
    }

    const payload = this.buildBatchPayload(masterOps, detailOps)
    const result = await postJson(this.masterBatchUrlValue, payload)
    if (!result) {
      return
    }

    const selectedMasterKey = result?.data?.selected_master_key?.toString().trim()
    if (selectedMasterKey) {
      this.selectedMasterValue = selectedMasterKey
      this.selectedMasterTempId = ""
      this.currentMasterRef = selectedMasterKey
    }

    showAlert(result.message || "저장이 완료되었습니다.")
    this.refreshGrid("master")
  }

  validateManager(manager, managerLabel) {
    const validation = manager.validateRows?.() || { valid: true, errors: [] }
    if (validation.valid) {
      return true
    }

    const errors = Array.isArray(validation.errors) ? validation.errors : []
    const firstError = validation.firstError || errors[0] || null
    const summary = manager.formatValidationSummary
      ? manager.formatValidationSummary(errors, { maxItems: 3 })
      : `${managerLabel} 입력값을 확인하세요.`

    if (firstError) {
      manager.focusValidationError?.(firstError)
    }
    showAlert("Validation", summary, "warning")
    return false
  }

  buildBatchPayload(masterOps, detailOps) {
    const selectedMaster = this.selectedMasterRowData()
    const selectedMasterKey = selectedMaster?.wrhs_exca_fee_rt_no?.toString().trim() || this.selectedMasterValue
    const selectedMasterTempId = selectedMaster?.client_temp_id?.toString().trim() ||
      selectedMaster?.__temp_id?.toString().trim() ||
      this.selectedMasterTempId

    return {
      rowsToInsert: masterOps.rowsToInsert,
      rowsToUpdate: masterOps.rowsToUpdate,
      rowsToDelete: masterOps.rowsToDelete,
      detailOperations: {
        rowsToInsert: detailOps.rowsToInsert,
        rowsToUpdate: detailOps.rowsToUpdate,
        rowsToDelete: detailOps.rowsToDelete,
        master_key: selectedMasterKey,
        master_client_temp_id: selectedMasterTempId
      }
    }
  }

  selectedMasterRowData() {
    const selectedRows = this.selectedRows("master")
    if (Array.isArray(selectedRows) && selectedRows.length > 0) {
      return selectedRows[0]
    }

    const api = this.masterManager?.api
    if (!api || !this.currentMasterRef) {
      return null
    }

    let matched = null
    api.forEachNode((node) => {
      if (!matched && this.masterRef(node?.data) === this.currentMasterRef) {
        matched = node.data
      }
    })
    return matched
  }

  detailHasPendingChanges() {
    const manager = this.detailManager
    if (!manager) {
      return false
    }
    return hasChanges(manager.buildOperations())
  }

  masterRef(rowData) {
    if (!rowData) {
      return ""
    }

    const persistedKey = rowData.wrhs_exca_fee_rt_no?.toString().trim()
    if (persistedKey) {
      return persistedKey
    }

    const clientTempId = rowData.client_temp_id?.toString().trim()
    if (clientTempId) {
      return clientTempId
    }

    const internalTempId = rowData.__temp_id?.toString().trim()
    if (internalTempId) {
      return internalTempId
    }

    return ""
  }

  normalizeDateText(value) {
    return (value || "").toString().replace(/[^0-9]/g, "")
  }

  todayYmd() {
    const now = new Date()
    const year = now.getFullYear()
    const month = String(now.getMonth() + 1).padStart(2, "0")
    const day = String(now.getDate()).padStart(2, "0")
    return `${year}${month}${day}`
  }

  newTempId() {
    return `TMP_${Date.now()}_${Math.random().toString(36).slice(2, 8).toUpperCase()}`
  }
}
