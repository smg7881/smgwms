import { themeQuartz, ModuleRegistry, AllCommunityModule } from "ag-grid-community"

/**
 * FORMATTER_REGISTRY
 * 
 * AG Grid 컬럼 정의 시 `formatter: 'currency'` 형태로 문자열을 지정하면, 
 * ag_grid_controller.js 에서 이 객체에 등록된 함수를 찾아 `valueFormatter`로 연결해 주는 레지스트리입니다.
 */
export const FORMATTER_REGISTRY = {
  // 숫자 값을 3자리 콤마가 포함된 원화 액수 형태로 포맷 (예: 1000 -> \1,000)
  currency: (params) => params.value != null ? `\\${Number(params.value).toLocaleString()}` : "",
  // 날짜 문자열을 한국 표준 표기법(YYYY. M. D.)으로 변환
  date: (params) => params.value ? new Date(params.value).toLocaleDateString("ko-KR") : "",
  // 일시(날짜+시간) 문자열을 한국 표준 표기법으로 변환
  datetime: (params) => params.value ? new Date(params.value).toLocaleString("ko-KR") : "",
  // 숫자 값 끝에 % 기호를 붙여 변환
  percent: (params) => params.value != null ? `${params.value}%` : "",
  // 긴 문자열 데이터를 50자까지만 자르고 '...'을 붙여 표시 (성능 및 UI 잘림 방지)
  truncate: (params) => (params.value?.length > 50 ? `${params.value.slice(0, 50)}...` : (params.value || ""))
}

/**
 * AG_GRID_LOCALE_KO
 * 
 * AG Grid에서 사용되는 각종 레이블, 메뉴명, 안내 문구들을 한국어로 번역하기 위한 객체입니다.
 * 그리드 초기화 시 localeText 옵션에 주입됩니다.
 */
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

/**
 * darkTheme
 * 
 * 시스템 UI 테마에 맞춘 사용자 정의 AG Grid 테마 객체입니다.
 * ag-grid-community의 themeQuartz 팩토리를 기반으로 색상상수(params)를 덮어씌웠습니다.
 * 그리드 초기화 시 theme 옵션에 반영됩니다.
 */
export const darkTheme = themeQuartz.withParams({
  backgroundColor: "#161b22",         // 그리드 전체 배경
  foregroundColor: "#e6edf3",         // 그리드 일반 텍스트 색상
  headerBackgroundColor: "#1c2333",   // 헤더 배경
  headerTextColor: "#8b949e",         // 헤더 텍스트 색상
  borderColor: "#30363d",             // 기본 테두리 색상
  inputBorder: "solid 1px #30363d",   // 에디터 입력창 테두리
  inputFocusBorder: "solid 1px #58a6ff",
  inputBorderRadius: 4,
  inputFocusBoxShadow: "0 0 0 2px rgba(88, 166, 255, 0.3)",
  menuBackgroundColor: "#1c2333",     // 필터, 컨텍스트 메뉴 배경
  menuBorder: "solid 1px #30363d",
  rowHoverColor: "#21262d",           // 마우스 호버 시 행 배경
  accentColor: "#58a6ff",             // 선택/포커스 등 하이라이트 색상 (Primary)
  oddRowBackgroundColor: "#0f1117",   // 홀수 행 배경 (Zebra stripe 패턴을 위함)
  headerFontSize: 12,
  fontSize: 13,
  borderRadius: 8,
  wrapperBorderRadius: 8,
  fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif'
})

// 한 번만 등록되도록 플래그로 보호된 모듈 자동 등록 함수 영역 (성능 및 충돌 방지)
let modulesRegistered = false

/**
 * registerAgGridCommunityModules
 * 
 * 애플리케이션 기동 시 AG Grid에 필요한 커뮤니티 모듈(AllCommunityModule)을 
 * 초기 1회 전역 레지스트리에 등록해주는 부트스트랩 성격의 함수입니다.
 */
export function registerAgGridCommunityModules() {
  if (modulesRegistered) return
  ModuleRegistry.registerModules([AllCommunityModule])
  modulesRegistered = true
}
