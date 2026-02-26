/**
 * ag_grid_controller.js
 * 
 * 프로젝트 전반에서 AG-Grid를 생성하고 제어하는 메인 Stimulus 컨트롤러입니다.
 * - 컬럼/데이터 주입, 페이징(로컬 및 서버사이드), 레이아웃 등 기본적인 옵션 관리를 수행합니다.
 * - 커스텀 테마, 한글화(Locale), 렌더러/포매터를 엮어 Grid를 화면에 그립니다.
 * - Turbo 특성에 맞춰 페이지 이동 시 메모리 누수 방지를 위한 정리(teardown) 작업을 처리합니다.
 */
import { Controller } from "@hotwired/stimulus"
import { createGrid } from "ag-grid-community"
import {
  AG_GRID_LOCALE_KO,
  FORMATTER_REGISTRY,
  darkTheme,
  registerAgGridCommunityModules
} from "controllers/ag_grid/grid_defaults"
import { RENDERER_REGISTRY } from "controllers/ag_grid/renderers"
import { openLookupPopup } from "controllers/lookup_popup_modal"

// 커뮤니티 전역 모듈 등록 (최초 1회만 동작하도록 내부 방어 로직 있음)
registerAgGridCommunityModules()

export default class extends Controller {
  // 본 컨트롤러와 연결된 DOM 내 실제 그리드 컨테이너 엘리먼트
  static targets = ["grid"]

  // 내부 상태 관리를 위한 프라이빗 변수 선언 (서버사이드 페이징 관련)
  #serverPage = 1
  #serverTotal = 0
  #suppressPaginationEvent = false // API에 의한 강제 페이지 전환 시 불필요한 이벤트 버블링 방지 플래그

  // HTML 레이아웃(data-ag-grid-*-value)에서 주입받는 다양한 설정값(상태 변수)들
  static values = {
    columns: { type: Array, default: [] },        // 컬럼 정의 배열
    url: String,                                  // 데이터를 Fetch 해올 API 엔드포인트 URL
    rowData: { type: Array, default: [] },        // 외부에서 직접 주입하는 초기 데이터 (URL 방식이 아닐 경우)
    pagination: { type: Boolean, default: true }, // 페이징 기능 사용 여부
    pageSize: { type: Number, default: 20 },      // 한 페이지당 노출 행 개수
    height: { type: String, default: "500px" },   // 그리드 UI의 높이값
    rowSelection: { type: String, default: "" },  // 체크박스/행 선택 모드 (예: "single" or "multiple")
    serverPagination: { type: Boolean, default: false }, // 백엔드 기반 페이징 여부
    gridId: { type: String, default: "" }         // 컬럼 순서/너비 등 사용자 커스텀 레이아웃 저장을 위한 고유 ID
  }

  // 화면이 로드되어 컨트롤러가 DOM에 연결될 때 자동 실행
  connect() {
    this.focusedRowNode = null // 현재 포커스 된 행을 추적하여 시각적 하이라이팅을 하거나 에디팅을 통제함
    this.#serverPage = 1
    this.#serverTotal = 0
    this.lookupPopupOpening = false

    // AG-Grid 인스턴스 초기화 함수 호출
    this.initGrid()

    this._lookupOpen = (event) => this.handleLookupOpenEvent(event)
    this.element.addEventListener("ag-grid:lookup-open", this._lookupOpen)

    // Rails Turbo(Hotwire) 기능 중 페이지가 캐시되기 직전에 기존 API 객체를 정리하는 이벤트 바인딩
    this._beforeCache = () => this.teardown()
    document.addEventListener("turbo:before-cache", this._beforeCache)
  }

  // 화면을 벗어나거나 Turbo에 의해 교체될 때 DOM에서 제거 전 자동 실행
  disconnect() {
    document.removeEventListener("turbo:before-cache", this._beforeCache)
    this.element.removeEventListener("ag-grid:lookup-open", this._lookupOpen)
    this.teardown() // 메모리 회수
  }

