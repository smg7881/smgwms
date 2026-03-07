/**
 * grid_event_manager.js
 * 
 * AG Grid에서 발생하는 이벤트를 관리하고, Stimulus 컨트롤러나 DOM 간의 이벤트 전달을 
 * 돕는 유틸리티 클래스/함수들의 모음입니다.
 */
import { isApiAlive } from "controllers/grid/core/api_guard"

/**
 * AG Grid에서 발생한 이벤트 객체로부터 해당 행(Row)의 포커싱된 데이터를 안전하게 추출합니다.
 * 이벤트 객체에 자체 data 맵핑이 없더라도, rowIndex 값을 통해 API에서 역탐색하여 가져옵니다.
 *
 * @param {Object} api AG Grid API 인스턴스
 * @param {Object} event AG Grid Event 객체
 * @returns {Object|null} 추출된 행 데이터 객체 (없으면 null)
 */
export function rowDataFromGridEvent(api, event) {
  if (event?.data) return event.data
  if (!isApiAlive(api)) return null
  if (typeof event?.rowIndex !== "number" || event.rowIndex < 0) return null

  return api.getDisplayedRowAtIndex(event.rowIndex)?.data || null
}

/**
 * 특정 AG Grid의 이벤트 핸들러들을 등록(bind)해 두고, 
 * 생명주기가 끝날 때 한꺼번에 해제(unbindAll)하기 위해 사용하는 상태 보존형 클래스입니다.
 * 주로 컨트롤러 단에서 인스턴스화하여 사용합니다.
 */
export class GridEventManager {
  constructor() {
    this.bindings = [] // 등록된 이벤트 리스너 캐시 배열
  }

  /**
   * AG Grid API에 이벤트를 바인딩하고 이력을 내부 배열에 기록합니다.
   *
   * @param {Object} api AG Grid 인스턴스
   * @param {string} eventName 연결할 AG Grid의 이벤트명 (ex: 'rowClicked')
   * @param {Function} handler 실행될 콜백 함수
   */
  bind(api, eventName, handler) {
    if (!isApiAlive(api) || !eventName || !handler) return

    api.addEventListener(eventName, handler)
    this.bindings.push({ api, eventName, handler })
  }

  /**
   * 내부 배열에 기록된 모든 이벤트들의 리스너를 일괄 해제(removeEventListener)하고,
   * 추적 캐시를 비워 메모리를 정리합니다.
   */
  unbindAll() {
    this.bindings.forEach(({ api, eventName, handler }) => {
      if (!isApiAlive(api)) return
      api.removeEventListener(eventName, handler)
    })
    this.bindings = []
  }
}
