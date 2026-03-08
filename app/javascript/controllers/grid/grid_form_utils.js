/**
 * grid_form_utils.js
 *
 * 마스터-디테일 구조의 화면에서 우측 상세 폼(Detail Form)과
 * 마스터 그리드 간의 데이터 동기화, UI 제어 등을 처리하는 공통 유틸리티 함수 모음
 */

import { isApiAlive } from "controllers/grid/core/api_guard"
import { getResourceFormValueFromElement, setResourceFormValue } from "controllers/grid/core/resource_form_bridge"
import { refreshGridCells } from "controllers/grid/grid_api_utils"

/**
 * 날짜형 데이터(Date 객체 혹은 날짜 문자열)를 HTML5 `<input type="date">` 요소와 호환되는
 * 순수 "YYYY-MM-DD" 포맷의 텍스트로 변환해주는 유틸리티 함수입니다.
 * @param {any} value 변환할 원본 날짜 데이터
 * @returns {string} yyyy-mm-dd 형식 문자열 (유효하지 않으면 빈 문자열)
 */
export function toDateInputValue(value) {
  const source = (value || "").toString().trim()
  if (source === "") return ""
  if (/^\d{4}-\d{2}-\d{2}$/.test(source)) return source

  const parsed = new Date(source)
  if (Number.isNaN(parsed.getTime())) return ""

  const yyyy = parsed.getFullYear()
  const mm = `${parsed.getMonth() + 1}`.padStart(2, "0")
  const dd = `${parsed.getDate()}`.padStart(2, "0")
  return `${yyyy}-${mm}-${dd}`
}

/**
 * 코드에 의해(프로그래밍 방식) 우측 디테일 폼의 값이 변경될 때, 다시 마스터 그리드로
 * 변경 사항이 무한 순환 역동기화되는 것을 방지하기 위한 Lock(억제) 래퍼 함수입니다.
 * @param {Object} controller BaseGridController 인스턴스
 * @param {Function} callback 동기화 억제 상태에서 수행할 콜백 함수
 */
function withDetailSyncSuppressed(controller, callback) {
  const previous = controller._suppressDetailFieldSync === true
  controller._suppressDetailFieldSync = true

  try {
    callback()
  } finally {
    controller._suppressDetailFieldSync = previous
  }
}

/**
 * 폼 태그 내부의 개별 입력 노드(Input, Select, Checkbox 등)의 성격에 맞게
 * 타입 캐스팅 및 상태 토글링을 진행하며 안전하게 값을 주입합니다.
 * (resource_form의 브릿지가 켜져있다면, 브릿지 쪽 세팅으로 우회 위임합니다.)
 * @param {Object} controller BaseGridController 인스턴스
 * @param {HTMLElement} fieldEl 값을 주입할 대상 폼 필드 엘리먼트
 * @param {any} value 주입하고자 하는 실제 값
 */
function setDetailFieldValue(controller, fieldEl, value) {
  const fieldName = fieldEl.getAttribute("name")
  if (!fieldName) return false

  return setResourceFormValue(controller.application, fieldName, value, { fieldElement: fieldEl })
}

/**
 * 폼 요소(Element)로부터 현재 사용자가 입력해 둔 실제 값을 타입 훼손 없이 올바르게 추출해냅니다.
 * @param {Object} controller BaseGridController 인스턴스
 * @param {HTMLElement} fieldEl 값을 추출할 대상 폼 필드 엘리먼트
 * @returns {any} 추출된 필드 값
 */
function getDetailFieldValue(controller, fieldEl) {
  return getResourceFormValueFromElement(controller.application, fieldEl)
}

/**
 * 마스터 그리드에서 선택된 특정 행 데이터(rowData)를 일괄적으로 읽어와,
 * `detailFieldTargets` 로 묶인 우측/하단 디테일 폼의 모든 입력창들에 알맞게 채워 넣습니다.
 *
 * @param {Object} controller 대상 BaseGridController 인스턴스
 * @param {Object} rowData 폼에 채워넣을 마스터 그리드 행 데이터 원본 (Key-Value)
 * @param {Object} [options] 전, 후, 개별 필드 채움 시 발동시킬 커스텀 Hook 콜백들
 */
export function fillDetailForm(controller, rowData, options = {}) {
  const { beforeFill, afterFill, onFieldFill } = options

  toggleDetailFields(controller, false, options)

  if (beforeFill) beforeFill(rowData)

  if (controller.hasDetailFieldTarget || controller.detailFieldTargets) {
    withDetailSyncSuppressed(controller, () => {
      controller.detailFieldTargets.forEach((field) => {
        const key = detailFieldKey(field)
        if (!key) return

        const normalized = controller.normalizeValueForInput ? controller.normalizeValueForInput(key, rowData[key]) : (rowData[key] || "")
        setDetailFieldValue(controller, field, normalized)

        if (onFieldFill) onFieldFill(field, key, normalized, rowData)
      })
    })
  }

  if (afterFill) afterFill(rowData)
}

