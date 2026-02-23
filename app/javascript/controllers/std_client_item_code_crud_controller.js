import BaseCrudController from "controllers/base_crud_controller"

export default class extends BaseCrudController {
  static resourceName = "client_item_code"
  static deleteConfirmKey = "itemCd"
  static entityLabel = "거래처별아이템코드"

  static targets = [
    "overlay", "modal", "modalTitle", "form",
    "fieldId", "fieldItemCd", "fieldBzacCd", "fieldBzacNm",
    "fieldGoodsnmCd", "fieldGoodsnmNm"
  ]

  static values = {
    createUrl: String,
    updateUrl: String,
    deleteUrl: String
  }

  connect() {
    this.connectBase({
      events: [
        { name: "std-client-item-code-crud:edit", handler: this.handleEdit },
        { name: "std-client-item-code-crud:delete", handler: this.handleDelete },
        { name: "search-popup:selected", handler: this.handlePopupSelected }
      ]
    })
  }

  disconnect() {
    this.disconnectBase()
  }

  openCreate() {
    this.resetForm()
    this.modalTitleTarget.textContent = "거래처별아이템코드 추가"
    this.mode = "create"
    this.fieldItemCdTarget.readOnly = false

    this.setFieldValue("use_yn_cd", "Y")
    this.setFieldValue("danger_yn_cd", "N")
    this.setFieldValue("png_yn_cd", "N")
    this.setFieldValue("mstair_lading_yn_cd", "N")
    this.setFieldValue("if_yn_cd", "N")

    const selectedBzacCd = this.selectedClientCodeFromSearch()
    if (selectedBzacCd && this.hasFieldBzacCdTarget) {
      this.fieldBzacCdTarget.value = selectedBzacCd
      this.fieldBzacCdTarget.dispatchEvent(new Event("change", { bubbles: true }))
    }

    this.setAuditPreviewForCreate()
    this.syncPopupDisplaysFromCodes()
    this.openModal()
  }

  handleEdit = (event) => {
    const data = event.detail.clientItemCodeData || {}

    this.resetForm()
    this.modalTitleTarget.textContent = "거래처별아이템코드 수정"
    this.mode = "update"

    this.fieldIdTarget.value = data.id || ""
    this.fieldItemCdTarget.value = data.item_cd || ""
    this.fieldItemCdTarget.readOnly = true

    this.setFieldValue("item_nm", data.item_nm || "")
    this.setFieldValue("bzac_cd", data.bzac_cd || "")
    this.setFieldValue("bzac_nm", data.bzac_nm || "")
    this.setFieldValue("goodsnm_cd", data.goodsnm_cd || "")
    this.setFieldValue("goodsnm_nm", data.goodsnm_nm || "")

    this.setFieldValue("danger_yn_cd", data.danger_yn_cd || "N")
    this.setFieldValue("png_yn_cd", data.png_yn_cd || "N")
    this.setFieldValue("mstair_lading_yn_cd", data.mstair_lading_yn_cd || "N")
    this.setFieldValue("if_yn_cd", data.if_yn_cd || "N")
    this.setFieldValue("wgt_unit_cd", data.wgt_unit_cd || "")
    this.setFieldValue("qty_unit_cd", data.qty_unit_cd || "")
    this.setFieldValue("tmpt_unit_cd", data.tmpt_unit_cd || "")
    this.setFieldValue("vol_unit_cd", data.vol_unit_cd || "")
    this.setFieldValue("basis_unit_cd", data.basis_unit_cd || "")
    this.setFieldValue("len_unit_cd", data.len_unit_cd || "")
    this.setFieldValue("pckg_qty", data.pckg_qty ?? "")
    this.setFieldValue("tot_wgt_kg", data.tot_wgt_kg ?? "")
    this.setFieldValue("net_wgt_kg", data.net_wgt_kg ?? "")
    this.setFieldValue("vessel_tmpt_c", data.vessel_tmpt_c ?? "")
    this.setFieldValue("vessel_width_m", data.vessel_width_m ?? "")
    this.setFieldValue("vessel_vert_m", data.vessel_vert_m ?? "")
    this.setFieldValue("vessel_hght_m", data.vessel_hght_m ?? "")
    this.setFieldValue("vessel_vol_cbm", data.vessel_vol_cbm ?? "")
    this.setFieldValue("use_yn_cd", data.use_yn_cd || "Y")
    this.setFieldValue("prod_nm_cd", data.prod_nm_cd || "")

    this.setAuditValues(data)
    this.syncPopupDisplaysFromCodes()
    this.openModal()
  }

  handlePopupSelected = (event) => {
    const fieldGroup = event.target?.closest?.("[data-field-name]")
    if (!fieldGroup) return

    const fieldName = fieldGroup.dataset.fieldName
    const displayName = String(event.detail?.name ?? event.detail?.display ?? "").trim()
    if (fieldName === "bzac_cd") {
      this.setFieldValue("bzac_nm", displayName)
      return
    }

    if (fieldName === "goodsnm_cd") {
      this.setFieldValue("goodsnm_nm", displayName)
    }
  }

  resetForm() {
    this.formTarget.reset()
    this.fieldIdTarget.value = ""
    this.fieldItemCdTarget.readOnly = false
    this.setFieldValue("bzac_nm", "")
    this.setFieldValue("goodsnm_nm", "")
    this.setFieldValue("danger_yn_cd", "N")
    this.setFieldValue("png_yn_cd", "N")
    this.setFieldValue("mstair_lading_yn_cd", "N")
    this.setFieldValue("if_yn_cd", "N")
    this.setFieldValue("use_yn_cd", "Y")
    this.setFieldValue("regr_nm_cd", "")
    this.setFieldValue("reg_date", "")
    this.setFieldValue("mdfr_nm_cd", "")
    this.setFieldValue("chgdt", "")
    this.syncPopupDisplaysFromCodes()
  }

  selectedClientCodeFromSearch() {
    const input = this.element.querySelector("input[name='q[bzac_cd]']")
    if (!input) return ""

    return String(input.value || "").trim().toUpperCase()
  }

  setFieldValue(fieldName, value) {
    const input = this.formTarget.querySelector(`[name='client_item_code[${fieldName}]']`)
    if (!input) return

    input.value = value
  }

  setAuditPreviewForCreate() {
    const nowText = this.formatDateTime(new Date())
    const actor = this.currentActor()
    this.setFieldValue("regr_nm_cd", actor)
    this.setFieldValue("reg_date", nowText)
    this.setFieldValue("mdfr_nm_cd", actor)
    this.setFieldValue("chgdt", nowText)
  }

  setAuditValues(data) {
    this.setFieldValue("regr_nm_cd", data.regr_nm_cd || "")
    this.setFieldValue("reg_date", this.formatDateTime(data.reg_date))
    this.setFieldValue("mdfr_nm_cd", data.mdfr_nm_cd || "")
    this.setFieldValue("chgdt", this.formatDateTime(data.chgdt))
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
