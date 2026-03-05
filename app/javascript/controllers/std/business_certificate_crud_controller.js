import BaseGridController from "controllers/base_grid_controller"
import { showAlert } from "components/ui/alert"
import { AttachmentMixin } from "controllers/concerns/attachment_mixin"

class BusinessCertificateCrudController extends BaseGridController {
  static resourceName = "business_certificate"
  static deleteConfirmKey = "bzacNm"
  static entityLabel = "사업자등록증"

  static targets = [
    ...BaseGridController.targets,
    "overlay", "modal", "modalTitle", "form",
    "fieldId", "fieldBzacCd", "fieldCompregSlip", "fieldBizmanYnCd",
    "fieldStoreNmCd", "fieldRptrNmCd", "fieldCorpRegNoCd", "fieldBizcondCd",
    "fieldIndstypeCd", "fieldZipCd", "fieldZipaddrCd",
    "fieldDtlAddrCd", "fieldClbizYmd", "fieldRmk",
    "fieldCreateBy", "fieldCreateTime", "fieldUpdateBy", "fieldUpdateTime",
    "fieldAttachments", "existingFiles", "selectedFiles"
  ]

  static values = {
    ...BaseGridController.values,
    createUrl: String,
    updateUrl: String,
    deleteUrl: String,
    clientDefaultsUrl: String
  }

