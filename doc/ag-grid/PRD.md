# PRD: AG Grid 공통 컴포넌트 통합

> **v1.2** — 화이트리스트 검증 강제 + CDN 장애 대비 추가

## 1. 개요

Rails 8.1 애플리케이션에 AG Grid Community(무료) 버전을 통합하여, 재사용 가능한 데이터 그리드 컴포넌트를 제공합니다. Importmap + Stimulus 기반으로 구현하며, 뷰에서 한 줄의 헬퍼 호출로 고성능 그리드를 렌더링할 수 있도록 공통화합니다.

---

## 2. 목표

| 구분 | 내용 |
|------|------|
| **핵심 목표** | AG Grid Community를 Stimulus 컨트롤러로 래핑하여, 뷰 헬퍼 한 줄로 그리드를 생성할 수 있는 공통 컴포넌트 구축 |
| **성능** | 10,000행 이상의 데이터를 지연 없이 렌더링 (클라이언트사이드 기준, 50,000행 초과 시 서버사이드 전환 권장) |
| **일관성** | 앱의 다크 테마(CSS 변수)와 자연스럽게 통합 |
| **호환성** | Turbo Drive/Frames 네비게이션 및 Turbo 캐시와 완벽 호환 |
| **안정성** | CDN 버전 고정, CSP 허용, 에러 분류로 운영 사고 최소화 |
| **확장성** | 새로운 화면에 그리드를 추가할 때 최소한의 코드만 필요 |

### 비목표

- AG Grid Enterprise 기능 사용 (Excel 내보내기, 서버사이드 행 모델, 마스터-디테일 등)
- 서버사이드 페이지네이션/필터링 (1차 구현에서는 클라이언트사이드만)
- AG Grid 기반 CRUD 인라인 편집 (2차 구현 고려)

---

## 3. 기술 스택

| 항목 | 선택 | 이유 |
|------|------|------|
| AG Grid 버전 | **Community v35.1.0** (patch 고정) | 무료, ESM 번들 지원, 최신 안정 버전 |
| JS 로딩 | **Importmap + jsDelivr CDN** (버전 고정) | Rails 8 기본 에셋 파이프라인, 번들러 불필요 |
| JS 프레임워크 | **Stimulus Controller** | 프로젝트 기존 패턴 |
| 테마 | **themeQuartz (Programmatic API)** | CSS 파일 없이 JS로 테마 커스터마이징, 다크 모드 지원 |
| 뷰 통합 | **Rails View Helper** | ERB에서 Ruby 코드로 그리드 선언 |
| 데이터 전달 | **JSON API (컨트롤러 respond_to)** | RESTful, 기존 라우팅 활용 |

---

## 4. AG Grid Community 무료 기능

### 사용 가능 (Community)

| 기능 | 설명 |
|------|------|
| 정렬 (Sorting) | 컬럼 헤더 클릭으로 오름차순/내림차순 정렬 |
| 필터링 (Filtering) | Text, Number, Date 필터 + 플로팅 필터 |
| 페이지네이션 | 클라이언트사이드 페이지네이션 |
| 셀 편집 | 인라인 셀 편집 |
| 행 선택 | 단일/다중 행 선택 + 체크박스 |
| CSV 내보내기 | 데이터를 CSV 파일로 다운로드 |
| 컬럼 고정 (Pinning) | 좌/우 컬럼 고정 |
| 컬럼 크기 조절 | 드래그로 컬럼 너비 변경 |
| 컬럼 이동 | 드래그로 컬럼 순서 변경 |
| 커스텀 셀 렌더러 | HTML/JS로 셀 내용 커스터마이징 |
| 행 애니메이션 | 정렬/필터 시 부드러운 행 이동 |
| 오버레이 | 로딩/데이터 없음/에러 오버레이 |
| 풀 너비 행 | 전체 너비를 차지하는 특수 행 |

### 사용 불가 (Enterprise 전용)

| 기능 | 대안 |
|------|------|
| Excel 내보내기 | CSV 내보내기 사용 |
| 서버사이드 행 모델 | 클라이언트사이드 + Rails 페이지네이션 |
| 세트 필터 (Set Filter) | 텍스트 필터 사용 |
| 컬럼 도구 패널 | 없음 (컬럼 이동/숨기기로 대체) |
| 통합 차트 | 별도 차트 라이브러리 사용 |
| 클립보드 | 브라우저 기본 복사 |
| 범위 선택 | 행 선택 사용 |
| 마스터-디테일 | 별도 상세 뷰 링크 |

---

## 5. 아키텍처

### 5.1 전체 구조

