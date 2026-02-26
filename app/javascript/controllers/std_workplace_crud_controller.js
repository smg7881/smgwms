import BaseCrudController from "controllers/base_crud_controller"
import { showAlert, confirmAction } from "components/ui/alert"

export default class extends BaseCrudController {
  static resourceName = "workplace"
  static deleteConfirmKey = "workplNm"
  static entityLabel = "작업장"

  static targets = [
    "overlay", "modal", "modalTitle", "form",
    "fieldId", "fieldCorpCd", "fieldWorkplCd", "fieldWorkplNm",
    "fieldUpperWorkplCd", "fieldDeptCd", "fieldWorkplSctnCd",
    "fieldCapaSpecUnitCd", "fieldMaxCapa", "fieldAdptCapa",
    "fieldDimemSpecUnitCd", "fieldDimem", "fieldBzacCd",
    "fieldCtryCd", "fieldZipCd", "fieldAddrCd", "fieldDtlAddrCd",
    "fieldRemkCd"
  ]

  static values = {
    createUrl: String,
    updateUrl: String,
    deleteUrl: String
  }

  connect() {
    this.connectBase({
      events: [
        { name: "std-workplace-crud:edit", handler: this.handleEdit },
        { name: "std-workplace-crud:delete", handler: this.handleDelete },
        { name: "search-popup:selected", handler: this.handlePopupSelected }
      ]
    })
  }

  disconnect() {
    this.disconnectBase()
  }

  openCreate() {
    this.resetForm()
    this.modalTitleTarget.textContent = "작업장관리 추가"
    this.mode = "create"
    this.fieldWorkplCdTarget.readOnly = false

    const corpCd = this.selectedCorpCodeFromSearch()
    if (corpCd) {
      this.fieldCorpCdTarget.value = corpCd
    }

    this.setRadioValue("workplace[wm_yn_cd]", "N")
    this.setRadioValue("workplace[use_yn_cd]", "Y")
    this.syncPopupDisplaysFromCodes()
    this.openModal()
  }

  handleEdit = (event) => {
    const data = event.detail.workplaceData || {}

    this.resetForm()
    this.modalTitleTarget.textContent = "작업장관리 수정"
    this.mode = "update"

    this.fieldIdTarget.value = data.id || data.workpl_cd || ""
    this.fieldCorpCdTarget.value = data.corp_cd || ""
    this.fieldWorkplCdTarget.value = data.workpl_cd || ""
    this.fieldWorkplNmTarget.value = data.workpl_nm || ""
    this.fieldUpperWorkplCdTarget.value = data.upper_workpl_cd || ""
    this.fieldDeptCdTarget.value = data.dept_cd || ""
    this.fieldWorkplSctnCdTarget.value = data.workpl_sctn_cd || ""
    this.fieldCapaSpecUnitCdTarget.value = data.capa_spec_unit_cd || ""
    this.fieldMaxCapaTarget.value = data.max_capa ?? ""
    this.fieldAdptCapaTarget.value = data.adpt_capa ?? ""
    this.fieldDimemSpecUnitCdTarget.value = data.dimem_spec_unit_cd || ""
    this.fieldDimemTarget.value = data.dimem ?? ""
    this.fieldBzacCdTarget.value = data.bzac_cd || ""
    this.fieldCtryCdTarget.value = data.ctry_cd || ""
    this.fieldZipCdTarget.value = data.zip_cd || ""
    this.fieldAddrCdTarget.value = data.addr_cd || ""
    this.fieldDtlAddrCdTarget.value = data.dtl_addr_cd || ""
    this.fieldRemkCdTarget.value = data.remk_cd || ""
    this.fieldWorkplCdTarget.readOnly = true

    this.setRadioValue("workplace[wm_yn_cd]", data.wm_yn_cd || "N")
    this.setRadioValue("workplace[use_yn_cd]", data.use_yn_cd || "Y")
    this.syncPopupDisplaysFromCodes()
    this.openModal()
  }

  resetForm() {
    this.formTarget.reset()
    this.fieldIdTarget.value = ""
    this.fieldWorkplCdTarget.readOnly = false
    this.fieldCtryCdTarget.value = "KR"
    this.setRadioValue("workplace[wm_yn_cd]", "N")
    this.setRadioValue("workplace[use_yn_cd]", "Y")
    this.syncPopupDisplaysFromCodes()
  }

  selectedCorpCodeFromSearch() {
    const input = this.element.querySelector("input[name='q[corp_cd]']")
    if (!input) return ""

    return String(input.value || "").trim().toUpperCase()
  }

  setRadioValue(fieldName, value) {
    const radios = this.formTarget.querySelectorAll(`input[type='radio'][name='${fieldName}']`)
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

  handlePopupSelected = (event) => {
    const fieldGroup = event.target?.closest?.("[data-field-name]")
    if (!fieldGroup) return
    if (fieldGroup.dataset.fieldName !== "upper_workpl_cd") return

    const selectedCode = this.normalizeCode(event.detail?.code)
    const workplCd = this.normalizeCode(this.fieldWorkplCdTarget?.value)
    if (!selectedCode || !workplCd) return

    if (selectedCode === workplCd) {
      showAlert("상위작업장은 현재 작업장과 동일하게 선택할 수 없습니다.")
      this.clearUpperWorkplaceField(fieldGroup)
    }
  }

  async save() {
    const workplCd = this.normalizeCode(this.fieldWorkplCdTarget?.value)
    const upperWorkplCd = this.normalizeCode(this.fieldUpperWorkplCdTarget?.value)
    if (workplCd && upperWorkplCd && workplCd === upperWorkplCd) {
      showAlert("상위작업장은 현재 작업장과 동일하게 저장할 수 없습니다.")
      this.clearUpperWorkplaceField()
      return
    }

    await super.save()
  }

  normalizeCode(value) {
    return String(value || "").trim().toUpperCase()
  }

  clearUpperWorkplaceField(fieldGroup = null) {
    if (this.hasFieldUpperWorkplCdTarget) {
      this.fieldUpperWorkplCdTarget.value = ""
      this.fieldUpperWorkplCdTarget.dispatchEvent(new Event("change", { bubbles: true }))
    }

    const group = fieldGroup || this.element.querySelector("[data-field-name='upper_workpl_cd']")
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
}
