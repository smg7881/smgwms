import { Controller } from "@hotwired/stimulus"
import { showAlert, confirmAction } from "components/ui/alert"

export default class extends Controller {
  static values = {
    searchUrl: String,
    createUrl: String,
    updateUrl: String,
    cancelUrl: String
  }

  static targets = [
    "searchOrdNo",
    "headerForm",
    "saveBtn", "cancelBtn",
    "fieldOrdNo", "fieldOrdStatCd", "fieldCreateTime",
    "fieldCtrtNo", "fieldOrdTypeCd", "fieldBilgCustCd", "fieldBilgCustNm",
    "fieldCtrtCustCd", "fieldCtrtCustNm", "fieldOrdReasonCd",
    "fieldOrdExecDeptCd", "fieldOrdExecDeptNm",
    "fieldOrdExecOfcrCd", "fieldOrdExecOfcrNm", "fieldRemk",
    "bilgCustSearchBtn", "ctrtCustSearchBtn",
    "fieldDptTypeCd", "fieldDptCd", "fieldDptZipCd", "fieldDptAddr", "fieldStrtReqYmd",
    "fieldArvTypeCd", "fieldArvCd", "fieldArvZipCd", "fieldArvAddr", "fieldAptdReqDtm",
    "tabButton", "tabPanel",
    "itemGrid"
  ]

  // lifecycle
  connect() {
    this.#mode = "view"
    this.#currentOrderId = null
    this.#itemGridApi = null
    this.#setFormDisabled(true)
  }

  registerItemGrid(event) {
    const gridElement = this.itemGridTarget
    const agGridController = this.application.getControllerForElementAndIdentifier(gridElement, "ag-grid")
    if (agGridController) {
      this.#itemGridApi = agGridController.gridOptions?.api || null
    }
  }

