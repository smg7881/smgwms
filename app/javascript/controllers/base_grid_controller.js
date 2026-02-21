/**
 * BaseGridController
 *
 * 단일 AG Grid CRUD 화면에서 공통으로 쓰는 Stimulus 베이스 컨트롤러입니다.
 *
 * 사용 시점:
 * - 화면 모달 없이 하나의 AG Grid 안에서 바로 행의 추가/수정/삭제 조작 후 
 * - 한 번의 '저장(배치 API 등)' 버튼 클릭으로 전체 변경사항을 전송/흐름 처리하는 편집 가능한 그리드 화면.
 * - 화면의 주요 레이스아웃 제어 로직은 동일하지만, 도메인에 따라 검증(Validation) 및 매핑 설정만 다른 경우 
 *
 * 사용 방법:
 * 1) 화면별 컨트롤러(예: code_grid_controller.js)가 BaseGridController를 상속합니다.
 * 2) 하위 컨트롤러에서 컴포넌트 특성에 맞도록 configureManager() 메서드를 오버라이드하여 GridCrudManager 설정을 반환하도록 구현합니다.
 * 3) 뷰 단(erb 파일)에 있는 ag-grid 엘리먼트가 'ag-grid:ready' 이벤트를 발송하면, 기본 registerGrid() 콜백 메서드가 매니저를 그리드와 결합시킵니다.
 *
 * 서브 클래스에서 덮어쓸(Override) 가능성이 높은 메서드 패턴 (오버라이드 포인트):
 * - configureManager() [필수 구현]
 * - buildNewRowOverrides() [선택] 신규로 행이 추가될 때 행에 주입할 기본값을 반환
 * - beforeDeleteRows(nodes) [선택] 삭제 버튼을 누를 때 수행 전 삭제 대상 조건 검증용 (차단할 시 false 등 로직)
 * - afterSaveSuccess() [선택] 공통 저장 로직 성공 후, 단순 refresh 외에 추가 행동(UI 갱신이나 모달 등)이 필요할 때 덮어씀
 * - saveMessage getter [선택] "저장이 완료되었습니다." 라는 기본 알림 문구를 커스터마이징 하고 싶을 시 사용
 */
import { Controller } from "@hotwired/stimulus"
import GridCrudManager from "controllers/grid/grid_crud_manager"
import { postJson, hasChanges } from "controllers/grid/grid_utils"

export default class BaseGridController extends Controller {
  // 컴포넌트 내에서 조작/참조할 타겟 정의
  static targets = ["grid"]

  // Stimulus의 data-[controller]-batch-url-value 와 결합되는 내부 변수 (저장 API 경로)
  static values = {
    batchUrl: String
  }

  // Stimulus 생명주기 - 컨트롤러가 DOM에 연결되었을 때 호출됩니다.
  // connect 시점에는 Grid Manager 참조 변수만 null로 초기화하고, 실제 AG Grid API 체인 연결은 그리드 준비 후 registerGrid에서 수행합니다.
  connect() {
    this.manager = null
    this.gridController = null
  }

  // ag-grid:ready(detail: { api, controller }) 이벤트를 받아 GridCrudManager를 그리드와 연결합니다.
  // 이 이벤트는 ag_grid_controller.js 초기화 완료 코드가 발송합니다.
  registerGrid(event) {
    const { api, controller } = event.detail
    this.gridController = controller

    // 자식 클래스에서 구현된 구체적인 환경 설정을 상속/호출하여 Manager를 생성합니다.
    const config = this.configureManager()
    this.manager = new GridCrudManager(config)

    // GridCrudManager에 실존하는 AG Grid의 조작 api를 위임하여 부착합니다.
    this.manager.attach(api)
  }

  // Stimulus 생명주기 - 페이지 이탈(Turbo 내비게이션 포함) 또는 엘리먼트 제거 시 불려집니다.
  // 메모리 누수를 방지하기 위해 생성했던 상태를 정리하고 이벤트/모듈 바인딩을 끊어냅니다.
  disconnect() {
    if (this.manager) {
      this.manager.detach()
      this.manager = null
    }
    this.gridController = null
  }

  // [공통 액션] '행 추가' 버튼을 눌렀을 때 실행됩니다.
  addRow() {
    if (!this.manager) return
    // 자식 클래스(서브 컨트롤러)가 buildNewRowOverrides()를 구현했다면 호출하여 데이터 초기값을 설정 객체(overrides)로 만듭니다.
    const overrides = this.buildNewRowOverrides?.() || {}
    this.manager.addRow(overrides)
  }

  // [공통 액션] '행 삭제' 버튼을 눌렀을 때 실행됩니다.
  deleteRows() {
    if (!this.manager) return
    // 삭제 실행의 권한을 manager에게 위임함.
    // 자식 클래스가 beforeDeleteRows 함수를 구현했다면 manager가 내부 검증 시점 때 호출할 수 있도록 콜백 바인딩을 넘깁니다.
    this.manager.deleteRows({
      beforeDelete: this.beforeDeleteRows?.bind(this)
    })
  }

  // [공통 액션] '저장' 버튼을 눌렀을 때 실행되는 메인 저장 프로세스.
  async saveRows() {
    if (!this.manager) return

    // 1. 현재 사용자(클라이언트측)가 편집 중이었던 셀을 강제로 종료시켜 입력 내용을 Cell 값으로 확정합니다.
    this.manager.stopEditing()

    // 2. 관리 중인 트래커에서 변경분(신규 등록, 데이터 변경 수정, 삭제 표시 등)이 담긴 객체 리스트 연산
    const operations = this.manager.buildOperations()
    if (!hasChanges(operations)) {
      alert("변경된 데이터가 없습니다.") // 생성되거나 수정된 이력이 전혀 없으면 불필요한 네트워크 송신 중단
      return
    }

    // 3. 변경사항이 담긴 operations 페이로드를 미리 약속한 엔드포인트(batchUrlValue)로 POST 백그라운드 전송
    const ok = await postJson(this.batchUrlValue, operations)
    if (!ok) return // 오류 발생 등 정상 성공 전송이 아니면 중단

    // 4. 저장 성공 알림 메시지 출력
    alert(this.saveMessage)

    // 5. 성공 이후의 후처리 
    // 기본적으로 그리드를 리로드하지만, 서브 클래스가 afterSaveSuccess() 콜백을 지니고 있다면 이를 우선합니다.
    if (this.afterSaveSuccess) {
      this.afterSaveSuccess()
    } else {
      this.reloadRows()
    }
  }

  // 기본 후처리 액션: ag-grid 컨트롤러에 내정된 refresh 메서드를 다시 호출해 서버로부터 목록 데이터를 다시 갱신하여 받아옵니다.
  reloadRows() {
    if (this.gridController?.refresh) {
      this.gridController.refresh()
    }
  }

  // --- 서브 클래스 계약 구조 (Interface 패턴 유사) ---

  // [필수 구현 강제] 설정 없이 manager가 동작할 수 없으므로 무조건 재정의하여 설정 객체를 반환하도록 강제함.
  configureManager() {
    throw new Error("서브클래스에서 configureManager()를 구현해야 합니다.")
  }

  // [선택 구현] 알림 저장 메시지를 자유롭게 재정의할 수 있도록 getter 패턴 제공
  get saveMessage() {
    return "저장이 완료되었습니다."
  }
}
