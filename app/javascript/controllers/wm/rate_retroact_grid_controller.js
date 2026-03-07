import BaseGridController from "controllers/base_grid_controller"
import { showAlert } from "components/ui/alert"
import { openLookupPopup } from "controllers/lookup_popup_modal"
import { buildTemplateUrl, refreshSelectionLabel, postJson } from "controllers/grid/grid_utils"
import { fetchJson } from "controllers/grid/core/http_client"
import { hasPendingChanges, blockIfPendingChanges } from "controllers/grid/grid_state_utils"
import { collectRows } from "controllers/grid/grid_api_utils"

export default class extends BaseGridController {
  static targets = [...BaseGridController.targets, "masterGrid", "detailGrid", "selectedMasterLabel", "selectedRetroRateLabel"]

  static values = {
    ...BaseGridController.values,
    masterBatchUrl: String,
    detailBatchUrlTemplate: String,
    detailListUrlTemplate: String,
    applyRetroRatesUrl: String,
    processRetroactsUrl: String,
    selectedMaster: String
  }

  connect() {
    super.connect()
    this.currentMasterRow = null
    this.selectedRetroRate = null
    this.refreshSelectedLabels()
  }

  masterConfig() {
    return {
      role: "master",
      batchUrl: "masterBatchUrlValue",
      saveMessage: "요율 데이터가 저장되었습니다.",
      pendingEntityLabel: "마스터 요율",
      key: {
        field: "wrhs_exca_fee_rt_no",
        stateProperty: "selectedMasterValue",
        labelTarget: "selectedMasterLabel",
        entityLabel: "요율",
        emptyMessage: "요율을 먼저 선택하세요."
      },
      onRowChange: {
        trackCurrentRow: true,
        syncForm: false,
        afterChange: () => {
          this.resetRetroRate()
          this.refreshSelectedLabels()
        }
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
      entityLabel: "요율",
      selectionMessage: "요율목록에서 기준 요율을 먼저 선택하세요."
    }]
  }

  gridRoles() {
    return {
      master: {
        target: "masterGrid",
        manager: this.masterManagerConfig(),
        isMaster: true,
        masterKeyField: "wrhs_exca_fee_rt_no"
      },
      detail: {
        target: "detailGrid",
        manager: this.detailManagerConfig(),
        parentGrid: "master",
        onMasterRowChange: (rowData) => this.onMasterRowChanged(rowData),
        detailLoader: (rowData) => this.fetchDetailRows(rowData)
      }
    }
  }

  masterManagerConfig() {
    return {
      pkFields: ["wrhs_exca_fee_rt_no"],
      fields: {
        wrhs_exca_fee_rt_no: "trimUpper",
        rtac_feert: "number"
      },
      defaultRow: {
        wrhs_exca_fee_rt_no: "",
        rtac_feert: 0
      },
      blankCheckFields: ["wrhs_exca_fee_rt_no"],
      comparableFields: ["rtac_feert"],
      firstEditCol: "rtac_feert"
    }
  }

  detailManagerConfig() {
    return {
      pkFields: ["exce_rslt_no"],
      fields: {
        exce_rslt_no: "trimUpper",
        rslt_std_ymd: "trim",
        op_rslt_mngt_no: "trimUpper",
        lineno: "number",
        rslt_qty: "number",
        aply_uprice: "number",
        rslt_amt: "number",
        cur_cd: "trimUpper",
        rtac_uprice: "number",
        rtac_amt: "number",
        uprice_diff: "number",
        amt_diff: "number"
      },
      defaultRow: {
        exce_rslt_no: "",
        rslt_std_ymd: "",
        op_rslt_mngt_no: "",
        lineno: 0,
        rslt_qty: 0,
        aply_uprice: 0,
        rslt_amt: 0,
        cur_cd: "KRW",
        rtac_uprice: 0,
        rtac_amt: 0,
        uprice_diff: 0,
        amt_diff: 0
      },
      blankCheckFields: ["exce_rslt_no"],
      comparableFields: ["cur_cd", "rtac_uprice", "rtac_amt", "uprice_diff", "amt_diff", "rslt_amt"],
      firstEditCol: "rtac_uprice"
    }
  }

