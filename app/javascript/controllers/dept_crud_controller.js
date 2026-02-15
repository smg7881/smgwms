import BaseCrudController from "controllers/base_crud_controller"

export default class extends BaseCrudController {
  static targets = [
    "overlay", "modal", "modalTitle", "form",
    "fieldId", "fieldDeptCode", "fieldDeptNm", "fieldParentDeptCode",
    "fieldDeptType", "fieldDeptOrder", "fieldDescription"
  ]

  static values = {
    createUrl: String,
    updateUrl: String,
    deleteUrl: String
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

  // Backward compatibility for existing data-action wiring.
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

  handleDelete = async (event) => {
    const { id, deptNm } = event.detail
    if (!confirm(`"${deptNm}" 부서를 삭제하시겠습니까?`)) return

    try {
      const { response, result } = await this.requestJson(this.deleteUrlValue.replace(":id", id), {
        method: "DELETE"
      })

      if (!response.ok || !result.success) {
        alert("삭제 실패: " + (result.errors || ["요청 처리 실패"]).join(", "))
        return
      }

      alert(result.message || "삭제되었습니다.")
      this.refreshGrid()
    } catch {
      alert("삭제 실패: 네트워크 오류")
    }
  }

  async saveDept() {
    const dept = this.buildJsonPayload()
    if (this.hasFieldIdTarget && this.fieldIdTarget.value) dept.id = this.fieldIdTarget.value

    let url
    let method
    if (this.mode === "create") {
      url = this.createUrlValue
      method = "POST"
      delete dept.id
    } else {
      url = this.updateUrlValue.replace(":id", dept.id)
      method = "PATCH"
      delete dept.id
    }

    try {
      const { response, result } = await this.requestJson(url, {
        method,
        body: { dept }
      })

      if (!response.ok || !result.success) {
        alert("저장 실패: " + (result.errors || ["요청 처리 실패"]).join(", "))
        return
      }

      alert(result.message || "저장되었습니다.")
      this.closeModal()
      this.refreshGrid()
    } catch {
      alert("저장 실패: 네트워크 오류")
    }
  }

  submitDept(event) {
    event.preventDefault()
    this.saveDept()
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
