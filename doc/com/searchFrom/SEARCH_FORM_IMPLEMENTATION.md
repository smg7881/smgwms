# SearchForm 선언적 검색 폼 시스템 — 구현 문서

## 개요

`search_form_tag` 헬퍼 한 줄로 검색 폼을 자동 생성하는 선언적 시스템.
기존 `AgGridHelper` / `ag_grid_controller.js` 패턴을 답습하여 **Rails Helper + Stimulus + ERB Partial + CSS Grid** 조합으로 구현.

```erb
<%= search_form_tag(
  url: posts_path,
  fields: [
    { field: "title", type: "input", label: "제목", placeholder: "제목 검색..." },
    { field: "status", type: "select", label: "상태",
      options: [
        { label: "전체", value: "" },
        { label: "게시됨", value: "published" },
        { label: "임시저장", value: "draft" }
      ],
      include_blank: false
    },
    { field: "created_at", type: "date_range", label: "작성일" }
  ],
  cols: 3,
  enable_collapse: true
) %>
```

---

## 아키텍처

```
┌─────────────────────────────────────────────────────────┐
│  뷰 (ERB)                                                │
│  search_form_tag(fields: [...], url: ..., cols: 3)       │
└──────────────┬──────────────────────────────────────────┘
               │ render partial
               ▼
┌─────────────────────────────────────────────────────────┐
│  SearchFormHelper (Ruby)                                  │
│  - sanitize_field_defs (화이트리스트 필터링)                │
│  - validate_field_name! (정규식 검증)                      │
│  - normalize_field_type (하이픈→언더스코어)                 │
│  - resolve_label / resolve_placeholder (i18n)             │
│  - span_classes_for (cols → CSS 클래스 변환)               │
│  - q_params / q_value (params 접근)                       │
└──────────────┬──────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────┐
│  ERB Partials                                             │
│  _form.html.erb → sf-wrapper + sf-grid + form_with        │
│    ├─ fields/_input.html.erb                              │
│    ├─ fields/_select.html.erb                             │
│    ├─ fields/_date_picker.html.erb                        │
│    ├─ fields/_date_range.html.erb                         │
│    └─ _buttons.html.erb                                   │
└──────────────┬──────────────────────────────────────────┘
               │ data-controller="search-form"
               ▼
┌─────────────────────────────────────────────────────────┐
│  search_form_controller.js (Stimulus)                     │
│  - search()  → checkValidity + requestSubmit               │
│  - reset()   → form.reset + Turbo.visit(baseUrl)           │
│  - toggleCollapse() → collapsedValue 토글                  │
│  - #applyCollapse() → getComputedStyle span 기반 hidden    │
│  - #updateButtonSpan() → 남은 공간에 버튼 배치             │
│  - ResizeObserver → 브레이크포인트 변경 시 재계산           │
└─────────────────────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────┐
│  search_form.css                                          │
│  - 24컬럼 CSS Grid (.sf-grid)                             │
│  - 반응형 span 유틸리티 (sm/md/lg 브레이크포인트)          │
│  - 다크 테마 (CSS 변수 재사용)                             │
└─────────────────────────────────────────────────────────┘
```

---

## 파일 구성

| 파일 | 역할 |
|------|------|
| `app/helpers/search_form_helper.rb` | 헬퍼 메서드 — 필드 검증, sanitize, i18n, span 변환 |
| `app/javascript/controllers/search_form_controller.js` | Stimulus 컨트롤러 — 검색, 초기화, 접기/펼치기, ResizeObserver |
| `app/assets/stylesheets/search_form.css` | CSS — 24컬럼 Grid, 반응형 span, 다크 테마 스타일 |
| `app/views/shared/search_form/_form.html.erb` | 메인 래퍼 partial (sf-wrapper + form_with) |
| `app/views/shared/search_form/_buttons.html.erb` | 버튼 그룹 (초기화, 검색, 접기/펼치기) |
| `app/views/shared/search_form/fields/_input.html.erb` | 텍스트 입력 필드 |
| `app/views/shared/search_form/fields/_select.html.erb` | 드롭다운 선택 필드 |
| `app/views/shared/search_form/fields/_date_picker.html.erb` | 단일 날짜/일시 선택 필드 |
| `app/views/shared/search_form/fields/_date_range.html.erb` | 날짜 범위 (from ~ to) 필드 |
| `app/views/layouts/application.html.erb` | `stylesheet_link_tag "search_form"` 추가 |
| `test/helpers/search_form_helper_test.rb` | 헬퍼 유닛 테스트 (5개) |

---

## 상세 구현

### 1. SearchFormHelper (`app/helpers/search_form_helper.rb`)

#### 메인 메서드: `search_form_tag`

```ruby
def search_form_tag(fields:, url:, turbo_frame: "main-content",
                    cols: 3, enable_collapse: true, collapsed_rows: 1,
                    show_buttons: true, **html_options)
```

