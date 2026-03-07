/**
 * user_crud_controller.js
 *
 * BaseGridController를 상속받아 사용자 CRUD 모달을 제어합니다.
 * - 프로필 사진 선택/미리보기/삭제 처리
 * - multipart 저장(save) 오버라이드
 */
import BaseGridController from "controllers/base_grid_controller"
import { showAlert } from "components/ui/alert"

export default class extends BaseGridController {
  static resourceName = "user"
  static deleteConfirmKey = "userNm"
  static entityLabel = "사용자"

  static PLACEHOLDER_PHOTO = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='80' height='80' viewBox='0 0 80 80'%3E%3Crect width='80' height='80' rx='8' fill='%23d0d7de'/%3E%3Cpath d='M30 50h20l-4-5-3 4-3-2-6 8zm-5-20v24a2 2 0 002 2h26a2 2 0 002-2V30a2 2 0 00-2-2h-5l-2-3H34l-2 3h-5a2 2 0 00-2 2zm15 4a6 6 0 110 12 6 6 0 010-12z' fill='%23fff'/%3E%3C/svg%3E"

  static targets = [
    ...BaseGridController.targets,
    "overlay", "modal", "modalTitle", "form",
    "fieldId", "fieldUserIdCode", "fieldUserNm", "fieldEmailAddress", "fieldPassword",
    "fieldDeptCd", "fieldDeptNm", "fieldRoleCd", "fieldPositionCd", "fieldJobTitleCd",
    "fieldWorkStatus", "fieldHireDate", "fieldResignDate",
    "fieldPhone", "fieldAddress", "fieldDetailAddress",
    "photoInput", "photoPreview", "photoRemoveBtn"
  ]

  static values = {
    ...BaseGridController.values,
    createUrl: String,
    updateUrl: String,
    deleteUrl: String,
    checkIdUrl: String,
    importHistoryUrl: String
  }

  connect() {
    super.connect()
    this.handleDelete = this.handleDelete.bind(this)
    this.connectBase({
      events: [
        { name: "user-crud:edit", handler: this.handleEdit },
        { name: "user-crud:delete", handler: this.handleDelete }
      ]
    })
  }

  disconnect() {
    this.disconnectBase()
    super.disconnect()
  }

  openCreate() {
    this.resetForm()
    this.modalTitleTarget.textContent = "사용자 추가"
    this.fieldUserIdCodeTarget.readOnly = false
    this.setFieldValues({ work_status: "ACTIVE" })
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

    this.fieldIdTarget.value = data.id ?? ""
    this.setFieldValues({
      user_id_code: data.user_id_code || "",
      user_nm: data.user_nm || "",
      email_address: data.email_address || "",
      dept_cd: data.dept_cd || "",
      dept_nm: data.dept_nm || "",
      role_cd: data.role_cd || "",
      position_cd: data.position_cd || "",
      job_title_cd: data.job_title_cd || "",
      work_status: data.work_status || "ACTIVE",
      hire_date: data.hire_date || "",
      resign_date: data.resign_date || "",
      phone: data.phone || "",
      address: data.address || "",
      detail_address: data.detail_address || ""
    })

    this.fieldUserIdCodeTarget.readOnly = true
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
    this.setFieldValues({ work_status: "ACTIVE" })
    this.removePhoto()
  }
}
