import BaseCrudController from "controllers/base_crud_controller"

export default class extends BaseCrudController {
  static resourceName = "dept"
  static deleteConfirmKey = "deptNm"
  static entityLabel = "부서"

  static targets = [
    "overlay", "modal", "modalTitle", "form",
    "fieldId", "fieldDeptCode", "fieldDeptNm", "fieldParentDeptCode",
    "fieldDeptType", "fieldDeptOrder", "fieldDescription"
  ]

  static values = {
    createUrl: String,
    updateUrl: String,
    deleteUrl: String,
    excelExportUrl: String,
    excelTemplateUrl: String,
    importHistoryUrl: String
  }

  connect() {
    this.connectBase({
      events: [
        { name: "dept-crud:add-child", handler: this.handleAddChild },
        { name: "dept-crud:edit", handler: this.handleEdit },
        { name: "dept-crud:delete", handler: this.handleDelete }
      ]
    })
  }

  disconnect() {
    this.disconnectBase()
  }

  openCreate() {
    this.resetForm()
    this.modalTitleTarget.textContent = "부서 추가"
    this.fieldDeptCodeTarget.readOnly = false
    this.fieldParentDeptCodeTarget.value = ""
    this.fieldDeptOrderTarget.value = 0
    this.mode = "create"
    this.openModal()
  }

  openAddTopLevel() {
    this.openCreate()
  }

  handleAddChild = (event) => {
    const { parentCode } = event.detail
    this.resetForm()
    this.modalTitleTarget.textContent = "하위 부서 추가"
    this.fieldDeptCodeTarget.readOnly = false
    this.fieldParentDeptCodeTarget.value = parentCode || ""
    this.fieldDeptOrderTarget.value = 0
    this.mode = "create"
    this.openModal()
  }

  handleEdit = (event) => {
    const data = event.detail.deptData
    this.resetForm()
    this.modalTitleTarget.textContent = "부서 수정"
    this.fieldIdTarget.value = data.id
    this.fieldDeptCodeTarget.value = data.dept_code || ""
    this.fieldDeptCodeTarget.readOnly = true
    this.fieldDeptNmTarget.value = data.dept_nm || ""
    this.fieldParentDeptCodeTarget.value = data.parent_dept_code || ""
    this.fieldDeptTypeTarget.value = data.dept_type || ""
    this.fieldDeptOrderTarget.value = data.dept_order ?? 0
    this.fieldDescriptionTarget.value = data.description || ""

    if (String(data.use_yn || "Y") === "N") {
      this.formTarget.querySelectorAll("input[type='radio'][name='dept[use_yn]']").forEach((radio) => {
        radio.checked = radio.value === "N"
      })
    }

    this.mode = "update"
    this.openModal()
  }

  resetForm() {
    this.formTarget.reset()
    this.fieldIdTarget.value = ""
    this.fieldDeptOrderTarget.value = 0
    this.formTarget.querySelectorAll("input[type='radio'][name='dept[use_yn]']").forEach((radio) => {
      radio.checked = radio.value === "Y"
    })
  }
}
