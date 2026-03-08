import BaseGridController from "controllers/base_grid_controller"
import { setResourceFormValue } from "controllers/grid/core/resource_form_bridge"

export default class extends BaseGridController {
  static resourceName = "std_work_step"
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
    this.setRadioValue("use_yn_cd", "Y")
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

    this.setRadioValue("use_yn_cd", data.use_yn_cd || "Y")
    this.openModal()
  }

  resetForm() {
    this.formTarget.reset()
    this.fieldIdTarget.value = ""
    this.fieldWorkStepCdTarget.readOnly = false
    this.fieldSortSeqTarget.value = 0
    this.setRadioValue("use_yn_cd", "Y")
  }

  setRadioValue(fieldName, value) {
    const normalized = String(value || "").trim().toUpperCase()
    const match = String(fieldName || "").match(/^([^\[]+)\[([^\]]+)\]$/)
    if (match) {
      setResourceFormValue(this.application, match[2], normalized, { resourceName: match[1], fieldElement: this.formTarget })
      return
    }

    setResourceFormValue(this.application, fieldName, normalized, { resourceName: this.constructor.resourceName, fieldElement: this.formTarget })
  }
}