  connect() {
    super.connect()
    this.initAttachment()
    this.handleDelete = this.handleDelete.bind(this)
    this.connectBase({
      events: [
        { name: "std-business-certificate-crud:edit", handler: this.handleEdit },
        { name: "std-business-certificate-crud:delete", handler: this.handleDelete },
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
    this.modalTitleTarget.textContent = "사업자등록증 등록"
    this.mode = "create"
    this.fieldBzacCdTarget.readOnly = false

    const selectedBzacCd = this.selectedClientCodeFromSearch()
    if (selectedBzacCd) {
      this.fieldBzacCdTarget.value = selectedBzacCd
    }

    const selectedBzacNm = this.selectedClientNameFromSearch()
    if (selectedBzacNm) {
      this.setScopedFieldValue("bzac_lookup", selectedBzacNm)
    }

    if (selectedBzacCd) {
      this.fetchClientDefaults(selectedBzacCd, { fallbackName: selectedBzacNm })
    }

    this.setAuditPreviewForCreate()
    this.syncPopupDisplaysFromCodes()
    this.openModal()
  }

  handleEdit = async (event) => {
    const id = String(event.detail.id || "").trim()
    if (!id) return

    this.resetForm()
    this.modalTitleTarget.textContent = "사업자등록증 수정"
    this.mode = "update"
    this.fieldBzacCdTarget.readOnly = true

    try {
      const response = await fetch(this.updateUrlValue.replace(":id", id), {
        headers: { Accept: "application/json" }
      })
      if (!response.ok) {
        showAlert("상세 조회에 실패했습니다.")
        return
      }

      const data = await response.json()
      this.fillForm(data)
      this.openModal()
    } catch {
      showAlert("상세 조회에 실패했습니다.")
    }
  }

  fillForm(data) {
    this.fieldIdTarget.value = data.id || data.bzac_cd || ""
    this.fieldBzacCdTarget.value = data.bzac_cd || ""
    this.fieldCompregSlipTarget.value = data.compreg_slip || ""
    this.fieldBizmanYnCdTarget.value = data.bizman_yn_cd || "BUSINESS"
    this.fieldStoreNmCdTarget.value = data.store_nm_cd || ""
    this.fieldRptrNmCdTarget.value = data.rptr_nm_cd || ""
    this.fieldCorpRegNoCdTarget.value = data.corp_reg_no_cd || ""
    this.fieldBizcondCdTarget.value = data.bizcond_cd || ""
    this.fieldIndstypeCdTarget.value = data.indstype_cd || ""
    this.setRadioValue("dup_bzac_yn_cd", data.dup_bzac_yn_cd || "N")
    this.fieldZipCdTarget.value = data.zip_cd || ""
    this.fieldZipaddrCdTarget.value = data.zipaddr_cd || ""
    this.fieldDtlAddrCdTarget.value = data.dtl_addr_cd || ""
    this.fieldClbizYmdTarget.value = data.clbiz_ymd || ""
    this.setRadioValue("use_yn_cd", data.use_yn_cd || "Y")
    this.fieldRmkTarget.value = data.rmk || ""
    this.fieldCreateByTarget.value = data.create_by || ""
    this.fieldCreateTimeTarget.value = this.formatDateTime(data.create_time)
    this.fieldUpdateByTarget.value = data.update_by || ""
    this.fieldUpdateTimeTarget.value = this.formatDateTime(data.update_time)

    this.setScopedFieldValue("bzac_lookup", data.bzac_nm || "")
    this.setScopedFieldValue("zip_lookup", data.zipaddr_cd || "")

    this.renderExistingFiles(data.attachments || [])
    this.renderSelectedFiles()
    this.syncPopupDisplaysFromCodes()
  }

  resetForm() {
    this.formTarget.reset()
    this.fieldIdTarget.value = ""
    this.fieldBzacCdTarget.readOnly = false
    this.fieldBizmanYnCdTarget.value = "BUSINESS"
    this.setRadioValue("dup_bzac_yn_cd", "N")
    this.setRadioValue("use_yn_cd", "Y")
    this.fieldCreateByTarget.value = ""
    this.fieldCreateTimeTarget.value = ""
    this.fieldUpdateByTarget.value = ""
    this.fieldUpdateTimeTarget.value = ""
    this.setScopedFieldValue("bzac_lookup", "")
    this.setScopedFieldValue("zip_lookup", "")
    this.resetAttachment()
    this.syncPopupDisplaysFromCodes()
  }

  selectedClientCodeFromSearch() {
    return this.getSearchFormValue("bzac_cd")
  }

  selectedClientNameFromSearch() {
    return this.getSearchFormValue("bzac_nm", { toUpperCase: false })
  }

  handlePopupSelected = (event) => {
    const fieldGroup = event.target?.closest?.("[data-field-name]")
    if (!fieldGroup) return

    const fieldName = fieldGroup.dataset.fieldName
    if (fieldName === "bzac_cd") {
      const selectedCode = String(event.detail?.code ?? this.fieldBzacCdTarget?.value ?? "").trim().toUpperCase()
      const selectedName = String(event.detail?.name ?? event.detail?.display ?? "").trim()
      this.setScopedFieldValue("bzac_lookup", selectedName)
      if (selectedCode) {
        this.fetchClientDefaults(selectedCode, { fallbackName: selectedName })
      }
      return
    }

    if (fieldName === "zip_cd") {
      const selectedName = String(event.detail?.name ?? event.detail?.display ?? "").trim()
      if (!selectedName) return
      this.setScopedFieldValue("zip_lookup", selectedName)
      this.fieldZipaddrCdTarget.value = selectedName
    }
  }

  async fetchClientDefaults(bzacCd, { fallbackName = "" } = {}) {
    if (!this.hasClientDefaultsUrlValue) return

    const normalizedCode = String(bzacCd || "").trim().toUpperCase()
    if (!normalizedCode) return

    const requestUrl = `${this.clientDefaultsUrlValue}?bzac_cd=${encodeURIComponent(normalizedCode)}`

    try {
      const response = await fetch(requestUrl, { headers: { Accept: "application/json" } })
      if (!response.ok) {
        showAlert("거래처 기본정보 조회에 실패했습니다.")
        return
      }

      const result = await response.json()
      if (!result.success || !result.defaults) {
        showAlert((result.errors || ["거래처 기본정보 조회에 실패했습니다."]).join(", "))
        return
      }

      this.applyClientDefaults(result.defaults, { fallbackName })
    } catch {
      showAlert("거래처 기본정보 조회에 실패했습니다.")
    }
  }

  applyClientDefaults(defaults, { fallbackName = "" } = {}) {
    this.fieldBzacCdTarget.value = defaults.bzac_cd || this.fieldBzacCdTarget.value || ""
    this.fieldCompregSlipTarget.value = defaults.compreg_slip || ""
    this.fieldBizmanYnCdTarget.value = defaults.bizman_yn_cd || "BUSINESS"
    this.fieldStoreNmCdTarget.value = defaults.store_nm_cd || ""
    this.fieldRptrNmCdTarget.value = defaults.rptr_nm_cd || ""
    this.fieldCorpRegNoCdTarget.value = defaults.corp_reg_no_cd || ""
    this.fieldBizcondCdTarget.value = defaults.bizcond_cd || ""
    this.fieldIndstypeCdTarget.value = defaults.indstype_cd || ""
    this.setRadioValue("dup_bzac_yn_cd", defaults.dup_bzac_yn_cd || "N")
    this.fieldZipCdTarget.value = defaults.zip_cd || ""
    this.fieldZipaddrCdTarget.value = defaults.zipaddr_cd || ""
    this.fieldDtlAddrCdTarget.value = defaults.dtl_addr_cd || ""
    this.setRadioValue("use_yn_cd", defaults.use_yn_cd || "Y")

    const lookupName = String(defaults.bzac_nm || fallbackName || "").trim()
    if (lookupName) {
      this.setScopedFieldValue("bzac_lookup", lookupName)
    }
    this.setScopedFieldValue("zip_lookup", defaults.zipaddr_cd || "")
    this.syncPopupDisplaysFromCodes()
  }

  formScopeKey() {
    const candidateName = this.hasFieldBzacCdTarget
      ? this.fieldBzacCdTarget.name
      : this.formTarget.querySelector("[name*='[']")?.name

    const match = String(candidateName || "").match(/^([^\[]+)\[/)
    if (match) {
      return match[1]
    }

    return this.constructor.resourceName
  }

  setScopedFieldValue(fieldName, value) {
    if (!this.hasFormTarget) return

    const input = this.formTarget.querySelector(`[name$='[${fieldName}]']`)
    if (!input) return

    input.value = value == null ? "" : value
  }

  setRadioValue(fieldName, value) {
    if (!this.hasFormTarget) return

    const radios = this.formTarget.querySelectorAll(`input[type='radio'][name$='[${fieldName}]']`)
    if (radios.length === 0) return

    const normalized = String(value || "").trim().toUpperCase()
    let matched = false
    radios.forEach((radio) => {
      const isMatch = radio.value === normalized
      radio.checked = isMatch
      if (isMatch) {
        matched = true
      }
    })

    if (!matched) {
      radios[0].checked = true
    }
  }

  async save() {
    const formData = new FormData(this.formTarget)
    const scope = this.formScopeKey()
    this.appendRemovedAttachmentIds(formData, scope)

    const id = this.hasFieldIdTarget && this.fieldIdTarget.value ? this.fieldIdTarget.value : null
    const isCreate = this.mode === "create"
    const url = isCreate ? this.createUrlValue : this.updateUrlValue.replace(":id", id)
    const method = isCreate ? "POST" : "PATCH"

    try {
      const { response, result } = await this.requestJson(url, {
        method,
        body: formData,
        isMultipart: true
      })

      if (!response.ok || !result.success) {
        showAlert("저장 실패: " + (result.errors || ["요청 처리 실패"]).join(", "))
        return
      }

      showAlert(result.message || "저장되었습니다.")
      this.closeModal()
      this._refreshModalGrid()
    } catch {
      showAlert("저장 실패: 네트워크 오류")
    }
  }

  setAuditPreviewForCreate() {
    const actor = this.currentActor()
    const nowText = this.formatDateTime(new Date())
    this.fieldCreateByTarget.value = actor
    this.fieldCreateTimeTarget.value = nowText
    this.fieldUpdateByTarget.value = actor
    this.fieldUpdateTimeTarget.value = nowText
  }

  currentActor() {
    const userLabel = document.querySelector(".sidebar .text-text-muted")
    const value = String(userLabel?.textContent || "").trim()
    if (value) {
      return value
    }

    return "현재로그인사용자"
  }
}

Object.assign(BusinessCertificateCrudController.prototype, AttachmentMixin)

export default BusinessCertificateCrudController
