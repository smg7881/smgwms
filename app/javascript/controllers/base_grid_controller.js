/**
 * BaseGridController
 *
 * 단일 AG Grid CRUD 화면에서 공통으로 쓰는 Stimulus 베이스 컨트롤러입니다.
 *
 * 사용 시점:
 * - 하나의 그리드에서 행 추가/삭제/저장(배치 API) 흐름이 필요한 화면
 * - 화면별로 PK/필드 정규화/변경 비교 규칙만 다르고 흐름은 동일한 경우
 *
 * 사용 방법:
 * 1) 화면 컨트롤러가 BaseGridController를 상속합니다.
 * 2) configureManager()를 구현해 GridCrudManager 설정을 반환합니다.
 * 3) 뷰의 ag-grid가 ag-grid:ready 이벤트를 발생시키면 registerGrid가 자동 결합합니다.
 *
 * 서브 클래스 오버라이드 포인트:
 * - configureManager() [필수]
 * - buildNewRowOverrides() [선택]
 * - beforeDeleteRows(nodes) [선택]
 * - afterSaveSuccess() [선택]
 * - saveMessage getter [선택]
 */
import { Controller } from "@hotwired/stimulus"
import GridCrudManager from "controllers/grid/grid_crud_manager"
import { postJson, hasChanges } from "controllers/grid/grid_utils"

export default class BaseGridController extends Controller {
  static targets = ["grid"]

  static values = {
    batchUrl: String
  }

  // connect 시점에는 참조만 초기화하고, 실제 AG Grid API 연결은 registerGrid에서 수행합니다.
  connect() {
    this.manager = null
    this.gridController = null
  }

  // ag-grid:ready(detail: { api, controller }) 이벤트를 받아 GridCrudManager를 연결합니다.
  registerGrid(event) {
    const { api, controller } = event.detail
    this.gridController = controller

    const config = this.configureManager()
    this.manager = new GridCrudManager(config)
    this.manager.attach(api)
  }

  // 페이지 이탈(Turbo 포함) 시 이벤트/상태를 정리해 메모리 누수를 방지합니다.
  disconnect() {
    if (this.manager) {
      this.manager.detach()
      this.manager = null
    }
    this.gridController = null
  }

  // 공통 행 추가 액션. 필요 시 buildNewRowOverrides()로 초기값을 주입합니다.
  addRow() {
    if (!this.manager) return
    const overrides = this.buildNewRowOverrides?.() || {}
    this.manager.addRow(overrides)
  }

  // 공통 행 삭제 액션. 필요 시 beforeDeleteRows()로 삭제 차단 검증을 넣을 수 있습니다.
  deleteRows() {
    if (!this.manager) return
    this.manager.deleteRows({
      beforeDelete: this.beforeDeleteRows?.bind(this)
    })
  }

  // 공통 저장 액션:
  // 1) 편집 종료 2) 변경분 계산 3) 배치 저장 4) 성공 후 후처리
  async saveRows() {
    if (!this.manager) return

    this.manager.stopEditing()
    const operations = this.manager.buildOperations()
    if (!hasChanges(operations)) {
      alert("변경된 데이터가 없습니다.")
      return
    }

    const ok = await postJson(this.batchUrlValue, operations)
    if (!ok) return

    alert(this.saveMessage)
    if (this.afterSaveSuccess) {
      this.afterSaveSuccess()
    } else {
      this.reloadRows()
    }
  }

  // 기본 후처리: ag-grid 컨트롤러의 refresh를 호출해 목록을 다시 조회합니다.
  reloadRows() {
    if (this.gridController?.refresh) {
      this.gridController.refresh()
    }
  }

  // --- 서브 클래스 계약 ---

  // 필수 구현: GridCrudManager 설정 객체를 반환해야 합니다.
  configureManager() {
    throw new Error("서브클래스에서 configureManager()를 구현해야 합니다.")
  }

  // 선택 구현: 저장 완료 메시지 커스터마이즈
  get saveMessage() {
    return "저장이 완료되었습니다."
  }
}
