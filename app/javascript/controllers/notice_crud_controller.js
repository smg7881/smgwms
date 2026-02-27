/**
 * notice_crud_controller.js
 *
 * [공통] BaseCrudController 상속체로서 "공지사항(Notice)" 게시판의 작성/수정 모달을 제어합니다.
 * 주요 확장 사양:
 * - 첨부파일(Attachments) 멀티 업로드 — AttachmentMixin 위임
 * - Trix 에디터(ActionText) 제어 — TrixMixin 위임
 * - 기존 첨부파일 목록 렌더링 및 삭제 대기열(removedAttachmentIds) 상태 관리
 * - 그리드 다중 선택을 통한 일괄 삭제(Bulk Delete) 기능 지원
 */
import BaseCrudController from "controllers/base_crud_controller"
import { showAlert, confirmAction } from "components/ui/alert"
import { AttachmentMixin } from "controllers/concerns/attachment_mixin"
import { TrixMixin } from "controllers/concerns/trix_mixin"

class NoticeCrudController extends BaseCrudController {
  static resourceName = "notice"      // 폼 데이터 생성 시 네임스페이스 (ex: notice[title])
  static deleteConfirmKey = "title"   // 삭제 확인 창에 띄울 필드 키맵
  static entityLabel = "공지사항"     // 얼럿 노출 텍스트

  // 공지사항 폼에서 통제하는 다양한 DOM 요소들
  static targets = [
    "overlay", "modal", "modalTitle", "form",
    "fieldId", "fieldCategoryCode", "fieldTitle",
    "fieldStartDate", "fieldEndDate", "fieldContent",
    "fieldAttachments", "existingFiles", "selectedFiles"
  ]

  static values = {
    createUrl: String,
    updateUrl: String,
    deleteUrl: String,
    bulkDeleteUrl: String // 일괄 삭제 전용 엔드포인트
  }

  connect() {
    this.initAttachment() // AttachmentMixin: removedAttachmentIds, selectedFilesBuffer 초기화

    // 이벤트 리스너 파이프라인 등록
    this.connectBase({
      events: [
        { name: "notice-crud:edit", handler: this.handleEdit },
        { name: "notice-crud:delete", handler: this.handleDelete }
      ]
    })
  }

  disconnect() {
    this.disconnectBase()
  }

  // 신규 등록 모달 열기
  openCreate() {
    this.resetForm()
    this.modalTitleTarget.textContent = "공지사항 등록"
    this.mode = "create"
    this.openModal()
  }

  // 수정 버튼 클릭 시 비동기 조회 및 모달 열기
  handleEdit = async (event) => {
    const { id } = event.detail
    if (!id) return

    this.resetForm()
    this.modalTitleTarget.textContent = "공지사항 수정"

    const url = this.updateUrlValue.replace(":id", id)
    try {
      // 공지사항은 내용(content)이 크기 때문에, 그리드 셀 데이터에 안 넣고 서버에서 상세 Data를 별도로 Fetch 함.
      const response = await fetch(url, { headers: { Accept: "application/json" } })
      if (!response.ok) {
        showAlert("상세 조회에 실패했습니다.")
        return
      }

      const data = await response.json()
      // 받아온 JSON으로 폼 필드들을 채움
      this.fillForm(data)
      this.mode = "update"
      this.openModal()
    } catch {
      showAlert("상세 조회에 실패했습니다.")
    }
  }

  // 서버에서 받은 JSON 데이터를 기반으로 HTML 인풋 Value 세팅
  fillForm(data) {
    this.fieldIdTarget.value = data.id || ""
    this.fieldCategoryCodeTarget.value = data.category_code || ""
    this.fieldTitleTarget.value = data.title || ""
    this.fieldStartDateTarget.value = data.start_date || ""
    this.fieldEndDateTarget.value = data.end_date || ""

    // Trix 본문 에디터 내용 주입
    this.setContentValue(data.content || "")

    // 상단고정, 게시여부 라디오 버튼 UI 동기화
    this.setRadioValue("is_top_fixed", data.is_top_fixed || "N")
    this.setRadioValue("is_published", data.is_published || "Y")

    // 첨부파일 영역 UI 동기화 (AttachmentMixin)
    this.renderExistingFiles(data.attachments || [])
    this.renderSelectedFiles()
  }

  // 네임스페이스 기반으로 라디오 버튼 그룹 중에 일치하는 value를 찾아 체크함
  setRadioValue(field, value) {
    const scope = this.formScopeKey()
    this.formTarget.querySelectorAll(`input[type='radio'][name='${scope}[${field}]']`).forEach((radio) => {
      radio.checked = radio.value === value
    })
  }

  // notice[title] 같이 감싸인 폼 Prefix 문자열 추출 로직
  formScopeKey() {
    const candidateName = this.hasFieldCategoryCodeTarget
      ? this.fieldCategoryCodeTarget.name
      : this.formTarget.querySelector("[name*='[']")?.name

    const match = String(candidateName || "").match(/^([^\[]+)\[/)
    return match ? match[1] : this.constructor.resourceName
  }

  // 파일 업로드가 포함된 오버라이드 폼 전송 액션
  async save() {
    const formData = new FormData(this.formTarget)
    const scope = this.formScopeKey()

    // 삭제 대상으로 마킹된 기존 첨부파일 ID들을 FormData에 추가 (AttachmentMixin)
    this.appendRemovedAttachmentIds(formData, scope)

    const id = this.hasFieldIdTarget && this.fieldIdTarget.value ? this.fieldIdTarget.value : null
    const isCreate = this.mode === "create"
    const url = isCreate ? this.createUrlValue : this.updateUrlValue.replace(":id", id)
    const method = isCreate ? "POST" : "PATCH"

    try {
      // BaseCrudController의 요청 래퍼 사용 (Multipart 활성화 = 첨부파일 전송 허가)
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
      this.refreshGrid()
    } catch {
      showAlert("저장 실패: 네트워크 오류")
    }
  }

  // ===================== [그리드 연계 액션] =========================

  // 메인 그리드에서 다중 체크박스로 여럿을 집어서 한방에 날릴때 사용
  async deleteSelected() {
    const selectedRows = this.selectedRows()
    if (selectedRows.length === 0) {
      showAlert("삭제할 공지사항을 선택해주세요.")
      return
    }

    if (!confirmAction(`선택한 ${selectedRows.length}건을 삭제하시겠습니까?`)) {
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
      this.refreshGrid()
    } catch {
      showAlert("삭제 실패: 네트워크 오류")
    }
  }

  selectedRows() {
    const api = this.getAgGridController()?.api
    if (!api || typeof api.getSelectedRows !== "function") {
      return []
    }

    return api.getSelectedRows() || []
  }

  // 모달 데이터 백지화
  resetForm() {
    this.formTarget.reset()
    this.fieldIdTarget.value = ""
    this.setRadioValue("is_top_fixed", "N")
    this.setRadioValue("is_published", "Y")

    // Trix 비우기
    this.setContentValue("")

    // 첨부파일 영역 비우기 (AttachmentMixin)
    this.resetAttachment()
  }

}

// 믹스인 적용
Object.assign(NoticeCrudController.prototype, AttachmentMixin)
Object.assign(NoticeCrudController.prototype, TrixMixin)

export default NoticeCrudController