  get masterManager() {
    return this.gridManager("master")
  }

  get detailManager() {
    return this.gridManager("detail")
  }

  onAllGridsReady() {
    this.refreshSelectedLabels()
  }

  beforeSearchReset() {
    this.currentMasterRow = null
    this.selectedMasterValue = ""
    this.resetRetroRate()
    this.refreshSelectedLabels()
    this.clearDetailRows?.()
  }

  async saveMasterRows() {
    if (!this.masterBatchUrlValue) {
      showAlert("저장 URL이 설정되지 않았습니다.")
      return
    }

    await this.saveRowsWith({
      manager: this.masterManager,
      batchUrl: this.masterBatchUrlValue,
      saveMessage: "요율 데이터가 저장되었습니다.",
      onSuccess: () => this.refreshGrid("master")
    })
  }

  async saveDetailRows() {
    if (!this.currentMasterRow || !this.selectedMasterValue) {
      showAlert("요율목록에서 기준 요율을 먼저 선택하세요.")
      return
    }
    if (this.blockDetailActionIfMasterChanged()) {
      return
    }

    const manager = this.detailManager
    if (!manager) {
      return
    }

    manager.stopEditing?.()
    const operations = manager.buildOperations ? manager.buildOperations() : null
    if (!operations || (!operations.rowsToInsert?.length && !operations.rowsToUpdate?.length && !operations.rowsToDelete?.length)) {
      showAlert("변경된 데이터가 없습니다.")
      return
    }

    const batchUrl = buildTemplateUrl(this.detailBatchUrlTemplateValue, ":id", this.selectedMasterValue)
    const result = await postJson(batchUrl, {
      ...operations,
      ref_fee_rt_no: this.selectedRetroRate?.ref_fee_rt_no || this.currentMasterRow.wrhs_exca_fee_rt_no,
      ref_fee_rt_lineno: this.selectedRetroRate?.ref_fee_rt_lineno || this.currentMasterRow.rate_lineno
    })

    if (!result) {
      return
    }

    showAlert(result.message || "실적 데이터가 저장되었습니다.")
    await this.reloadDetailRows()
  }

  async openRetroRatePopup() {
    if (!this.currentMasterRow) {
      showAlert("요율목록에서 기준 요율을 먼저 선택하세요.")
      return
    }

    const popupUrl = this.buildFeeRatePopupUrl()
    const selection = await openLookupPopup({
      type: "fee_rate",
      url: popupUrl,
      keyword: this.currentMasterRow.sell_buy_attr_nm,
      title: "보관요율 선택"
    })

    if (!selection) {
      return
    }

    const selectedRate = {
      ref_fee_rt_no: selection.wrhs_exca_fee_rt_no || selection.code,
      ref_fee_rt_lineno: Number(selection.lineno || 0),
      rtac_uprice: Number(selection.aply_uprice || 0),
      cur_cd: String(selection.cur_cd || "KRW").toUpperCase(),
      sell_buy_attr_cd: selection.sell_buy_attr_cd,
      display: selection.display || selection.name || selection.code
    }

    if (!selectedRate.ref_fee_rt_no || selectedRate.rtac_uprice <= 0) {
      showAlert("선택한 소급요율 정보가 올바르지 않습니다.")
      return
    }

    this.selectedRetroRate = selectedRate
    this.updateMasterRetroRateColumn(selectedRate.rtac_uprice)
    this.refreshSelectedLabels()
    showAlert("소급요율이 선택되었습니다.")
  }

