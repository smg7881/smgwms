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
  page: "페이지",
  of: "/",
  to: "~",
  nextPage: "다음 페이지",
  lastPage: "마지막 페이지",
  firstPage: "첫 페이지",
  previousPage: "이전 페이지",
  pageSizeSelectorLabel: "페이지 크기:",
  loadingOoo: "로딩 중...",
  noRowsToShow: "데이터가 없습니다",
  filterOoo: "필터...",
  equals: "같음",
  notEqual: "같지 않음",
  contains: "포함",
  notContains: "미포함",
  startsWith: "시작 문자",
  endsWith: "끝 문자",
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
  columns: "컬럼",
  copy: "복사",
  ctrlC: "Ctrl+C",
  csvExport: "CSV 내보내기",
  export: "내보내기",
  sortAscending: "오름차순 정렬",
  sortDescending: "내림차순 정렬",
  sortUnSort: "정렬 해제"
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

  static values = {
    columns: { type: Array, default: [] },
    url: String,
    rowData: { type: Array, default: [] },
    pagination: { type: Boolean, default: true },
    pageSize: { type: Number, default: 20 },
    height: { type: String, default: "500px" },
    rowSelection: { type: String, default: "" }
  }

  connect() {
    this.initGrid()
    this._beforeCache = () => this.teardown()
    document.addEventListener("turbo:before-cache", this._beforeCache)
  }

  disconnect() {
    document.removeEventListener("turbo:before-cache", this._beforeCache)
    this.teardown()
  }

  refresh() {
    if (this.hasUrlValue && this.urlValue) this.fetchData()
  }

  get api() {
    return this.gridApi
  }

  exportCsv() {
    this.gridApi?.exportDataAsCsv()
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
      rowData: [],
      overlayNoRowsTemplate: `<span class="ag-overlay-no-rows-center">${AG_GRID_LOCALE_KO.noRowsToShow}</span>`
    }

    this.defaultNoRowsTemplate = gridOptions.overlayNoRowsTemplate

    if (this.rowSelectionValue) {
      gridOptions.rowSelection = {
        mode: this.rowSelectionValue === "single" ? "singleRow" : "multiRow"
      }
    }

    this.gridTarget.style.height = this.heightValue
    this.gridTarget.style.width = "100%"
    this.gridApi = createGrid(this.gridTarget, gridOptions)

    if (this.hasUrlValue && this.urlValue) {
      this.fetchData()
    } else if (this.rowDataValue.length > 0) {
      this.gridApi.setGridOption("rowData", this.rowDataValue)
    }
  }

  teardown() {
    if (!this.gridApi) return
    this.gridApi.destroy()
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
    this.gridApi.setGridOption("loading", true)

    fetch(this.urlValue, { headers: { Accept: "application/json" } })
      .then((response) => {
        if (!response.ok) throw new Error(`HTTP ${response.status}`)
        return response.json()
      })
      .then((data) => {
        this.gridApi.setGridOption("loading", false)
        this.gridApi.setGridOption("overlayNoRowsTemplate", this.defaultNoRowsTemplate)
        this.gridApi.setGridOption("rowData", data)
        if (data.length === 0) this.gridApi.showNoRowsOverlay()
      })
      .catch((error) => {
        console.error("[ag-grid] data load failed:", error)
        this.gridApi.setGridOption("loading", false)
        this.gridApi.setGridOption(
          "overlayNoRowsTemplate",
          '<div style="padding:20px;text-align:center;">' +
            '<div style="color:#f85149;font-weight:600;margin-bottom:4px;">데이터 로딩 실패</div>' +
            '<div style="color:#8b949e;font-size:12px;">네트워크 상태를 확인해주세요</div>' +
          "</div>"
        )
        this.gridApi.showNoRowsOverlay()
      })
  }
}
