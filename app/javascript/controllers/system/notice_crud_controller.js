/**
 * notice_crud_controller.js
 *
 * BaseGridController를 상속받아 공지사항 CRUD 모달을 제어합니다.
 * - 첨부파일/에디터 동작은 AttachmentMixin, TrixMixin으로 위임
 * - 공지사항 상세 조회 후 폼 주입 및 일괄 삭제 지원
 * - buildMultipartFormData()를 선언하여 ModalMixin.save()가 multipart로 전송
 */
import BaseGridController from "controllers/base_grid_controller"
import { showAlert } from "components/ui/alert"
import { AttachmentMixin } from "controllers/concerns/attachment_mixin"
import { TrixMixin } from "controllers/concerns/trix_mixin"
import { setResourceFormValue } from "controllers/grid/core/resource_form_bridge"
import { fetchJson } from "controllers/grid/core/http_client"

class NoticeCrudController extends BaseGridController {
  static resourceName = "adm_notice"
  static deleteConfirmKey = "title"
  static entityLabel = "공지사항"

  static targets = [
    ...BaseGridController.targets,
    "overlay", "modal", "modalTitle", "form",
    "fieldId", "fieldCategoryCode", "fieldTitle",
    "fieldStartDate", "fieldEndDate", "fieldContent",
    "fieldAttachments", "existingFiles", "selectedFiles"
  ]

  static values = {
    ...BaseGridController.values,
    createUrl: String,
    updateUrl: String,
    deleteUrl: String,
  }

  connect() {
    super.connect()
    this.connectModal({
      events: [
        { name: "notice-crud:edit",   handler: this.handleEdit },
        { name: "notice-crud:delete", handler: this.handleDelete }
      ],
      initHooks: [this.initAttachment]
    })
  }

  disconnect() {
    this.disconnectModal()
    super.disconnect()
  }

  openCreate() {
    this.openCreateModal({ title: "공지사항 등록" })
  }

  handleEdit = async (event) => {
    const { id } = event.detail
    if (!id) return

    this.resetForm()
    this.modalTitleTarget.textContent = "공지사항 수정"

    const url = this.updateUrlValue.replace(":id", id)
    try {
      const data = await fetchJson(url)
      this.fillForm(data)
      this.mode = "update"
      this.openModal()
    } catch {
      showAlert("상세 조회에 실패했습니다.")
    }
  }

  fillForm(data) {
    this.fieldIdTarget.value = data.id ?? ""
    this.setFieldValues({
      category_code: data.category_code || "",
      title: data.title || "",
      start_date: data.start_date || "",
      end_date: data.end_date || ""
    })

    this.setContentValue(data.content || "")
    this.setRadioValue("is_top_fixed", data.is_top_fixed || "N")
    this.setRadioValue("is_published", data.is_published || "Y")
    this.renderExistingFiles(data.attachments || [])
    this.renderSelectedFiles()
  }

  setRadioValue(field, value) {
    const normalized = String(value || "").trim().toUpperCase()
    setResourceFormValue(this.application, field, normalized, {
      resourceName: this.constructor.resourceName,
      fieldElement: this.formTarget
    })
  }

  buildMultipartFormData() {
    const formData = new FormData(this.formTarget)
    this.appendRemovedAttachmentIds(formData, this.constructor.resourceName)
    return formData
  }

  resetForm() {
    this.resetFormBase({
      hooks: [
        () => this.setRadioValue("is_top_fixed", "N"),
        () => this.setRadioValue("is_published", "Y"),
        () => this.setContentValue(""),
        this.resetAttachment
      ]
    })
  }
}

Object.assign(NoticeCrudController.prototype, AttachmentMixin)
Object.assign(NoticeCrudController.prototype, TrixMixin)

export default NoticeCrudController
