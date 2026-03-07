/**
 * 해당 AG-Grid API 인스턴스가 현재 정상적으로 살아있으며(DOM 상에 존재하고),
 * 파기(Destroyed)되지 않은 상태인지 안전망 검사를 수행합니다.
 *
 * @param {Object} api 검사할 AG Grid API 객체
 * @returns {boolean} 사용 가능하면 true
 */
export function isApiAlive(api) {
  return Boolean(api) && !(typeof api.isDestroyed === "function" && api.isDestroyed())
}

