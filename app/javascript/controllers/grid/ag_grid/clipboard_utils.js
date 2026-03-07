/**
 * clipboard_utils.js
 *
 * AG Grid 셀 단위 클립보드(Ctrl+C / Ctrl+V) 처리 유틸리티 함수 모음.
 * ag_grid_controller.js에서 분리된 순수 로직입니다.
 */
import { isApiAlive } from "controllers/grid/core/api_guard"

/**
 * Ctrl/Cmd+C 단축키 여부를 판별합니다.
 * 네이티브 INPUT/TEXTAREA/SELECT 포커스 중에는 false를 반환합니다.
 */
export function isGridCopyShortcut(keyboardEvent) {
  if (!keyboardEvent) return false
  if (isNativeInputTarget(keyboardEvent.target)) return false
  if (!(keyboardEvent.ctrlKey || keyboardEvent.metaKey)) return false
  if (keyboardEvent.altKey) return false
  return String(keyboardEvent.key || "").toLowerCase() === "c"
}

/**
 * Ctrl/Cmd+V 단축키 여부를 판별합니다.
 * 네이티브 INPUT/TEXTAREA/SELECT 포커스 중에는 false를 반환합니다.
 */
export function isGridPasteShortcut(keyboardEvent) {
  if (!keyboardEvent) return false
  if (isNativeInputTarget(keyboardEvent.target)) return false
  if (!(keyboardEvent.ctrlKey || keyboardEvent.metaKey)) return false
  if (keyboardEvent.altKey) return false
  return String(keyboardEvent.key || "").toLowerCase() === "v"
}

/**
 * 이벤트 target이 네이티브 입력 요소인지 판별합니다.
 * (INPUT, TEXTAREA, SELECT, contenteditable)
 */
export function isNativeInputTarget(target) {
  if (!(target instanceof HTMLElement)) return false
  const tagName = target.tagName
  if (tagName === "INPUT" || tagName === "TEXTAREA" || tagName === "SELECT") return true
  if (target.isContentEditable) return true
  return Boolean(target.closest("[contenteditable='true']"))
}

/**
 * AG Grid 셀의 현재 값을 클립보드에 복사합니다.
 * 복사 불가 셀(actions, __ 접두어)은 onWarning을 호출합니다.
 *
 * @param {object} cellEvent - AG Grid cellKeyDown 이벤트 객체
 * @param {{ get: () => string, set: (v: string) => void }} localClipboard - 인메모리 폴백 클립보드 접근자
 * @param {(msg: string) => void} onWarning - 경고 메시지 콜백
 */
export async function copyCurrentCellValue(cellEvent, localClipboard, onWarning) {
  const rowNode = cellEvent?.node
  const colDef = cellEvent?.column?.getColDef?.()
  const field = colDef?.field
  if (!rowNode?.data || !field) {
    onWarning("복사할 수 없는 셀입니다")
    return
  }
  if (field === "actions" || String(field).startsWith("__")) {
    onWarning("복사할 수 없는 셀입니다")
    return
  }

  const rawValue = rowNode.data[field]
  const text = rawValue == null ? "" : String(rawValue)
  localClipboard.set(text)

  const ok = await writeTextToClipboard(text)
  if (!ok) onWarning("시스템 클립보드 복사에 실패했습니다")
}

/**
 * 클립보드 텍스트를 AG Grid 셀에 붙여넣습니다.
 * 붙여넣기 불가 셀(읽기 전용, actions 등)은 onWarning을 호출합니다.
 *
 * @param {object} cellEvent - AG Grid cellKeyDown 이벤트 객체
 * @param {object} gridApi - AG Grid API 인스턴스
 * @param {{ get: () => string, set: (v: string) => void }} localClipboard - 인메모리 폴백 클립보드 접근자
 * @param {(msg: string) => void} onWarning - 경고 메시지 콜백
 */
export async function pasteCurrentCellValue(cellEvent, gridApi, localClipboard, onWarning) {
  const rowNode = cellEvent?.node
  const colDef = cellEvent?.column?.getColDef?.()
  const field = colDef?.field
  if (!rowNode?.data || !field) {
    onWarning("붙여넣을 수 없는 셀입니다")
    return
  }
  if (!canPasteToCell(cellEvent, rowNode, colDef)) {
    onWarning("붙여넣을 수 없는 셀입니다")
    return
  }

  const text = await readTextFromClipboard(localClipboard)
  if (text == null) {
    onWarning("클립보드 텍스트를 읽을 수 없습니다")
    return
  }
  if (String(rowNode.data[field] ?? "") === String(text)) return

  rowNode.setDataValue(field, text)
  if (isApiAlive(gridApi)) {
    gridApi.refreshCells({ rowNodes: [rowNode], columns: [field], force: true })
  }
}

/**
 * 해당 셀에 붙여넣기가 가능한지 판별합니다.
 * 읽기 전용(editable=false), actions, __ 접두어 필드는 불가합니다.
 */
export function canPasteToCell(cellEvent, rowNode, colDef) {
  if (!rowNode?.data || !colDef) return false
  if (colDef.field === "actions") return false
  if (String(colDef.field || "").startsWith("__")) return false

  const column = cellEvent?.column
  if (column?.isCellEditable) {
    return Boolean(column.isCellEditable(rowNode))
  }

  if (typeof colDef.editable === "function") {
    return Boolean(colDef.editable({
      ...cellEvent,
      node: rowNode,
      data: rowNode.data,
      colDef
    }))
  }

  return Boolean(colDef.editable)
}

/**
 * 시스템 클립보드에 텍스트를 씁니다. 실패 시 false를 반환합니다.
 */
export async function writeTextToClipboard(text) {
  if (!navigator?.clipboard?.writeText) return false
  try {
    await navigator.clipboard.writeText(text)
    return true
  } catch (_error) {
    return false
  }
}

/**
 * 시스템 클립보드에서 텍스트를 읽습니다.
 * 권한이 없거나 실패하면 인메모리 폴백 값을 반환합니다.
 *
 * @param {{ get: () => string, set: (v: string) => void }} localClipboard - 인메모리 폴백 클립보드 접근자
 */
export async function readTextFromClipboard(localClipboard) {
  if (navigator?.clipboard?.readText) {
    try {
      const text = await navigator.clipboard.readText()
      localClipboard.set(text)
      return text
    } catch (_error) {
      // 권한 거부 등 → 인메모리 폴백 사용
    }
  }

  const fallback = localClipboard.get()
  if (fallback == null) return null
  return fallback
}
