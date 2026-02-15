import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
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
    this.dragState = null
    this.element.addEventListener("user-crud:edit", this.handleEdit)
    this.element.addEventListener("user-crud:delete", this.handleDelete)
    this.element.addEventListener("click", this.handleDelegatedClick)
    window.addEventListener("mousemove", this.handleDragMove)
    window.addEventListener("mouseup", this.endDrag)
  }

  disconnect() {
    this.element.removeEventListener("user-crud:edit", this.handleEdit)
    this.element.removeEventListener("user-crud:delete", this.handleDelete)
    this.element.removeEventListener("click", this.handleDelegatedClick)
    window.removeEventListener("mousemove", this.handleDragMove)
    window.removeEventListener("mouseup", this.endDrag)
  }

  openAdd() {
    this.resetForm()
    this.modalTitleTarget.textContent = "사용자 추가"
    this.fieldUserIdCodeTarget.readOnly = false
    this.fieldWorkStatusTarget.value = "ACTIVE"
    this.mode = "create"
    this.openModal()
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

  handleDelete = async (event) => {
    const { id, userNm } = event.detail
    if (!confirm(`"${userNm}" 사용자를 삭제하시겠습니까?`)) return

    try {
      const response = await fetch(this.deleteUrlValue.replace(":id", id), {
        method: "DELETE",
        headers: { "X-CSRF-Token": this.csrfToken }
      })
      const result = await response.json()
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

  async saveUser() {
    const formData = new FormData(this.formTarget)

    // 사진 파일 추가
    const photoFile = this.photoInputTarget.files[0]
    if (photoFile) {
      formData.append("user[photo]", photoFile)
    }

    let id = null
    if (this.hasFieldIdTarget && this.fieldIdTarget.value) {
      id = this.fieldIdTarget.value
    }

    let url
    let method
    if (this.mode === "create") {
      url = this.createUrlValue
      method = "POST"
    } else {
      url = this.updateUrlValue.replace(":id", id)
      method = "PATCH"
    }

    try {
      const response = await fetch(url, {
        method,
        headers: {
          "X-CSRF-Token": this.csrfToken
        },
        body: formData
      })

      const result = await response.json()
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
    if (file) {
      const reader = new FileReader()
      reader.onload = (e) => {
        this.photoPreviewTarget.src = e.target.result
        this.photoRemoveBtnTarget.hidden = false
      }
      reader.readAsDataURL(file)
    }
  }

  removePhoto() {
    this.photoInputTarget.value = ""
    this.photoPreviewTarget.src = this.constructor.PLACEHOLDER_PHOTO
    this.photoRemoveBtnTarget.hidden = true
  }

  submitUser(event) {
    event.preventDefault()
    this.saveUser()
  }

  closeModal() {
    this.overlayTarget.hidden = true
    this.endDrag()
  }

  stopPropagation(event) {
    event.stopPropagation()
  }

  get csrfToken() {
    return document.querySelector("[name='csrf-token']")?.content || ""
  }

  openModal() {
    this.overlayTarget.hidden = false
  }

  resetForm() {
    this.formTarget.reset()
    this.fieldIdTarget.value = ""
    this.fieldWorkStatusTarget.value = "ACTIVE"
    this.removePhoto()
  }

  refreshGrid() {
    const agGridEl = this.element.querySelector("[data-controller='ag-grid']")
    const agGridController = this.application.getControllerForElementAndIdentifier(agGridEl, "ag-grid")
    agGridController?.refresh()
  }

  handleDelegatedClick = (event) => {
    const cancelButton = event.target.closest("[data-user-crud-role='cancel']")
    if (cancelButton) {
      event.preventDefault()
      this.closeModal()
    }
  }

  startDrag(event) {
    if (event.button !== 0) return
    if (!this.hasModalTarget || !this.hasOverlayTarget) return
    if (event.target.closest("button")) return

    const modalRect = this.modalTarget.getBoundingClientRect()
    this.modalTarget.style.position = "absolute"
    this.modalTarget.style.left = `${modalRect.left}px`
    this.modalTarget.style.top = `${modalRect.top}px`
    this.modalTarget.style.margin = "0"

    this.dragState = {
      offsetX: event.clientX - modalRect.left,
      offsetY: event.clientY - modalRect.top
    }

    document.body.style.userSelect = "none"
    this.modalTarget.style.cursor = "grabbing"
    event.preventDefault()
  }

  handleDragMove = (event) => {
    if (!this.dragState || !this.hasModalTarget) return

    const maxLeft = Math.max(0, window.innerWidth - this.modalTarget.offsetWidth)
    const maxTop = Math.max(0, window.innerHeight - this.modalTarget.offsetHeight)
    const nextLeft = event.clientX - this.dragState.offsetX
    const nextTop = event.clientY - this.dragState.offsetY
    const clampedLeft = Math.min(Math.max(0, nextLeft), maxLeft)
    const clampedTop = Math.min(Math.max(0, nextTop), maxTop)

    this.modalTarget.style.left = `${clampedLeft}px`
    this.modalTarget.style.top = `${clampedTop}px`
  }

  endDrag = () => {
    this.dragState = null
    document.body.style.userSelect = ""
    if (this.hasModalTarget) {
      this.modalTarget.style.cursor = ""
    }
  }
}
