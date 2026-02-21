/**
 * GridCrudManager
 *
 * 단일 AG Grid의 CRUD 상태 추적/조작을 캡슐화하는 순수 JS 클래스.
 * Stimulus 컨트롤러와 독립적으로 동작하며, 하나의 AG Grid API에 연결된다.
 *
 * Config 스키마:
 * {
 *   pkFields:          ["workpl_cd", "area_cd"],           // PK 필드 배열
 *   fields:            { field_name: "trim|trimUpper|..." }, // 필드 정규화 규칙
 *   defaultRow:        { use_yn: "Y" },                    // 새 행 기본값
 *   blankCheckFields:  ["code", "name"],                   // 빈 행 판별 필드
 *   comparableFields:  ["name", "use_yn"],                 // 변경 감지 비교 필드
 *   firstEditCol:      "code",                             // 추가 후 편집 시작 컬럼
 *   pkLabels:          { code: "코드" },                   // PK 편집 방지 alert 메시지용
 *   onCellValueChanged: (event) => {},                     // 셀 값 변경 콜백
 *   onRowDataUpdated:   () => {}                           // 행 데이터 갱신 콜백
 * }
 */
import { isApiAlive, uuid, collectRows, refreshStatusCells, hideNoRowsOverlay } from "controllers/grid/grid_utils"

const NORMALIZERS = {
  trim: (v) => (v || "").toString().trim(),
  trimUpper: (v) => (v || "").toString().trim().toUpperCase(),
  number: (v) => {
    if (v == null || v === "") return null
    const n = Number(v)
    return Number.isNaN(n) ? null : n
  }
}

function parseNormalizerSpec(spec) {
  if (spec.startsWith("trimUpperDefault:")) {
    const defaultValue = spec.split(":")[1]
    return (v) => (v || defaultValue).toString().trim().toUpperCase()
  }
  return NORMALIZERS[spec] || NORMALIZERS.trim
}

export default class GridCrudManager {
  #api = null
  #config = null
  #originalMap = new Map()
  #deletedKeys = []
  #isCompositePk = false
  #normalizerMap = new Map()

  #handleCellValueChanged = null
  #handleRowDataUpdated = null

  constructor(config) {
    this.#config = config
    this.#isCompositePk = config.pkFields.length > 1

    Object.entries(config.fields).forEach(([field, spec]) => {
      this.#normalizerMap.set(field, parseNormalizerSpec(spec))
    })

    this.#handleCellValueChanged = (event) => this.#onCellValueChanged(event)
    this.#handleRowDataUpdated = () => this.#onRowDataUpdated()
  }

  get api() {
    return this.#api
  }