/**
 * `detailFieldTargets` 로 묶인 상세 폼의 모든 입력값들을 빈칸("") 으로 일괄 초기화하고,
 * 필요에 따라 폼 영역 자체를 disabled(비활성화) 처리합니다.
 * 신규 추가를 대기하거나, 마스터 선택이 해제되었을 때 주로 호출됩니다.
 *
 * @param {Object} controller 대상 BaseGridController 인스턴스
 * @param {Object} [options] 전, 후, 필드 렌더 시 발동시킬 커스텀 Hook 콜백들
 */
export function clearDetailForm(controller, options = {}) {
  const { beforeClear, afterClear, onFieldClear } = options

  if (beforeClear) beforeClear()

  if (controller.hasDetailFieldTarget || controller.detailFieldTargets) {
    withDetailSyncSuppressed(controller, () => {
      controller.detailFieldTargets.forEach((field) => {
        setDetailFieldValue(controller, field, "")
        const key = detailFieldKey(field)
        if (onFieldClear && key) onFieldClear(field, key)
      })
    })
  }

  toggleDetailFields(controller, true, options)

  if (afterClear) afterClear()
}

/**
 * 디테일 폼 내부의 입력 요소들과 연계된 조회(Lookup) 버튼들의 활성/비활성 여부를 일괄 토글합니다.
 * @param {Object} controller 대상 BaseGridController 인스턴스
 * @param {boolean} disabled true 이면 폼 사용 불가(Read-Only), false 이면 작성 가능
 * @param {Object} [options] 각 필드 토글마다 추가 진행할 커스텀 콜백 (onFieldToggle)
 */
export function toggleDetailFields(controller, disabled, options = {}) {
  const { onFieldToggle } = options

  if (controller.hasDetailFieldTarget || controller.detailFieldTargets) {
    controller.detailFieldTargets.forEach((field) => {
      field.disabled = disabled
      if (field.tomselect) {
        disabled ? field.tomselect.disable() : field.tomselect.enable()
      }
      if (onFieldToggle) onFieldToggle(field, disabled)
    })
  }

  if (controller.hasLookupButtonTarget || controller.lookupButtonTargets) {
    controller.lookupButtonTargets.forEach((button) => {
      button.disabled = disabled
    })
  }
}

/**
 * 우측 디테일 폼 영역에서 사용자의 이벤트(Input, Change)로 인해 필드 값이 변경될 때,
 * 이를 낚아채어 현재 선택되어 있는 '마스터 그리드의 행 데이터(currentMasterRow)' 에 실시간으로 역동기화(Patch)해 줍니다.
 *
 * @param {Event} event 발생한 DOM 이벤트 (Input, Change 방아쇠)
 * @param {Object} controller 이벤트를 수신한 BaseGridController 인스턴스
 */
export function syncDetailField(event, controller) {
  if (controller._suppressDetailFieldSync) return
  if (!controller.currentMasterRow) return

  const fieldEl = event.currentTarget
  const key = detailFieldKey(fieldEl)
  if (!key) return

  const originalValue = getDetailFieldValue(controller, fieldEl)
  const normalized = controller.normalizeDetailFieldValue ? controller.normalizeDetailFieldValue(key, originalValue) : originalValue

  if (originalValue !== normalized) {
    withDetailSyncSuppressed(controller, () => {
      setDetailFieldValue(controller, fieldEl, normalized)
    })
  }

  controller.currentMasterRow[key] = normalized

  markCurrentMasterRowUpdated(controller)
  refreshMasterRowCells(controller, [key, "__row_status"])
}

/**
 * HTML 요소(`fieldEl`)가 지니고 있는 속성(dataset.field, name, id 등)을 다각도로 분석하여,
 * 해당 폼 요소가 백엔드 데이터베이스 상에서 어떤 필드(Key)와 매칭되는지 문자열 코드로 역산출해 냅니다.
 * @param {HTMLElement} fieldEl 분석할 DOM 요소 노드
 * @returns {string} 파싱된 데이터베이스 컬럼 혹은 필드 키본명
 */
export function detailFieldKey(fieldEl) {
  if (!fieldEl) return ""

  const keyFromDataset = fieldEl.dataset.field
  if (keyFromDataset) return keyFromDataset

  const nameAttr = fieldEl.getAttribute("name") || ""
  const matchFromName = nameAttr.match(/\[([^\]]+)\]$/)
  if (matchFromName) return matchFromName[1]

  const idAttr = fieldEl.getAttribute("id") || ""
  const matchFromId = idAttr.match(/_([a-z0-9_]+)$/i)
  if (matchFromId) return matchFromId[1]

  return ""
}

