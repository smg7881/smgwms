/**
 * Grid 컨트롤러 공통 유틸리티 함수
 *
 * Grid 컨트롤러에서 동일하게 사용되는 순수 유틸리티 함수를 제공한다.
 * 상태를 갖지 않으며, 모든 함수는 named export로 제공된다.
 */

import { showAlert } from "components/ui/alert"
import { resolveAgGridRegistration } from "controllers/grid/grid_event_manager"
import GridCrudManager from "controllers/grid/grid_crud_manager"


export function isApiAlive(api) {
  return Boolean(api) && !(typeof api.isDestroyed === "function" && api.isDestroyed())
}

// 임시 ID 발급용 고유 UUID 문자열 생성 반환 
export function uuid() {
  return `${Date.now()}_${Math.random().toString(36).slice(2, 8)}`
}

// Rails 레이아웃에서 메타 태그로 심겨진 CSRF 토큰(보안) 문자열을 가져옴
export function getCsrfToken() {
  return document.querySelector("[name='csrf-token']")?.content || ""
}

// CSRF 토큰을 탑재하여 JSON 데이터를 POST 메소드로 서버에 전송하는 헬퍼 함수
export async function postJson(url, body) {
  try {
    const response = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": getCsrfToken()
      },
      body: JSON.stringify(body)
    })

    const result = await response.json()
    // HTTP OK 상태 코드가 아니거나 비즈니스 로직(success 플래그) 실패 시 얼럿
    if (!response.ok || !result.success) {
      showAlert("저장 실패: " + (result.errors || ["요청 처리 실패"]).join(", "))
      return false
    }

    return true
  } catch {
    showAlert("저장 실패: 네트워크 오류")
    return false
  }
}

// AbortSignal 등을 받아 JSON 데이터를 GET 해오는 헬퍼 함수
export async function fetchJson(url, { signal } = {}) {
  const response = await fetch(url, {
    headers: { Accept: "application/json" },
    signal
  })
  if (!response.ok) {
    throw new Error(`HTTP ${response.status}`)
  }
  return response.json()
}

// 그리드에 데이터가 1건이라도 표출되어 있다면 "데이터 미존재" 오버레이를 감춤
export function hideNoRowsOverlay(api) {
  if (!isApiAlive(api)) return

  const rowCount = api.getDisplayedRowCount?.() || 0
  if (rowCount > 0) {
    // AG Grid v32+: hideOverlay does not hide loading overlay while loading=true.
    if (typeof api.setGridOption === "function") {
      api.setGridOption("loading", false)
    }
    api.hideOverlay?.()
  }
}

// 전체 그리드의 모든 행(Node)을 순회하며 데이터들을 배열로 가져옴
export function collectRows(api) {
  if (!isApiAlive(api)) return []

  const rows = []
  api.forEachNode((node) => {
    if (node.data) rows.push(node.data)
  })
  return rows
}

// 그리드에 특정 데이터 배열을 일괄 주입하여 그림 (기존 데이터 교체)
export function setGridRowData(api, rows = []) {
  if (!isApiAlive(api)) return false
  api.setGridOption("rowData", rows)
  return true
}

// GridCrudManager가 부착된 경우, 데이터 주입과 동시에 변경 상태 추적(Tracking)까지 초기화함
export function setManagerRowData(manager, rows = []) {
  if (!manager || !isApiAlive(manager.api)) return false

  manager.api.setGridOption("rowData", rows)
  if (typeof manager.resetTracking === "function") {
    manager.resetTracking() // Insert, Update, Delete 흔적 초기화
  }
  return true
}

// 변경된 내역이 생겼을 때, 첫번째(혹은 지정된) 상태 렌더러 컬럼(row_status 아이콘 표기란)을 강제로 다시 그리게 함
export function refreshStatusCells(api, rowNodes) {
  api.refreshCells({
    rowNodes,
    columns: ["__row_status"],
    force: true
  })
}

// GridCrudManager가 추출한 연산 객체(operations) 중 저장할 삽입/수정/삭제 건수가 하나라도 있는지 검증
export function hasChanges(operations) {
  return (
    operations.rowsToInsert.length > 0 ||
    operations.rowsToUpdate.length > 0 ||
    operations.rowsToDelete.length > 0
  )
}

// 문자열 등 형태를 순수 Number 타입으로 파싱하되 실패나 빈값이면 Null 반환
export function numberOrNull(value) {
  if (value == null || value === "") return null

  const numeric = Number(value)
  if (Number.isNaN(numeric)) return null
  return numeric
}

// 그리드 첫 번째 행에 포커스를 설정하고 해당 행 데이터를 반환
export function focusFirstRow(api, { ensureVisible = false, select = false } = {}) {
  if (!isApiAlive(api)) return null

  const node = api.getDisplayedRowAtIndex(0)
  if (!node?.data) return null

  if (ensureVisible) api.ensureIndexVisible(0)

  const col = api.getAllDisplayedColumns()?.[0]
  if (col) api.setFocusedCell(0, col.getColId())

  if (select) node.setSelected(true, true)
  return node.data
}

// GridCrudManager에 미저장 변경사항이 있는지 확인
export function hasPendingChanges(manager) {
  if (!manager) return false
  return hasChanges(manager.buildOperations())
}

// 미저장 변경사항이 있으면 얼럿 후 true 반환 (호출부에서 차단용)
export function blockIfPendingChanges(manager, entityLabel = "마스터") {
  if (!hasPendingChanges(manager)) return false
  showAlert(`${entityLabel}에 저장되지 않은 변경이 있습니다.`)
  return true
}

