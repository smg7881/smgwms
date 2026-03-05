import BaseGridController from "controllers/base_grid_controller"
import { showAlert } from "components/ui/alert"
import { openLookupPopup } from "controllers/lookup_popup_modal"
import {
  fetchJson,
  buildTemplateUrl,
  refreshSelectionLabel,
  collectRows,
  postJson
} from "controllers/grid/grid_utils"

export default class extends BaseGridController {
  static targets = [...BaseGridController.targets, "masterGrid", "detailGrid", "selectedMasterLabel", "selectedRetroRateLabel"]

  static values = {
    ...BaseGridController.values,
    detailListUrlTemplate: String,
    applyRetroRatesUrl: String,
    processRetroactsUrl: String,
    selectedMaster: String
  }

  connect() {
    super.connect()
    this.currentMasterRow = null
    this.selectedRetroRate = null
    this.detailLoadToken = 0
  }

  gridRoles() {
    return {
      master: {
        target: "masterGrid",
        isMaster: true,
        masterKeyField: "id"
      },
      detail: {
        target: "detailGrid",
        parentGrid: "master",
        onMasterRowChange: (rowData) => {
          this.currentMasterRow = rowData || null
          this.selectedMasterValue = rowData?.wrhs_exca_fee_rt_no?.toString().trim() || ""
          this.resetRetroRate()
          this.refreshSelectedLabels()
        },
        detailLoader: async (rowData) => this.loadDetailRows(rowData)
      }
    }
  }

  onAllGridsReady() {
    this.refreshSelectedLabels()
  }

  beforeSearchReset() {
    this.currentMasterRow = null
    this.selectedMasterValue = ""
    this.resetRetroRate()
    this.refreshSelectedLabels()
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

  async loadDetailRows(rowData) {
    if (!rowData || !rowData.wrhs_exca_fee_rt_no) {
      return []
    }

    const token = ++this.detailLoadToken
    const url = buildTemplateUrl(this.detailListUrlTemplateValue, { rate_retroact_id: rowData.wrhs_exca_fee_rt_no })
    const query = this.buildDetailQuery(rowData)
    const queryString = query.toString()
    const requestUrl = queryString.length > 0 ? `${url}?${queryString}` : url

    try {
      const rows = await fetchJson(requestUrl)
      if (token !== this.detailLoadToken) {
        return []
      }
      return Array.isArray(rows) ? rows : []
    } catch {
      if (token !== this.detailLoadToken) {
        return []
      }
      showAlert("실적목록 조회에 실패했습니다.")
      return []
    }
  }

  async reloadDetailRows() {
    if (!this.currentMasterRow) {
      return
    }

    const rows = await this.loadDetailRows(this.currentMasterRow)
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
