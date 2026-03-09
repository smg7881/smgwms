/**
 * user_crud_controller.js
 *
 * BaseGridController를 상속받아 사용자 CRUD 모달을 제어합니다.
 * - 프로필 사진 선택/미리보기/삭제 처리
 * - buildMultipartFormData()를 선언하여 ModalMixin.save()가 multipart로 전송
 */
import BaseGridController from "controllers/base_grid_controller"

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
    this.connectModal({
      events: [
        { name: "user-crud:edit",   handler: this.handleEdit },
        { name: "user-crud:delete", handler: this.handleDelete }
      ]
    })
  }

  disconnect() {
    this.disconnectModal()
    super.disconnect()
  }

  openCreate() {
    this.openCreateModal({
      title: "사용자 추가",
      readWrite: [this.fieldUserIdCodeTarget]
    })
  }

  openAdd() {
    this.openCreate()
  }

  handleEdit = (event) => {
    const data = event.detail.userData
    this.openEditModal(data, {
      title: "사용자 수정",
      readOnly: [this.fieldUserIdCodeTarget],
      afterFill: (d) => {
        if (d.photo_url) {
          this.photoPreviewTarget.src = d.photo_url
          this.photoRemoveBtnTarget.hidden = false
        }
      }
    })
  }

  buildMultipartFormData() {
    const formData = new FormData(this.formTarget)
    const photoFile = this.photoInputTarget.files[0]
    if (photoFile) formData.append("user[photo]", photoFile)
    return formData
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
    this.resetFormBase({
      defaults: { work_status: "ACTIVE" },
      hooks: [this.removePhoto]
    })
  }
}