  // 부모 컨트롤러나 외부에서 강제로 최신 데이터를 재조회할 때 부르는 공용 메서드
  refresh() {
    if (!this.isApiAlive(this.gridApi)) return // 이미 파괴된 객체라면 중단

    if (this.serverPaginationValue) {
      // 서버사이드 페이징: 1페이지부터 다시 Fetch
      this.#serverPage = 1
      this.fetchServerPage()
    } else if (this.hasUrlValue && this.urlValue) {
      // 일반 통신: 전체 데이터 API 호출
      this.fetchData()
    }
  }

  // 이 Stimulus 안의 ag-grid 인스턴스를 외부에서 참조할 수 있도록 열어주는 getter
  get api() {
    return this.gridApi
  }

  // 화면에 렌더링 된 리스트 전체를 CSV 형태로 내보냅니다. (커뮤니티 내장 플러그인 사용)
  exportCsv() {
    if (!this.isApiAlive(this.gridApi)) return
    this.gridApi.exportDataAsCsv()
  }

  // 그리드 기본 옵션과 데이터를 셋업하고 API 객체를 생성 및 초기화합니다.
  initGrid() {
    // AG Grid Configuration
    const gridOptions = {
      theme: darkTheme, // grid_defaults에서 생성한 다크 시스템 테마 적용
      columnDefs: this.buildColumnDefs(),     // 컬럼 구조/렌더러 파싱 처리
      defaultColDef: this.defaultColDef(),      // 컬럼의 공통 기본 속성(예: 정렬 등)
      pagination: this.paginationValue,         // 페이징 on/off
      paginationPageSize: this.pageSizeValue,   // 1페이지 크기 등록
      paginationPageSizeSelector: [10, 20, 50, 100], // 페이지당 뷰 필터링 셀렉트박스 옵션
      localeText: AG_GRID_LOCALE_KO,            // 한국어 문자열 지원
      // 컬럼 헤더 필터 아이콘 커스텀 (SVG)
      icons: {
        filter: '<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" style="color: #8b949e;"><polygon points="22 3 2 3 10 12.46 10 19 14 21 14 12.46 22 3"/></svg>'
      },
      animateRows: true, // 정렬/필터 시 행 애니메이션 부드러운 효과 적용
      // 각 行 마다 특정 조건식(삭제 상태 등)이 부합할 때 커스텀 클래스를 주입하기 위한 콜백
      getRowClass: (params) => this.buildRowClass(params),

      // 셀 포커스 이동 시 선택 하이라이팅을 이동시키기 위한 핸들러 연동
      onCellFocused: (event) => this.handleCellFocused(event),
      onCellKeyDown: (event) => this.handleCellKeyDown(event),
      onRowClicked: (event) => {
        this.element.dispatchEvent(new CustomEvent("ag-grid:rowClicked", { bubbles: true, detail: event }))
      },
      onSelectionChanged: (event) => {
        this.element.dispatchEvent(new CustomEvent("ag-grid:selectionChanged", { bubbles: true, detail: event }))
      },
      onCellValueChanged: (event) => {
        this.element.dispatchEvent(new CustomEvent("ag-grid:cellValueChanged", { bubbles: true, detail: event }))
      },
      rowData: [],
      // 데이터가 0건일 때 중앙에 출력될 HTML 템플릿 처리 
      overlayNoRowsTemplate: `<span class="ag-overlay-no-rows-center">${AG_GRID_LOCALE_KO.noRowsToShow}</span>`,
      stopEditingWhenCellsLoseFocus: true // 셀 편집 중 다른 곳 클릭 시 자동 변경분 적용(포커스 잃음 반영)
    }

    this.defaultNoRowsTemplate = gridOptions.overlayNoRowsTemplate

    // 서버사이드 페이징일 경우, 페이지 이동 버튼 클릭 시 이벤트를 잡아당기도록 연동
    if (this.serverPaginationValue) {
      gridOptions.onPaginationChanged = (event) => this.#handleServerPaginationChanged(event)
    }

    // "rowSelection: multiple/single" 값이 있다면 
    // 좌측에 선택 전용 체크박스 컬럼(selectionColumnDef)을 최상단 옵션으로 주입합니다.
    if (this.rowSelectionValue) {
      gridOptions.rowSelection = {
        mode: this.rowSelectionValue === "single" ? "singleRow" : "multiRow"
      }
      gridOptions.selectionColumnDef = {
        width: 46,
        minWidth: 46,
        maxWidth: 46,
        sortable: false, // 선택 전용 체크박스는 정렬 안 함
        filter: false,   // 헤더 필터에서 제외
        resizable: false,
        suppressHeaderMenuButton: true
      }
    }

    // 그리드의 물리적 크기 높/너비를 적용
    // height: "100%" 사용 시 외부 wrapper에도 height를 적용해야 내부 grid div의 100%가 올바르게 계산됨
    this.element.style.height = this.heightValue
    this.gridTarget.style.height = this.heightValue
    this.gridTarget.style.width = "100%"

    // 실제 DOM 트리를 대상으로 Grid 객체 런타임 생성, API 할당
    this.gridApi = createGrid(this.gridTarget, gridOptions)

    // 만약 "수정/삭제 등 진행 상태"를 나타내는 가상 상태 컬럼이 있다면 
    // 체크박스 바로 다음(좌측 2번째 등) 고정된 위치로 수급순서(order)를 보정해주는 함수
    this.ensureStatusColumnOrder()

    // 1차 옵션 세팅 완료 후 실제 데이터 로딩 분기처리
    if (this.serverPaginationValue) {
      this.#serverPage = 1
      this.fetchServerPage() // 서버 API(Page/perPage param 부착) 호출
    } else if (this.hasUrlValue && this.urlValue) {
      this.fetchData() // 통 API 로드
    } else if (this.rowDataValue.length > 0 && this.isApiAlive(this.gridApi)) {
      this.focusedRowNode = null
      this.gridApi.setGridOption("rowData", this.rowDataValue) // 하드코딩된 초깃값 배열 주입
    }

    // 사용자가 이전에 저장했던 컬럼의 순서, 너비, 숨김 여부를 Local Storage에서 복원
    this.#restoreColumnState()

    // 그리드 준비 완료 이벤트를 본 컨트롤러(루트 div)에서 방출
    // base_grid_controller 등의 GridCrudManager가 이를 수신하고 위임 연결 작업을 수행합니다.
    this.element.dispatchEvent(new CustomEvent("ag-grid:ready", {
      bubbles: true,
      detail: { api: this.gridApi, controller: this }
    }))
  }