| 파라미터 | 타입 | 기본값 | 설명 |
|----------|------|--------|------|
| `fields` | `Array<Hash>` | (필수) | 필드 정의 배열 |
| `url` | `String` | (필수) | 폼 action URL |
| `turbo_frame` | `String` | `"main-content"` | Turbo Frame ID |
| `cols` | `Integer` | `3` | 그리드 논리 컬럼 수 |
| `enable_collapse` | `Boolean` | `true` | 접기/펼치기 활성화 |
| `collapsed_rows` | `Integer` | `1` | 접힌 상태 보이는 행 수 |
| `show_buttons` | `Boolean` | `true` | 버튼 표시 여부 |
| `html_options` | `Hash` | `{}` | 래퍼에 추가할 HTML 속성 |

#### 필드 정의 키 (ALLOWED_FIELD_KEYS)

```ruby
ALLOWED_FIELD_KEYS = %i[
  field type label label_key placeholder placeholder_key
  span options required clearable disabled
  pattern minlength maxlength inputmode autocomplete
  date_type date_format min max
  popup_type code_field
  include_blank help
].freeze
```

허용되지 않은 키는 자동 제거되며 경고 로그를 남깁니다.

#### 보안 검증

- **필드 이름 검증**: `/\A[a-zA-Z0-9_]+\z/` 정규식으로 검증, 실패 시 `ArgumentError`
- **타입 정규화**: 하이픈을 언더스코어로 변환 (`date-picker` → `date_picker`)
- **popup 타입 검증**: `code_field`가 반드시 필요, 없으면 `ArgumentError`

#### i18n 우선순위

- **label**: `label` > `label_key`(I18n.t) > `field.humanize`
- **placeholder**: `placeholder` > `placeholder_key`(I18n.t) > `nil`

#### span → CSS 클래스 변환

```ruby
# 기본값 (cols 기반)
cols: 2 → "sf-span-24 sf-span-sm-12"
cols: 3 → "sf-span-24 sf-span-sm-12 sf-span-md-8"
cols: 4 → "sf-span-24 sf-span-sm-12 sf-span-md-6"

# 커스텀 span 문자열
span: "24 s:12 m:8 l:6" → "sf-span-24 sf-span-sm-12 sf-span-md-8 sf-span-lg-6"
```

#### params 접근 헬퍼

```ruby
q_params          # → params.fetch(:q, {}) 전체 반환
q_value("title")  # → params[:q][:title] 반환
```

---

### 2. ERB Partials

#### `_form.html.erb` — 메인 래퍼

```
sf-wrapper (data-controller="search-form")
  └─ form_with (method: :get, data-turbo-frame)
       └─ sf-grid (24컬럼 CSS Grid)
            ├─ fields (타입별 partial 렌더링)
            └─ _buttons (검색/초기화/접기펼치기)
```

- `form_with`를 사용하여 Rails CSRF 토큰 자동 포함
- `novalidate: true`로 브라우저 기본 검증 비활성화 (Stimulus에서 제어)
- `submit->search-form#search` 액션으로 폼 제출 이벤트 처리

#### `fields/_input.html.erb` — 텍스트 입력

- `name="q[field_name]"` 형식의 파라미터 이름
- `q_value(field[:field])`로 현재 검색 값 복원
- HTML5 검증 속성: `required`, `pattern`, `minlength`, `maxlength`

#### `fields/_select.html.erb` — 드롭다운 선택

- options 3가지 형식 지원:
  - **Hash**: `{ label: "표시명", value: "값" }`
  - **Array**: `["표시명", "값"]`
  - **String**: `"값"` (label과 value 동일)
- `include_blank: false`로 자동 빈 옵션 제외
- `selected` 속성으로 현재 값 복원

#### `fields/_date_picker.html.erb` — 단일 날짜

- `date_type: "datetime"` → `<input type="datetime-local">`
- `date_type` 미지정 → `<input type="date">`
- `min`, `max` 속성 지원

#### `fields/_date_range.html.erb` — 날짜 범위

- 두 개의 `<input type="date">` + `~` 구분자
- 파라미터 이름: `q[field_from]`, `q[field_to]`

#### `_buttons.html.erb` — 버튼 그룹

| 버튼 | 액션 | 설명 |
|------|------|------|
| 초기화 | `search-form#reset` | 폼 초기화 + URL 쿼리 제거 |
| 검색 | `submit` (type=submit) | HTML5 검증 후 폼 제출 |
| 펼치기/접기 | `search-form#toggleCollapse` | 접기/펼치기 토글 |

---

### 3. Stimulus 컨트롤러 (`search_form_controller.js`)

#### Targets

