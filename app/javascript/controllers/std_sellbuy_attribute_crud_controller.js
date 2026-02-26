import BaseCrudController from "controllers/base_crud_controller"
import { showAlert, confirmAction } from "components/ui/alert"
import { getSearchFieldValue } from "controllers/grid/grid_utils"

export default class extends BaseCrudController {
  static resourceName = "sellbuy_attribute"
  static deleteConfirmKey = "sellbuyAttrNm"
  static entityLabel = "매출입항목"

  static targets = [
    "overlay", "modal", "modalTitle", "form",
    "fieldId", "fieldCorpCd", "fieldSellbuyAttrCd", "fieldUpperSellbuyAttrCd"
  ]

  static values = {
    createUrl: String,
    updateUrl: String,
    deleteUrl: String
  }

  connect() {
    this.connectBase({
      events: [
        { name: "std-sellbuy-attribute-crud:edit", handler: this.handleEdit },
        { name: "std-sellbuy-attribute-crud:delete", handler: this.handleDelete },
        { name: "search-popup:selected", handler: this.handlePopupSelected }
      ]
    })
  }

  disconnect() {
    this.disconnectBase()
  }

  openCreate() {
    this.resetForm()
    this.modalTitleTarget.textContent = "매출입항목 추가"
    this.mode = "create"
    this.fieldSellbuyAttrCdTarget.readOnly = true

    const selectedCorpCd = this.selectedCorpCodeFromSearch()
    if (selectedCorpCd && this.hasFieldCorpCdTarget) {
      this.fieldCorpCdTarget.value = selectedCorpCd
    }

    this.setFieldValue("use_yn_cd", "Y")
    this.setDefaultFlagValues()
    this.setAuditPreviewForCreate()
    this.syncPopupDisplaysFromCodes()
    this.openModal()
  }

  handleEdit = (event) => {
    const data = event.detail.sellbuyAttrData || {}

    this.resetForm()
    this.modalTitleTarget.textContent = "매출입항목 수정"
    this.mode = "update"

    const sellbuyAttrCd = data.sellbuy_attr_cd || data.id || ""
    this.fieldIdTarget.value = sellbuyAttrCd
    this.fieldSellbuyAttrCdTarget.value = sellbuyAttrCd
    this.fieldSellbuyAttrCdTarget.readOnly = true

    this.setFieldValue("corp_cd", data.corp_cd || "")
    this.setFieldValue("sellbuy_attr_nm", data.sellbuy_attr_nm || "")
    this.setFieldValue("rdtn_nm", data.rdtn_nm || "")
    this.setFieldValue("sellbuy_attr_eng_nm", data.sellbuy_attr_eng_nm || "")
    this.setFieldValue("upper_sellbuy_attr_cd", data.upper_sellbuy_attr_cd || "")
    this.setUpperSellbuyName(data.upper_sellbuy_attr_nm || "")

    this.setFieldValue("sell_yn_cd", data.sell_yn_cd || "N")
    this.setFieldValue("pur_yn_cd", data.pur_yn_cd || "N")
    this.setFieldValue("tran_yn_cd", data.tran_yn_cd || "N")
    this.setFieldValue("fis_air_yn_cd", data.fis_air_yn_cd || "N")
    this.setFieldValue("strg_yn_cd", data.strg_yn_cd || "N")
    this.setFieldValue("cgwrk_yn_cd", data.cgwrk_yn_cd || "N")
    this.setFieldValue("fis_shpng_yn_cd", data.fis_shpng_yn_cd || "N")
    this.setFieldValue("dc_extr_yn_cd", data.dc_extr_yn_cd || "N")
    this.setFieldValue("tax_payfor_yn_cd", data.tax_payfor_yn_cd || "N")
    this.setFieldValue("lumpsum_yn_cd", data.lumpsum_yn_cd || "N")
    this.setFieldValue("dcnct_reg_pms_yn_cd", data.dcnct_reg_pms_yn_cd || "N")
    this.setFieldValue("use_yn_cd", data.use_yn_cd || "Y")

    this.setFieldValue("sell_dr_acct_cd", data.sell_dr_acct_cd || "")
    this.setFieldValue("sell_cr_acct_cd", data.sell_cr_acct_cd || "")
    this.setFieldValue("pur_dr_acct_cd", data.pur_dr_acct_cd || "")
    this.setFieldValue("pur_cr_acct_cd", data.pur_cr_acct_cd || "")
    this.setFieldValue("sys_sctn_cd", data.sys_sctn_cd || "")
    this.setFieldValue("ndcsn_sell_cr_acct_cd", data.ndcsn_sell_cr_acct_cd || "")
    this.setFieldValue("ndcsn_cost_dr_acct_cd", data.ndcsn_cost_dr_acct_cd || "")
    this.setFieldValue("rmk_cd", data.rmk_cd || "")
    this.setAuditValues(data)

    this.syncPopupDisplaysFromCodes()
    this.openModal()
  }

  resetForm() {
    this.formTarget.reset()
    this.fieldIdTarget.value = ""
    this.fieldSellbuyAttrCdTarget.value = ""
    this.fieldSellbuyAttrCdTarget.readOnly = true
    this.setDefaultFlagValues()
    this.setFieldValue("use_yn_cd", "Y")
    this.setFieldValue("upper_sellbuy_attr_nm", "")
    this.setFieldValue("create_by", "")
    this.setFieldValue("create_time", "")
    this.setFieldValue("update_by", "")
    this.setFieldValue("update_time", "")
    this.syncPopupDisplaysFromCodes()
  }

  selectedCorpCodeFromSearch() {
    getSearchFieldValue(this.element, "corp_cd")
  }

