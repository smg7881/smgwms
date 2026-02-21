/**
 * BaseGridController
 *
 * 단일 그리드 CRUD 패턴용 Stimulus 베이스 컨트롤러.
 * GridCrudManager 인스턴스를 자동 생성/관리하며,
 * 서브클래스는 configureManager()로 설정만 반환하면 된다.
 *
 * 서브클래스 훅:
 *   configureManager()          — GridCrudManager config 반환 (필수)
 *   buildNewRowOverrides()      — 새 행 기본값 오버라이드
 *   beforeDeleteRows(nodes)     — 삭제 전 검증 (true 반환 시 차단)
 *   onCellValueChanged(event)   — 셀 값 변경 후 커스텀 처리
 *   afterSaveSuccess()          — 저장 성공 후 커스텀 처리
 *   get saveMessage()           — 저장 완료 메시지
 */
import { Controller } from "@hotwired/stimulus"
import GridCrudManager from "controllers/grid/grid_crud_manager"
import { postJson, hasChanges } from "controllers/grid/grid_utils"

export default class BaseGridController extends Controller {
  static targets = ["grid"]

  static values = {
    batchUrl: String
  }

  connect() {
    this.manager = null
    this.gridController = null
  }

  registerGrid(event) {
    const { api, controller } = event.detail
    this.gridController = controller

    const config = this.configureManager()
    this.manager = new GridCrudManager(config)
    this.manager.attach(api)
  }

  disconnect() {
    if (this.manager) {
      this.manager.detach()
      this.manager = null
    }
    this.gridController = null
  }

  addRow() {
    if (!this.manager) return
    const overrides = this.buildNewRowOverrides?.() || {}
    this.manager.addRow(overrides)
  }

  deleteRows() {
    if (!this.manager) return
    this.manager.deleteRows({
      beforeDelete: this.beforeDeleteRows?.bind(this)
    })
  }

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

  reloadRows() {
    if (this.gridController?.refresh) {
      this.gridController.refresh()
    }
  }

  // --- 서브클래스 훅 (오버라이드 가능) ---

  configureManager() {
    throw new Error("서브클래스에서 configureManager()를 구현해야 합니다.")
  }

  get saveMessage() {
    return "저장이 완료되었습니다."
  }
}
