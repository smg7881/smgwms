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
  loadingOoo: "Loading...",
  noRowsToShow: "No rows to show",
  filterOoo: "Filter...",
  equals: "Equals",
  notEqual: "Not equal",
  contains: "Contains",
  notContains: "Does not contain",
  startsWith: "Starts with",
  endsWith: "Ends with",
  lessThan: "Less than",
  greaterThan: "Greater than",
  lessThanOrEqual: "Less than or equal",
  greaterThanOrEqual: "Greater than or equal",
  andCondition: "AND",
  orCondition: "OR",
  applyFilter: "Apply",
  resetFilter: "Reset",
  clearFilter: "Clear",
  cancelFilter: "Cancel",
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
    serverPagination: { type: Boolean, default: false }
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
      animateRows: true,
      getRowClass: (params) => this.buildRowClass(params),
      onCellFocused: (event) => this.handleCellFocused(event),
      rowData: [],
      overlayNoRowsTemplate: `<span class="ag-overlay-no-rows-center">${AG_GRID_LOCALE_KO.noRowsToShow}</span>`
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
      sortable: true,
      resizable: true
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
}
