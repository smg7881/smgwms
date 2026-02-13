import { Controller } from "@hotwired/stimulus"
import {
  createGrid,
  themeQuartz,
  ModuleRegistry,
  AllCommunityModule
} from "ag-grid-community"

// ── AG Grid 모듈 등록 ──
// Community 버전의 모든 기능(CSV 내보내기, 필터링, 정렬 등)을 사용하기 위해 등록합니다.
// 엔터프라이즈 기능이 필요한 경우 ag-grid-enterprise 패키지를 추가로 등록해야 합니다.
let _agGridModulesRegistered = false
if (!_agGridModulesRegistered) {
  ModuleRegistry.registerModules([AllCommunityModule])
  _agGridModulesRegistered = true
}

// ── 데이터 포맷터 레지스트리 (Formatter Registry) ──
// 서버에서 전달받은 columnDefs의 `formatter` 문자열 키를 실제 JavaScript 함수로 매핑하는 객체입니다.
// 예: columnDefs: [{ field: "price", formatter: "currency" }]
const FORMATTER_REGISTRY = {
  // 통화 포맷: 값이 있으면 '₩' 기호와 천 단위 구분 기호를 추가합니다.
  currency: (params) => params.value != null ? `₩${params.value.toLocaleString()}` : "",
  // 날짜 포맷: 'YYYY-MM-DD' 형식의 한국어 날짜 문자열로 변환합니다.
  date: (params) => params.value ? new Date(params.value).toLocaleDateString("ko-KR") : "",
  // 일시 포맷: 'YYYY-MM-DD HH:mm:ss' 형식의 한국어 날짜 및 시간 문자열로 변환합니다.
  datetime: (params) => params.value ? new Date(params.value).toLocaleString("ko-KR") : "",
  // 퍼센트 포맷: 값 뒤에 '%' 기호를 추가합니다.
  percent: (params) => params.value != null ? `${params.value}%` : "",
  // 말줄임 포맷: 50자를 초과하는 경우 50자까지만 보여주고 '…'을 추가합니다.
  truncate: (params) => params.value?.length > 50 ? params.value.slice(0, 50) + "…" : params.value ?? "",
}

// ── 데이터 렌더러 레지스트리 (Renderer Registry) ──
// 서버에서 전달받은 columnDefs의 `cellRenderer` 문자열 키를 실제 JavaScript 함수/컴포넌트로 매핑합니다.
const RENDERER_REGISTRY = {
  // 링크 렌더러: cellRendererParams.path를 사용하여 링크를 생성합니다.
  // path 내의 '${id}'는 행 데이터의 id로 치환됩니다. (예: "/posts/${id}")
  link: (params) => {
    if (params.value == null) return ""

    const pathTemplate = params.colDef.cellRendererParams?.path
    if (!pathTemplate) return String(params.value)

    // ${field} 형식의 플레이스홀더를 데이터 값으로 치환 (값 0도 유지, URL 인코딩 적용)
    const href = pathTemplate.replace(/\${(\w+)}/g, (_, key) => {
      const v = params.data?.[key]
      return encodeURIComponent(v ?? "")
    })

    // DOM 요소 반환 및 textContent 사용으로 XSS 방지
    const a = document.createElement("a")
    a.className = "ag-grid-link"
    a.dataset.turboFrame = "_top"
    a.href = href
    a.textContent = String(params.value)
    return a
  }
}