```
┌─────────────────────────────────────────────────────────┐
│  View (ERB)                                             │
│  <%= ag_grid_tag(columns: [...], url: "...") %>         │
│                                                         │
│  ┌─────────────────────────────────────────────────┐    │
│  │  AgGridHelper (View Helper)                     │    │
│  │  - HTML 생성 + data-* 속성 바인딩               │    │
│  │  - columnDefs 화이트리스트 검증                  │    │
│  └─────────────────┬───────────────────────────────┘    │
│                    │ data-controller="ag-grid"           │
│  ┌─────────────────▼───────────────────────────────┐    │
│  │  ag_grid_controller.js (Stimulus)               │    │
│  │  - AG Grid 초기화/해제                          │    │
│  │  - turbo:before-cache 대응                      │    │
│  │  - 테마 적용 + 한국어 locale                    │    │
│  │  - 데이터 fetch + 에러 분류                     │    │
│  │  - Formatter Registry (키 → 함수 매핑)          │    │
│  └─────────────────┬───────────────────────────────┘    │
│                    │ createGrid()                        │
│  ┌─────────────────▼───────────────────────────────┐    │
│  │  AG Grid Community v35.1.0 (CDN ESM, 버전 고정) │    │
│  │  - AllCommunityModule                           │    │
│  │  - themeQuartz (다크 테마 커스터마이징)           │    │
│  └─────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  Controller (Rails)                                     │
│  respond_to :html, :json                                │
│  GET /posts.json → @posts.to_json                       │
└─────────────────────────────────────────────────────────┘
```

### 5.2 데이터 흐름

```
1. 브라우저 → GET /posts (HTML)
2. ERB 렌더링 → ag_grid_tag() 헬퍼가 div + data 속성 생성
3. Stimulus connect() → ag_grid_controller 초기화
4. turbo:before-cache 이벤트 리스너 등록
5. AG Grid 생성 → createGrid(div, gridOptions)
6. fetch(url) → GET /posts.json
7. JSON 응답 → gridApi.setGridOption("rowData", data)
8. AG Grid 렌더링 완료
```

### 5.3 Turbo 호환 라이프사이클

```
페이지 진입 (Turbo visit)
  → Stimulus connect()
    → turbo:before-cache 리스너 등록
    → AG Grid createGrid()
    → 데이터 fetch & 렌더링

Turbo 캐시 저장 전 (turbo:before-cache)
  → #teardown() 호출
    → gridApi.destroy()
    → DOM에서 AG Grid 흔적 제거 (캐시에 깨진 상태 저장 방지)

페이지 이탈 (Turbo visit)
  → Stimulus disconnect()
    → turbo:before-cache 리스너 해제
    → #teardown() 호출 (아직 안 된 경우)
    → 메모리 해제

캐시에서 복귀 (Turbo restoration visit)
  → Stimulus connect() 재호출
    → AG Grid 새로 초기화 (깨끗한 상태에서 시작)
```

---

## 6. 운영 안정성 정책

### 6.1 CDN 버전 고정 (Critical)

Importmap 핀에 **반드시 정확한 patch 버전을 명시**하여 빌드 재현성을 확보합니다.

```ruby
# Good — 버전 고정
pin "ag-grid-community",
    to: "https://cdn.jsdelivr.net/npm/ag-grid-community@35.1.0/dist/ag-grid-community.auto.esm.min.js"

# Bad — latest를 따라가서 예기치 않은 breaking change 위험
pin "ag-grid-community",
    to: "https://cdn.jsdelivr.net/npm/ag-grid-community/dist/ag-grid-community.auto.esm.min.js"
```

**업그레이드 절차**: 버전 변경 시 반드시 개발 환경에서 먼저 테스트 후 커밋합니다.

### 6.2 CSP (콘텐츠 보안 정책)

CSP를 활성화할 경우, jsDelivr CDN 도메인을 `script_src`에 허용해야 합니다.

**파일: `config/initializers/content_security_policy.rb`**

```ruby
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data
    policy.object_src  :none
    policy.script_src  :self, :https, "https://cdn.jsdelivr.net"
    policy.style_src   :self, :https
    policy.connect_src :self  # fetch로 /posts.json 등 자체 API 호출
  end
end
```

> 현재 CSP는 비활성화(주석 처리) 상태입니다. 향후 CSP를 켤 때 `cdn.jsdelivr.net`을 반드시 허용하세요.

### 6.3 Turbo 캐시 대응 (Critical)

Turbo는 페이지를 캐시에 저장할 때 DOM을 그대로 보관합니다. AG Grid가 초기화된 상태로 캐시되면 **복귀 시 중복 초기화/이벤트 누수/레이아웃 깨짐**이 발생합니다.

**해결**: `turbo:before-cache` 이벤트에서 그리드를 확실히 해제합니다.

