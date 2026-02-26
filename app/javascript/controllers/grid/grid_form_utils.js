/**
 * grid_form_utils.js
 * 
 * 마스터-디테일 구조의 화면에서 우측 상세 폼(Detail Form)과 
 * 마스터 그리드 간의 데이터 동기화, UI 제어 등을 처리하는 공통 유틸리티 함수 모음
 */

import { isApiAlive } from "controllers/grid/grid_utils"

/**
 * 선택된 마스터 행 데이터를 기반으로 우측 상세 폼 입력창들의 값을 채움
 */
export function fillDetailForm(controller, rowData, options = {}) {
    const { beforeFill, afterFill, onFieldFill } = options

    toggleDetailFields(controller, false, options)

    if (beforeFill) beforeFill(rowData)

    if (controller.hasDetailFieldTarget || controller.detailFieldTargets) {
        controller.detailFieldTargets.forEach((field) => {
            const key = detailFieldKey(field)
            if (!key) return

            const normalized = controller.normalizeValueForInput ? controller.normalizeValueForInput(key, rowData[key]) : (rowData[key] || "")
            field.value = normalized

            if (onFieldFill) onFieldFill(field, key, normalized, rowData)
        })
    }

    if (afterFill) afterFill(rowData)
}

/**
 * 상세 폼 초기화
 */
export function clearDetailForm(controller, options = {}) {
    const { beforeClear, afterClear, onFieldClear } = options

    if (beforeClear) beforeClear()

    if (controller.hasDetailFieldTarget || controller.detailFieldTargets) {
        controller.detailFieldTargets.forEach((field) => {
            field.value = ""
            const key = detailFieldKey(field)
            if (onFieldClear && key) onFieldClear(field, key)
        })
    }

    toggleDetailFields(controller, true, options)

    if (afterClear) afterClear()
}

/**
 * 상세 폼 입력창 활성화 상태 토글
 */
export function toggleDetailFields(controller, disabled, options = {}) {
    const { onFieldToggle } = options

    if (controller.hasDetailFieldTarget || controller.detailFieldTargets) {
        controller.detailFieldTargets.forEach((field) => {
            field.disabled = disabled
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
 * 상세 폼의 입력값이 변경될 때 마스터 그리드의 해당 행 데이터를 실시간 업데이트
 */
export function syncDetailField(event, controller) {
    if (!controller.currentMasterRow) return

    const fieldEl = event.currentTarget
    const key = detailFieldKey(fieldEl)
    if (!key) return

    const originalValue = fieldEl.value
    const normalized = controller.normalizeDetailFieldValue ? controller.normalizeDetailFieldValue(key, originalValue) : originalValue

    if (originalValue !== normalized) {
        fieldEl.value = normalized
    }

    controller.currentMasterRow[key] = normalized

    markCurrentMasterRowUpdated(controller)
    refreshMasterRowCells(controller, [key, "__row_status"])
}

/**
 * 필드의 dataset, name, id 속성으로부터 매핑될 데이터를 추출하여 데이터 키 반환
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
 * 폼 필드 이벤트 리스너 바인딩
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
 * 폼 필드 이벤트 리스너 해제
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
 * 현재 마스터 로우의 변경 상태 마킹
 */
export function markCurrentMasterRowUpdated(controller) {
    if (!controller.currentMasterRow) return
    if (controller.currentMasterRow.__is_new || controller.currentMasterRow.__is_deleted) return

    controller.currentMasterRow.__is_updated = true
}

/**
 * 마스터 그리드에서 데이터에 매칭되는 행(Node) 검색
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
 * 마스터 행의 특정 셀들을 리프레시하여 새 값과 상태 반영
 */
export function refreshMasterRowCells(controller, columns = []) {
    if (!isApiAlive(controller.manager?.api) || !controller.currentMasterRow) return

    const node = findMasterNodeByData(controller, controller.currentMasterRow)
    if (!node) return

    controller.manager.api.refreshCells({
        rowNodes: [node],
        columns,
        force: true
    })
}