// ── AG Grid 한국어 로케일 설정 (Korean Locale) ──
// 그리드 내의 모든 영어 텍스트를 한국어로 표시하기 위한 설정 객체입니다.
// 페이징, 필터, 메뉴 등 UI 전반에 적용됩니다.
const AG_GRID_LOCALE_KO = {
  // 페이징 관련
  page: "페이지",
  of: "/",
  to: "~",
  nextPage: "다음 페이지",
  lastPage: "마지막 페이지",
  firstPage: "첫 페이지",
  previousPage: "이전 페이지",
  pageSizeSelectorLabel: "페이지 크기:",

  // 상태 메시지
  loadingOoo: "로딩 중...",
  noRowsToShow: "데이터가 없습니다",

  // 필터 관련
  filterOoo: "필터...",
  equals: "같음",
  notEqual: "같지 않음",
  contains: "포함",
  notContains: "미포함",
  startsWith: "시작 문자",
  endsWith: "끝 문자",
  blank: "빈 값",
  notBlank: "비어있지 않음",
  lessThan: "미만",
  greaterThan: "초과",
  lessThanOrEqual: "이하",
  greaterThanOrEqual: "이상",
  inRange: "범위 내",

  // 필터 조건 결합
  andCondition: "그리고",
  orCondition: "또는",

  // 필터 버튼
  applyFilter: "적용",
  resetFilter: "초기화",
  clearFilter: "지우기",
  cancelFilter: "취소",

  // 컬럼 메뉴
  columns: "컬럼",
  pinColumn: "컬럼 고정",
  pinLeft: "왼쪽 고정",
  pinRight: "오른쪽 고정",
  noPin: "고정 해제",
  autosizeThisColumn: "이 컬럼 자동 크기",
  autosizeAllColumns: "전체 컬럼 자동 크기",
  resetColumns: "컬럼 초기화",

  // 클립보드 및 내보내기
  copy: "복사",
  ctrlC: "Ctrl+C",
  csvExport: "CSV 내보내기",
  export: "내보내기",

  // 정렬
  sortAscending: "오름차순 정렬",
  sortDescending: "내림차순 정렬",
  sortUnSort: "정렬 해제",
}

// ── 테마 설정 (Dark Theme Setup) ──
// ag-grid-community의 themeQuartz를 기반으로 커스텀 스타일을 적용합니다.
// 애플리케이션의 다크 모드 디자인 시스템과 일치하도록 색상을 조정했습니다.
const darkTheme = themeQuartz.withParams({
  backgroundColor: "#161b22",       // 그리드 배경색
  foregroundColor: "#e6edf3",       // 기본 텍스트 색상
  headerBackgroundColor: "#1c2333", // 헤더 배경색
  headerTextColor: "#8b949e",       // 헤더 텍스트 색상
  borderColor: "#30363d",           // 테두리 색상
  rowHoverColor: "#21262d",         // 행 호버 시 배경색
  accentColor: "#58a6ff",           // 강조 색상 (체크박스, 포커스 등)
  oddRowBackgroundColor: "#0f1117", // 홀수 행 배경색 (스트라이프 효과)
  headerFontSize: 12,               // 헤더 폰트 크기
  fontSize: 13,                     // 본문 폰트 크기
  borderRadius: 8,                  // 모서리 둥글기
  wrapperBorderRadius: 8,           // 외곽 래퍼 모서리 둥글기
  fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif', // 폰트 설정
})

// ── Stimulus AG Grid 컨트롤러 ──
// HTML 요소에 data-controller="ag-grid"를 추가하여 사용합니다.
export default class extends Controller {
  // ── 타겟 정의 ──
  // 그리드가 렌더링될 DOM 요소를 지정합니다. (ex: <div data-ag-grid-target="grid"></div>)
  static targets = ["grid"]

  // ── 값 정의 (Values) ──
  // HTML의 data-ag-grid-*-value 속성을 통해 전달받는 값들입니다.
  static values = {
    // 컬럼 정의: 서버에서 JSON 형태로 전달받는 컬럼 설정 배열
    columns: { type: Array, default: [] },
    // 데이터 URL: 데이터를 비동기로 로드할 API 엔드포인트
    url: String,
    // 정적 데이터: URL 대신 직접 데이터를 주입할 때 사용
    rowData: { type: Array, default: [] },
    // 페이지네이션 사용 여부
    pagination: { type: Boolean, default: true },
    // 페이지당 표시할 행 수
    pageSize: { type: Number, default: 20 },
    // 그리드 높이 (CSS 값)
    height: { type: String, default: "500px" },
    // 행 선택 모드: "single" | "multiple" | "" (없음)
    rowSelection: { type: String, default: "" },
  }

