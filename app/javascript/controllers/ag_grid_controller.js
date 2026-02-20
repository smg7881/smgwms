import { Controller } from "@hotwired/stimulus"
import {
  createGrid,
  themeQuartz,
  ModuleRegistry,
  AllCommunityModule
} from "ag-grid-community"
import { RENDERER_REGISTRY } from "controllers/ag_grid/renderers"

const FORMATTER_REGISTRY = {
  currency: (params) => params.value != null ? `\\${Number(params.value).toLocaleString()}` : "",
  date: (params) => params.value ? new Date(params.value).toLocaleDateString("ko-KR") : "",
  datetime: (params) => params.value ? new Date(params.value).toLocaleString("ko-KR") : "",
  percent: (params) => params.value != null ? `${params.value}%` : "",
  truncate: (params) => (params.value?.length > 50 ? `${params.value.slice(0, 50)}...` : (params.value || ""))
}

const AG_GRID_LOCALE_KO = {
  page: "Page",
  of: "/",
  to: "~",
  nextPage: "Next Page",
  lastPage: "Last Page",
  firstPage: "First Page",
  previousPage: "Previous Page",
  pageSizeSelectorLabel: "Page Size:",
  loadingOoo: "조회중",
  noRowsToShow: "데이터 미존재",
  filterOoo: "필터 검색...",
  blank: "비어 있음",
  notBlank: "비어 있지 않음",
  empty: "값 선택",
  equals: "같음",
  notEqual: "같지 않음",
  contains: "포함",
  notContains: "포함하지 않음",
  startsWith: "시작하는 단어",
  endsWith: "끝나는 단어",
  lessThan: "미만",
  greaterThan: "초과",
  lessThanOrEqual: "이하",
  greaterThanOrEqual: "이상",
  andCondition: "그리고",
  orCondition: "또는",
  applyFilter: "적용",
  resetFilter: "초기화",
  clearFilter: "지우기",
  cancelFilter: "취소",
  columns: "Columns",
  copy: "Copy",
  ctrlC: "Ctrl+C",
  csvExport: "CSV Export",
  export: "Export",
  sortAscending: "Sort Ascending",
  sortDescending: "Sort Descending",
  sortUnSort: "Clear Sort"
}

const darkTheme = themeQuartz.withParams({
  backgroundColor: "#161b22",
  foregroundColor: "#e6edf3",
  headerBackgroundColor: "#1c2333",
  headerTextColor: "#8b949e",
  borderColor: "#30363d",
  inputBorder: "solid 1px #30363d",
  inputFocusBorder: "solid 1px #58a6ff",
  inputBorderRadius: 4,
  inputFocusBoxShadow: "0 0 0 2px rgba(88, 166, 255, 0.3)",
  menuBackgroundColor: "#1c2333",
  menuBorder: "solid 1px #30363d",
  rowHoverColor: "#21262d",
  accentColor: "#58a6ff",
  oddRowBackgroundColor: "#0f1117",
  headerFontSize: 12,
  fontSize: 13,
  borderRadius: 8,
  wrapperBorderRadius: 8,
  fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif'
})

let modulesRegistered = false
if (!modulesRegistered) {
  ModuleRegistry.registerModules([AllCommunityModule])
  modulesRegistered = true
}

export default class extends Controller {
  static targets = ["grid"]

  #serverPage = 1
  #serverTotal = 0
  #suppressPaginationEvent = false

  static values = {
    columns: { type: Array, default: [] },
    url: String,
    rowData: { type: Array, default: [] },
    pagination: { type: Boolean, default: true },
    pageSize: { type: Number, default: 20 },
    height: { type: String, default: "500px" },
    rowSelection: { type: String, default: "" },
    serverPagination: { type: Boolean, default: false },
    gridId: { type: String, default: "" }
  }

  connect() {
    this.focusedRowNode = null
    this.#serverPage = 1
    this.#serverTotal = 0
    this.initGrid()
    this._beforeCache = () => this.teardown()
    document.addEventListener("turbo:before-cache", this._beforeCache)
  }

  disconnect() {
    document.removeEventListener("turbo:before-cache", this._beforeCache)
    this.teardown()
  }

  refresh() {
    if (!this.isApiAlive(this.gridApi)) return
    if (this.serverPaginationValue) {
      this.#serverPage = 1
      this.fetchServerPage()
    } else if (this.hasUrlValue && this.urlValue) {
      this.fetchData()
    }
  }