  // 클라이언트의 로컬 스토리지에 현재 설정된 컬럼 너비/순서 등의 뷰 상태를 저장합니다.
  saveColumnState(gridId) {
    const id = gridId || this.gridIdValue
    if (!id || !this.isApiAlive(this.gridApi)) return

    const state = this.gridApi.getColumnState()
    localStorage.setItem(this.#storageKey(id), JSON.stringify(state))
    this.#showToast("컬럼 상태가 저장되었습니다")
  }

  // 레이아웃이 꼬였거나 기본값 화면으로 되돌리고 싶을 때 저장된 기록을 삭제하고 원복합니다.
  resetColumnState(gridId) {
    const id = gridId || this.gridIdValue
    if (!id || !this.isApiAlive(this.gridApi)) return

    localStorage.removeItem(this.#storageKey(id))
    this.gridApi.resetColumnState()
    this.#showToast("컬럼 상태가 초기화되었습니다")
  }

  // DOM을 말끔히 치우고 인스턴스(API)를 강제 제거(destroy)하여 메모리를 확보합니다.
  teardown() {
    if (!this.gridApi) return
    if (this.isApiAlive(this.gridApi)) this.gridApi.destroy()
    this.gridApi = null
    this.gridTarget.innerHTML = "" // 남아있는 찌꺼기 돔 방지
  }

  // HTML 속성으로 부터 넘겨받은 { field: 'name', type: 'text',... } JSON 배열에 대해서 
  // 실제 AGGrid가 읽어들일 수 있는 colDef 스펙으로 변환(Render, Formatter 삽입) 해주는 파서(parser) 역할
  buildColumnDefs() {
    return this.columnsValue.map((column) => {
      const def = { ...column }

      // Move AG Grid invalid custom properties (lookup_*) into `colDef.context`
      def.context = def.context || {}
      Object.keys(def).forEach(key => {
        if (key.startsWith('lookup_')) {
          def.context[key] = def[key]
          delete def[key]
        }
      })

      const hasLookupPopup = this.isLookupColumn(def)

      if (hasLookupPopup) {
        if (!def.context.lookup_name_field && def.field) {
          def.context.lookup_name_field = def.field
        }
        if (!def.cellRenderer) {
          def.cellRenderer = "lookupPopupCellRenderer"
        }
        // lookup 컬럼은 렌더러 내부 입력창으로 편집하므로 AG Grid 기본 편집모드는 비활성화
        def.editable = false
      }

      // "formatter: 'date'" 등 문자열 포맷터 호출에 맞는 실제 함수 할당
      if (def.formatter && FORMATTER_REGISTRY[def.formatter]) {
        def.valueFormatter = FORMATTER_REGISTRY[def.formatter]
        delete def.formatter
      }

      // "cellRenderer: 'link'" 등 텍스트를 해당하는 컴포넌트 함수 렌더러로 변경 연결
      if (def.cellRenderer && RENDERER_REGISTRY[def.cellRenderer]) {
        def.cellRenderer = RENDERER_REGISTRY[def.cellRenderer]
      }

      // 수정(Edit) 진입 가능 여부를 관리형태로 처리
      // 이미 삭제 처리(소프트삭제)된 행의 락업(Lock-up)을 구현하기 위해 함수화 (data.__is_deleted 여부 참조)
      if (def.editable === true) {
        def.editable = (params) => !params?.data?.__is_deleted
      }

      return def
    })
  }

  // 공통 적용 컬럼 속성 모음
  defaultColDef() {
    return {
      flex: 1,                    // 남은 화면 빈 공간을 비율에 맞게 꽉 채움
      minWidth: 100,
      filter: true,               // 기본 필터 세팅
      floatingFilter: false,      // 헤더 아래 인풋 박스형 필터 표시여부
      sortable: true,             // 컬럼 내용 클릭 시 정렬 (ASC/DESC/NONE)
      resizable: true,            // 드래그를 통해 너비 조절 기능
      // AG Grid v35에서는 suppressMenuHide가 제거됨. 메뉴 버튼은 suppressHeaderMenuButton으로 제어.
      suppressHeaderMenuButton: false
    }
  }

  // 일반 API Fetch. 1차원적으로 모든 데이터를 JSON으로 다 가져오는 방식.
  fetchData() {
    const api = this.gridApi
    if (!this.isApiAlive(api)) return

    api.setGridOption("loading", true) // 조회중 상태 UI On

    fetch(this.urlValue, { headers: { Accept: "application/json" } })
      .then((response) => {
        if (!response.ok) throw new Error(`HTTP ${response.status}`)
        return response.json()
      })
      .then((data) => {
        if (!this.isApiAlive(api) || api !== this.gridApi) return // 중간 통신 응답 대기 시점에 소멸 시 방어

        api.setGridOption("loading", false)
        api.setGridOption("overlayNoRowsTemplate", this.defaultNoRowsTemplate)
        this.focusedRowNode = null // 이전 포커스 흔적 삭제 

        api.setGridOption("rowData", data) // 가져온 전체 데이터를 채움

        // 0건일 시 텅 빈 표시(No rows) 수행
        if (data.length === 0) api.showNoRowsOverlay()
        else api.hideOverlay()
      })
      .catch((error) => {
        console.error("[ag-grid] data load failed:", error)
        if (!this.isApiAlive(api) || api !== this.gridApi) return

        api.setGridOption("loading", false)
        // 에러 스켈레톤 UI
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

  // 검색 폼 등에서 초기화 시 그리드에 할당된 뷰 필터 및 숨김상태, 퀵 서치(Quick Search)까지 말끔히 해제
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

    // 통계 등 퀵 필터도 초기화 (있는 경우)
    if (this.gridApi.setGridOption) {
      this.gridApi.setGridOption('quickFilterText', '')
    }

    // 변경사항 적용 이벤트 발송 (AG-grid 내장 이벤트)
    if (typeof this.gridApi.onFilterChanged === 'function') {
      this.gridApi.onFilterChanged()
    }

    this.#showToast("필터가 초기화되었습니다")
  }

  // 서버사이드 페이징 옵션(serverPagination=true) 일 때만 반응하며,
  // 다음 페이지 <a> 태그나 번호를 누를 경우 새 페이지 번호 정보를 따와 URL에 연결합니다.
  #handleServerPaginationChanged(event) {
    if (this.#suppressPaginationEvent) return
    if (!this.isApiAlive(this.gridApi)) return

    const newPage = this.gridApi.paginationGetCurrentPage() + 1
    if (newPage !== this.#serverPage) {
      this.#serverPage = newPage
      this.fetchServerPage() // 페이지 번호만 바꾸고 전송 재실행
    }
  }

  // 서버에 현재 페이지/RowLimit 값을 전달하여 1페이지분씩 가져오는 동작 처리 부분.
  fetchServerPage() {
    const api = this.gridApi
    if (!this.isApiAlive(api)) return

    api.setGridOption("loading", true)

    // URL URL 인스턴스화 후 query params(page, per_page) 강제 바인딩
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
        this.#serverTotal = data.total || 0 // (서버 응답값 컨벤션: { rows: [...], total: 숫자 } 기반 처리)

        // 페이징된 배열 데이터만 꽂음
        api.setGridOption("rowData", data.rows || [])
        // 사이즈가 동적으로 바뀌는 경우 대비, 1P 사이즈 강제 주입
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

  // [키보드 이동 및 셀 포커스 디자인 담당 핸들러]
  // AG-Grid가 기본적으로 한 칸 셀 단위로 파란 선 포커싱을 한다면
  // 여기서는 로우(행, 가로) 전체가 파란색/포커스 배경을 갖도록 강제로 이벤트를 연결합니다. (Excel 행 전체 선택 느낌)
  handleCellFocused(event) {
    if (typeof event?.rowIndex !== "number") return // 인덱스를 모르면 처리 불가

    // 버튼, 액션 박스, 체크박스 컬럼을 누르는 경우는 보통 독립 프로세스가 진행되므로 행 하이라이팅 무시함.
    if (this.isSelectionCheckboxColumn(event)) return
    if (this.isActionColumn(event)) return
    if (!this.isApiAlive(this.gridApi)) return

    const nextFocusedNode = this.gridApi.getDisplayedRowAtIndex(event.rowIndex)
    if (!nextFocusedNode) return
    if (this.focusedRowNode === nextFocusedNode) return

    const prevFocusedNode = this.focusedRowNode
    this.focusedRowNode = nextFocusedNode // 현재 포커스 대상 최신화

    // 포커스를 잃은 이전 로우와, 얻게 된 지금 로우 2개의 스타일을 재적용(redraw)하기 위해 추출
    const rowNodes = []
    if (prevFocusedNode) rowNodes.push(prevFocusedNode)
    rowNodes.push(nextFocusedNode)

    if (rowNodes.length > 0 && this.isApiAlive(this.gridApi)) {
      // 행 다시 그리기 => getRowClass() 함수가 호출됨
      this.gridApi.redrawRows({ rowNodes })
    }

    // 포커스된 행이 변경되었으므로 이벤트를 방출하여 외부에서 알 수 있게 함
    this.element.dispatchEvent(new CustomEvent("ag-grid:rowFocused", {
      bubbles: true,
      detail: { node: nextFocusedNode, data: nextFocusedNode.data, rowIndex: event.rowIndex }
    }))
  }

  handleCellKeyDown(event) {
    if (event?.event?.key !== "Enter") return

    const colDef = event?.column?.getColDef?.()
    if (!this.isLookupColumn(colDef)) return
    if (!this.isApiAlive(this.gridApi)) return

    event.event.preventDefault()
    event.event.stopPropagation()

    this.gridApi.stopEditing()

    const rowNode = event.node || this.gridApi.getDisplayedRowAtIndex(event.rowIndex)
    if (!rowNode?.data) return

    const nameField = colDef.lookup_name_field || colDef.field
    const keyword = rowNode.data?.[nameField] || ""

    this.openLookupForCell({ rowNode, colDef, keyword })
  }

  handleLookupOpenEvent(event) {
    event.stopPropagation()
    if (!this.isApiAlive(this.gridApi)) return

    const detail = event.detail || {}
    const colDef = detail.colDef
    if (!this.isLookupColumn(colDef)) return

    const rowNode = detail.rowNode || this.gridApi.getDisplayedRowAtIndex(detail.rowIndex)
    if (!rowNode?.data) return

    this.openLookupForCell({
      rowNode,
      colDef,
      keyword: detail.keyword
    })
  }

  async openLookupForCell({ rowNode, colDef, keyword }) {
    if (!this.isLookupColumn(colDef)) return
    if (!rowNode?.data) return
    if (this.lookupPopupOpening) return

    const ctx = colDef.context || {}
    const popupType = ctx.lookup_popup_type
    const popupUrl = ctx.lookup_popup_url
    const popupTitle = ctx.lookup_popup_title
    const nameField = ctx.lookup_name_field || colDef.field
    const codeField = ctx.lookup_code_field
    const seedKeyword = String(keyword ?? rowNode.data?.[nameField] ?? "").trim()

    this.lookupPopupOpening = true
    try {
      const selection = await openLookupPopup({
        type: popupType,
        url: popupUrl,
        keyword: seedKeyword,
        title: popupTitle
      })

      if (!selection) return

      const nextName = String(selection.name ?? selection.display ?? "").trim()
      const nextCode = String(selection.code ?? "").trim()

      rowNode.setDataValue(nameField, nextName)
      if (codeField) {
        rowNode.setDataValue(codeField, nextCode)
      }

      const refreshColumns = [nameField, codeField].filter(Boolean)
      if (refreshColumns.length > 0) {
        this.gridApi.refreshCells({
          rowNodes: [rowNode],
          columns: refreshColumns,
          force: true
        })
      }

      this.element.dispatchEvent(new CustomEvent("ag-grid:lookup-selected", {
        bubbles: true,
        detail: {
          rowNode,
          colDef,
          selection
        }
      }))
    } finally {
      this.lookupPopupOpening = false
    }
  }

  // 각 행이 그려질 때마다 주입할 클래스를 연산. 
  // (예방적 포커싱 기능 및 삭제 상태일 때 흐리게 보이는(soft-deleted) 클래스 주입 등)
  buildRowClass(params) {
    const classes = []
    if (params.node === this.focusedRowNode) classes.push("ag-row-keyboard-focus")
    if (params.data?.__is_deleted) classes.push("ag-row-soft-deleted") // Batch 삭제 표시 효과 
    return classes.join(" ")
  }

  isLookupColumn(colDef) {
    return Boolean(colDef?.context?.lookup_popup_type)
  }

  // 현재 이벤트 대상이 '체크박스 선택 전용' 컬럼인지 판별하기 위한 헬퍼 추론 함수
  isSelectionCheckboxColumn(event) {
    const column = event?.column
    if (!column) return false

    const colDef = column.getColDef?.()
    if (colDef?.checkboxSelection) return true

    const colId = column.getColId?.()
    if (!colId) return false

    return colId === "ag-Grid-SelectionColumn" || colId.includes("SelectionColumn")
  }

  // 현재 이벤트 대상이 버튼이나 'actions' 등과 같은 행위 모음 컬럼인지 판별하는 헬퍼 함수
  isActionColumn(event) {
    const colDef = event?.column?.getColDef?.()
    if (!colDef) return false

    if (colDef.field === "actions") return true // 필드명이 actions 면 true

    // 클래스명 유추 방식 추가 판별
    const { cellClass } = colDef
    if (typeof cellClass === "string") {
      return cellClass.includes("ag-cell-actions")
    }
    if (Array.isArray(cellClass)) {
      return cellClass.some((klass) => String(klass).includes("ag-cell-actions"))
    }

    return false
  }

  // (가상/UI전용 컬럼) "__row_status" 상태 아이콘 표기 컬럼이
  // 무조건 체크박스(존재한다면) 바로 다음 위치, 혹은 없다면 첫번째에 배치될 수 있도록
  // 초기 로딩 후 컬럼 이동(moveColumns) 명령을 비동기(Microtask & timeout)로 강제하는 함수.
  ensureStatusColumnOrder() {
    const reposition = () => {
      if (!this.isApiAlive(this.gridApi)) return
      if (!this.gridApi?.moveColumns || !this.gridApi?.getAllGridColumns) return

      const columns = this.gridApi.getAllGridColumns()
      const hasStatus = columns.some((column) => column.getColId?.() === "__row_status")
      if (!hasStatus) return // 상태 컬럼 없음

      // 체크박스 위치 찾기
      const selectionIndex = columns.findIndex((column) => {
        const colId = column.getColId?.() || ""
        return colId === "ag-Grid-SelectionColumn" || colId.includes("SelectionColumn")
      })
      if (selectionIndex < 0) return // 체크박스가 없다면 위치를 안바꿀 수 있음

      const statusIndex = columns.findIndex((column) => column.getColId?.() === "__row_status")

      // 이미 체크박스 뒤에 있다면 중단
      if (statusIndex === selectionIndex + 1) return

      // 순서 강제 이관 
      this.gridApi.moveColumns(["__row_status"], selectionIndex + 1)
    }

    // 렌더링 스텝 등과 맞물리는 충돌 방지용 타이머 지연 
    queueMicrotask(reposition)
    setTimeout(reposition, 0)
  }

  // 객체 생명주기 검증 함수. AG-Grid API가 null이거나 강제 할당해제(destroy)되지 않았는지 판별.
  isApiAlive(api) {
    return Boolean(api) && !(typeof api.isDestroyed === "function" && api.isDestroyed())
  }

  // 브라우저 localStorage에서 커스텀 컬럼 정보를 추출하여 파싱하고 
  // 실제 Grid Api 객체에 재적용시키는 기능.
  #restoreColumnState() {
    const id = this.gridIdValue
    if (!id || !this.isApiAlive(this.gridApi)) return // 고유 ID가 부여된 그리드만 복원 가능

    const saved = localStorage.getItem(this.#storageKey(id))
    if (!saved) return // 저장된 스냅샷 없음

    try {
      const state = JSON.parse(saved)
      this.gridApi.applyColumnState({ state, applyOrder: true }) // 너비, 감춤, 정렬 및 순서(applyOrder) 함께 복원
    } catch (e) {
      // JSON 호환 불가 오류 등 손상된 경우 캐시 제거
      console.warn("[ag-grid] failed to restore column state:", e)
      localStorage.removeItem(this.#storageKey(id))
    }
  }

  #storageKey(gridId) {
    return `ag-grid-state:${gridId}`
  }

  // UI 상단이 아닌 우측 하단에 조용히 띄워주는 "A가 완료되었습니다" 형식 컴포넌트 유틸리티
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

    // UI 스레드가 돔 변경을 인지한 직후 fade-in 애니메이션 수행
    requestAnimationFrame(() => { toast.style.opacity = "1" })

    // 2초 뒤 서서히 지우기 시도, 트랜지션 완료 직후 이벤트로 돔 완전 파괴 연동
    setTimeout(() => {
      toast.style.opacity = "0"
      toast.addEventListener("transitionend", () => toast.remove())
    }, 2000)
  }
}
