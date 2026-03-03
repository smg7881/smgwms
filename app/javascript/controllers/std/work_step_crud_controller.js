import BaseGridController from "controllers/base_grid_controller"

export default class extends BaseGridController {
  static resourceName = "work_step"
  static deleteConfirmKey = "workStepNm"
  static entityLabel = "작업단계"

  static targets = [
    ...BaseGridController.targets,
    "overlay", "modal", "modalTitle", "form",
    "fieldId", "fieldWorkStepCd", "fieldWorkStepNm",
    "fieldWorkStepLevel1Cd", "fieldWorkStepLevel2Cd",
    "fieldSortSeq", "fieldContsCd", "fieldRmkCd"
  ]

  static values = {
    ...BaseGridController.values,
    createUrl: String,
    updateUrl: String,
    deleteUrl: String
  }

  connect() {
    super.connect()
    this.handleDelete = this.handleDelete.bind(this)
    this.connectBase({
      events: [
        { name: "std-work-step-crud:edit", handler: this.handleEdit },
        { name: "std-work-step-crud:delete", handler: this.handleDelete }
      ]
    })
  }

  disconnect() {
    this.disconnectBase()
    super.disconnect()
  }

  openCreate() {
    this.resetForm()
    this.modalTitleTarget.textContent = "기본작업단계 추가"
    this.mode = "create"
    this.fieldWorkStepCdTarget.readOnly = false
    this.setRadioValue("work_step[use_yn_cd]", "Y")
    this.openModal()
  }

  handleEdit = (event) => {
    const data = event.detail.workStepData || {}

    this.resetForm()
    this.modalTitleTarget.textContent = "기본작업단계 수정"
    this.mode = "update"

    this.fieldIdTarget.value = data.id || data.work_step_cd || ""
    this.fieldWorkStepCdTarget.value = data.work_step_cd || ""
    this.fieldWorkStepNmTarget.value = data.work_step_nm || ""
    this.fieldWorkStepLevel1CdTarget.value = data.work_step_level1_cd || ""
    this.fieldWorkStepLevel1CdTarget.dispatchEvent(new Event("change", { bubbles: true }))
    this.fieldWorkStepLevel2CdTarget.value = data.work_step_level2_cd || ""
    this.fieldSortSeqTarget.value = data.sort_seq ?? 0
    this.fieldContsCdTarget.value = data.conts_cd || ""
    this.fieldRmkCdTarget.value = data.rmk_cd || ""
    this.fieldWorkStepCdTarget.readOnly = true

    this.setRadioValue("work_step[use_yn_cd]", data.use_yn_cd || "Y")
    this.openModal()
  }

  resetForm() {
    this.formTarget.reset()
    this.fieldIdTarget.value = ""
    this.fieldWorkStepCdTarget.readOnly = false
    this.fieldSortSeqTarget.value = 0
    this.setRadioValue("work_step[use_yn_cd]", "Y")
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
}