/**
 * 상세 폼(`detailFieldTargets`) 전체에 'input' 및 'change' 이벤트 리스너를 바인딩하여,
 * 타이핑 즉시 마스터 그리드와 실시간 양방향 동기화(`syncDetailField`)가 일어나도록 세팅합니다.
 * 컨트롤러가 Mount(Connect) 될 때 단발성으로 호출해야 합니다.
 *
 * @param {Object} controller 이벤트가 바인딩 될 BaseGridController 인스턴스
 * @param {Function|null} onInputCallback (선택) 외부에서 주입할 커스텀 Input 이벤트 래퍼
 * @param {Function|null} onChangeCallback (선택) 외부에서 주입할 커스텀 Change 이벤트 래퍼
 */
export function bindDetailFieldEvents(controller, onInputCallback = null, onChangeCallback = null) {
  unbindDetailFieldEvents(controller)

  controller._onDetailInput = onInputCallback || ((event) => {
    if (controller.syncDetailField) {
      controller.syncDetailField(event)
    } else {
      syncDetailField(event, controller)
    }
  })

  controller._onDetailChange = onChangeCallback || ((event) => {
    if (controller.syncDetailField) {
      controller.syncDetailField(event)
    } else {
      syncDetailField(event, controller)
      // Custom controller logic like tracking dependent fields
      if (controller.onDetailChangeExt) {
        controller.onDetailChangeExt(event)
      }
    }
  })

  if (controller.hasDetailFieldTarget || controller.detailFieldTargets) {
    controller.detailFieldTargets.forEach((field) => {
      field.addEventListener("input", controller._onDetailInput)
      field.addEventListener("change", controller._onDetailChange)
    })
  }
}

/**
 * `bindDetailFieldEvents` 에 의해 폼 전체에 걸려있던 동기화 연동 이벤트 리스너들을 모두 제거합니다.
 * 컨트롤러 해제(Disconnect) 시 메모리 누수를 방지하기 위해 필수 호출되어야 합니다.
 *
 * @param {Object} controller 이벤트 바인딩을 해제할 BaseGridController 인스턴스
 */
export function unbindDetailFieldEvents(controller) {
  if (!controller._onDetailInput && !controller._onDetailChange) return

  if (controller.hasDetailFieldTarget || controller.detailFieldTargets) {
    controller.detailFieldTargets.forEach((field) => {
      if (controller._onDetailInput) {
        field.removeEventListener("input", controller._onDetailInput)
      }
      if (controller._onDetailChange) {
        field.removeEventListener("change", controller._onDetailChange)
      }
    })
  }

  controller._onDetailInput = null
  controller._onDetailChange = null
}

/**
 * 폼 수정 등으로 인해 현재 포커싱 된 마스터 그리드의 데이터에 변경사항이 파생(Diff)되었을 경우,
 * 데이터 뭉치인 `currentMasterRow` 객체 내부에 `__is_updated: true` 플래그를 찍어줍니다.
 *
 * @param {Object} controller BaseGridController 인스턴스
 */
export function markCurrentMasterRowUpdated(controller) {
  if (!controller.currentMasterRow) return
  if (controller.currentMasterRow.__is_new || controller.currentMasterRow.__is_deleted) return

  controller.currentMasterRow.__is_updated = true
}

/**
 * 특정 JSON 데이터 객체(`rowData`) 원본 참조값과 정확히 1:1 결합(맵핑)되어 있는
 * 실제 AG-Grid 내부의 행 노드(RowNode)를 전체 순회 탐색을 통해 찾아내 반환합니다.
 * @param {Object} controller BaseGridController
 * @param {Object} rowData 대상 행 데이터 객체 원본
 * @returns {Object|null} 매칭된 RowNode (없으면 null)
 */
export function findMasterNodeByData(controller, rowData) {
  if (!isApiAlive(controller.manager?.api) || !rowData) return null

  let found = null
  controller.manager.api.forEachNode((node) => {
    if (node.data === rowData) {
      found = node
    }
  })
  return found
}

/**
 * `findMasterNodeByData` 유틸리티를 활용해 마스터 그리드의 타겟 행을 찾아낸 뒤,
 * 인자로 넘겨진 특정 컬럼명 배열에 대해서만 셀 UI(화면)를 강제 새로고침(Refresh) 처리 합니다.
 * 주로 폼 동기화 결과물이 그리드 화면상에도 즉각 반영되어야 할 때 호출합니다.
 *
 * @param {Object} controller BaseGridController 인스턴스
 * @param {Array<string>} columns 강제로 다시 그릴(Refresh) 대상 컬럼 ID 배열
 */
export function refreshMasterRowCells(controller, columns = []) {
  if (!isApiAlive(controller.manager?.api) || !controller.currentMasterRow) return

  const node = findMasterNodeByData(controller, controller.currentMasterRow)
  if (!node) return

  refreshGridCells(controller.manager.api, {
    rowNodes: [node],
    columns,
    force: true
  })
}