```javascript
connect() {
  this.#initGrid()
  this._beforeCache = () => this.#teardown()
  document.addEventListener("turbo:before-cache", this._beforeCache)
}

disconnect() {
  document.removeEventListener("turbo:before-cache", this._beforeCache)
  this.#teardown()
}

#teardown() {
  if (this.gridApi) {
    this.gridApi.destroy()
    this.gridApi = null
    this.gridTarget.innerHTML = ""  // AG Grid DOM 흔적 제거
  }
}
```

### 6.4 columnDefs 보안 정책 — Whitelist + Formatter Registry

서버에서 내려주는 columnDefs는 **순수 데이터(화이트리스트된 옵션)만** 허용합니다. `valueFormatter`, `cellRenderer` 등 함수가 필요한 속성은 **문자열 expression 대신 키 기반 레지스트리**로 구현합니다.

```javascript
// Formatter Registry — 서버는 키만 전달, JS에서 함수로 매핑
const FORMATTER_REGISTRY = {
  currency:  (params) => params.value != null ? `₩${params.value.toLocaleString()}` : "",
  date:      (params) => params.value ? new Date(params.value).toLocaleDateString("ko-KR") : "",
  datetime:  (params) => params.value ? new Date(params.value).toLocaleString("ko-KR") : "",
  percent:   (params) => params.value != null ? `${params.value}%` : "",
  truncate:  (params) => params.value?.length > 50 ? params.value.slice(0, 50) + "…" : params.value ?? "",
}
```

**서버(뷰)에서의 사용법:**

```ruby
columns = [
  { field: "price", headerName: "가격", formatter: "currency" },
  { field: "created_at", headerName: "작성일", formatter: "date" },
]
```

**Stimulus 컨트롤러에서 매핑:**

```javascript
#buildColumnDefs() {
  return this.columnsValue.map(col => {
    const def = { ...col }
    if (def.formatter && FORMATTER_REGISTRY[def.formatter]) {
      def.valueFormatter = FORMATTER_REGISTRY[def.formatter]
      delete def.formatter
    }
    return def
  })
}
```

> `valueFormatter: "expression string"` 형태는 eval 유혹과 XSS 위험이 있으므로 사용하지 않습니다.

### 6.5 columnDefs 화이트리스트 검증 강제 (Critical)

Helper에서 columnDefs를 HTML `data-*` 속성으로 직렬화할 때, **허용되지 않은 키는 자동 제거**하고 **개발 환경에서는 경고 로그**를 출력합니다.

```ruby
# ag_grid_helper.rb — 화이트리스트 검증
ALLOWED_COLUMN_KEYS = %w[
  field headerName
  flex minWidth maxWidth width
  filter sortable resizable editable
  pinned hide cellStyle
  formatter
].freeze

def sanitize_column_defs(columns)
  columns.map do |col|
    sanitized = col.slice(*ALLOWED_COLUMN_KEYS.map(&:to_sym))

    rejected = col.keys.map(&:to_s) - ALLOWED_COLUMN_KEYS
    if rejected.any?
      Rails.logger.warn("[ag_grid_helper] 허용되지 않은 columnDef 키 제거: #{rejected.join(', ')}")
    end

    sanitized
  end
end
```

**검증 전략:**

| 환경 | 동작 |
|------|------|
| **개발/테스트** | 허용되지 않은 키 제거 + `Rails.logger.warn` 경고 출력 |
| **프로덕션** | 허용되지 않은 키 제거 (사일런트, 페이지 렌더링 중단 방지) |

> `valueFormatter`, `cellRenderer` 등 함수 속성이 서버에서 전달되면 자동으로 걸러집니다. 이 키들이 필요하면 반드시 Formatter/Renderer Registry를 통해 JS에서 매핑하세요.

### 6.6 CDN 장애 대비

jsDelivr CDN에 장애가 발생하면 AG Grid ESM 모듈 로딩 자체가 실패합니다. 이 경우 그리드가 렌더링되지 않으므로, **사용자에게 상황을 안내**하고 **운영자가 인지**할 수 있어야 합니다.

**1차 대응 (현재 구현):**

```javascript
// ag_grid_controller.js — CDN 장애 시 import 실패 감지
// import 문이 실패하면 Stimulus 컨트롤러 자체가 로드되지 않음
// → connect()가 호출되지 않음 → 그리드 영역이 빈 상태로 남음

// Fallback: 그리드 타겟에 CSS로 기본 안내 메시지 표시
// (Stimulus 컨트롤러가 로드되지 않아도 보이도록 CSS only)
```

```css
/* application.css — AG Grid 로딩 실패 폴백 */
[data-ag-grid-target="grid"]:empty::after {
  content: "그리드를 불러오는 중...";
  display: flex;
  align-items: center;
  justify-content: center;
  height: 200px;
  color: #8b949e;
  font-size: 14px;
}
```

