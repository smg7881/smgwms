# AG Grid 기술 설계 문서

> **v1.2** — 화이트리스트 검증 강제 + CDN 장애 대비 추가

## 1. 컴포넌트 다이어그램

```
config/importmap.rb
  └─ pin "ag-grid-community@35.1.0" (CDN ESM, 버전 고정)

config/initializers/content_security_policy.rb
  └─ script_src: "https://cdn.jsdelivr.net" (CSP 활성화 시)

app/javascript/controllers/
  ├─ index.js                  ← AG Grid 컨트롤러 등록 추가
  └─ ag_grid_controller.js     ← [신규] 핵심 Stimulus 컨트롤러
                                   ├─ Turbo 캐시 대응 (turbo:before-cache)
                                   ├─ Formatter Registry (키 → 함수 매핑)
                                   ├─ 한국어 localeText
                                   └─ 에러/빈 데이터 오버레이 분리

app/helpers/
  └─ ag_grid_helper.rb         ← [신규] ag_grid_tag 뷰 헬퍼

app/controllers/
  └─ posts_controller.rb       ← respond_to :json 추가 (예시)

app/views/posts/
  └─ index.html.erb            ← ag_grid_tag 적용 (예시)
```

---

## 2. Stimulus 컨트롤러 상세 설계

### 2.1 Values (데이터 속성)

| Value | 타입 | 기본값 | 설명 |
|-------|------|--------|------|
| `columns` | `Array` | (필수) | AG Grid columnDefs 배열 |
| `url` | `String` | `""` | JSON 데이터 fetch URL |
| `rowData` | `Array` | `[]` | 인라인 행 데이터 |
| `pagination` | `Boolean` | `true` | 페이지네이션 ON/OFF |
| `pageSize` | `Number` | `20` | 페이지당 행 수 |
| `height` | `String` | `"500px"` | 그리드 컨테이너 높이 |
| `rowSelection` | `String` | `""` | `"single"` 또는 `"multiple"` |

### 2.2 Targets

| Target | 용도 |
|--------|------|
| `grid` | AG Grid가 마운트되는 DOM 요소 |

### 2.3 Actions (외부 호출 가능)

| 메서드 | 설명 | 사용 예시 |
|--------|------|----------|
| `refresh()` | URL에서 데이터 재조회 | `data-action="click->ag-grid#refresh"` |
| `exportCsv()` | CSV 파일 내보내기 | `data-action="click->ag-grid#exportCsv"` |

### 2.4 라이프사이클 (Turbo 캐시 대응 포함)

```
connect()
  ├─ #initGrid()
  │   ├─ gridOptions 구성 (localeText 포함)
  │   ├─ #buildColumnDefs() → Formatter Registry 매핑
  │   ├─ createGrid(target, options) → gridApi 저장
  │   └─ URL이 있으면 #fetchData()
  │       또는 rowData가 있으면 직접 설정
  └─ turbo:before-cache 이벤트 리스너 등록

turbo:before-cache (Turbo 캐시 저장 직전)
  └─ #teardown()
      ├─ gridApi.destroy()
      ├─ gridApi = null
      └─ gridTarget.innerHTML = "" (DOM 흔적 제거)

disconnect()
  ├─ turbo:before-cache 리스너 해제
  └─ #teardown() (아직 해제 안 된 경우)
```

### 2.5 Formatter Registry

서버에서 내려주는 columnDefs에는 **데이터 속성만** 포함합니다. 함수가 필요한 포맷터는 키 기반으로 매핑합니다.

```
서버(ERB) → { field: "price", formatter: "currency" }
               │
               ▼
#buildColumnDefs() → FORMATTER_REGISTRY["currency"] 조회
               │
               ▼
AG Grid → { field: "price", valueFormatter: (params) => ... }
```

**등록된 포맷터:**

| 키 | 출력 예시 |
|----|----------|
| `currency` | `₩1,234,567` |
| `date` | `2026. 2. 13.` |
| `datetime` | `2026. 2. 13. 오후 3:45:00` |
| `percent` | `85%` |
| `truncate` | `긴 텍스트가 50자를 넘...` |

**새 포맷터 추가 방법**: `ag_grid_controller.js`의 `FORMATTER_REGISTRY` 객체에 키-함수 쌍을 추가합니다.

---

## 3. View Helper API

### `ag_grid_tag` 메서드 시그니처

```ruby
ag_grid_tag(
  columns:,           # Array<Hash> — 필수, AG Grid columnDefs
  url: nil,           # String — JSON 데이터 URL
  row_data: nil,      # Array<Hash> — 인라인 데이터
  pagination: true,   # Boolean
  page_size: 20,      # Integer
  height: "500px",    # String — CSS 높이값
  row_selection: nil,  # String — "single" | "multiple"
  **html_options       # Hash — 추가 HTML 속성 (class, id 등)
)
```