  get api() {
    return this.gridApi
  }

  exportCsv() {
    if (!this.isApiAlive(this.gridApi)) return
    this.gridApi.exportDataAsCsv()
  }

  initGrid() {
    const gridOptions = {
      theme: darkTheme,
      columnDefs: this.buildColumnDefs(),
      defaultColDef: this.defaultColDef(),
      pagination: this.paginationValue,
      paginationPageSize: this.pageSizeValue,
      paginationPageSizeSelector: [10, 20, 50, 100],
      localeText: AG_GRID_LOCALE_KO,
      icons: {
        filter: '<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" style="color: #8b949e;"><polygon points="22 3 2 3 10 12.46 10 19 14 21 14 12.46 22 3"/></svg>'
      },
      animateRows: true,
      getRowClass: (params) => this.buildRowClass(params),
      onCellFocused: (event) => this.handleCellFocused(event),
      rowData: [],
      overlayNoRowsTemplate: `<span class="ag-overlay-no-rows-center">${AG_GRID_LOCALE_KO.noRowsToShow}</span>`,
      stopEditingWhenCellsLoseFocus: true
    }

    this.defaultNoRowsTemplate = gridOptions.overlayNoRowsTemplate

    if (this.serverPaginationValue) {
      gridOptions.onPaginationChanged = (event) => this.#handleServerPaginationChanged(event)
    }

    if (this.rowSelectionValue) {
      gridOptions.rowSelection = {
        mode: this.rowSelectionValue === "single" ? "singleRow" : "multiRow"
      }
      gridOptions.selectionColumnDef = {
        width: 46,
        minWidth: 46,
        maxWidth: 46,
        sortable: false,
        filter: false,
        resizable: false,
        suppressHeaderMenuButton: true
      }
    }

    this.gridTarget.style.height = this.heightValue
    this.gridTarget.style.width = "100%"
    this.gridApi = createGrid(this.gridTarget, gridOptions)
    this.ensureStatusColumnOrder()

    if (this.serverPaginationValue) {
      this.#serverPage = 1
      this.fetchServerPage()
    } else if (this.hasUrlValue && this.urlValue) {
      this.fetchData()
    } else if (this.rowDataValue.length > 0 && this.isApiAlive(this.gridApi)) {
      this.focusedRowNode = null
      this.gridApi.setGridOption("rowData", this.rowDataValue)
    }

    this.#restoreColumnState()

    this.element.dispatchEvent(new CustomEvent("ag-grid:ready", {
      bubbles: true,
      detail: { api: this.gridApi, controller: this }
    }))
  }