  // ── 생명주기 메서드: 연결 (Connect) ──
  // 컨트롤러가 DOM 요소에 연결될 때 실행됩니다.
  connect() {
    // 그리드 초기화 실행
    this.#initGrid()

    // Turbo Drive 페이지 이동 시 캐시 문제 방지
    // 페이지를 떠날 때 그리드를 확실히 파괴(destroy)해야 합니다.
    this._beforeCache = () => this.#teardown()
    document.addEventListener("turbo:before-cache", this._beforeCache)
  }

  // ── 생명주기 메서드: 연결 해제 (Disconnect) ──
  // 컨트롤러가 DOM에서 제거될 때 실행됩니다.
  disconnect() {
    // 이벤트 리스너 정리
    document.removeEventListener("turbo:before-cache", this._beforeCache)
    // 그리드 리소스 정리
    this.#teardown()
  }

  // ── 퍼블릭 API ──
  // 외부(다른 Stimulus 컨트롤러나 이벤트 핸들러)에서 접근 가능한 메서드들입니다.

  // 데이터 새로고침 메서드
  // URL이 설정되어 있는 경우, 데이터를 다시 서버에서 가져옵니다.
  refresh() {
    if (this.hasUrlValue && this.urlValue) {
      this.#fetchData()
    }
  }

  // Grid API 접근자
  // AG Grid의 네이티브 API 객체를 반환하여, 고급 기능을 사용할 수 있게 합니다.
  get api() {
    return this.gridApi
  }

  // CSV 내보내기 메서드
  // 현재 그리드에 표시된 데이터를 CSV 파일로 다운로드합니다.
  exportCsv() {
    this.gridApi?.exportDataAsCsv()
  }

  // ── 프라이빗 메서드 (Private Methods) ──
  // 내부 로직을 처리하는 메서드들로, 클래스 외부에서 호출하지 않습니다.

  // 그리드 초기화 로직
  // AG Grid 옵션을 설정하고, 그리드 인스턴스를 생성합니다.
  #initGrid() {
    const gridOptions = {
      // 테마 설정
      theme: darkTheme,
      // 컬럼 정의 (formatter 매핑 처리 포함)
      columnDefs: this.#buildColumnDefs(),
      // 기본 컬럼 설정 (모든 컬럼에 공통 적용)
      defaultColDef: this.#defaultColDef(),
      // 페이지네이션 설정
      pagination: this.paginationValue,
      paginationPageSize: this.pageSizeValue,
      paginationPageSizeSelector: [10, 20, 50, 100], // 페이지 크기 선택 옵션
      // 한국어 텍스트 설정
      localeText: AG_GRID_LOCALE_KO,
      // 행 애니메이션 활성화 (정렬/필터링 시 부드러운 전환)
      animateRows: true,
      // 초기 데이터 (빈 배열로 시작)
      rowData: [],
      // 기본 '데이터 없음' 템플릿 설정
      overlayNoRowsTemplate: `<span class="ag-overlay-no-rows-center">${AG_GRID_LOCALE_KO.noRowsToShow}</span>`,
    }

    // 기본 템플릿 저장 (에러 발생 시 변경했다가 복구하기 위함)
    this._defaultNoRowsTemplate = gridOptions.overlayNoRowsTemplate

    // 행 선택 모드 설정 (값이 있을 경우에만 설정)
    if (this.rowSelectionValue) {
      gridOptions.rowSelection = {
        mode: this.rowSelectionValue === "single" ? "singleRow" : "multiRow",
      }
    }

    // 그리드 컨테이너 스타일 설정
    this.gridTarget.style.height = this.heightValue
    this.gridTarget.style.width = "100%"

    // 실제 그리드 생성 (createGrid 함수 사용)
    this.gridApi = createGrid(this.gridTarget, gridOptions)

