import BaseGridController from "controllers/base_grid_controller"
import { showAlert, confirmAction } from "components/ui/alert"
import { buildTemplateUrl, refreshSelectionLabel } from "controllers/grid/grid_utils"
import { isApiAlive } from "controllers/grid/core/api_guard"
import { fetchJson } from "controllers/grid/core/http_client"
import { refreshGridCells, setManagerRowData } from "controllers/grid/grid_api_utils"

const NUMBER_FIELDS = [
  "ord_qty",
  "ord_wgt",
  "ord_vol",
  "div_cmpt_qty",
  "div_cmpt_wgt",
  "div_cmpt_vol",
  "avail_stock_qty",
  "avail_stock_wgt",
  "avail_stock_vol",
  "div_qty",
  "div_wgt",
  "div_vol",
  "balance_qty",
  "balance_wgt",
  "balance_vol"
]

export default class extends BaseGridController {
  static targets = [
    ...BaseGridController.targets,
    "masterGrid",
    "detailGrid",
    "selectedOrderLabel"
  ]

  static values = {
    ...BaseGridController.values,
    detailListUrlTemplate: String,
    detailBatchUrlTemplate: String,
    selectedOrder: String
  }

  connect() {
    super.connect()
    this.refreshSelectedOrderLabel()
  }

  gridRoles() {
    return {
      master: {
        target: "masterGrid",
        masterKeyField: "ord_no"
      },
      detail: {
        target: "detailGrid",
        manager: this.detailManagerConfig(),
        parentGrid: "master",
        onMasterRowChange: (rowData) => {
          this.selectedOrderValue = rowData?.ord_no || ""
          this.refreshSelectedOrderLabel()
          this.clearDetailRows()
        },
        detailLoader: async (rowData) => {
          const ordNo = rowData?.ord_no
          if (!ordNo) return []

          try {
            const url = buildTemplateUrl(this.detailListUrlTemplateValue, "__ORD_NO__", ordNo)
            const rows = await fetchJson(url)
            if (Array.isArray(rows)) {
              return rows.map((row) => this.normalizeDetailRow(row))
            }
            return []
          } catch {
            showAlert("대기오더상세 조회에 실패했습니다.")
            return []
          }
        }
      }
    }
  }

  beforeSearchReset() {
    this.selectedOrderValue = ""
    this.refreshSelectedOrderLabel()
    this.clearDetailRows()
  }

  async checkAvailableStock() {
    if (!this.selectedOrderValue) {
      showAlert("오더를 먼저 선택하세요.")
      return
    }

    const reloaded = await this.reloadDetailRows()
    if (reloaded) {
      showAlert("가용재고 조회가 완료되었습니다.")
    }
  }

  async distributeDetailRows() {
    if (!this.selectedOrderValue) {
      showAlert("오더를 먼저 선택하세요.")
      return
    }

    const confirmed = await confirmAction("오더분배", "현재 상세 분배값을 저장하시겠습니까?")
    if (!confirmed) {
      return
    }

    const saved = await this.saveDetailRows()
    if (saved) {
      await this.reloadDetailRows()
      this.refreshGrid("master")
    }
  }

  async saveDetailRows() {
    if (!this.detailManager) return false

    const batchUrl = buildTemplateUrl(this.detailBatchUrlTemplateValue, "__ORD_NO__", this.selectedOrderValue)
    return this.saveRowsWith({
      manager: this.detailManager,
      batchUrl,
      saveMessage: "오더분배 정보가 저장되었습니다.",
      emptyMessage: "저장할 분배 변경 데이터가 없습니다.",
      onSuccess: null
    })
  }

  detailManagerConfig() {
    return {
      pkFields: ["ord_no", "seq"],
      fields: {
        ord_no: "trimUpper",
        seq: "number",
        item_cd: "trimUpper",
        div_qty: "number",
        div_wgt: "number",
        div_vol: "number"
      },
      defaultRow: {
        ord_no: "",
        seq: 1,
        item_cd: "",
        div_qty: 0,
        div_wgt: 0,
        div_vol: 0
      },
      blankCheckFields: ["ord_no"],
      comparableFields: ["div_qty", "div_wgt", "div_vol"],
      validationRules: {
        requiredFields: ["ord_no", "seq"],
        fieldLabels: {
          ord_no: "오더번호",
          seq: "순번",
          div_qty: "분배수량",
          div_wgt: "분배중량",
          div_vol: "분배부피"
        },
        rowRules: [
          {
            validate: ({ row }) => this.validateDistributionRow(row)
          }
        ]
      },
      firstEditCol: "div_qty",
      onCellValueChanged: (event) => this.handleDetailValueChanged(event),
      pkLabels: { ord_no: "오더번호", seq: "순번" }
    }
  }

  get detailManager() {
    return this.gridManager("detail")
  }

