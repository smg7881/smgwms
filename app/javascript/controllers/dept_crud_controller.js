/**
 * dept_crud_controller.js
 * 
 * [공통] BaseCrudController (모달 폼 기반)를 상속하여 '부서정보' 관리를 제어합니다.
 * 주요 확장 기능:
 * - "최상위 부서 추가", "하위 부서 추가", "부서 수정" 등의 다양한 의도를 가진 모달 폼으로 
 *   동일한 템플릿(DOM)을 재활용하며 타이틀과 ReadOnly 등을 스위칭합니다.
 * - 트리 그리드(ag_grid/renderers.js 기반) 내부에서 버튼 클릭 시 날아오는 이벤트를 수신합니다.
 */
import BaseCrudController from "controllers/base_crud_controller"

export default class extends BaseCrudController {
  // 모달 기반 메타데이터 오버라이드
  static resourceName = "dept"       // 객체 참조 변수명 단위 ex: dept[dept_nm]
  static deleteConfirmKey = "deptNm" // 삭제 컨펌창에 띄울 필드 맵핑 키
  static entityLabel = "부서"        // Alert 표출용 국문

  // 모달 폼 안에 속한 무수한 인풋 DOM 타겟들
  static targets = [
    "overlay", "modal", "modalTitle", "form",
    "fieldId", "fieldDeptCode", "fieldDeptNm", "fieldParentDeptCode",
    "fieldDeptType", "fieldDeptOrder", "fieldDescription"
  ]

  // 백엔드 요청을 위한 엔드포인트 URL 모음
  static values = {
    createUrl: String,
    updateUrl: String,
    deleteUrl: String,
    excelExportUrl: String,
    excelTemplateUrl: String,
    importHistoryUrl: String
  }

  connect() {
    // 부모단 로직(connectBase)을 기동하며, 커스텀 이벤트 버스들을 브릿지시켜둠.
    // 그리드 내부 셀 렌더러가 버튼클릭 시 방출하는 "dept-crud:edit" 등을 낚아챔.
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

  // 최상단 버튼을 통한 '순수 신규 작성' 모달 열기용 진입점
  openCreate() {
    this.resetForm()
    this.modalTitleTarget.textContent = "부서 추가"
    this.fieldDeptCodeTarget.readOnly = false // PK지만 새것이므로 활성화
    this.fieldParentDeptCodeTarget.value = "" // 루트 최상위 노드로 설정
    this.fieldDeptOrderTarget.value = 0
    this.mode = "create"
    this.openModal()
  }

  // 위와 같으나 다른 UI 레이어에서 접근 시 alias
  openAddTopLevel() {
    this.openCreate()
  }

  // 특정 부서행 맨 우측의 [+] 버튼 등을 눌렀을 때 트리거
  handleAddChild = (event) => {
    // 이벤트 detail 객체 안에 그리드가 넣어준 모(Parent) 코드 추출
    const { parentCode } = event.detail
    this.resetForm()
    this.modalTitleTarget.textContent = "하위 부서 추가"

    this.fieldDeptCodeTarget.readOnly = false
    this.fieldParentDeptCodeTarget.value = parentCode || "" // 선택했던 부서를 나의 부모로 자동 채워줌
    this.fieldDeptOrderTarget.value = 0

    this.mode = "create"
    this.openModal()
  }

  // 특정 부서행 [수정] 펜 아이콘 눌렀을 때 트리거
  handleEdit = (event) => {
    // 그리드의 해당 RowData 전체
    const data = event.detail.deptData
    this.resetForm()
    this.modalTitleTarget.textContent = "부서 수정"

    // DB에 할당되어있던 레거시 PK(ID)를 숨겨진 인풋에 세팅 (레일즈 라우팅용 등)
    this.fieldIdTarget.value = data.id

    // 값 주입 및 불허가 로직 (PK는 수정불가)
    this.fieldDeptCodeTarget.value = data.dept_code || ""
    this.fieldDeptCodeTarget.readOnly = true

    this.fieldDeptNmTarget.value = data.dept_nm || ""
    this.fieldParentDeptCodeTarget.value = data.parent_dept_code || ""
    this.fieldDeptTypeTarget.value = data.dept_type || ""
    this.fieldDeptOrderTarget.value = data.dept_order ?? 0
    this.fieldDescriptionTarget.value = data.description || ""

    // 라디오 버튼(사용여부 값 'Y' / 'N') UI 세팅
    if (String(data.use_yn || "Y") === "N") {
      this.formTarget.querySelectorAll("input[type='radio'][name='dept[use_yn]']").forEach((radio) => {
        radio.checked = radio.value === "N"
      })
    }

    this.mode = "update"
    this.openModal()
  }

  // 모달이 닫히거나 다음 노출을 대비하여 데이터를 White-out 하는 클리너
  resetForm() {
    this.formTarget.reset() // DOM 폼태그 초기화 지원명령 
    this.fieldIdTarget.value = ""
    this.fieldDeptOrderTarget.value = 0
    // 라디오 버튼 강제 원복
    this.formTarget.querySelectorAll("input[type='radio'][name='dept[use_yn]']").forEach((radio) => {
      radio.checked = radio.value === "Y"
    })
  }
}