  async applyRetroRate() {
    if (!this.currentMasterRow) {
      showAlert("요율목록에서 기준 요율을 먼저 선택하세요.")
      return
    }
    if (!this.selectedRetroRate) {
      showAlert("소급요율검색으로 소급요율을 먼저 선택하세요.")
      return
    }

    const rows = collectRows(this.gridApi("detail"))
    if (rows.length === 0) {
      showAlert("소급 적용 대상 실적이 없습니다.")
      return
    }

    const payloadRows = rows.map((row) => {
      return {
        exce_rslt_no: row.exce_rslt_no,
        rslt_qty: row.rslt_qty,
        aply_uprice: row.aply_uprice
      }
    })

    const result = await postJson(this.applyRetroRatesUrlValue, {
      retro_uprice: this.selectedRetroRate.rtac_uprice,
      retro_cur_cd: this.selectedRetroRate.cur_cd,
      rows: payloadRows
    })

    if (!result) {
      return
    }

    const appliedRows = result?.data?.rows
    if (!Array.isArray(appliedRows)) {
      showAlert("소급요율 적용 결과를 확인할 수 없습니다.")
      return
    }

    const appliedMap = new Map(appliedRows.map((row) => [String(row.exce_rslt_no), row]))
    const detailApi = this.gridApi("detail")
    if (!detailApi) {
      return
    }

    detailApi.forEachNode((node) => {
      const key = node?.data?.exce_rslt_no?.toString()
      const applied = appliedMap.get(key)
      if (!applied) {
        return
      }

      node.setData({
        ...node.data,
        cur_cd: applied.cur_cd,
        rtac_uprice: applied.rtac_uprice,
        rtac_amt: applied.rtac_amt,
        uprice_diff: applied.uprice_diff,
        amt_diff: applied.amt_diff,
        rslt_amt: applied.rslt_amt
      })
    })

    showAlert(result.message || "소급요율이 적용되었습니다.")
  }

  async processRetroacts() {
    if (!this.currentMasterRow) {
      showAlert("요율목록에서 기준 요율을 먼저 선택하세요.")
      return
    }

    const selectedRows = this.selectedRows("detail")
    if (!Array.isArray(selectedRows) || selectedRows.length === 0) {
      showAlert("소급처리할 실적행을 선택하세요.")
      return
    }

    const hasAppliedRate = selectedRows.some((row) => Number(row.rtac_uprice || 0) > 0)
    if (!hasAppliedRate) {
      showAlert("소급요율적용 후 소급처리할 수 있습니다.")
      return
    }

    const payloadRows = selectedRows.map((row) => {
      return {
        exce_rslt_no: row.exce_rslt_no,
        rslt_std_ymd: row.rslt_std_ymd,
        op_rslt_mngt_no: row.op_rslt_mngt_no,
        lineno: row.lineno,
        rslt_qty: row.rslt_qty,
        aply_uprice: row.aply_uprice,
        rslt_amt: row.rslt_amt,
        cur_cd: row.cur_cd,
        rtac_uprice: row.rtac_uprice,
        rtac_amt: row.rtac_amt,
        uprice_diff: row.uprice_diff,
        amt_diff: row.amt_diff
      }
    })

    const result = await postJson(this.processRetroactsUrlValue, {
      work_pl_cd: this.currentMasterRow.work_pl_cd,
      sell_buy_sctn_cd: this.currentMasterRow.sell_buy_sctn_cd,
      bzac_cd: this.currentMasterRow.bzac_cd,
      sell_buy_attr_cd: this.currentMasterRow.sell_buy_attr_cd,
      ref_fee_rt_no: this.selectedRetroRate?.ref_fee_rt_no || this.currentMasterRow.wrhs_exca_fee_rt_no,
      ref_fee_rt_lineno: this.selectedRetroRate?.ref_fee_rt_lineno || this.currentMasterRow.rate_lineno,
      rows: payloadRows
    })

    if (!result) {
      return
    }

    showAlert(result.message || "요율소급처리가 완료되었습니다.")
    await this.reloadDetailRows()
  }

  hasMasterPendingChanges() {
    return hasPendingChanges(this.masterManager)
  }

  blockDetailActionIfMasterChanged() {
    return blockIfPendingChanges(this.masterManager, "마스터 요율")
  }

