/**
 * dept_crud_controller.js
 *
 * BaseGridController를 상속받아 부서 CRUD 모달을 제어합니다.
 * - 최상위/하위 추가, 수정 모달 상태 전환
 * - 그리드 액션 이벤트(dept-crud:*) 수신
 */
import BaseGridController from "controllers/base_grid_controller"
import { setResourceFormValue } from "controllers/grid/core/resource_form_bridge"

export default class extends BaseGridController {
  static resourceName = "adm_dept"
  static deleteConfirmKey = "deptNm"
  static entityLabel = "부서"

  static targets = [
    ...BaseGridController.targets,
    "overlay", "modal", "modalTitle", "form",
    "fieldId", "fieldDeptCode", "fieldDeptNm", "fieldParentDeptCode",
    "fieldDeptType", "fieldDeptOrder", "fieldDescription"
  ]

  static values = {
    ...BaseGridController.values,
    createUrl: String,
    updateUrl: String,
    deleteUrl: String,
    importHistoryUrl: String
  }

  connect() {
    super.connect()
    this.handleDelete = this.handleDelete.bind(this)

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
    super.disconnect()
  }

  openCreate() {
    this.resetForm()
    this.modalTitleTarget.textContent = "부서 추가"
    this.fieldDeptCodeTarget.readOnly = false
    this.setFieldValues({
      parent_dept_code: "",
      dept_order: 0
    })
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
    this.setFieldValues({
      parent_dept_code: parentCode || "",
      dept_order: 0
    })

    this.mode = "create"
    this.openModal()
  }

  handleEdit = (event) => {
    const data = event.detail.deptData
    this.resetForm()
    this.modalTitleTarget.textContent = "부서 수정"

    this.fieldIdTarget.value = data.id ?? ""

    this.setFieldValues({
      dept_code: data.dept_code || "",
      dept_nm: data.dept_nm || "",
      parent_dept_code: data.parent_dept_code || "",
      dept_type: data.dept_type || "",
      dept_order: data.dept_order ?? 0,
      description: data.description || ""
    })

    this.fieldDeptCodeTarget.readOnly = true
    this.setUseYn(data.use_yn || "Y")

    this.mode = "update"
    this.openModal()
  }

  resetForm() {
    this.formTarget.reset()
    this.fieldIdTarget.value = ""
    this.setFieldValues({ dept_order: 0 })
    this.setUseYn("Y")
  }

  setUseYn(value = "Y") {
    const selected = String(value || "Y").toUpperCase() === "N" ? "N" : "Y"
    setResourceFormValue(this.application, "use_yn", selected, {
      resourceName: this.constructor.resourceName,
      fieldElement: this.formTarget
    })
  }
}