### columnDefs 허용 옵션 (화이트리스트)

| 카테고리 | 허용 키 |
|---------|---------|
| 필드 정의 | `field`, `headerName` |
| 크기 | `flex`, `minWidth`, `maxWidth`, `width` |
| 동작 | `filter`, `sortable`, `resizable`, `editable` |
| 표시 | `pinned`, `hide`, `cellStyle` |
| 포맷터 | `formatter` (Registry 키) |

> `valueFormatter`, `cellRenderer` 등 함수 속성은 columnDefs에 직접 넣지 않습니다. Formatter/Renderer Registry를 통해 JS 쪽에서 매핑합니다.

### columnDefs 화이트리스트 검증 (Helper 내부)

Helper에서 `ag_grid_tag`를 호출할 때, **허용되지 않은 키는 자동 제거**됩니다.

```
호출: { field: "name", valueFormatter: "evil()", cellRenderer: "xss" }
  │
  ▼ sanitize_column_defs()
결과: { field: "name" }  ← valueFormatter, cellRenderer 자동 제거
  │
  ▼ Rails.logger.warn
로그: "[ag_grid_helper] 허용되지 않은 columnDef 키 제거: valueFormatter, cellRenderer (field: name)"
```

| 환경 | 허용되지 않은 키 발견 시 |
|------|------------------------|
| 개발/테스트 | 키 제거 + `Rails.logger.warn` 경고 |
| 프로덕션 | 키 제거 (사일런트, 페이지 렌더링 중단 없음) |

### 생성되는 HTML

```html
<div data-controller="ag-grid"
     data-ag-grid-columns-value='[{"field":"name","headerName":"이름","formatter":"date"}]'
     data-ag-grid-url-value="/items.json"
     data-ag-grid-pagination-value="true"
     data-ag-grid-page-size-value="20"
     data-ag-grid-height-value="500px">
  <div data-ag-grid-target="grid"></div>
</div>
```

---

## 4. 다크 테마 구현

AG Grid v33+의 Programmatic Theming API를 사용합니다. CSS 파일을 별도로 임포트할 필요가 없습니다.

```javascript
import { themeQuartz } from "ag-grid-community"

const darkTheme = themeQuartz.withParams({
  // 배경
  backgroundColor:       "#161b22",  // --bg-secondary
  oddRowBackgroundColor:  "#0f1117",  // --bg-primary
  headerBackgroundColor:  "#1c2333",  // --bg-tertiary
  rowHoverColor:          "#21262d",  // --bg-hover

  // 텍스트
  foregroundColor:        "#e6edf3",  // --text-primary
  headerTextColor:        "#8b949e",  // --text-secondary

  // 테두리
  borderColor:            "#30363d",  // --border

  // 강조
  accentColor:            "#58a6ff",  // --accent

  // 타이포그래피
  fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif',
  fontSize:               13,
  headerFontSize:         12,

  // 모서리
  borderRadius:           8,
  wrapperBorderRadius:    8,
})
```

---

## 5. 한국어 Locale 지원

AG Grid 기본 UI 텍스트(필터, 페이지네이션, 정렬 등)를 한국어로 표시합니다.

```javascript
const AG_GRID_LOCALE_KO = {
  // 페이지네이션
  page: "페이지", of: "/", to: "~",
  nextPage: "다음 페이지", lastPage: "마지막 페이지",
  firstPage: "첫 페이지", previousPage: "이전 페이지",
  pageSizeSelectorLabel: "페이지 크기:",

  // 오버레이
  loadingOoo: "로딩 중...", noRowsToShow: "데이터가 없습니다",

  // 필터
  filterOoo: "필터...",
  equals: "같음", notEqual: "같지 않음",
  contains: "포함", notContains: "미포함",
  startsWith: "시작 문자", endsWith: "끝 문자",
  // ... (전체 목록은 Stimulus 컨트롤러 코드 참조)
}
```

`gridOptions.localeText`에 전달하면 AG Grid 전체 UI가 한국어로 표시됩니다.

---

## 6. JSON 응답 패턴

### 기본 패턴 (respond_to 추가)

```ruby
class PostsController < ApplicationController
  def index
    @posts = Post.order(created_at: :desc)

    respond_to do |format|
      format.html
      format.json { render json: @posts }
    end
  end
end
```

### 커스텀 필드 패턴 (as_json 오버라이드)

모델에서 JSON 직렬화를 커스터마이징합니다:

```ruby
class Post < ApplicationRecord
  def as_json(options = {})
    super(options.merge(
      only: [:id, :title, :content, :created_at],
      methods: [:formatted_date]
    ))
  end

  def formatted_date
    created_at.strftime("%Y-%m-%d")
  end
end
```