  // actions
  async search() {
    const ordNo = this.searchOrdNoTarget.value.trim()
    if (!ordNo) {
      showAlert("오더번호를 입력하세요.")
      this.searchOrdNoTarget.focus()
      return
    }

    try {
      const url = `${this.searchUrlValue}?q[ord_no]=${encodeURIComponent(ordNo)}`
      const response = await fetch(url, {
        headers: { "Accept": "application/json", "X-CSRF-Token": this.#csrfToken }
      })
      const result = await response.json()

      if (response.ok && result.success) {
        this.#loadOrderData(result.data)
      } else {
        showAlert(result.message || "오더를 찾을 수 없습니다.")
      }
    } catch (error) {
      console.error("[om-internal-order] search error:", error)
      showAlert("서버 연결에 실패했습니다.")
    }
  }

  newOrder() {
    this.#mode = "create"
    this.#currentOrderId = null
    this.#clearForm()
    this.#setFormDisabled(false)
    this.fieldOrdNoTarget.value = ""
    this.fieldOrdStatCdTarget.value = ""
    this.fieldCreateTimeTarget.value = ""

    if (this.#itemGridApi) {
      this.#itemGridApi.setGridOption("rowData", [])
    }
  }

  async saveOrder() {
    const payload = this.#collectPayload()

    const isCreate = this.#mode === "create"
    const url = isCreate ? this.createUrlValue : this.updateUrlValue.replace(":id", this.#currentOrderId)
    const method = isCreate ? "POST" : "PATCH"

    try {
      const response = await this.#requestJson(url, method, payload)
      const result = await response.json()

      if (response.ok && result.success) {
        showAlert(result.message)
        this.#loadOrderData(result.data)
      } else {
        const errors = result.errors ? result.errors.join("\n") : (result.message || "저장에 실패했습니다.")
        showAlert(errors)
      }
    } catch (error) {
      console.error("[om-internal-order] save error:", error)
      showAlert("서버 연결에 실패했습니다.")
    }
  }

  async cancelOrder() {
    if (!this.#currentOrderId) {
      showAlert("취소할 오더가 선택되지 않았습니다.")
      return
    }

    if (!confirmAction("이 오더를 취소하시겠습니까?")) {
      return
    }

    try {
      const url = this.cancelUrlValue.replace(":id", this.#currentOrderId)
      const response = await this.#requestJson(url, "POST", {})
      const result = await response.json()

      if (response.ok && result.success) {
        showAlert(result.message)
        this.#loadOrderData(result.data)
      } else {
        showAlert(result.message || "취소에 실패했습니다.")
      }
    } catch (error) {
      console.error("[om-internal-order] cancel error:", error)
      showAlert("오류가 발생했습니다.")
    }
  }

  switchTab(event) {
    const tab = event.currentTarget.dataset.tab

    if (this.hasTabButtonTarget) {
      this.tabButtonTargets.forEach((btn) => {
        if (btn.dataset.tab === tab) {
          btn.classList.add("is-active")
          btn.setAttribute("aria-selected", "true")
        } else {
          btn.classList.remove("is-active")
          btn.setAttribute("aria-selected", "false")
        }
      })
    }

    if (this.hasTabPanelTarget) {
      this.tabPanelTargets.forEach((panel) => {
        if (panel.dataset.tabPanel === tab) {
          panel.classList.remove("hidden")
        } else {
          panel.classList.add("hidden")
        }
      })
    }

    if (tab === "items") {
      // AG Grid는 hidden 상태에서 사이즈를 못 잡으므로 refresh
      if (this.#itemGridApi) {
        setTimeout(() => this.#itemGridApi.sizeColumnsToFit(), 100)
      }
    }
  }

  addItemRow() {
    if (!this.#itemGridApi) return

    const allRows = []
    this.#itemGridApi.forEachNode(node => allRows.push(node.data))

    if (allRows.length >= 20) {
      showAlert("아이템은 최대 20건까지 등록 가능합니다.")
      return
    }

    const nextSeq = allRows.length + 1
    this.#itemGridApi.applyTransaction({
      add: [{ seq_no: nextSeq, item_cd: "", item_nm: "", ord_qty: 0, ord_wgt: 0, ord_vol: 0 }]
    })
  }

  deleteItemRows() {
    if (!this.#itemGridApi) return

    const selected = this.#itemGridApi.getSelectedRows()
    if (selected.length === 0) {
      showAlert("삭제할 행을 선택하세요.")
      return
    }

    this.#itemGridApi.applyTransaction({ remove: selected })
    this.#renumberItems()
  }

  onDptTypeChange() {
    // 출발지 유형 변경 시 코드 필드 초기화
    this.fieldDptCdTarget.value = ""
    this.fieldDptZipCdTarget.value = ""
    this.fieldDptAddrTarget.value = ""
  }

  onArvTypeChange() {
    // 도착지 유형 변경 시 코드 필드 초기화
    this.fieldArvCdTarget.value = ""
    this.fieldArvZipCdTarget.value = ""
    this.fieldArvAddrTarget.value = ""
  }

  // private
  #mode = "view"
  #currentOrderId = null
  #itemGridApi = null

  get #csrfToken() {
    return document.querySelector("[name='csrf-token']")?.content || ""
  }

  async #requestJson(url, method, body) {
    return fetch(url, {
      method,
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "X-CSRF-Token": this.#csrfToken
      },
      body: JSON.stringify(body)
    })
  }

  #loadOrderData(data) {
    this.#mode = data.cancel_yn === "Y" ? "view" : "edit"
    this.#currentOrderId = data.id
    const isCancelled = data.cancel_yn === "Y"

    // 헤더 읽기전용 필드
    this.fieldOrdNoTarget.value = data.ord_no || ""
    this.fieldOrdStatCdTarget.value = data.ord_stat_cd || ""
    this.fieldCreateTimeTarget.value = data.create_time || ""

    // 헤더 편집 필드
    this.fieldCtrtNoTarget.value = data.ctrt_no || ""
    this.fieldOrdTypeCdTarget.value = data.ord_type_cd || ""
    this.fieldBilgCustCdTarget.value = data.bilg_cust_cd || ""
    this.fieldCtrtCustCdTarget.value = data.ctrt_cust_cd || ""
    this.fieldOrdReasonCdTarget.value = data.ord_reason_cd || ""
    this.fieldOrdExecDeptCdTarget.value = data.ord_exec_dept_cd || ""
    this.fieldOrdExecDeptNmTarget.value = data.ord_exec_dept_nm || ""
    this.fieldOrdExecOfcrCdTarget.value = data.ord_exec_ofcr_cd || ""
    this.fieldOrdExecOfcrNmTarget.value = data.ord_exec_ofcr_nm || ""
    this.fieldRemkTarget.value = data.remk || ""

    // 출도착지
    this.fieldDptTypeCdTarget.value = data.dpt_type_cd || ""
    this.fieldDptCdTarget.value = data.dpt_cd || ""
    this.fieldDptZipCdTarget.value = data.dpt_zip_cd || ""
    this.fieldDptAddrTarget.value = data.dpt_addr || ""
    if (data.strt_req_ymd) {
      this.fieldStrtReqYmdTarget.value = this.#formatDateForInput(data.strt_req_ymd)
    } else {
      this.fieldStrtReqYmdTarget.value = ""
    }

    this.fieldArvTypeCdTarget.value = data.arv_type_cd || ""
    this.fieldArvCdTarget.value = data.arv_cd || ""
    this.fieldArvZipCdTarget.value = data.arv_zip_cd || ""
    this.fieldArvAddrTarget.value = data.arv_addr || ""
    if (data.aptd_req_dtm) {
      this.fieldAptdReqDtmTarget.value = this.#formatDateTimeForInput(data.aptd_req_dtm)
    } else {
      this.fieldAptdReqDtmTarget.value = ""
    }

    // 아이템
    if (this.#itemGridApi && data.items) {
      this.#itemGridApi.setGridOption("rowData", data.items)
    }

    this.#setFormDisabled(isCancelled)
  }