  handlePopupSelected = (event) => {
    const fieldGroup = event.target?.closest?.("[data-field-name]")
    if (!fieldGroup) return
    if (fieldGroup.dataset.fieldName !== "upper_sellbuy_attr_cd") return

    const selectedCode = this.normalizeCode(event.detail?.code || event.detail?.sellbuy_attr_cd)
    const selectedName = this.normalizeName(event.detail?.name || event.detail?.sellbuy_attr_nm || event.detail?.display)
    const currentCode = this.normalizeCode(this.fieldSellbuyAttrCdTarget?.value)

    if (!selectedCode) {
      this.clearUpperSellbuyAttrField(fieldGroup)
      return
    }

    if (selectedCode === currentCode) {
      showAlert("상위매출입항목은 자기 자신을 선택할 수 없습니다.")
      this.clearUpperSellbuyAttrField(fieldGroup)
      return
    }

    this.setUpperSellbuyName(selectedName)
  }

  async save() {
    const sellbuyAttrCd = this.normalizeCode(this.fieldSellbuyAttrCdTarget?.value)
    const upperSellbuyAttrCd = this.normalizeCode(this.fieldUpperSellbuyAttrCdTarget?.value)

    if (!upperSellbuyAttrCd) {
      this.setUpperSellbuyName("")
    }

    if (sellbuyAttrCd && upperSellbuyAttrCd && sellbuyAttrCd === upperSellbuyAttrCd) {
      showAlert("상위매출입항목코드는 자기 자신과 같을 수 없습니다.")
      this.clearUpperSellbuyAttrField()
      return
    }

    await super.save()
  }

  setFieldValue(fieldName, value) {
    const input = this.formTarget.querySelector(`[name='sellbuy_attribute[${fieldName}]']`)
    if (!input) return

    input.value = value
  }

  setDefaultFlagValues() {
    this.setFieldValue("sell_yn_cd", "N")
    this.setFieldValue("pur_yn_cd", "N")
    this.setFieldValue("tran_yn_cd", "N")
    this.setFieldValue("fis_air_yn_cd", "N")
    this.setFieldValue("strg_yn_cd", "N")
    this.setFieldValue("cgwrk_yn_cd", "N")
    this.setFieldValue("fis_shpng_yn_cd", "N")
    this.setFieldValue("dc_extr_yn_cd", "N")
    this.setFieldValue("tax_payfor_yn_cd", "N")
    this.setFieldValue("lumpsum_yn_cd", "N")
    this.setFieldValue("dcnct_reg_pms_yn_cd", "N")
  }

  setAuditPreviewForCreate() {
    const nowText = this.formatDateTime(new Date())
    const actor = this.currentActor()
    this.setFieldValue("create_by", actor)
    this.setFieldValue("create_time", nowText)
    this.setFieldValue("update_by", actor)
    this.setFieldValue("update_time", nowText)
  }

  setAuditValues(data) {
    this.setFieldValue("create_by", data.create_by || "")
    this.setFieldValue("create_time", this.formatDateTime(data.create_time))
    this.setFieldValue("update_by", data.update_by || "")
    this.setFieldValue("update_time", this.formatDateTime(data.update_time))
  }

  setUpperSellbuyName(name) {
    this.setFieldValue("upper_sellbuy_attr_nm", this.normalizeName(name))
  }

  clearUpperSellbuyAttrField(fieldGroup = null) {
    if (this.hasFieldUpperSellbuyAttrCdTarget) {
      this.fieldUpperSellbuyAttrCdTarget.value = ""
      this.fieldUpperSellbuyAttrCdTarget.dispatchEvent(new Event("change", { bubbles: true }))
    }
    this.setUpperSellbuyName("")

    const group = fieldGroup || this.element.querySelector("[data-field-name='upper_sellbuy_attr_cd']")
    if (!group) return

    const codeDisplay = group.querySelector("[data-search-popup-target='codeDisplay']")
    const displayInput = group.querySelector("[data-search-popup-target='display']")
    if (codeDisplay) {
      codeDisplay.value = ""
    }
    if (displayInput) {
      displayInput.value = ""
      displayInput.dispatchEvent(new Event("change", { bubbles: true }))
    }
  }

  syncPopupDisplaysFromCodes() {
    const wrappers = this.element.querySelectorAll("[data-controller~='search-popup']")
    wrappers.forEach((wrapper) => {
      const codeInput = wrapper.querySelector("[data-search-popup-target='code']")
      const codeDisplay = wrapper.querySelector("[data-search-popup-target='codeDisplay']")
      const displayInput = wrapper.querySelector("[data-search-popup-target='display']")
      if (!codeInput) return

      const codeValue = String(codeInput.value || "").trim()
      if (codeDisplay) {
        codeDisplay.value = codeValue
      }
      if (displayInput && String(displayInput.value || "").trim() === "") {
        displayInput.value = codeValue
      }
    })
  }

  normalizeCode(value) {
    return String(value || "").trim().toUpperCase()
  }

  normalizeName(value) {
    return String(value || "").trim()
  }

  formatDateTime(value) {
    if (!value) return ""

    const date = value instanceof Date ? value : new Date(value)
    if (Number.isNaN(date.getTime())) {
      return String(value)
    }

    const year = date.getFullYear()
    const month = String(date.getMonth() + 1).padStart(2, "0")
    const day = String(date.getDate()).padStart(2, "0")
    const hour = String(date.getHours()).padStart(2, "0")
    const minute = String(date.getMinutes()).padStart(2, "0")
    const second = String(date.getSeconds()).padStart(2, "0")
    return `${year}-${month}-${day} ${hour}:${minute}:${second}`
  }

  currentActor() {
    const userLabel = document.querySelector(".sidebar .text-text-muted")
    const value = String(userLabel?.textContent || "").trim()
    if (value) return value

    return "현재로그인사용자"
  }
}