### Jbuilder 패턴 (복잡한 JSON)

```ruby
# app/views/posts/index.json.jbuilder
json.array! @posts do |post|
  json.extract! post, :id, :title, :content
  json.created_at post.created_at.strftime("%Y-%m-%d %H:%M")
  json.author post.user&.name
end
```

---

## 7. 새 화면에 AG Grid 추가하는 절차

### Step 1: 컨트롤러에 JSON 응답 추가

```ruby
def index
  @items = Item.all
  respond_to do |format|
    format.html
    format.json { render json: @items }
  end
end
```

### Step 2: 뷰에서 헬퍼 호출

```erb
<%= ag_grid_tag(
  columns: [
    { field: "id", headerName: "#", maxWidth: 80 },
    { field: "name", headerName: "이름", flex: 2 },
    { field: "price", headerName: "가격", formatter: "currency" },
    { field: "created_at", headerName: "작성일", formatter: "date" }
  ],
  url: items_path(format: :json),
  height: "calc(100vh - 220px)"
) %>
```

**끝.** 이 두 단계만으로 새 화면에 AG Grid를 추가할 수 있습니다.

---

## 8. 에러 처리

| 시나리오 | 처리 | 사용자 UX |
|---------|------|----------|
| JSON fetch 실패 (네트워크/서버 에러) | 콘솔에 에러 로그 + **에러 오버레이** 표시 | "데이터 로딩 실패 / 네트워크 상태를 확인해주세요" (빨간색) |
| 빈 데이터 (정상 응답, 0건) | **데이터 없음 오버레이** 표시 | "데이터가 없습니다" (회색) |
| 잘못된 컬럼 정의 | AG Grid 내부 에러 (콘솔 경고) | 그리드 렌더링 실패 |
| Turbo 캐시 복귀 | `turbo:before-cache`에서 destroy → connect()에서 재초기화 | 깨끗한 그리드 재생성 |

### 에러 vs 빈 데이터 오버레이 분리

```javascript
// fetch 성공 + 0건
if (data.length === 0) {
  this.gridApi.showNoRowsOverlay()  // "데이터가 없습니다" (기본)
}

// fetch 실패
.catch(error => {
  // 별도 에러 오버레이 템플릿 설정 후 표시
  this.gridApi.setGridOption("overlayNoRowsTemplate",
    '<div style="color:#f85149;font-weight:600;">데이터 로딩 실패</div>' +
    '<div style="color:#8b949e;font-size:12px;">네트워크 상태를 확인해주세요</div>'
  )
  this.gridApi.showNoRowsOverlay()
})
```

---

## 9. 운영 안정성 체크리스트

### CDN 버전 고정

```ruby
# importmap.rb — 반드시 @버전 명시
pin "ag-grid-community",
    to: "https://cdn.jsdelivr.net/npm/ag-grid-community@35.1.0/dist/ag-grid-community.auto.esm.min.js"
```

**업그레이드 절차:**
1. 개발 환경에서 새 버전으로 핀 변경
2. 전체 테스트 통과 확인
3. 시스템 테스트에서 그리드 렌더링 확인
4. 커밋 후 배포

### CSP 설정

CSP 활성화 시 `config/initializers/content_security_policy.rb`에서:

```ruby
policy.script_src :self, :https, "https://cdn.jsdelivr.net"
```

### Turbo 캐시

`turbo:before-cache` 이벤트에서 `gridApi.destroy()` + `innerHTML = ""` 필수.

### columnDefs 화이트리스트

Helper에서 `ALLOWED_COLUMN_KEYS` 화이트리스트로 검증. 허용되지 않은 키 자동 제거 + 로그 경고.

### CDN 장애 대비

1차 대응: CSS `:empty::after` 폴백으로 "그리드를 불러오는 중..." 안내.
향후 강화: `vendor/javascript/`에 로컬 파일 호스팅 또는 에러 모니터링(Sentry) 추가.

---

## 10. 성능 고려사항

| 항목 | 전략 |
|------|------|
| 초기 로딩 | CDN + 브라우저 캐시 (jsDelivr는 영구 캐시 지원, 버전 고정으로 캐시 효율 극대화) |
| 대량 데이터 | AG Grid의 가상화 렌더링 (DOM에 보이는 행만 렌더) |
| 번들 크기 | ~300KB (gzip ~90KB) — auto.esm 단일 파일 |
| Turbo 호환 | connect/disconnect + turbo:before-cache 라이프사이클로 메모리 누수 방지 |
| 데이터 볼륨 | 10,000행 클라이언트사이드 / 50,000행 초과 시 서버사이드 전환 |