  attach(api) {
    this.#api = api
    api.addEventListener("cellValueChanged", this.#handleCellValueChanged)
    api.addEventListener("rowDataUpdated", this.#handleRowDataUpdated)
  }

  detach() {
    if (isApiAlive(this.#api)) {
      this.#api.removeEventListener("cellValueChanged", this.#handleCellValueChanged)
      this.#api.removeEventListener("rowDataUpdated", this.#handleRowDataUpdated)
    }
    this.#api = null
    this.#originalMap = new Map()
    this.#deletedKeys = []
  }

  addRow(overrides = {}, { startCol } = {}) {
    if (!isApiAlive(this.#api)) return

    const newRow = {
      ...this.#config.defaultRow,
      ...overrides,
      __is_new: true,
      __temp_id: uuid()
    }

    const txResult = this.#api.applyTransaction({ add: [newRow], addIndex: 0 })
    hideNoRowsOverlay(this.#api)

    this.#api.startEditingCell({ rowIndex: 0, colKey: startCol || this.#config.firstEditCol })
    return txResult
  }

  deleteRows({ beforeDelete } = {}) {
    if (!isApiAlive(this.#api)) return false

    const selectedNodes = this.#api.getSelectedNodes()
    if (!selectedNodes.length) {
      alert("삭제할 행을 선택하세요.")
      return false
    }

    if (beforeDelete) {
      const blocked = beforeDelete(selectedNodes)
      if (blocked) return false
    }

    const rowsToRemove = []
    const nodesToRefresh = []

    selectedNodes.forEach((node) => {
      const row = node.data
      if (!row) return

      if (row.__is_new) {
        rowsToRemove.push(row)
        return
      }

      const key = this.#extractDeleteKey(row)
      if (key) this.#deletedKeys.push(key)
      row.__is_deleted = true
      delete row.__is_updated
      nodesToRefresh.push(node)
    })

    if (rowsToRemove.length > 0) {
      this.#api.applyTransaction({ remove: rowsToRemove })
    }
    if (nodesToRefresh.length > 0) {
      refreshStatusCells(this.#api, nodesToRefresh)
    }

    return true
  }

  buildOperations() {
    const rows = collectRows(this.#api)

    const rowsToInsert = rows
      .filter((row) => row.__is_new && !row.__is_deleted && !this.#isBlankRow(row))
      .map((row) => this.#pickFields(row))

    const rowsToUpdate = rows
      .filter((row) => !row.__is_new && !row.__is_deleted && this.#rowChanged(row))
      .map((row) => this.#pickFields(row))

    if (this.#isCompositePk) {
      const deleteKeyMap = new Map()
      this.#deletedKeys.forEach((key) => {
        deleteKeyMap.set(this.#serializeKey(key), key)
      })
      rows
        .filter((row) => row.__is_deleted)
        .map((row) => this.#extractDeleteKey(row))
        .filter(Boolean)
        .forEach((key) => {
          deleteKeyMap.set(this.#serializeKey(key), key)
        })

      return { rowsToInsert, rowsToUpdate, rowsToDelete: Array.from(deleteKeyMap.values()) }
    }

    const pkField = this.#config.pkFields[0]
    const rowsToDelete = [
      ...this.#deletedKeys,
      ...rows.filter((row) => row.__is_deleted && row[pkField]).map((row) => row[pkField])
    ]

    return { rowsToInsert, rowsToUpdate, rowsToDelete: [...new Set(rowsToDelete)] }
  }

  resetTracking() {
    this.#deletedKeys = []
    this.#originalMap = new Map()

    collectRows(this.#api).forEach((row) => {
      if (row.__is_new) {
        delete row.__is_updated
        delete row.__is_deleted
        return
      }

      const key = this.#rowKey(row)
      if (key) this.#originalMap.set(key, { ...row })
      delete row.__is_new
      delete row.__is_updated
      delete row.__is_deleted
      delete row.__temp_id
    })
  }

  stopEditing() {
    if (isApiAlive(this.#api)) {
      this.#api.stopEditing()
    }
  }

  // --- Private ---

  #onCellValueChanged(event) {
    if (this.#preventInvalidPrimaryKeyEdit(event)) return
    if (this.#config.onCellValueChanged) {
      this.#config.onCellValueChanged(event)
    }
    this.#markRowUpdated(event)
  }

  #onRowDataUpdated() {
    this.resetTracking()
    if (this.#config.onRowDataUpdated) {
      this.#config.onRowDataUpdated()
    }
  }

  #preventInvalidPrimaryKeyEdit(event) {
    const field = event?.colDef?.field
    if (!this.#config.pkFields.includes(field)) return false
    if (!event?.node?.data) return false

    const row = event.node.data
    if (row.__is_new) return false

    row[field] = event.oldValue || ""
    this.#api.refreshCells({
      rowNodes: [event.node],
      columns: [field],
      force: true
    })

    const label = this.#config.pkLabels?.[field] || field
    alert(`기존 ${label}는 수정할 수 없습니다.`)
    return true
  }

  #markRowUpdated(event) {
    if (!event?.node?.data) return
    if (event.colDef?.field === "__row_status") return
    if (event.newValue === event.oldValue) return

    const row = event.node.data
    if (row.__is_new || row.__is_deleted) return

    row.__is_updated = true
    refreshStatusCells(this.#api, [event.node])
  }

  #pickFields(row) {
    const result = {}
    Object.entries(this.#config.fields).forEach(([field, _spec]) => {
      const normalizer = this.#normalizerMap.get(field)
      result[field] = normalizer(row[field])
    })
    return result
  }

  #extractDeleteKey(row) {
    if (this.#isCompositePk) {
      const key = {}
      for (const field of this.#config.pkFields) {
        const value = (row[field] || "").toString().trim().toUpperCase()
        if (!value) return null
        key[field] = value
      }
      return key
    }

    const pkField = this.#config.pkFields[0]
    return (row[pkField] || "").toString().trim() || null
  }

  #serializeKey(key) {
    if (typeof key === "string") return key
    return this.#config.pkFields.map((f) => key[f]).join("::")
  }

  #rowKey(row) {
    const parts = this.#config.pkFields.map((f) => (row[f] || "").toString().trim().toUpperCase())
    if (parts.some((p) => !p)) return null
    return parts.join("::")
  }

  #rowChanged(row) {
    const key = this.#rowKey(row)
    const original = key ? this.#originalMap.get(key) : null
    if (!original) return true

    return this.#config.comparableFields.some((field) => {
      const spec = this.#config.fields[field]
      if (spec === "number") {
        const a = row[field] == null ? "" : row[field].toString().trim()
        const b = original[field] == null ? "" : original[field].toString().trim()
        return a !== b
      }
      return (row[field] || "").toString().trim() !== (original[field] || "").toString().trim()
    })
  }

  #isBlankRow(row) {
    return this.#config.blankCheckFields.every((field) => (row[field] || "").toString().trim() === "")
  }
}