> Stimulus 컨트롤러가 정상 로드되면 `connect()`에서 AG Grid를 마운트하므로 `:empty` 상태가 해제되어 폴백 메시지가 자동으로 사라집니다.

**2차 대응 (향후 강화 시):**

| 방안 | 설명 | 장단점 |
|------|------|--------|
| 로컬 파일 호스팅 | `ag-grid-community.auto.esm.min.js`를 `vendor/javascript/`에 배치 후 Importmap 핀 변경 | CDN 의존성 제거, 번들 크기 ~300KB 증가 |
| 미러 CDN 전환 | jsDelivr 장애 시 unpkg/cdnjs로 수동 전환 | 긴급 대응 가능, 자동화 불가 |
| 에러 모니터링 | JS 에러 트래킹(Sentry 등)으로 import 실패 감지 | 장애 인지 속도 향상 |

> 현재 프로젝트 규모에서는 1차 대응(CSS 폴백 메시지)으로 충분합니다. CDN 장애가 반복되면 로컬 파일 호스팅으로 전환하세요.

---

## 7. 구현 명세

### 7.1 Importmap 설정

**파일: `config/importmap.rb`**

```ruby
# 기존 핀 유지
pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

# AG Grid Community — 반드시 patch 버전까지 고정
pin "ag-grid-community", to: "https://cdn.jsdelivr.net/npm/ag-grid-community@35.1.0/dist/ag-grid-community.auto.esm.min.js"
```

> `ag-grid-community.auto.esm.min.js`는 AllCommunityModule이 포함된 단일 ESM 번들입니다. Importmap과 완벽 호환됩니다.

### 7.2 Stimulus 컨트롤러

**파일: `app/javascript/controllers/ag_grid_controller.js`**

