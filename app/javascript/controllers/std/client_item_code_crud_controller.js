import BaseGridController from "controllers/base_grid_controller"

export default class extends BaseGridController {
  static resourceName = "client_item_code"
  static deleteConfirmKey = "itemCd"
  static entityLabel = "거래처별아이템코드"

  static targets = [
    ...BaseGridController.targets,
    "overlay", "modal", "modalTitle", "form",
    "fieldId", "fieldItemCd", "fieldBzacCd", "fieldGoodsnmCd"
  ]

  static values = {
    ...BaseGridController.values,
    createUrl: String,
    updateUrl: String,
    deleteUrl: String
  }

  connect() {
    super.connect()
    // handleDelete는 ModalMixin에서 일반 메서드로 정의되어 있으므로 this 바인딩이 필요합니다.
    this.handleDelete = this.handleDelete.bind(this)
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
    super.disconnect()
  }

  openCreate() {
    this.resetForm()
    this.modalTitleTarget.textContent = "거래처별아이템코드 추가"
    this.mode = "create"
    this.fieldItemCdTarget.readOnly = false

    this.setFieldValues({
      use_yn_cd: "Y",
      ...this.defaultYnFlags()
    })

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

    this.setFieldValues({
      item_nm: data.item_nm || "",
      bzac_cd: data.bzac_cd || "",
      bzac_lookup: data.bzac_nm || data.bzac_cd || "",
      goodsnm_cd: data.goodsnm_cd || "",
      goods_lookup: data.goodsnm_nm || data.goodsnm_cd || "",
      ...this.defaultYnFlags(data),
      wgt_unit_cd: data.wgt_unit_cd || "",
      qty_unit_cd: data.qty_unit_cd || "",
      tmpt_unit_cd: data.tmpt_unit_cd || "",
      vol_unit_cd: data.vol_unit_cd || "",
      basis_unit_cd: data.basis_unit_cd || "",
      len_unit_cd: data.len_unit_cd || "",
      pckg_qty: data.pckg_qty ?? "",
      tot_wgt_kg: data.tot_wgt_kg ?? "",
      net_wgt_kg: data.net_wgt_kg ?? "",
      vessel_tmpt_c: data.vessel_tmpt_c ?? "",
      vessel_width_m: data.vessel_width_m ?? "",
      vessel_vert_m: data.vessel_vert_m ?? "",
      vessel_hght_m: data.vessel_hght_m ?? "",
      vessel_vol_cbm: data.vessel_vol_cbm ?? "",
      use_yn_cd: data.use_yn_cd || "Y",
      prod_nm_cd: data.prod_nm_cd || ""
    })

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
      this.setFieldValue("bzac_lookup", displayName)
      return
    }

    if (fieldName === "goodsnm_cd") {
      this.setFieldValue("goods_lookup", displayName)
    }
  }

  resetForm() {
    this.formTarget.reset()
    this.fieldIdTarget.value = ""
    this.fieldItemCdTarget.readOnly = false
    this.setFieldValues({
      bzac_lookup: "",
      goods_lookup: "",
      ...this.defaultYnFlags(),
      use_yn_cd: "Y",
      regr_nm_cd: "",
      reg_date: "",
      mdfr_nm_cd: "",
      chgdt: ""
    })
    this.syncPopupDisplaysFromCodes()
  }

  selectedClientCodeFromSearch() {
    return this.getSearchFormValue("bzac_cd")
  }

  defaultYnFlags(data = {}) {
    return {
      danger_yn_cd: data.danger_yn_cd || "N",
      png_yn_cd: data.png_yn_cd || "N",
      mstair_lading_yn_cd: data.mstair_lading_yn_cd || "N",
      if_yn_cd: data.if_yn_cd || "N"
    }
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

  currentActor() {
    const userLabel = document.querySelector(".sidebar .text-text-muted")
    const value = String(userLabel?.textContent || "").trim()
    if (value) return value

    return "현재로그인사용자"
  }
}
