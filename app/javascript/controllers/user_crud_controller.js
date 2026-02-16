import BaseCrudController from "controllers/base_crud_controller"

export default class extends BaseCrudController {
  static resourceName = "user"
  static deleteConfirmKey = "userNm"
  static entityLabel = "사용자"

  static PLACEHOLDER_PHOTO = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='80' height='80' viewBox='0 0 80 80'%3E%3Crect width='80' height='80' rx='8' fill='%23d0d7de'/%3E%3Cpath d='M30 50h20l-4-5-3 4-3-2-6 8zm-5-20v24a2 2 0 002 2h26a2 2 0 002-2V30a2 2 0 00-2-2h-5l-2-3H34l-2 3h-5a2 2 0 00-2 2zm15 4a6 6 0 110 12 6 6 0 010-12z' fill='%23fff'/%3E%3C/svg%3E"

  static targets = [
    "overlay", "modal", "modalTitle", "form",
    "fieldId", "fieldUserIdCode", "fieldUserNm", "fieldEmailAddress", "fieldPassword",
    "fieldDeptCd", "fieldDeptNm", "fieldRoleCd", "fieldPositionCd", "fieldJobTitleCd",
    "fieldWorkStatus", "fieldHireDate", "fieldResignDate",
    "fieldPhone", "fieldAddress", "fieldDetailAddress",
    "photoInput", "photoPreview", "photoRemoveBtn"
  ]

  static values = {
    createUrl: String,
    updateUrl: String,
    deleteUrl: String,
    checkIdUrl: String
  }

  connect() {
    this.connectBase({
      events: [
        { name: "user-crud:edit", handler: this.handleEdit },
        { name: "user-crud:delete", handler: this.handleDelete }
      ]
    })
  }

  disconnect() {
    this.disconnectBase()
  }

  openCreate() {
    this.resetForm()
    this.modalTitleTarget.textContent = "사용자 추가"
    this.fieldUserIdCodeTarget.readOnly = false
    this.fieldWorkStatusTarget.value = "ACTIVE"
    this.mode = "create"
    this.openModal()
  }

  openAdd() {
    this.openCreate()
  }

  handleEdit = (event) => {
    const data = event.detail.userData
    this.resetForm()
    this.modalTitleTarget.textContent = "사용자 수정"
    this.fieldIdTarget.value = data.id
    this.fieldUserIdCodeTarget.value = data.user_id_code || ""
    this.fieldUserIdCodeTarget.readOnly = true
    this.fieldUserNmTarget.value = data.user_nm || ""
    this.fieldEmailAddressTarget.value = data.email_address || ""
    this.fieldDeptCdTarget.value = data.dept_cd || ""
    this.fieldDeptNmTarget.value = data.dept_nm || ""
    this.fieldRoleCdTarget.value = data.role_cd || ""
    this.fieldPositionCdTarget.value = data.position_cd || ""
    this.fieldJobTitleCdTarget.value = data.job_title_cd || ""
    this.fieldWorkStatusTarget.value = data.work_status || "ACTIVE"
    this.fieldHireDateTarget.value = data.hire_date || ""
    this.fieldResignDateTarget.value = data.resign_date || ""
    this.fieldPhoneTarget.value = data.phone || ""
    this.fieldAddressTarget.value = data.address || ""
    this.fieldDetailAddressTarget.value = data.detail_address || ""
    if (data.photo_url) {
      this.photoPreviewTarget.src = data.photo_url
      this.photoRemoveBtnTarget.hidden = false
    }
    this.mode = "update"
    this.openModal()
  }

  async save() {
    const formData = new FormData(this.formTarget)
    const photoFile = this.photoInputTarget.files[0]
    if (photoFile) formData.append("user[photo]", photoFile)

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

  triggerPhotoSelect() {
    this.photoInputTarget.click()
  }

  previewPhoto() {
    const file = this.photoInputTarget.files[0]
    if (!file) return

    const reader = new FileReader()
    reader.onload = (event) => {
      this.photoPreviewTarget.src = event.target.result
      this.photoRemoveBtnTarget.hidden = false
    }
    reader.readAsDataURL(file)
  }

  removePhoto() {
    this.photoInputTarget.value = ""
    this.photoPreviewTarget.src = this.constructor.PLACEHOLDER_PHOTO
    this.photoRemoveBtnTarget.hidden = true
  }

  resetForm() {
    this.formTarget.reset()
    this.fieldIdTarget.value = ""
    this.fieldWorkStatusTarget.value = "ACTIVE"
    this.removePhoto()
  }
}