```javascript
import { Controller } from "@hotwired/stimulus"
import {
  AllCommunityModule,
  ModuleRegistry,
  createGrid,
  themeQuartz
} from "ag-grid-community"

// AG Grid 모듈 등록 (한 번만 실행)
ModuleRegistry.registerModules([AllCommunityModule])

// ── Formatter Registry (키 → 함수 매핑) ──
// columnDefs에 formatter: "currency" 형태로 사용
const FORMATTER_REGISTRY = {
  currency:  (params) => params.value != null ? `₩${params.value.toLocaleString()}` : "",
  date:      (params) => params.value ? new Date(params.value).toLocaleDateString("ko-KR") : "",
  datetime:  (params) => params.value ? new Date(params.value).toLocaleString("ko-KR") : "",
  percent:   (params) => params.value != null ? `${params.value}%` : "",
  truncate:  (params) => params.value?.length > 50 ? params.value.slice(0, 50) + "…" : params.value ?? "",
}

// ── 한국어 locale 텍스트 ──
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
  blank: "빈 값",
  notBlank: "비어있지 않음",
  lessThan: "미만",
  greaterThan: "초과",
  lessThanOrEqual: "이하",
  greaterThanOrEqual: "이상",
  inRange: "범위 내",
  andCondition: "그리고",
  orCondition: "또는",
  applyFilter: "적용",
  resetFilter: "초기화",
  clearFilter: "지우기",
  cancelFilter: "취소",
  columns: "컬럼",
  pinColumn: "컬럼 고정",
  pinLeft: "왼쪽 고정",
  pinRight: "오른쪽 고정",
  noPin: "고정 해제",
  autosizeThisColumn: "이 컬럼 자동 크기",
  autosizeAllColumns: "전체 컬럼 자동 크기",
  resetColumns: "컬럼 초기화",
  copy: "복사",
  ctrlC: "Ctrl+C",
  csvExport: "CSV 내보내기",
  export: "내보내기",
  sortAscending: "오름차순 정렬",
  sortDescending: "내림차순 정렬",
  sortUnSort: "정렬 해제",
}

// ── 앱 다크 테마에 맞춘 AG Grid 테마 ──
const darkTheme = themeQuartz.withParams({
  backgroundColor:       "#161b22",
  foregroundColor:        "#e6edf3",
  headerBackgroundColor:  "#1c2333",
  headerTextColor:        "#8b949e",
  borderColor:            "#30363d",
  rowHoverColor:          "#21262d",
  accentColor:            "#58a6ff",
  oddRowBackgroundColor:  "#0f1117",
  headerFontSize:         12,
  fontSize:               13,
  borderRadius:           8,
  wrapperBorderRadius:    8,
  fontFamily:             '-apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif',
})

export default class extends Controller {
  static targets = ["grid"]

  static values = {
    columns:       Array,                          // 컬럼 정의 배열
    url:           String,                         // 데이터 fetch URL
    rowData:       { type: Array, default: [] },   // 인라인 데이터
    pagination:    { type: Boolean, default: true },
    pageSize:      { type: Number, default: 20 },
    height:        { type: String, default: "500px" },
    rowSelection:  { type: String, default: "" },  // "single" | "multiple"
  }

  connect() {
    this.#initGrid()
    // Turbo 캐시 대응: 캐시 저장 전에 그리드를 해제
    this._beforeCache = () => this.#teardown()
    document.addEventListener("turbo:before-cache", this._beforeCache)
  }

  disconnect() {
    document.removeEventListener("turbo:before-cache", this._beforeCache)
    this.#teardown()
  }

  // ── 퍼블릭 API (data-action 또는 다른 컨트롤러에서 호출) ──

  refresh() {
    if (this.hasUrlValue && this.urlValue) {
      this.#fetchData()
    }
  }

  get api() {
    return this.gridApi
  }

  exportCsv() {
    this.gridApi?.exportDataAsCsv()
  }

  // ── 프라이빗 ──

  #initGrid() {
    const gridOptions = {
      theme:            darkTheme,
      columnDefs:       this.#buildColumnDefs(),
      defaultColDef:    this.#defaultColDef(),
      pagination:       this.paginationValue,
      paginationPageSize: this.pageSizeValue,
      paginationPageSizeSelector: [10, 20, 50, 100],
      localeText:       AG_GRID_LOCALE_KO,
      animateRows:      true,
      rowData:          [],
    }

    // 행 선택 설정
    if (this.rowSelectionValue) {
      gridOptions.rowSelection = {
        mode: this.rowSelectionValue === "single" ? "singleRow" : "multiRow",
      }
    }

    // 그리드 높이 설정
    this.gridTarget.style.height = this.heightValue
    this.gridTarget.style.width = "100%"

    // 그리드 생성
    this.gridApi = createGrid(this.gridTarget, gridOptions)

    // 데이터 로딩
    if (this.hasUrlValue && this.urlValue) {
      this.#fetchData()
    } else if (this.rowDataValue.length > 0) {
      this.gridApi.setGridOption("rowData", this.rowDataValue)
    }
  }

  #teardown() {
    if (this.gridApi) {
      this.gridApi.destroy()
      this.gridApi = null
      this.gridTarget.innerHTML = ""  // AG Grid DOM 흔적 제거
    }
  }

  #buildColumnDefs() {
    return this.columnsValue.map(col => {
      const def = { ...col }
      // Formatter Registry 매핑: 서버는 키만 전달, JS에서 함수로 변환
      if (def.formatter && FORMATTER_REGISTRY[def.formatter]) {
        def.valueFormatter = FORMATTER_REGISTRY[def.formatter]
        delete def.formatter
      }
      return def
    })
  }

  #defaultColDef() {
    return {
      flex:       1,
      minWidth:   100,
      filter:     true,
      sortable:   true,
      resizable:  true,
    }
  }

  #fetchData() {
    this.gridApi.showLoadingOverlay()

    fetch(this.urlValue, {
      headers: { "Accept": "application/json" }
    })
      .then(response => {
        if (!response.ok) throw new Error(`HTTP ${response.status}`)
        return response.json()
      })
      .then(data => {
        this.gridApi.setGridOption("rowData", data)
        if (data.length === 0) {
          this.gridApi.showNoRowsOverlay()
        }
      })
      .catch(error => {
        console.error("[ag-grid] 데이터 로딩 실패:", error)
        // 에러 오버레이: "데이터 없음"과 구분되는 에러 메시지 표시
        this.gridApi.setGridOption("overlayNoRowsTemplate",
          '<div style="padding:20px;text-align:center;">' +
          '<div style="color:#f85149;font-weight:600;margin-bottom:4px;">데이터 로딩 실패</div>' +
          '<div style="color:#8b949e;font-size:12px;">네트워크 상태를 확인해주세요</div>' +
          '</div>'
        )
        this.gridApi.showNoRowsOverlay()
      })
  }
}
```

### 7.3 Stimulus 컨트롤러 등록

**파일: `app/javascript/controllers/index.js`** (추가)

```javascript
import AgGridController from "controllers/ag_grid_controller"
application.register("ag-grid", AgGridController)
```

### 7.4 View Helper

**파일: `app/helpers/ag_grid_helper.rb`**

