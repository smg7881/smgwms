/**
 * grid_dependent_select_utils.js
 *
 * 계층형 의존 SELECT(검색폼 드롭다운 연동) 공통 유틸리티 함수 모음.
 * grid_form_utils.js와 동일한 설계 원칙을 따릅니다:
 * - 순수 named export 함수 방식
 * - 컨트롤러(controller)를 첫 번째 인자로 받음
 * - 핸들러 참조를 controller._xxx 인스턴스 필드로 저장
 *
 * Config 객체 구조:
 * {
 *   fields: ["workpl_cd", "area_cd", "zone_cd"],  // getSearchFieldElement() 인자
 *   onChange: [
 *     async (controller, fields) => { ... },  // fields[0] 변경 시
 *     async (controller, fields) => { ... }   // fields[1] 변경 시
 *   ],
 *   hydrate: async (controller, fields) => { ... }  // 초기 진입 시 옵션 채우기
 * }
 */

import { fetchJson } from "controllers/grid/core/http_client"
import { showAlert } from "components/ui/alert"

/**
 * 검색 폼 내 지정된 다단계 콤보박스(의존 SELECT) 요소들을 찾아 `change` 이벤트를 리스닝합니다.
 * 컴포넌트 마운트 초기 단계에서 로딩(Hydate) 콜백이 있다면 즉시 수행합니다.
 *
 * @param {Object} controller - BaseGridController 인스턴스
 * @param {Object} config - 의존 SELECT 설정
 * @param {string[]} config.fields - SELECT 필드명 배열 (getSearchFieldElement 인자)
 * @param {Function[]} config.onChange - 각 SELECT 변경 시 실행될 핸들러 배열 (인덱스 0부터)
 * @param {Function} [config.hydrate] - 초기 진입 시 옵션 채우기 핸들러
 */
export async function bindDependentSelects(controller, config) {
  const { fields, onChange, hydrate } = config

  // DOM 엘리먼트 취득 후 컨트롤러 인스턴스 필드로 저장
  controller._dependentFields = fields.map((name) => controller.getSearchFieldElement(name))

  // 각 필드에 이벤트 바인딩 (마지막 필드는 onChange 없을 수 있음)
  controller._dependentHandlers = []
  fields.forEach((name, i) => {
    if (!onChange[i]) return
    const field = controller._dependentFields[i]
    if (!field) return

    const handler = () => onChange[i](controller, controller._dependentFields)
    controller._dependentHandlers[i] = handler
    field.addEventListener("change", handler)
  })

  // 초기 hydration
  if (hydrate) {
    await hydrate(controller, controller._dependentFields)
  }
}

/**
 * 컨트롤러 파기 시점에 호출합니다.
 * `bindDependentSelects`에서 묶어두었던 다단계 콤보박스(SELECT)의 이벤트 리스너들을 모두 해제하여 메모리 누수를 방지합니다.
 *
 * @param {Object} controller - BaseGridController 인스턴스
 */
export function unbindDependentSelects(controller) {
  const fields = controller._dependentFields || []
  const handlers = controller._dependentHandlers || []

  fields.forEach((field, i) => {
    if (field && handlers[i]) {
      field.removeEventListener("change", handlers[i])
    }
  })

  controller._dependentFields = null
  controller._dependentHandlers = null
}

/**
 * 비동기 통신 코어 함수(`fetchJson`)를 래핑하여, 하위 SELECT 옵션 데이터를 동적으로 불러옵니다.
 * 통신 실패 시 사용자에게 알림창(alert)을 띄우고 null을 반환합니다.
 *
 * @param {Object} controller - BaseGridController 인스턴스 (일관성을 위해 포함)
 * @param {string} baseUrl - 요청 URL
 * @param {Object} params - 쿼리 파라미터
 * @param {string} errorMessage - 오류 시 표시할 메시지
 * @returns {Array|null} 결과 배열 또는 null
 */
export async function loadSelectOptions(controller, baseUrl, params, errorMessage) {
  const query = new URLSearchParams(params)

  try {
    return await fetchJson(`${baseUrl}?${query.toString()}`)
  } catch {
    showAlert(errorMessage)
    return null
  }
}

/**
 * 백엔드 통신 없이, 이미 프론트에 로드된 sectionMap 데이터 캐시를 활용해 하위 SELECT 옵션을 계산해내는 순수 함수입니다.
 * 그룹 코드가 지정되지 않았다면 맵 전체의 옵션들을 중복 없이 합쳐서 반환합니다.
 *
 * @param {Object} map { "공통코드": [{label, value}, ...], ... } 형태의 맵 객체
 * @param {string} groupCode - 선택된 그룹 코드 (없으면 전체 dedupe 반환)
 * @returns {Array} { label, value } 옵션 배열
 */
export function resolveMapOptions(map, groupCode) {
  const normalized = (groupCode || "").toString().trim().toUpperCase()
  if (normalized && map[normalized]) return map[normalized]

  const all = Object.values(map).flat()
  const seen = new Set()
  return all.filter((item) => {
    if (!item?.value || seen.has(item.value)) return false
    seen.add(item.value)
    return true
  })
}