| Target | 설명 |
|--------|------|
| `form` | `<form>` 요소 |
| `fieldGroup` | 각 필드 래퍼 (`.sf-field`) |
| `collapseBtn` | 접기/펼치기 버튼 |
| `collapseBtnText` | 버튼 텍스트 ("펼치기" / "접기") |
| `collapseBtnIcon` | 버튼 아이콘 ("▼" / "▲") |
| `buttonGroup` | 버튼 그룹 래퍼 |

#### Values

| Value | 타입 | 기본값 | 설명 |
|-------|------|--------|------|
| `collapsed` | Boolean | `true` | 현재 접힘 상태 |
| `loading` | Boolean | `false` | 로딩 상태 |
| `collapsedRows` | Number | `1` | 접힌 상태에서 보이는 행 수 |
| `cols` | Number | `3` | 논리 컬럼 수 |
| `enableCollapse` | Boolean | `true` | 접기/펼치기 활성화 여부 |

#### 핵심 동작

**검색 (`search`)**
1. `event.preventDefault()` — 기본 폼 제출 방지
2. `formTarget.checkValidity()` — HTML5 유효성 검사
3. 유효하면 `formTarget.requestSubmit()` — Turbo Frame으로 폼 제출

**초기화 (`reset`)**
1. `formTarget.reset()` — 모든 입력값 초기화
2. URL에서 쿼리 파라미터 제거
3. `Turbo.visit(baseUrl, { frame: turboFrame })` — 결과 새로고침

**접기/펼치기 (`toggleCollapse` → `collapsedValueChanged`)**
1. `collapsedValue` 토글
2. 접힘 시: `#applyCollapse()` — `getComputedStyle`로 실제 span 읽어 누적, `collapsedRows * 24` 초과 시 `hidden`
3. 펼침 시: `#showAllFields()` — 모든 `hidden` 해제
4. `#updateButtonSpan()` — 버튼 그룹이 남은 공간을 차지하도록 `grid-column` 동적 계산
5. `#updateCollapseButton()` — 버튼 텍스트/아이콘/aria-expanded 업데이트

**ResizeObserver**
- `connect()`에서 등록, `disconnect()`에서 해제
- 브레이크포인트 변경 시 collapse 상태 재계산

---

### 4. CSS (`search_form.css`)

#### 24컬럼 CSS Grid 시스템

```css
.sf-grid {
  display: grid;
  grid-template-columns: repeat(24, 1fr);
  gap: 16px;
  align-items: end;
}
```

#### 반응형 브레이크포인트

| 브레이크포인트 | 접두사 | 최소 너비 |
|---------------|--------|----------|
| 기본 (모바일) | `sf-span-` | 0px |
| sm | `sf-span-sm-` | 640px |
| md | `sf-span-md-` | 768px |
| lg | `sf-span-lg-` | 1024px |

사용 가능한 span 값: `4`, `6`, `8`, `12`, `24`

#### 주요 CSS 클래스

| 클래스 | 설명 |
|--------|------|
| `.sf-wrapper` | 폼 래퍼 (배경, 테두리, 패딩) |
| `.sf-grid` | 24컬럼 그리드 컨테이너 |
| `.sf-field` | 필드 래퍼 (flex-column) |
| `.sf-label` | 라벨 |
| `.sf-control` | 컨트롤 래퍼 (flex) |
| `.sf-input` | 텍스트/날짜 입력 |
| `.sf-select` | 드롭다운 |
| `.sf-date-range` | 날짜 범위 래퍼 |
| `.sf-range-sep` | 범위 구분자 (`~`) |
| `.sf-buttons` | 버튼 그룹 (`grid-column: 1 / -1`) |
| `.sf-divider` | 폼-그리드 구분선 |

#### 다크 테마

`application.css`의 CSS 변수를 fallback 값과 함께 재사용:

```css
background-color: var(--bg-primary, #0f1117);
color: var(--text-primary, #e6edf3);
border: 1px solid var(--border, #30363d);
```

날짜 입력의 `color-scheme: dark` + 커스텀 캘린더 아이콘 SVG 적용.

---

### 5. 컨트롤러 수정 (`PostsController`)

```ruby
def index
  @posts = Post.order(created_at: :desc)
  @posts = @posts.where("title LIKE ?", "%#{search_params[:title]}%") if search_params[:title].present?
  @posts = @posts.where(status: search_params[:status]) if search_params[:status].present?
  @posts = @posts.where("created_at >= ?", search_params[:created_at_from]) if search_params[:created_at_from].present?
  @posts = @posts.where("created_at <= ?", "#{search_params[:created_at_to]} 23:59:59") if search_params[:created_at_to].present?
  # ...
end

private
  def search_params
    params.fetch(:q, {}).permit(:title, :status, :created_at_from, :created_at_to)
  end
```