  clearDetailRows() {
    if (this.detailManager) {
      setManagerRowData(this.detailManager, [])
    } else {
      this.setRows("detail", [])
    }
  }

  refreshSelectedOrderLabel() {
    if (!this.hasSelectedOrderLabelTarget) return
    refreshSelectionLabel(this.selectedOrderLabelTarget, this.selectedOrderValue, "오더", "오더를 먼저 선택하세요.")
  }

  async reloadDetailRows() {
    if (!this.selectedOrderValue) {
      this.clearDetailRows()
      return false
    }

    try {
      const url = buildTemplateUrl(this.detailListUrlTemplateValue, "__ORD_NO__", this.selectedOrderValue)
      const rows = await fetchJson(url)
      const normalizedRows = Array.isArray(rows) ? rows.map((row) => this.normalizeDetailRow(row)) : []

      if (this.detailManager) {
        setManagerRowData(this.detailManager, normalizedRows)
      } else {
        this.setRows("detail", normalizedRows)
      }
      return true
    } catch {
      this.clearDetailRows()
      showAlert("상세 데이터를 다시 불러오지 못했습니다.")
      return false
    }
  }

  handleDetailValueChanged(event) {
    const row = event?.node?.data
    if (!row) return

    row.div_qty = this.toNumber(row.div_qty)
    row.div_wgt = this.toNumber(row.div_wgt)
    row.div_vol = this.toNumber(row.div_vol)
    this.recalculateBalance(row)

    const api = this.gridApi("detail")
    if (isApiAlive(api)) {
      refreshGridCells(api, {
        rowNodes: [event.node],
        columns: ["div_qty", "div_wgt", "div_vol", "balance_qty", "balance_wgt", "balance_vol"],
        force: true
      })
    }
  }

  normalizeDetailRow(row) {
    const normalized = { ...row }
    NUMBER_FIELDS.forEach((field) => {
      normalized[field] = this.toNumber(normalized[field])
    })
    normalized.seq = this.toNumber(normalized.seq || 1)
    this.recalculateBalance(normalized)
    return normalized
  }

  validateDistributionRow(row) {
    const divQty = this.toNumber(row.div_qty)
    const divWgt = this.toNumber(row.div_wgt)
    const divVol = this.toNumber(row.div_vol)
    const availQty = this.toNumber(row.avail_stock_qty)
    const availWgt = this.toNumber(row.avail_stock_wgt)
    const availVol = this.toNumber(row.avail_stock_vol)
    const baseBalQty = this.baseBalance(row.ord_qty, row.div_cmpt_qty)
    const baseBalWgt = this.baseBalance(row.ord_wgt, row.div_cmpt_wgt)
    const baseBalVol = this.baseBalance(row.ord_vol, row.div_cmpt_vol)

    if (divQty < 0) {
      return { valid: false, field: "div_qty", message: "분배수량은 0 이상이어야 합니다." }
    }
    if (divWgt < 0) {
      return { valid: false, field: "div_wgt", message: "분배중량은 0 이상이어야 합니다." }
    }
    if (divVol < 0) {
      return { valid: false, field: "div_vol", message: "분배부피는 0 이상이어야 합니다." }
    }

    if (divQty > availQty || divQty > baseBalQty) {
      return { valid: false, field: "div_qty", message: "분배수량은 잔여량/가용재고량을 초과할 수 없습니다." }
    }
    if (divWgt > availWgt || divWgt > baseBalWgt) {
      return { valid: false, field: "div_wgt", message: "분배중량은 잔여량/가용재고량을 초과할 수 없습니다." }
    }
    if (divVol > availVol || divVol > baseBalVol) {
      return { valid: false, field: "div_vol", message: "분배부피는 잔여량/가용재고량을 초과할 수 없습니다." }
    }

    return { valid: true }
  }

  recalculateBalance(row) {
    const baseQty = this.baseBalance(row.ord_qty, row.div_cmpt_qty)
    const baseWgt = this.baseBalance(row.ord_wgt, row.div_cmpt_wgt)
    const baseVol = this.baseBalance(row.ord_vol, row.div_cmpt_vol)

    row.balance_qty = this.roundTo3(Math.max(baseQty - this.toNumber(row.div_qty), 0))
    row.balance_wgt = this.roundTo3(Math.max(baseWgt - this.toNumber(row.div_wgt), 0))
    row.balance_vol = this.roundTo3(Math.max(baseVol - this.toNumber(row.div_vol), 0))
  }

  baseBalance(total, completed) {
    return this.roundTo3(Math.max(this.toNumber(total) - this.toNumber(completed), 0))
  }

  toNumber(value) {
    const numeric = Number(value)
    if (Number.isFinite(numeric)) {
      return this.roundTo3(numeric)
    }
    return 0
  }

  roundTo3(value) {
    return Math.round(value * 1000) / 1000
  }
}