```ruby
module AgGridHelper
  # columnDefs 화이트리스트 — 허용된 키만 HTML 직렬화
  ALLOWED_COLUMN_KEYS = %i[
    field headerName
    flex minWidth maxWidth width
    filter sortable resizable editable
    pinned hide cellStyle
    formatter
  ].freeze

  # AG Grid 데이터 그리드를 렌더링합니다.
  #
  # ==== 매개변수
  # * +columns+ - 컬럼 정의 배열 (필수)
  #   [{ field: "title", headerName: "제목", flex: 2 }, ...]
  # * +url+ - JSON 데이터를 가져올 URL (url 또는 row_data 중 하나 필수)
  # * +row_data+ - 인라인 행 데이터 배열
  # * +pagination+ - 페이지네이션 활성화 (기본값: true)
  # * +page_size+ - 페이지당 행 수 (기본값: 20)
  # * +height+ - 그리드 높이 (기본값: "500px")
  # * +row_selection+ - 행 선택 모드 ("single" 또는 "multiple")
  # * +html_options+ - 추가 HTML 속성
  #
  # ==== 컬럼 정의 허용 옵션 (화이트리스트)
  # 데이터 속성: field, headerName, flex, minWidth, maxWidth, width,
  #             filter, sortable, resizable, pinned, hide, cellStyle
  # 포맷터 키:  formatter ("currency", "date", "datetime", "percent", "truncate")
  #
  # ==== 사용 예시
  #   <%= ag_grid_tag(
  #     columns: [
  #       { field: "id", headerName: "#", maxWidth: 80 },
  #       { field: "title", headerName: "제목", flex: 2 },
  #       { field: "price", headerName: "가격", formatter: "currency" },
  #       { field: "created_at", headerName: "작성일", formatter: "date" }
  #     ],
  #     url: posts_path(format: :json)
  #   ) %>
  def ag_grid_tag(columns:, url: nil, row_data: nil, pagination: true,
                  page_size: 20, height: "500px", row_selection: nil,
                  **html_options)
    safe_columns = sanitize_column_defs(columns)

    stimulus_data = {
      controller: "ag-grid",
      "ag-grid-columns-value" => safe_columns.to_json,
      "ag-grid-pagination-value" => pagination,
      "ag-grid-page-size-value" => page_size,
      "ag-grid-height-value" => height,
    }

    stimulus_data["ag-grid-url-value"] = url if url.present?
    stimulus_data["ag-grid-row-data-value"] = row_data.to_json if row_data.present?
    stimulus_data["ag-grid-row-selection-value"] = row_selection if row_selection.present?

    wrapper_attrs = html_options.merge(data: stimulus_data)

    content_tag(:div, wrapper_attrs) do
      content_tag(:div, "", data: { "ag-grid-target": "grid" })
    end
  end

  private
    # 허용되지 않은 columnDef 키를 제거하고 경고 로그를 출력합니다.
    def sanitize_column_defs(columns)
      columns.map do |col|
        col = col.symbolize_keys
        sanitized = col.slice(*ALLOWED_COLUMN_KEYS)

        rejected = col.keys - ALLOWED_COLUMN_KEYS
        if rejected.any?
          Rails.logger.warn(
            "[ag_grid_helper] 허용되지 않은 columnDef 키 제거: #{rejected.join(', ')} " \
            "(field: #{col[:field]})"
          )
        end

        sanitized
      end
    end
end
```

### 7.5 컨트롤러 JSON 응답

**파일: `app/controllers/posts_controller.rb`** (index 액션 수정)

```ruby
def index
  @posts = Post.order(created_at: :desc)

  respond_to do |format|
    format.html
    format.json { render json: @posts }
  end
end
```

### 7.6 뷰 적용 예시

**파일: `app/views/posts/index.html.erb`** (AG Grid 버전)

```erb
<%= turbo_frame_tag "main-content" do %>
  <div class="page-header">
    <h2>게시물 목록</h2>
    <div class="page-actions">
      <%= link_to "새 게시물", new_post_path, class: "btn btn-primary" %>
    </div>
  </div>

  <%= ag_grid_tag(
    columns: [
      { field: "id", headerName: "#", maxWidth: 80, filter: false },
      { field: "title", headerName: "제목", flex: 2 },
      { field: "content", headerName: "내용" },
      { field: "created_at", headerName: "작성일", maxWidth: 160, formatter: "date" }
    ],
    url: posts_path(format: :json),
    height: "calc(100vh - 220px)",
    page_size: 20
  ) %>
<% end %>
```

---

## 8. 파일 변경 목록