    // 데이터 로딩 전략 결정
    // 1. URL이 있으면 서버에서 fetch
    // 2. rowDataValue가 있으면 정적 데이터 사용
    if (this.hasUrlValue && this.urlValue) {
      this.#fetchData()
    } else if (this.rowDataValue.length > 0) {
      this.gridApi.setGridOption("rowData", this.rowDataValue)
    }
  }

  // 그리드 정리 로직
  // 메모리 누수를 방지하기 위해 그리드 인스턴스를 파괴하고 DOM을 비웁니다.
  #teardown() {
    if (this.gridApi) {
      this.gridApi.destroy() // AG Grid API의 destroy 호출
      this.gridApi = null    // 참조 제거
      this.gridTarget.innerHTML = "" // DOM 내용 삭제
    }
  }

  // 컬럼 정의 빌더
  // 포맷터 문자열을 실제 함수로 변환하는 작업을 수행합니다.
  #buildColumnDefs() {
    return this.columnsValue.map(col => {
      // 원본 객체 복사 (불변성 유지)
      const def = { ...col }

      // 'formatter' 속성이 있고, 레지스트리에 등록된 키라면 함수로 변환
      if (def.formatter && FORMATTER_REGISTRY[def.formatter]) {
        def.valueFormatter = FORMATTER_REGISTRY[def.formatter]
        delete def.formatter // 원본 문자열 속성은 삭제 (AG Grid는 valueFormatter를 사용)
      }

      // 'cellRenderer' 속성이 있고, 레지스트리에 등록된 키라면 컴포넌트/함수로 변환
      if (def.cellRenderer && RENDERER_REGISTRY[def.cellRenderer]) {
        def.cellRenderer = RENDERER_REGISTRY[def.cellRenderer]
      }

      return def
    })
  }

  // 기본 컬럼 설정
  // 모든 컬럼에 공통적으로 적용될 속성들입니다.
  #defaultColDef() {
    return {
      flex: 1,          // 그리드 너비에 맞춰 컬럼 크기 자동 조절
      minWidth: 100,    // 컬럼 최소 너비
      filter: true,     // 필터 기능 활성화
      sortable: true,   // 정렬 기능 활성화
      resizable: true,  // 컬럼 크기 조절 활성화
    }
  }

  // 서버 데이터 가져오기 (Fetch Data)
  // 비동기로 데이터를 가져와서 그리드에 바인딩합니다.
  #fetchData() {
    // 로딩 오버레이 표시
    this.gridApi.setGridOption("loading", true)

    fetch(this.urlValue, {
      headers: { "Accept": "application/json" }
    })
      .then(response => {
        // HTTP 에러 처리
        if (!response.ok) throw new Error(`HTTP ${response.status}`)
        return response.json()
      })
      .then(data => {
        // 로딩 완료 처리
        this.gridApi.setGridOption("loading", false)
        // 오버레이 템플릿 원복 (에러 상태 등에서 복구)
        this.gridApi.setGridOption("overlayNoRowsTemplate", this._defaultNoRowsTemplate)
        // 데이터 설정
        this.gridApi.setGridOption("rowData", data)
        // 데이터가 없는 경우 '데이터 없음' 오버레이 표시
        if (data.length === 0) {
          this.gridApi.showNoRowsOverlay()
        }
      })
      .catch(error => {
        console.error("[ag-grid] 데이터 로딩 실패:", error)
        // 로딩 상태 해제
        this.gridApi.setGridOption("loading", false)

        // 커스텀 에러 오버레이 설정
        // 기본 텍스트 대신 HTML을 사용하여 스타일링된 에러 메시지를 보여줍니다.
        this.gridApi.setGridOption("overlayNoRowsTemplate",
          '<div style="padding:20px;text-align:center;">' +
          '<div style="color:#f85149;font-weight:600;margin-bottom:4px;">데이터 로딩 실패</div>' +
          '<div style="color:#8b949e;font-size:12px;">네트워크 상태를 확인해주세요</div>' +
          '</div>'
        )
        // 에러 오버레이 표시 (여기서는 NoRowsOverlay를 재활용하여 표시)
        this.gridApi.showNoRowsOverlay()
      })
  }
}
