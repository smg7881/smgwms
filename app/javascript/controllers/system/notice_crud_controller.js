/**
 * notice_crud_controller.js
 *
 * BaseGridController를 상속받아 공지사항 CRUD 모달을 제어합니다.
 * - 첨부파일/에디터 동작은 AttachmentMixin, TrixMixin으로 위임
 * - 공지사항 상세 조회 후 폼 주입 및 일괄 삭제 지원
 */
import BaseGridController from "controllers/base_grid_controller"
import { showAlert, confirmAction } from "components/ui/alert"
import { AttachmentMixin } from "controllers/concerns/attachment_mixin"
import { TrixMixin } from "controllers/concerns/trix_mixin"
import { setResourceFormValue } from "controllers/grid/core/resource_form_bridge"

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
    bulkDeleteUrl: String
  }

  connect() {
    super.connect()
    this.initAttachment()
    this.handleDelete = this.handleDelete.bind(this)

    this.connectBase({
      events: [
        { name: "notice-crud:edit", handler: this.handleEdit },
        { name: "notice-crud:delete", handler: this.handleDelete }
      ]
    })
  }

  disconnect() {
    this.disconnectBase()
    super.disconnect()
  }

  openCreate() {
    this.resetForm()
    this.modalTitleTarget.textContent = "공지사항 등록"
    this.mode = "create"
    this.openModal()
  }

  handleEdit = async (event) => {
    const { id } = event.detail
    if (!id) return

    this.resetForm()
    this.modalTitleTarget.textContent = "공지사항 수정"

    const url = this.updateUrlValue.replace(":id", id)
    try {
      const response = await fetch(url, { headers: { Accept: "application/json" } })
      if (!response.ok) {
        showAlert("상세 조회에 실패했습니다.")
        return
      }

      const data = await response.json()
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

  async save() {
    const formData = new FormData(this.formTarget)
    const scope = this.constructor.resourceName

    this.appendRemovedAttachmentIds(formData, scope)

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

  async deleteSelected() {
    const selectedRows = this._getModalSelectedRows()
    if (selectedRows.length === 0) {
      showAlert("삭제할 공지사항을 선택해주세요.")
      return
    }

    if (!await confirmAction(`선택한 ${selectedRows.length}건을 삭제하시겠습니까?`)) {
      return
    }

    const ids = selectedRows.map((row) => row.id).filter((id) => Boolean(id))
    if (ids.length === 0) {
      showAlert("삭제할 공지사항을 선택해주세요.")
      return
    }

    try {
      const { response, result } = await this.requestJson(this.bulkDeleteUrlValue, {
        method: "DELETE",
        body: { ids }
      })

      if (!response.ok || !result.success) {
        showAlert("삭제 실패: " + (result.errors || ["요청 처리 실패"]).join(", "))
        return
      }

      showAlert(result.message || "삭제되었습니다.")
      this._refreshModalGrid()
    } catch {
      showAlert("삭제 실패: 네트워크 오류")
    }
  }

  _getModalSelectedRows() {
    const agGridEl = this.element.querySelector("[data-controller='ag-grid']")
    if (!agGridEl) return []

    const api = this.application.getControllerForElementAndIdentifier(agGridEl, "ag-grid")?.api
    if (!api || typeof api.getSelectedRows !== "function") {
      return []
    }

    return api.getSelectedRows() || []
  }

  resetForm() {
    this.formTarget.reset()
    this.fieldIdTarget.value = ""
    this.setRadioValue("is_top_fixed", "N")
    this.setRadioValue("is_published", "Y")
    this.setContentValue("")
    this.resetAttachment()
  }
}

Object.assign(NoticeCrudController.prototype, AttachmentMixin)
Object.assign(NoticeCrudController.prototype, TrixMixin)

export default NoticeCrudController