  #clearForm() {
    const targets = [
      "fieldOrdNo", "fieldOrdStatCd", "fieldCreateTime",
      "fieldCtrtNo", "fieldBilgCustCd", "fieldBilgCustNm",
      "fieldCtrtCustCd", "fieldCtrtCustNm",
      "fieldOrdExecDeptCd", "fieldOrdExecDeptNm",
      "fieldOrdExecOfcrCd", "fieldOrdExecOfcrNm", "fieldRemk",
      "fieldDptCd", "fieldDptZipCd", "fieldDptAddr", "fieldStrtReqYmd",
      "fieldArvCd", "fieldArvZipCd", "fieldArvAddr", "fieldAptdReqDtm"
    ]
    targets.forEach(name => {
      if (this[`has${name.charAt(0).toUpperCase() + name.slice(1)}Target`]) {
        this[`${name}Target`].value = ""
      }
    })

    // select 필드 초기화
    if (this.hasFieldOrdTypeCdTarget) this.fieldOrdTypeCdTarget.value = ""
    if (this.hasFieldOrdReasonCdTarget) this.fieldOrdReasonCdTarget.value = ""
    if (this.hasFieldDptTypeCdTarget) this.fieldDptTypeCdTarget.value = ""
    if (this.hasFieldArvTypeCdTarget) this.fieldArvTypeCdTarget.value = ""
  }

  #setFormDisabled(disabled) {
    const editableFields = [
      "fieldCtrtNo", "fieldOrdExecDeptCd", "fieldOrdExecDeptNm",
      "fieldOrdExecOfcrCd", "fieldOrdExecOfcrNm", "fieldRemk",
      "fieldDptCd", "fieldDptZipCd", "fieldDptAddr", "fieldStrtReqYmd",
      "fieldArvCd", "fieldArvZipCd", "fieldArvAddr", "fieldAptdReqDtm"
    ]
    const selectFields = [
      "fieldOrdTypeCd", "fieldOrdReasonCd", "fieldDptTypeCd", "fieldArvTypeCd"
    ]

    editableFields.forEach(name => {
      const targetName = `${name}Target`
      if (this[`has${name.charAt(0).toUpperCase() + name.slice(1)}Target`]) {
        this[targetName].disabled = disabled
      }
    })

    selectFields.forEach(name => {
      const targetName = `${name}Target`
      if (this[`has${name.charAt(0).toUpperCase() + name.slice(1)}Target`]) {
        this[targetName].disabled = disabled
      }
    })

    // 팝업 버튼
    if (this.hasBilgCustSearchBtnTarget) this.bilgCustSearchBtnTarget.disabled = disabled
    if (this.hasCtrtCustSearchBtnTarget) this.ctrtCustSearchBtnTarget.disabled = disabled
    // 고객코드 필드
    if (this.hasFieldBilgCustCdTarget) this.fieldBilgCustCdTarget.disabled = disabled
    if (this.hasFieldCtrtCustCdTarget) this.fieldCtrtCustCdTarget.disabled = disabled
  }

  #collectPayload() {
    const order = {
      ctrt_no: this.fieldCtrtNoTarget.value,
      ord_type_cd: this.fieldOrdTypeCdTarget.value,
      bilg_cust_cd: this.fieldBilgCustCdTarget.value,
      ctrt_cust_cd: this.fieldCtrtCustCdTarget.value,
      ord_reason_cd: this.fieldOrdReasonCdTarget.value,
      ord_exec_dept_cd: this.fieldOrdExecDeptCdTarget.value,
      ord_exec_dept_nm: this.fieldOrdExecDeptNmTarget.value,
      ord_exec_ofcr_cd: this.fieldOrdExecOfcrCdTarget.value,
      ord_exec_ofcr_nm: this.fieldOrdExecOfcrNmTarget.value,
      remk: this.fieldRemkTarget.value,
      dpt_type_cd: this.fieldDptTypeCdTarget.value,
      dpt_cd: this.fieldDptCdTarget.value,
      dpt_zip_cd: this.fieldDptZipCdTarget.value,
      dpt_addr: this.fieldDptAddrTarget.value,
      strt_req_ymd: this.#formatDateToYmd(this.fieldStrtReqYmdTarget.value),
      arv_type_cd: this.fieldArvTypeCdTarget.value,
      arv_cd: this.fieldArvCdTarget.value,
      arv_zip_cd: this.fieldArvZipCdTarget.value,
      arv_addr: this.fieldArvAddrTarget.value,
      aptd_req_dtm: this.#formatDateTimeToDtm(this.fieldAptdReqDtmTarget.value)
    }

    const items = []
    if (this.#itemGridApi) {
      this.#itemGridApi.forEachNode(node => {
        if (node.data.item_cd) {
          items.push(node.data)
        }
      })
    }

    return { order, items }
  }

  #renumberItems() {
    if (!this.#itemGridApi) return
    let seq = 1
    this.#itemGridApi.forEachNode(node => {
      node.setDataValue("seq_no", seq++)
    })
  }

  #formatDateForInput(ymd) {
    // YYYYMMDD -> YYYY-MM-DD
    if (!ymd) return ""
    if (ymd.length === 8) {
      return `${ymd.substring(0, 4)}-${ymd.substring(4, 6)}-${ymd.substring(6, 8)}`
    }
    return ymd
  }

  #formatDateTimeForInput(dtm) {
    // YYYYMMDDHHMMSS -> YYYY-MM-DDTHH:MM
    if (!dtm) return ""
    if (dtm.length >= 12) {
      return `${dtm.substring(0, 4)}-${dtm.substring(4, 6)}-${dtm.substring(6, 8)}T${dtm.substring(8, 10)}:${dtm.substring(10, 12)}`
    }
    return dtm
  }

  #formatDateToYmd(value) {
    // YYYY-MM-DD -> YYYYMMDD
    if (!value) return ""
    return value.replace(/-/g, "")
  }

  #formatDateTimeToDtm(value) {
    // YYYY-MM-DDTHH:MM -> YYYYMMDDHHMMSS
    if (!value) return ""
    return value.replace(/[-T:]/g, "").padEnd(14, "0")
  }
}
