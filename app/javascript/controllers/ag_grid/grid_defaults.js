import { themeQuartz, ModuleRegistry, AllCommunityModule } from "ag-grid-community"

export const FORMATTER_REGISTRY = {
  currency: (params) => params.value != null ? `\\${Number(params.value).toLocaleString()}` : "",
  date: (params) => params.value ? new Date(params.value).toLocaleDateString("ko-KR") : "",
  datetime: (params) => params.value ? new Date(params.value).toLocaleString("ko-KR") : "",
  percent: (params) => params.value != null ? `${params.value}%` : "",
  truncate: (params) => (params.value?.length > 50 ? `${params.value.slice(0, 50)}...` : (params.value || ""))
}

export const AG_GRID_LOCALE_KO = {
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

export const darkTheme = themeQuartz.withParams({
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

export function registerAgGridCommunityModules() {
  if (modulesRegistered) return
  ModuleRegistry.registerModules([AllCommunityModule])
  modulesRegistered = true
}