  async fetchDetailRows(rowData) {
    if (!rowData || !rowData.wrhs_exca_fee_rt_no) {
      return []
    }

    const url = buildTemplateUrl(this.detailListUrlTemplateValue, { rate_retroact_id: rowData.wrhs_exca_fee_rt_no })
    const query = this.buildDetailQuery(rowData)
    const queryString = query.toString()
    const requestUrl = queryString.length > 0 ? `${url}?${queryString}` : url

    try {
      const rows = await fetchJson(requestUrl)
      return Array.isArray(rows) ? rows : []
    } catch {
      showAlert("실적목록 조회에 실패했습니다.")
      return []
    }
  }

  async reloadDetailRows() {
    if (!this.currentMasterRow) {
      return
    }

    const rows = await this.fetchDetailRows(this.currentMasterRow)
    this.setRows("detail", rows)
  }

  refreshSelectedLabels() {
    if (this.hasSelectedMasterLabelTarget) {
      refreshSelectionLabel(this.selectedMasterLabelTarget, this.selectedMasterValue, "요율", "요율을 먼저 선택하세요.")
    }

    if (this.hasSelectedRetroRateLabelTarget) {
      const retroLabel = this.selectedRetroRate
        ? `${this.selectedRetroRate.ref_fee_rt_no} / ${this.selectedRetroRate.rtac_uprice}`
        : ""
      refreshSelectionLabel(this.selectedRetroRateLabelTarget, retroLabel, "소급요율", "소급요율을 선택하세요.")
    }
  }

  buildDetailQuery(rowData) {
    const query = new URLSearchParams()
    query.set("selected_lineno", rowData.rate_lineno || "")
    query.set("base_uprice", rowData.aply_feert || 0)
    query.set("base_cur_cd", rowData.cur_cd || "KRW")

    this.appendQueryParam(query, "q[work_pl_cd]", this.getSearchFormValue("work_pl_cd"))
    this.appendQueryParam(query, "q[sell_buy_sctn_cd]", this.getSearchFormValue("sell_buy_sctn_cd"))
    this.appendQueryParam(query, "q[bzac_cd]", this.getSearchFormValue("bzac_cd"))
    this.appendQueryParam(query, "q[sell_buy_attr_cd]", this.getSearchFormValue("sell_buy_attr_cd"))
    this.appendQueryParam(query, "q[rslt_std_date_from]", this.getSearchFormValue("rslt_std_date_from", { toUpperCase: false }))
    this.appendQueryParam(query, "q[rslt_std_date_to]", this.getSearchFormValue("rslt_std_date_to", { toUpperCase: false }))

    return query
  }

  buildFeeRatePopupUrl() {
    const query = new URLSearchParams()
    this.appendQueryParam(query, "work_pl_cd", this.currentMasterRow?.work_pl_cd)
    this.appendQueryParam(query, "sell_buy_sctn_cd", this.currentMasterRow?.sell_buy_sctn_cd)
    this.appendQueryParam(query, "bzac_cd", this.currentMasterRow?.bzac_cd)
    this.appendQueryParam(query, "sell_buy_attr_cd", this.currentMasterRow?.sell_buy_attr_cd)
    this.appendQueryParam(query, "aply_ymd", this.getSearchFormValue("aply_date_to", { toUpperCase: false }))

    const queryString = query.toString()
    if (queryString.length > 0) {
      return `/search_popups/fee_rate?${queryString}`
    }
    return "/search_popups/fee_rate"
  }

  appendQueryParam(query, key, value) {
    const normalized = value == null ? "" : value.toString().trim()
    if (normalized.length > 0) {
      query.set(key, normalized)
    }
  }

  updateMasterRetroRateColumn(rtacFeert) {
    const masterApi = this.gridApi("master")
    if (!masterApi || !this.currentMasterRow) {
      return
    }

    const targetId = this.currentMasterRow.id
    masterApi.forEachNode((node) => {
      if (node?.data?.id === targetId) {
        node.setData({ ...node.data, rtac_feert: rtacFeert })
      }
    })
  }

  resetRetroRate() {
    this.selectedRetroRate = null
  }
}
