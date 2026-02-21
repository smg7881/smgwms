/**
 * user_crud_controller.js
 * 
 * [공통] BaseCrudController (모달 CRUD 컨트롤러) 상속체로서 "사용자(User) 관리"를 담당.
 * 주요 확장 사양:
 * - 프로필 사진(Photo)의 파일 선택기(Input) 트리거링, FileReader를 이용한 Base64 디코딩 및 미리보기.
 * - 프로필 사진 삭제 액션 및 휴지통 상태 관리.
 * - FormData를 사용해 Multipart로 사진과 함께 사용자 정보를 쏘는 액션 커스텀 오버라이딩.
 */
import BaseCrudController from "controllers/base_crud_controller"

export default class extends BaseCrudController {
  static resourceName = "user"
  static deleteConfirmKey = "userNm"  // 삭제 시 물어볼 사람 이름
  static entityLabel = "사용자"

  // 등록되지 않은 유저 전용으로 보여줄 기본 SVG 프로필 아이콘(실루엣) 하드코딩 토큰 
  static PLACEHOLDER_PHOTO = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='80' height='80' viewBox='0 0 80 80'%3E%3Crect width='80' height='80' rx='8' fill='%23d0d7de'/%3E%3Cpath d='M30 50h20l-4-5-3 4-3-2-6 8zm-5-20v24a2 2 0 002 2h26a2 2 0 002-2V30a2 2 0 00-2-2h-5l-2-3H34l-2 3h-5a2 2 0 00-2 2zm15 4a6 6 0 110 12 6 6 0 010-12z' fill='%23fff'/%3E%3C/svg%3E"

  static targets = [
    "overlay", "modal", "modalTitle", "form",
    "fieldId", "fieldUserIdCode", "fieldUserNm", "fieldEmailAddress", "fieldPassword",
    "fieldDeptCd", "fieldDeptNm", "fieldRoleCd", "fieldPositionCd", "fieldJobTitleCd",
    "fieldWorkStatus", "fieldHireDate", "fieldResignDate",
    "fieldPhone", "fieldAddress", "fieldDetailAddress",
    // 포토 전용 타겟
    "photoInput", "photoPreview", "photoRemoveBtn"
  ]

  static values = {
    createUrl: String,
    updateUrl: String,
    deleteUrl: String,
    checkIdUrl: String,
    excelExportUrl: String,
    excelTemplateUrl: String,
    importHistoryUrl: String
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

  // 상단 공통 [추가/작성] 버튼을 통한 신규 오픈
  openCreate() {
    this.resetForm()
    this.modalTitleTarget.textContent = "사용자 추가"
    this.fieldUserIdCodeTarget.readOnly = false // 사원번호/ID 신규 할당 허가
    this.fieldWorkStatusTarget.value = "ACTIVE" // 디폴트 재직 상태
    this.mode = "create"
    this.openModal()
  }

  // UI 알리아스
  openAdd() {
    this.openCreate()
  }

  // [수정] 펜 아이콘을 통한 모달 오픈
  handleEdit = (event) => {
    // 그리드 row 객체 Payload 전체
    const data = event.detail.userData
    this.resetForm()
    this.modalTitleTarget.textContent = "사용자 수정"

    this.fieldIdTarget.value = data.id
    this.fieldUserIdCodeTarget.value = data.user_id_code || ""
    this.fieldUserIdCodeTarget.readOnly = true // 사원번호 고유값은 수정 불가
    this.fieldUserNmTarget.value = data.user_nm || ""
    this.fieldEmailAddressTarget.value = data.email_address || ""

    // 조직도, 권한 등 맵핑
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

    // 이미지를 ActiveStorage 등으로 부터 서빙받은 URL이 있다면 표출 수행
    if (data.photo_url) {
      this.photoPreviewTarget.src = data.photo_url // <img src> 속성 변경
      this.photoRemoveBtnTarget.hidden = false     // X 삭제버튼 노출
    }

    this.mode = "update"
    this.openModal()
  }

  // 사진을 포함(Multipart Form Data)하여 서버 저장을 치는 재정의된 Save 메서드
  async save() {
    const formData = new FormData(this.formTarget)
    // 썸네일 input file 타겟에서 뽑아낸 바이너리를 폼에 수작업 Add.
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
        isMultipart: true // Application-JSON Stringify가 되지 않도록 방어하는 인터페이스 속성
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

  // 프로필 프사 쪽 네모 컨테이너를 누르면 브라우저 파일 탐색기 인풋이 클릭되도록 포워딩함
  triggerPhotoSelect() {
    this.photoInputTarget.click()
  }

  // 파일 탐색기에서 사진이 선택되었을때 Change 이벤트를 감지하여 동작
  previewPhoto() {
    const file = this.photoInputTarget.files[0]
    if (!file) return

    // 브라우저 캐시 레벨에서 바이너리를 Base64로 떠서 바로 미리보기를 띄워줌
    const reader = new FileReader()
    reader.onload = (event) => {
      this.photoPreviewTarget.src = event.target.result // Base64 DATA URI 
      this.photoRemoveBtnTarget.hidden = false          // 삭제 버튼 On
    }
    // 인코딩 시작
    reader.readAsDataURL(file)
  }

  // 휴지통 / 사진 지우기 버튼 액션
  removePhoto() {
    this.photoInputTarget.value = "" // 첨부 해제
    this.photoPreviewTarget.src = this.constructor.PLACEHOLDER_PHOTO // 텅 비어보이는 SVG 실루엣으로 교체
    this.photoRemoveBtnTarget.hidden = true // 삭제 버튼 없앰
  }

  // 모달 닫힐 때 혹은 신규 진입 때의 화면 클린작업
  resetForm() {
    this.formTarget.reset()
    this.fieldIdTarget.value = ""
    this.fieldWorkStatusTarget.value = "ACTIVE"
    this.removePhoto()
  }
}
