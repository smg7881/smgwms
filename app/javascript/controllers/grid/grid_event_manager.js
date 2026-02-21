/**
 * grid_event_manager.js
 * 
 * AG Grid에서 발생하는 이벤트를 관리하고, Stimulus 컨트롤러나 DOM 간의 이벤트 전달을 
 * 돕는 유틸리티 클래스/함수들의 모음입니다.
 */
import { isApiAlive } from "controllers/grid/grid_utils"

// 메인 AG Grid 컨트롤러가 바인딩되는 CSS 선택자
const AG_GRID_SELECTOR = "[data-controller='ag-grid']"

/**
 * resolveAgGridRegistration
 * 
 * 이벤트 타겟으로부터 가장 가까운 AG Grid 컨트롤러 엘리먼트를 찾고, 
 * 그 엘리먼트에 연결된 API와 컨트롤러 인스턴스를 반환하는 함수입니다.
 */
export function resolveAgGridRegistration(event) {
  const gridElement = event?.target?.closest?.(AG_GRID_SELECTOR)
  if (!gridElement) return null

  const { api, controller } = event.detail || {}
  if (!api) return null

  return { gridElement, api, controller }
}

/**
 * rowDataFromGridEvent
 * 
 * AG Grid에서 발생한 이벤트 객체로부터 해당 행(Row)의 데이터를 안전하게 추출합니다.
 */
export function rowDataFromGridEvent(api, event) {
  if (event?.data) return event.data
  if (!isApiAlive(api)) return null
  if (typeof event?.rowIndex !== "number" || event.rowIndex < 0) return null

  return api.getDisplayedRowAtIndex(event.rowIndex)?.data || null
}

/**
 * GridEventManager
 * 
 * 특정 AG Grid의 이벤트 핸들러들을 등록(bind)해 두고, 
 * 생명주기가 끝날 때 한꺼번에 해제(unbindAll)하기 위해 사용하는 상태 보존형 클래스입니다.
 */
export class GridEventManager {
  constructor() {
    this.bindings = [] // 등록된 이벤트 리스너 캐시 배열
  }

  // AG Grid API에 이벤트를 바인딩하고 추적 배열에 기록합니다.
  bind(api, eventName, handler) {
    if (!isApiAlive(api) || !eventName || !handler) return

    api.addEventListener(eventName, handler)
    this.bindings.push({ api, eventName, handler })
  }

  // 배열에 기록된 모든 이벤트를 일괄 이벤트리스너 해제(remove)하고 비웁니다.
  unbindAll() {
    this.bindings.forEach(({ api, eventName, handler }) => {
      if (!isApiAlive(api)) return
      api.removeEventListener(eventName, handler)
    })
    this.bindings = []
  }
}
