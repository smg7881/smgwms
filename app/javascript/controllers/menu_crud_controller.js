/**
 * menu_crud_controller.js
 * 
 * [공통] BaseCrudController 상속체로서 "메뉴(Menu) 계층 트리" 데이터를 관리하는 모달 기능에 관여합니다.
 * 주요 확장 사양:
 * - 메뉴의 계층(Menu Level)을 계산하여 '최상위(폴더) 만들기 대상'인지, '자식(링크) 달기 대상'인지 판별
 * - 그리드 액션에서 넘긴 데이터를 모달 폼으로 밀어넣고(Editing), 상태값을 서버 대응 인터페이스에 매칭
 */
import BaseCrudController from "controllers/base_crud_controller"

export default class extends BaseCrudController {
  static resourceName = "menu"       // Form Builder에서 백엔드로 전송 시 그룹핑될 파라미터 Key명
  static deleteConfirmKey = "menuCd" // 삭제 컨펌 얼럿을 띄울 때 보여줄 메뉴코드 Key명
  static entityLabel = "메뉴"        // "메뉴 삭제를 진행하시겠습니까?" 등 Alert 활용 목적

  // 모달 안쪽 폼이 보유해야 할 거의 모든 인풋 구성 요소 Target 바인딩
  static targets = [
    "overlay", "modal", "modalTitle", "form",
    "fieldId", "fieldMenuCd", "fieldMenuNm", "fieldParentCd",
    "fieldMenuUrl", "fieldMenuIcon", "fieldSortOrder",
    "fieldMenuLevel", "fieldMenuType", "fieldUseYn", "fieldTabId"
  ]

  static values = {
    createUrl: String,
    updateUrl: String,
    deleteUrl: String
  }

  connect() {
    // 트리 셀 안의 버튼([+], [수정], [휴지통])이 눌려 전역 버스로 발송된 CustomEvent를 낚아채서 맵핑함
    this.connectBase({
      events: [
        { name: "menu-crud:add-child", handler: this.handleAddChild },
        { name: "menu-crud:edit", handler: this.handleEdit },
        { name: "menu-crud:delete", handler: this.handleDelete }
      ]
    })
  }

  disconnect() {
    this.disconnectBase()
  }

  // "최상위 메뉴 추가" 버튼용. 부모가 없는 순살(루트) 데이터 폼 세팅
  openCreate() {
    this.resetForm()
    this.modalTitleTarget.textContent = "최상위 메뉴 추가"
    this.fieldParentCdTarget.value = "" // 부모 코드 널값
    this.fieldMenuLevelTarget.value = 1 // 최상위이므로 Level은 1
    this.fieldMenuTypeTarget.value = "FOLDER" // 최상위는 진입 링크가 없고 폴더니깐 FOLDER 타입 할당 강제
    this.fieldMenuCdTarget.readOnly = false // 코드는 신규작성이므로 활짝오픈
    this.mode = "create"
    this.openModal()
  }

  openAddTopLevel() {
    this.openCreate()
  }

  // 트리의 1~2 뎁스 폴더 노드 등에서 [+] 아이콘 클릭 시
  handleAddChild = (event) => {
    // 디스패치된 정보에서 나의 상위 부모님이 누구신지, 몇뎁스이신지 알아옴
    const { parentCd, parentLevel } = event.detail
    this.resetForm()
    this.modalTitleTarget.textContent = "하위 메뉴 추가"

    this.fieldParentCdTarget.value = parentCd
    // 부모의 뎁스보다 한 단계 등급을 낮춰(숫자는 더해) 자식 뎁스로 세팅함
    this.fieldMenuLevelTarget.value = Number(parentLevel || 1) + 1
    // 하위라는 것은 보통 클릭해서 타고 들어가는 링크 단위일 확률이 높으므로 MENU로 세팅
    this.fieldMenuTypeTarget.value = "MENU"
    this.fieldMenuCdTarget.readOnly = false
    this.mode = "create"
    this.openModal() // 모달 오픈!
  }

  // 펜 아이콘(수정) 클릭 시, 데이터 바인딩 
  handleEdit = (event) => {
    const data = event.detail.menuData
    this.resetForm()
    this.modalTitleTarget.textContent = "메뉴 수정"

    // 서버가 보유하고 있는 내부 식별자 ID 등 맵핑
    this.fieldIdTarget.value = data.id
    this.fieldMenuCdTarget.value = data.menu_cd
    this.fieldMenuCdTarget.readOnly = true // 이미 DB에 박힌 코드는 재수정하면 DB무결성이 작살나므로 금지

    this.fieldMenuNmTarget.value = data.menu_nm
    this.fieldParentCdTarget.value = data.parent_cd || ""
    this.fieldMenuUrlTarget.value = data.menu_url || ""
    this.fieldMenuIconTarget.value = data.menu_icon || ""
    this.fieldSortOrderTarget.value = data.sort_order
    this.fieldMenuLevelTarget.value = data.menu_level
    this.fieldMenuTypeTarget.value = data.menu_type
    this.fieldUseYnTarget.value = data.use_yn
    this.fieldTabIdTarget.value = data.tab_id || ""

    this.mode = "update" // 업데이트 모드 전환 후
    this.openModal()     // 팝업 표출
  }

  // 양식 백지화
  resetForm() {
    this.formTarget.reset() // DOM clear
    this.fieldIdTarget.value = ""
    this.fieldSortOrderTarget.value = 0
    this.fieldUseYnTarget.value = "Y" // 디폴트 Y할당
  }
}