| 작업 | 파일 경로 | 설명 |
|------|----------|------|
| **수정** | `config/importmap.rb` | AG Grid CDN 핀 추가 (v35.1.0 고정) |
| **생성** | `app/javascript/controllers/ag_grid_controller.js` | Stimulus 컨트롤러 (Turbo 캐시 대응 + Formatter Registry + 한국어 locale + 에러 분류) |
| **수정** | `app/javascript/controllers/index.js` | AG Grid 컨트롤러 등록 |
| **생성** | `app/helpers/ag_grid_helper.rb` | 뷰 헬퍼 |
| **수정** | `app/controllers/posts_controller.rb` | JSON 응답 추가 |
| **수정** | `app/views/posts/index.html.erb` | AG Grid 적용 (예시) |
| **수정** | `app/assets/stylesheets/application.css` | AG Grid 로딩 폴백 CSS (CDN 장애 대비) |
| **(참고)** | `config/initializers/content_security_policy.rb` | CSP 활성화 시 jsDelivr 허용 필요 |

---

## 9. 사용법 가이드

### 9.1 기본 사용법 (URL 기반)

컨트롤러에서 JSON 응답을 추가하고, 뷰에서 헬퍼를 호출합니다.

```ruby
# 컨트롤러
def index
  @items = Item.all
  respond_to do |format|
    format.html
    format.json { render json: @items }
  end
end
```

```erb
<%# 뷰 %>
<%= ag_grid_tag(
  columns: [
    { field: "name", headerName: "이름" },
    { field: "price", headerName: "가격", filter: "agNumberColumnFilter" }
  ],
  url: items_path(format: :json)
) %>
```

### 9.2 인라인 데이터

소규모 데이터나 서버에서 미리 로드한 데이터를 직접 전달합니다.

```erb
<%= ag_grid_tag(
  columns: [
    { field: "name", headerName: "이름" },
    { field: "status", headerName: "상태" }
  ],
  row_data: @items.as_json(only: [:name, :status])
) %>
```

### 9.3 행 선택 활성화

```erb
<%= ag_grid_tag(
  columns: [...],
  url: items_path(format: :json),
  row_selection: "multiple"
) %>
```

### 9.4 컬럼 정의 상세 옵션 (Formatter Registry 활용)

```ruby
columns = [
  {
    field: "id",
    headerName: "#",
    maxWidth: 80,
    filter: false,
    sortable: false
  },
  {
    field: "title",
    headerName: "제목",
    flex: 2,
    filter: "agTextColumnFilter"
  },
  {
    field: "price",
    headerName: "가격",
    filter: "agNumberColumnFilter",
    formatter: "currency"        # Formatter Registry 키 사용
  },
  {
    field: "created_at",
    headerName: "작성일",
    maxWidth: 160,
    formatter: "date"            # Formatter Registry 키 사용
  },
  {
    field: "ratio",
    headerName: "비율",
    maxWidth: 100,
    formatter: "percent"
  },
  {
    field: "status",
    headerName: "상태",
    maxWidth: 120,
    cellStyle: { textAlign: "center" }
  }
]
```

**등록된 Formatter 키:**

| 키 | 출력 예시 | 설명 |
|----|----------|------|
| `currency` | `₩1,234,567` | 원화 통화 형식 |
| `date` | `2026. 2. 13.` | 한국어 날짜 |
| `datetime` | `2026. 2. 13. 오후 3:45:00` | 한국어 날짜+시간 |
| `percent` | `85%` | 퍼센트 |
| `truncate` | `긴 텍스트가 50자를 넘으면 잘...` | 50자 말줄임 |

> 새 포맷터가 필요하면 `ag_grid_controller.js`의 `FORMATTER_REGISTRY`에 키-함수 쌍을 추가하세요.

### 9.5 CSV 내보내기 버튼 추가

```erb
<div class="page-actions">
  <button class="btn btn-secondary"
          data-action="ag-grid#exportCsv">
    CSV 다운로드
  </button>
</div>

<%= ag_grid_tag(columns: [...], url: "...") %>
```

> CSV 버튼의 `data-action`은 ag-grid 컨트롤러의 `exportCsv()` 메서드를 호출합니다.
> 단, 버튼이 ag-grid 컨트롤러 스코프 내에 있어야 합니다.
> 스코프 밖이라면 `data-controller`를 상위 요소로 올리거나 Stimulus outlet을 사용하세요.

---

## 10. 다크 테마 매핑

AG Grid 테마 파라미터와 앱 CSS 변수의 매핑:

| AG Grid 파라미터 | 앱 CSS 변수 | 값 |
|-----------------|-------------|-----|
| `backgroundColor` | `--bg-secondary` | `#161b22` |
| `foregroundColor` | `--text-primary` | `#e6edf3` |
| `headerBackgroundColor` | `--bg-tertiary` | `#1c2333` |
| `headerTextColor` | `--text-secondary` | `#8b949e` |
| `borderColor` | `--border` | `#30363d` |
| `rowHoverColor` | `--bg-hover` | `#21262d` |
| `accentColor` | `--accent` | `#58a6ff` |
| `oddRowBackgroundColor` | `--bg-primary` | `#0f1117` |