  saveColumnState(gridId) {
    const id = gridId || this.gridIdValue
    if (!id || !this.isApiAlive(this.gridApi)) return

    const state = this.gridApi.getColumnState()
    localStorage.setItem(this.#storageKey(id), JSON.stringify(state))
    this.#showToast("컬럼 상태가 저장되었습니다")
  }

  resetColumnState(gridId) {
    const id = gridId || this.gridIdValue
    if (!id || !this.isApiAlive(this.gridApi)) return

    localStorage.removeItem(this.#storageKey(id))
    this.gridApi.resetColumnState()
    this.#showToast("컬럼 상태가 초기화되었습니다")
  }

  teardown() {
    if (!this.gridApi) return
    if (this.isApiAlive(this.gridApi)) this.gridApi.destroy()
    this.gridApi = null
    this.gridTarget.innerHTML = ""
  }

  buildColumnDefs() {
    return this.columnsValue.map((column) => {
      const def = { ...column }

      if (def.formatter && FORMATTER_REGISTRY[def.formatter]) {
        def.valueFormatter = FORMATTER_REGISTRY[def.formatter]
        delete def.formatter
      }

      if (def.cellRenderer && RENDERER_REGISTRY[def.cellRenderer]) {
        def.cellRenderer = RENDERER_REGISTRY[def.cellRenderer]
      }

      if (def.editable === true) {
        def.editable = (params) => !params?.data?.__is_deleted
      }

      return def
    })
  }

  defaultColDef() {
    return {
      flex: 1,
      minWidth: 100,
      filter: true,
      floatingFilter: false,
      sortable: true,
      resizable: true,
      suppressHeaderMenuButton: false,
      suppressMenuHide: true
    }
  }

  fetchData() {
    const api = this.gridApi
    if (!this.isApiAlive(api)) return

    api.setGridOption("loading", true)

    fetch(this.urlValue, { headers: { Accept: "application/json" } })
      .then((response) => {
        if (!response.ok) throw new Error(`HTTP ${response.status}`)
        return response.json()
      })
      .then((data) => {
        if (!this.isApiAlive(api) || api !== this.gridApi) return

        api.setGridOption("loading", false)
        api.setGridOption("overlayNoRowsTemplate", this.defaultNoRowsTemplate)
        this.focusedRowNode = null
        api.setGridOption("rowData", data)
        if (data.length === 0) api.showNoRowsOverlay()
        else api.hideOverlay()
      })
      .catch((error) => {
        console.error("[ag-grid] data load failed:", error)
        if (!this.isApiAlive(api) || api !== this.gridApi) return

        api.setGridOption("loading", false)
        api.setGridOption(
          "overlayNoRowsTemplate",
          '<div style="padding:20px;text-align:center;">' +
          '<div style="color:#f85149;font-weight:600;margin-bottom:4px;">?곗씠??濡쒕뵫 ?ㅽ뙣</div>' +
          '<div style="color:#8b949e;font-size:12px;">?ㅽ듃?뚰겕 ?곹깭瑜??뺤씤?댁＜?몄슂</div>' +
          "</div>"
        )
        api.showNoRowsOverlay()
      })
  }

  clearFilter() {
    if (!this.isApiAlive(this.gridApi)) return

    // 모든 컬럼의 필터 인스턴스를 초기화
    this.gridApi.setFilterModel(null)

    // 명시적으로 필터 파괴 (DOM에 남아있는 상태값 완전 제거)
    const columns = this.gridApi.getColumns ? this.gridApi.getColumns() : []
    if (columns && columns.length > 0) {
      columns.forEach(col => {
        this.gridApi.destroyFilter(col)
      })
    }

    // 퀵 필터도 초기화 (있는 경우)
    if (this.gridApi.setGridOption) {
      this.gridApi.setGridOption('quickFilterText', '')
    }

    // 변경사항 적용
    if (typeof this.gridApi.onFilterChanged === 'function') {
      this.gridApi.onFilterChanged()
    }

    this.#showToast("필터가 초기화되었습니다")
  }

  #handleServerPaginationChanged(event) {
    if (this.#suppressPaginationEvent) return
    if (!this.isApiAlive(this.gridApi)) return

    const newPage = this.gridApi.paginationGetCurrentPage() + 1
    if (newPage !== this.#serverPage) {
      this.#serverPage = newPage
      this.fetchServerPage()
    }
  }

  fetchServerPage() {
    const api = this.gridApi
    if (!this.isApiAlive(api)) return

    api.setGridOption("loading", true)

    const url = new URL(this.urlValue, window.location.origin)
    url.searchParams.set("page", this.#serverPage)
    url.searchParams.set("per_page", this.pageSizeValue)

    fetch(url.toString(), { headers: { Accept: "application/json" } })
      .then((response) => {
        if (!response.ok) throw new Error(`HTTP ${response.status}`)
        return response.json()
      })
      .then((data) => {
        if (!this.isApiAlive(api) || api !== this.gridApi) return

        api.setGridOption("loading", false)
        api.setGridOption("overlayNoRowsTemplate", this.defaultNoRowsTemplate)
        this.focusedRowNode = null
        this.#serverTotal = data.total || 0

        api.setGridOption("rowData", data.rows || [])
        api.setGridOption("paginationPageSize", this.pageSizeValue)

        if ((data.rows || []).length === 0) api.showNoRowsOverlay()
        else api.hideOverlay()
      })
      .catch((error) => {
        console.error("[ag-grid] server page load failed:", error)
        if (!this.isApiAlive(api) || api !== this.gridApi) return

        api.setGridOption("loading", false)
        api.setGridOption(
          "overlayNoRowsTemplate",
          '<div style="padding:20px;text-align:center;">' +
          '<div style="color:#f85149;font-weight:600;margin-bottom:4px;">데이터 로딩 실패</div>' +
          '<div style="color:#8b949e;font-size:12px;">네트워크 상태를 확인해주세요</div>' +
          "</div>"
        )
        api.showNoRowsOverlay()
      })
  }

  handleCellFocused(event) {
    if (typeof event?.rowIndex !== "number") return
    if (this.isSelectionCheckboxColumn(event)) return
    if (this.isActionColumn(event)) return
    if (!this.isApiAlive(this.gridApi)) return

    const nextFocusedNode = this.gridApi.getDisplayedRowAtIndex(event.rowIndex)
    if (!nextFocusedNode) return
    if (this.focusedRowNode === nextFocusedNode) return

    const prevFocusedNode = this.focusedRowNode
    this.focusedRowNode = nextFocusedNode

    const rowNodes = []
    if (prevFocusedNode) rowNodes.push(prevFocusedNode)
    rowNodes.push(nextFocusedNode)

    if (rowNodes.length > 0 && this.isApiAlive(this.gridApi)) {
      this.gridApi.redrawRows({ rowNodes })
    }
  }

  buildRowClass(params) {
    const classes = []
    if (params.node === this.focusedRowNode) classes.push("ag-row-keyboard-focus")
    if (params.data?.__is_deleted) classes.push("ag-row-soft-deleted")
    return classes.join(" ")
  }

  isSelectionCheckboxColumn(event) {
    const column = event?.column
    if (!column) return false

    const colDef = column.getColDef?.()
    if (colDef?.checkboxSelection) return true

    const colId = column.getColId?.()
    if (!colId) return false

    return colId === "ag-Grid-SelectionColumn" || colId.includes("SelectionColumn")
  }

  isActionColumn(event) {
    const colDef = event?.column?.getColDef?.()
    if (!colDef) return false

    if (colDef.field === "actions") return true

    const { cellClass } = colDef
    if (typeof cellClass === "string") {
      return cellClass.includes("ag-cell-actions")
    }
    if (Array.isArray(cellClass)) {
      return cellClass.some((klass) => String(klass).includes("ag-cell-actions"))
    }

    return false
  }

  ensureStatusColumnOrder() {
    const reposition = () => {
      if (!this.isApiAlive(this.gridApi)) return
      if (!this.gridApi?.moveColumns || !this.gridApi?.getAllGridColumns) return

      const columns = this.gridApi.getAllGridColumns()
      const hasStatus = columns.some((column) => column.getColId?.() === "__row_status")
      if (!hasStatus) return

      const selectionIndex = columns.findIndex((column) => {
        const colId = column.getColId?.() || ""
        return colId === "ag-Grid-SelectionColumn" || colId.includes("SelectionColumn")
      })
      if (selectionIndex < 0) return

      const statusIndex = columns.findIndex((column) => column.getColId?.() === "__row_status")
      if (statusIndex === selectionIndex + 1) return

      this.gridApi.moveColumns(["__row_status"], selectionIndex + 1)
    }

    queueMicrotask(reposition)
    setTimeout(reposition, 0)
  }

  isApiAlive(api) {
    return Boolean(api) && !(typeof api.isDestroyed === "function" && api.isDestroyed())
  }

  #restoreColumnState() {
    const id = this.gridIdValue
    if (!id || !this.isApiAlive(this.gridApi)) return

    const saved = localStorage.getItem(this.#storageKey(id))
    if (!saved) return

    try {
      const state = JSON.parse(saved)
      this.gridApi.applyColumnState({ state, applyOrder: true })
    } catch (e) {
      console.warn("[ag-grid] failed to restore column state:", e)
      localStorage.removeItem(this.#storageKey(id))
    }
  }

  #storageKey(gridId) {
    return `ag-grid-state:${gridId}`
  }

  #showToast(message) {
    const toast = document.createElement("div")
    toast.textContent = message
    toast.style.cssText = [
      "position:fixed", "bottom:24px", "right:24px", "z-index:9999",
      "padding:10px 20px", "border-radius:8px",
      "background:#1c2333", "color:#e6edf3", "border:1px solid #30363d",
      "font-size:13px", "box-shadow:0 4px 12px rgba(0,0,0,0.4)",
      "opacity:0", "transition:opacity 0.3s ease"
    ].join(";")

    document.body.appendChild(toast)
    requestAnimationFrame(() => { toast.style.opacity = "1" })

    setTimeout(() => {
      toast.style.opacity = "0"
      toast.addEventListener("transitionend", () => toast.remove())
    }, 2000)
  }
}