// URL 템플릿의 :key 플레이스홀더를 실제 값으로 치환
// 두 가지 방식 모두 지원:
//   - 객체 방식: buildTemplateUrl("/wm/gr_prars/:gr_prar_id/save", { gr_prar_id: "GR001" })
//   - 문자열 방식: buildTemplateUrl("/items/:id/children", ":id", "ITEM001")
export function buildTemplateUrl(template, paramsOrPlaceholder, value) {
  if (paramsOrPlaceholder !== null && typeof paramsOrPlaceholder === "object") {
    // 객체 방식: { key: value } 형태로 여러 플레이스홀더 치환
    return Object.entries(paramsOrPlaceholder).reduce((url, [key, val]) => {
      return url.replace(`:${key}`, encodeURIComponent(val ?? ""))
    }, template)
  } else {
    // 문자열 방식: (template, ":placeholder", value) 형태
    return template.replace(paramsOrPlaceholder, encodeURIComponent(value ?? ""))
  }
}

// SELECT 요소에 옵션 목록을 렌더링 (blankLabel=null이면 빈 옵션 생략)
export function setSelectOptions(selectEl, options, selectedValue = "", blankLabel = "전체") {
  if (!selectEl) return ""

  const normalized = (selectedValue || "").toString()
  const values = options.map((o) => o.value.toString())
  const canSelect = normalized && values.includes(normalized)

  selectEl.innerHTML = ""

  if (blankLabel !== null) {
    const blank = document.createElement("option")
    blank.value = ""
    blank.textContent = blankLabel
    selectEl.appendChild(blank)
  }

  options.forEach((opt) => {
    const el = document.createElement("option")
    el.value = opt.value
    el.textContent = opt.label
    selectEl.appendChild(el)
  })

  selectEl.value = canSelect ? normalized : ""
  return selectEl.value
}

// SELECT 요소의 옵션을 빈 옵션 하나만 남기고 초기화
export function clearSelectOptions(selectEl, blankLabel = "전체") {
  setSelectOptions(selectEl, [], "", blankLabel)
}

// 선택 상태 라벨 텍스트를 갱신
export function refreshSelectionLabel(target, value, entityLabel, emptyMessage) {
  if (!target) return
  target.textContent = value
    ? `선택 ${entityLabel}: ${value}`
    : (emptyMessage || `${entityLabel}을(를) 먼저 선택해주세요.`)
}

// 코드→이름 매핑 Map/Object에서 이름을 조회
export function resolveNameFromMap(map, code) {
  if (!code || !map) return ""
  return map[code] || ""
}

// 여러 필드 값을 구분자로 결합하여 복합 키 문자열 생성
export function buildCompositeKey(fields, separator = "::") {
  return fields.join(separator)
}

/**
 * registerGridInstance
 * 
 * 여러 모듈에 흩어진 `registerGrid(event)` 중복 로직을 제거하기 위한 공통 함수.
 * grid_crud_manager 와 ag-grid api 들을 연결하고 모두 등록되었을 때 onAllReady 콜백을 실행한다.
 * 
 * @param {Event} event - ag-grid:ready 커스텀 이벤트 객체
 * @param {Object} context - Stimulus Controller (this)
 * @param {Array} configs - 각 그리드별 설정 배열.
 *        [
 *          { 
 *            target: DOMElement (e.g. this.masterGridTarget), 
 *            isMaster: boolean, // 마스터의 경우 super.registerGrid(event) 등 자체 처리 함수 위임용
 *            setup: function(event) // isMaster 일 때 수행할 콜백
 *          },
 *          {
 *            target: DOMElement (e.g. this.detailGridTarget),
 *            controllerKey: string (e.g. "detailGridController"),
 *            managerKey: string (e.g. "detailManager"),
 *            configMethod: string (e.g. "configureDetailManager") - context 내의 GridCrudManager 설정 반환 메서드 이름
 *          }
 *        ]
 * @param {Function} onAllReady - 지정한 모든 그리드의 api가 준비되었을 때 1회 실행되는 콜백
 */
export function registerGridInstance(event, context, configs, onAllReady) {
  const registration = resolveAgGridRegistration(event)
  if (!registration) return

  const { gridElement, api, controller } = registration

  for (const config of configs) {
    if (!config.target || gridElement !== config.target) continue

    if (config.isMaster && typeof config.setup === "function") {
      config.setup(event)
    } else {
      const { controllerKey, managerKey, configMethod } = config
      if (typeof context[managerKey] !== "undefined" && context[managerKey]) {
        context[managerKey].detach()
      }

      if (controllerKey) {
        context[controllerKey] = controller
      }

      if (managerKey && configMethod && typeof context[configMethod] === "function") {
        context[managerKey] = new GridCrudManager(context[configMethod]())
        context[managerKey].attach(api)
      }
    }
    // 루프 내에서 처리된 대상이 있다면 멈춤
    break
  }

  // 모든 그리드 API가 확보(할당)되었는지 확인
  let allManagersReady = true
  for (const config of configs) {
    // 마스터인 경우 context.manager.api, 서브인 경우 context[managerKey].api 가 보통 있음
    // 서브 컨트롤러 속성만 있는 경우 (historyGridController 등)에는 context[controllerKey].api 판별
    let isReady = false

    if (config.isMaster) {
      if (context.manager && isApiAlive(context.manager.api)) isReady = true
      else if (context._singleGridApi) isReady = true // 읽기 전용 단일 그리드
    } else {
      if (config.managerKey && context[config.managerKey] && isApiAlive(context[config.managerKey].api)) isReady = true
      else if (config.controllerKey && context[config.controllerKey] && isApiAlive(context[config.controllerKey].api)) isReady = true
    }

    if (!isReady) {
      allManagersReady = false
      break
    }
  }

  if (allManagersReady && typeof onAllReady === "function") {
    onAllReady()
  }
}
