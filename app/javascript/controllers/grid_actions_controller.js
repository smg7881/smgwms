/**
 * grid_actions_controller.js
 * 
 * 그리드 바깥에 위치한 "조회조건 영역"이나 "최상단 버튼 영역" 등에 포진한
 * [필터초기화], [컬럼저장], [컬럼초기화], [엑셀다운] 등과 같은 '그리드 간접제어 액션 버튼'들을 누를 때,
 * 해당 액션이 실제 목적지인 ag_grid_controller 로 안전하게 위임(Delegate)되도록 이어주는 역할을 하는 컨트롤러입니다.
 */
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // 타겟 그리드 컴포넌트의 고유 아이디 문자열
  static values = {
    gridId: String
  }

  // [컬럼 너비/순서 저장 버튼 클릭 핸들러]
  saveColumnState() {
    const agGridController = this.#findAgGridController()
    if (!agGridController) return

    agGridController.saveColumnState(this.gridIdValue)
  }

  // [컬럼 너비/순서 원본복구 버튼 클릭 핸들러]
  resetColumnState() {
    const agGridController = this.#findAgGridController()
    if (!agGridController) return

    agGridController.resetColumnState(this.gridIdValue)
  }

  // [엑셀 다운로드 버튼 클릭 핸들러]
  exportCsv() {
    const agGridController = this.#findAgGridController()
    if (!agGridController) return

    agGridController.exportCsv() // 그리드 컨트롤러 내부 exportCsv 진입 유도
  }

  // [헤더조건 필터 클리어 버튼 클릭 핸들러]
  clearFilter() {
    const agGridController = this.#findAgGridController()
    if (!agGridController) return

    agGridController.clearFilter()
  }

  // ----------------------------------------------------------------------
  // [Private Core] 
  // 화면에 렌더링되어있는 무수히 많은 DOM 중에 "gridIdValue" 를 가진
  // 본래의 메인 AG Grdid 객체가 부착된 컨트롤러 인스턴스를 역탐색하는 로직
  // ----------------------------------------------------------------------
  #findAgGridController() {
    const gridId = this.gridIdValue
    // 1단계: HTML 속성 중 data-ag-grid-grid-id-value=OOO 인 div 요소 특정
    const selector = `[data-ag-grid-grid-id-value="${gridId}"]`
    const agGridEl = document.querySelector(selector)
    if (!agGridEl) return null

    // 2단계: Stimulus Application Global 레지스트리에서 해당 DOM과 'ag-grid' 식별자로 묶여있는 JS 인스턴스를 강제 추출하여 리턴
    return this.application.getControllerForElementAndIdentifier(agGridEl, "ag-grid")
  }
}
