import BaseGridController from "controllers/base_grid_controller"
import { showAlert } from "components/ui/alert"
import { buildTemplateUrl } from "controllers/grid/grid_utils"
import { refreshGridCells } from "controllers/grid/grid_api_utils"

const DETAIL_WEIGHT_PER_QTY = 1.5
const DETAIL_VOLUME_PER_QTY = 2.0

export default class extends BaseGridController {
  static targets = [
    ...BaseGridController.targets,
    "masterGrid",
    "detailGrid",
    "selectedOrderLabel"
  ]

  static values = {
    ...BaseGridController.values,
    detailBatchUrlTemplate: String,
    detailListUrlTemplate: String,
    selectedOrder: String
  }

  connect() {
    super.connect()
    this.refreshSelectedLabel()
  }

  masterConfig() {
    return {
      role: "master",
      key: {
        field: "ord_no",
        stateProperty: "selectedOrderValue",
        labelTarget: "selectedOrderLabel",
        entityLabel: "오더",
        emptyMessage: "오더를 먼저 선택하세요."
      },
      onRowChange: {
        trackCurrentRow: false,
        syncForm: false
      },
      beforeSearch: {
        clearValidation: false,
        clearForm: false
      },
      onAdded: (rowData) => {
        this.selectedOrderValue = rowData?.ord_no || ""
        this.refreshSelectedLabel()
        this.clearDetailRows?.()
      }
    }
  }

  detailGrids() {
    return [{
      role: "detail",
      masterKeyField: "ord_no",
      placeholder: ":id",
      listUrlTemplate: "detailListUrlTemplateValue",
      batchUrlTemplate: "detailBatchUrlTemplateValue",
      entityLabel: "오더",
      selectionMessage: "오더를 먼저 선택하세요.",
      saveMessage: "오더 상세 내역이 저장되었습니다.",
      fetchErrorMessage: "오더 상세 내역 조회에 실패했습니다.",
      overrides: ({ selectedValue }) => ({ ord_no: selectedValue }),
      onSaveSuccess: () => this.refreshGrid("master")
    }]
  }

  gridRoles() {
    return {
      master: {
        target: "masterGrid",
        manager: "masterManagerConfig",
        masterKeyField: "ord_no"
      },
      detail: {
        target: "detailGrid",
        manager: "detailManagerConfig",
        parentGrid: "master",
        onMasterRowChange: (rowData) => this.onMasterRowChanged(rowData),
        detailLoader: (rowData) => this.loadDetailRows("detail", rowData)
      }
    }
  }

  masterManagerConfig() {
    return {
      pkFields: ["ord_no"],
      fields: {
        ord_no: "trimUpper",
        ord_stat_cd: "trimUpper",
        ord_type_cd: "trimUpper",
        cust_cd: "trimUpper",
        cust_nm: "trim",
        dpt_ar_cd: "trimUpper",
        arv_ar_cd: "trimUpper"
      },
      defaultRow: {
        ord_no: "",
        ord_stat_cd: "",
        ord_type_cd: "",
        cust_cd: "",
        cust_nm: "",
        dpt_ar_cd: "",
        arv_ar_cd: ""
      },
      blankCheckFields: ["ord_no"],
      comparableFields: [],
      firstEditCol: "ord_no"
    }
  }

  detailManagerConfig() {
    return {
      pkFields: ["seq_no"],
      fields: {
        seq_no: "number",
        ord_no: "trimUpper",
        item_cd: "trimUpper",
        item_nm: "trim",
        ord_qty: "number",
        ord_wgt: "number",
        ord_vol: "number"
      },
      defaultRow: {
        seq_no: null,
        ord_no: "",
        item_cd: "",
        item_nm: "",
        ord_qty: 0,
        ord_wgt: 0,
        ord_vol: 0
      },
      blankCheckFields: ["item_cd", "item_nm"],
      comparableFields: ["item_cd", "item_nm", "ord_qty", "ord_wgt", "ord_vol"],
      validationRules: {
        requiredFields: ["item_cd"],
        fieldLabels: {
          item_cd: "아이템코드"
        }
      },
      firstEditCol: "item_cd",
      onCellValueChanged: (event) => this.normalizeDetailField(event)
    }
  }

  get masterManager() {
    return this.gridManager("master")
  }

  get detailManager() {
    return this.gridManager("detail")
  }

  get manager() {
    return this.masterManager
  }

  set manager(_value) {
    // BaseGridController 단일그리드 모드 호환 흡수
  }

  beforeSearchReset() {
    this.selectedOrderValue = ""
    this.refreshSelectedLabel()
    this.clearDetailRows?.()
  }

  onMasterRowChanged(rowData) {
    this.selectedOrderValue = rowData?.ord_no || ""
    this.refreshSelectedLabel()
  }

  normalizeDetailField(event) {
    const row = event?.node?.data
    const field = event?.colDef?.field
    if (!row || !field) return

    row.ord_no = this.selectedOrderValue || row.ord_no || ""

    if (field === "ord_qty") {
      const qty = Number(row.ord_qty) || 0
      row.ord_wgt = Number((qty * DETAIL_WEIGHT_PER_QTY).toFixed(3))
      row.ord_vol = Number((qty * DETAIL_VOLUME_PER_QTY).toFixed(3))
    }

    refreshGridCells(this.detailManager?.api, {
      rowNodes: [event.node],
      columns: ["ord_no", field, "ord_wgt", "ord_vol"],
      force: true
    })
  }

  async saveDetailRows() {
    if (!this.selectedOrderValue) {
      showAlert("오더를 먼저 선택하세요.")
      return
    }

    const detailRows = []
    this.detailManager?.api?.forEachNode((node) => {
      if (!node?.data || node.data.__is_deleted) return
      detailRows.push(node.data)
    })
    if (detailRows.length > 1) {
      showAlert("서비스 오더 상세는 1건만 입력할 수 있습니다.")
      return
    }

    const batchUrl = buildTemplateUrl(this.detailBatchUrlTemplateValue, ":id", this.selectedOrderValue)
    await this.saveRowsWith({
      manager: this.detailManager,
      batchUrl,
      saveMessage: "오더 상세 내역이 저장되었습니다.",
      onSuccess: () => this.refreshGrid("master")
    })
  }

  addDetailRow() {
    const manager = this.detailManager
    if (!manager?.api) return

    if (!this.selectedOrderValue) {
      showAlert("오더를 먼저 선택하세요.")
      return
    }

    const rowCount = manager.api.getDisplayedRowCount()
    if (rowCount >= 1) {
      showAlert("서비스 오더 상세는 1건만 입력할 수 있습니다.")
      return
    }

    this.addRow({
      manager,
      overrides: {
        seq_no: 1,
        ord_no: this.selectedOrderValue
      },
      config: { startCol: "item_cd" }
    })
  }

  async cancelSelectedOrder() {
    const ordNo = (this.selectedOrderValue || "").toString().trim()
    if (ordNo === "") {
      showAlert("취소할 오더를 먼저 선택하세요.")
      return
    }

    const reason = window.prompt("오더 취소 사유를 입력해주세요:")
    if (!reason || reason.trim() === "") {
      return
    }

    const url = `/om/service_orders/${encodeURIComponent(ordNo)}/cancel`
    await this.postAction(url, { order: { cancel_reason: reason.trim() } }, {
      onSuccess: () => {
        showAlert("오더가 취소되었습니다.")
        this.refreshGrid("master")
        this.clearDetailRows?.()
      }
    })
  }
}