- `search_params`로 `q` 네임스페이스 파라미터를 strong parameters로 허용
- 각 조건은 `present?` 체크 후 체이닝
- `date_range`의 `_to`는 `23:59:59`를 붙여 해당 날짜 끝까지 포함

---

### 6. 뷰 적용 (`posts/index.html.erb`)

```erb
<%= search_form_tag(
  url: posts_path,
  fields: [
    { field: "title", type: "input", label: "제목", placeholder: "제목 검색..." },
    { field: "status", type: "select", label: "상태",
      options: [
        { label: "전체", value: "" },
        { label: "게시됨", value: "published" },
        { label: "임시저장", value: "draft" }
      ],
      include_blank: false
    },
    { field: "created_at", type: "date_range", label: "작성일" }
  ],
  cols: 3,
  enable_collapse: true
) %>
```

AG Grid 높이를 `calc(100vh - 320px)`로 조정하여 검색 폼 영역을 반영.

---

## 테스트

```bash
bin/rails test test/helpers/search_form_helper_test.rb
```

| 테스트 | 검증 항목 |
|--------|----------|
| `sanitize_field_defs removes disallowed keys` | 화이트리스트 외 키 제거 |
| `sanitize_field_defs normalizes type` | `date-picker` → `date_picker` 변환 |
| `span_classes_for handles different formats` | 문자열 span 파싱 + cols 기본값 |
| `resolve_label prioritizes label > label_key > humanized field` | i18n 우선순위 |
| `sanitize_field_defs validates code_field for popup type` | popup 필드 code_field 필수 검증 |

---

## 사용 가이드

### 새 페이지에 검색 폼 추가하기

**1단계: 컨트롤러에 검색 로직 추가**

```ruby
def index
  @items = Item.order(created_at: :desc)
  @items = @items.where("name LIKE ?", "%#{search_params[:name]}%") if search_params[:name].present?

  respond_to do |format|
    format.html
    format.json { render json: @items }
  end
end

private
  def search_params
    params.fetch(:q, {}).permit(:name, :category, :date_from, :date_to)
  end
```

**2단계: 뷰에 search_form_tag 추가**

```erb
<%= search_form_tag(
  url: items_path,
  fields: [
    { field: "name", type: "input", label: "이름" },
    { field: "category", type: "select", label: "카테고리",
      options: [["전자", "electronics"], ["의류", "clothing"]] },
    { field: "date", type: "date_range", label: "기간" }
  ]
) %>
```

### 필드 타입별 옵션

#### input

```ruby
{ field: "name", type: "input", label: "이름",
  placeholder: "검색어 입력",
  required: true,
  pattern: "[A-Za-z]+",
  minlength: 2,
  maxlength: 50 }
```

#### select

```ruby
# Hash 형식
{ field: "status", type: "select", label: "상태",
  options: [
    { label: "전체", value: "" },
    { label: "활성", value: "active" }
  ],
  include_blank: false }

# Array 형식
{ field: "status", type: "select", label: "상태",
  options: [["활성", "active"], ["비활성", "inactive"]] }
```

#### date_picker

```ruby
{ field: "birth_date", type: "date_picker", label: "생년월일",
  min: "1900-01-01", max: "2025-12-31" }

# datetime 타입
{ field: "event_time", type: "date_picker", label: "이벤트 일시",
  date_type: "datetime" }
```

#### date_range

```ruby
{ field: "created_at", type: "date_range", label: "기간" }
# → q[created_at_from], q[created_at_to] 파라미터 생성
```

### 커스텀 span (반응형 레이아웃)

```ruby
# 기본: cols 값에 따라 자동 결정
cols: 3  # → 모바일 24, sm 12, md 8

# 커스텀: 필드별 span 문자열
{ field: "name", type: "input", span: "24 s:12 m:6 l:4" }
# → 모바일 풀폭, sm 반폭, md 1/4, lg 1/6
```

---

## Phase 구현 현황

| Phase | 내용 | 상태 |
|-------|------|------|
| Phase 1 | input, select 필드 + 핵심 구조 | 완료 |
| Phase 2 | date_picker, date_range + 반응형 + 접기/펼치기 | 완료 |
| Phase 3 | popup 필드 (코드 검색 팝업) | 미구현 (CSS만 준비) |

---

## 재사용한 기존 코드

| 기존 코드 | 재사용 방식 |
|-----------|------------|
| `AgGridHelper` | ALLOWED_KEYS 화이트리스트, sanitize, partial 렌더링 패턴 |
| `ag_grid_controller.js` | static targets/values, connect/disconnect, #private 메서드 패턴 |
| `application.css` CSS 변수 | `--bg-*`, `--text-*`, `--border`, `--accent` 전체 재사용 |
| `.btn`, `.btn-primary`, `.btn-secondary` | 버튼 클래스 그대로 사용 |
| `.form-control` 스타일 | `.sf-input`, `.sf-select`에 동일 패턴 적용 |