---

## 11. 테스트 계획

### 11.1 단위 테스트

```ruby
# test/helpers/ag_grid_helper_test.rb
class AgGridHelperTest < ActionView::TestCase
  test "ag_grid_tag renders with required attributes" do
    html = ag_grid_tag(
      columns: [{ field: "name" }],
      url: "/items.json"
    )
    assert_includes html, 'data-controller="ag-grid"'
    assert_includes html, 'data-ag-grid-url-value="/items.json"'
    assert_includes html, 'data-ag-grid-target="grid"'
  end

  test "ag_grid_tag supports inline data" do
    html = ag_grid_tag(
      columns: [{ field: "name" }],
      row_data: [{ name: "Test" }]
    )
    assert_includes html, 'data-ag-grid-row-data-value'
  end

  test "ag_grid_tag includes formatter key in column values" do
    html = ag_grid_tag(
      columns: [{ field: "price", formatter: "currency" }],
      url: "/items.json"
    )
    assert_includes html, '"formatter":"currency"'
  end

  test "ag_grid_tag sanitizes disallowed column keys" do
    html = ag_grid_tag(
      columns: [{ field: "name", valueFormatter: "evil()", cellRenderer: "xss" }],
      url: "/items.json"
    )
    # 허용되지 않은 키는 제거됨
    assert_not_includes html, "valueFormatter"
    assert_not_includes html, "cellRenderer"
    # 허용된 키는 유지됨
    assert_includes html, '"field":"name"'
  end
end
```

### 11.2 시스템 테스트

```ruby
# test/system/ag_grid_test.rb
class AgGridTest < ApplicationSystemTestCase
  test "posts index renders AG Grid" do
    Post.create!(title: "테스트", content: "내용")
    visit posts_path

    assert_selector "[data-controller='ag-grid']"
    # AG Grid가 렌더링되면 .ag-root-wrapper 클래스가 생성됨
    # 비동기 fetch 완료를 대기
    assert_selector ".ag-root-wrapper", wait: 10
    assert_text "테스트", wait: 10
  end

  test "AG Grid survives Turbo navigation round-trip" do
    Post.create!(title: "왕복테스트", content: "내용")
    visit posts_path
    assert_selector ".ag-root-wrapper", wait: 10

    # 다른 페이지로 이동 후 뒤로가기
    visit root_path
    go_back
    assert_selector ".ag-root-wrapper", wait: 10
    assert_text "왕복테스트", wait: 10
  end
end
```

### 11.3 JSON 응답 테스트

```ruby
# test/controllers/posts_controller_test.rb
test "index responds to json" do
  Post.create!(title: "테스트", content: "내용")
  get posts_url, as: :json

  assert_response :success
  json = JSON.parse(response.body)
  assert_equal 1, json.length
  assert_equal "테스트", json.first["title"]
end
```

---

## 12. 데이터 볼륨 운영 가이드

| 행 수 | 전략 | 비고 |
|-------|------|------|
| ~10,000 | **클라이언트사이드** (1차 구현) | JSON 전체 로딩 + AG Grid 가상화 |
| 10,000~50,000 | 클라이언트사이드 + 경고 모니터링 | JSON 응답 크기와 초기 로딩 시간 모니터링 |
| 50,000+ | **서버사이드 전환 권장** (2차 구현) | Pagy 기반 서버 페이징, AG Grid Infinite Row Model |

**전환 임계점 판단 기준:**
- JSON 응답 크기 > 5MB
- 초기 로딩 시간 > 3초
- 사용자 불만 피드백 발생

> 2차 구현의 서버사이드 페이지네이션은 `향후 확장 고려사항`에서 별도 설계합니다.

---

## 13. 향후 확장 고려사항

| 단계 | 기능 | 설명 |
|------|------|------|
| 2차 | 서버사이드 페이지네이션 | Pagy + JSON API 연동 (50,000행 이상 대응) |
| 2차 | 인라인 편집 → 서버 저장 | 셀 편집 후 PATCH 요청으로 저장 |
| 2차 | 컬럼 상태 저장 | localStorage에 컬럼 순서/너비/정렬 상태 저장 |
| 3차 | 커스텀 셀 렌더러 Registry | Renderer Registry 패턴으로 링크/배지/버튼 렌더러 등록 |
| 3차 | 그리드 간 연동 | 마스터-디테일 패턴 (Community 범위 내) |

---

## 14. 의존성

| 패키지 | 버전 | 설치 방법 |
|--------|------|----------|
| `ag-grid-community` | **`35.1.0`** (patch 고정) | Importmap CDN 핀 (설치 불필요) |

**추가 gem 설치 없음.** Rails Importmap으로 CDN에서 직접 로딩합니다.
