# SearchForm PRD — 선언적 검색 폼 시스템

## 1. 개요

### 1.1 목적

Rails 8.1 Hotwire/Stimulus 기반의 **선언적 검색 폼 시스템**을 구축한다. Ruby Hash 배열로 필드를 정의하면 검색 폼 UI가 자동 생성되며, Turbo Frame을 통해 AG Grid와 연동된다.

### 1.2 배경

기존 Vue 3 `EnhancedSearch` 컴포넌트는 `SearchFieldDef[]` 배열만 전달하면 5가지 필드 타입(input, select, date-picker, date-range, popup)의 검색 폼을 자동 생성한다. 이 선언적 패턴을 Rails Helper + Stimulus 컨트롤러 + ERB partial 조합으로 마이그레이션하여, 기존 `ag_grid_helper.rb` / `ag_grid_controller.js` 패턴과 일관된 아키텍처를 유지한다.

### 1.3 핵심 원칙

- **선언적 API**: 뷰에서 `search_form_tag(fields: [...])` 한 줄로 검색 폼 생성
- **서버 중심**: 필드 정의, 유효성 검사, i18n은 서버(Ruby)에서 처리
- **Stimulus 최소 역할**: 접기/펼치기, 로딩 상태 등 클라이언트 상호작용만 담당
- **기존 패턴 답습**: `AgGridHelper` / `ag_grid_controller.js`의 구조를 그대로 따름

---

## 2. 원본 분석 — Vue EnhancedSearch 아키텍처

### 2.1 SearchFieldDef 타입 구조

```typescript
interface SearchFieldDef {
  field: string;              // 폼 필드명 (name 속성)
  type: SearchFieldType;      // 'input' | 'select' | 'date-picker' | 'date-range' | 'popup'
  label?: string;             // 직접 레이블 텍스트
  labelKey?: string;          // i18n 키
  placeholder?: string;       // 직접 플레이스홀더
  placeholderKey?: string;    // i18n 플레이스홀더 키
  span?: string | number;     // 개별 그리드 span (기본: defaultSpan)
  options?: Option[];         // select 타입 옵션 목록
  rules?: FormRule[];         // 유효성 검사 규칙
  required?: boolean;         // 필수 입력 여부
  clearable?: boolean;        // 지우기 버튼 (기본: true)
  disabled?: boolean;         // 비활성화
  dateType?: string;          // date-picker 세부 타입
  dateFormat?: string;        // 날짜 포맷
  popupType?: string;         // popup 프리셋 키
  codeField?: string;         // popup 코드 바인딩 필드
  componentProps?: Record;    // 컴포넌트 직접 전달 Props
}
```

### 2.2 5가지 필드 타입

| 타입 | Vue 컴포넌트 | 설명 |
|------|-------------|------|
| `input` | `<NInput>` | 텍스트 입력 |
| `select` | `<NSelect>` | 드롭다운 선택 |
| `date-picker` | `<NDatePicker>` | 단일 날짜 선택 |
| `date-range` | `<NDatePicker type="daterange">` | 날짜 범위 선택 |
| `popup` | `<SearchPopupInput>` | 팝업 검색 (코드+명칭 이중 바인딩) |

### 2.3 Composable 로직 (`useEnhancedSearchForm`)

- **rules**: `required: true` 필드에 자동으로 필수 입력 규칙 추가, 기존 `rules` 배열과 병합
- **validate()**: 검증 가능한 필드가 있을 때만 폼 검증 수행 (성능 최적화)
- **reset()**: 모든 필드를 `null`로 초기화 + 검증 상태 복원

### 2.4 접기/펼치기 로직

- 전체 필드의 span 합계가 24 초과 시 접기 기능 활성화
- 접힌 상태: `collapsedRows * 2`개 필드만 표시 (기본 1행 = 2개)
- 접힌 상태 span 고정: 필드 6 + 필드 6 + 버튼 12 = 24 (한 줄)
- 펼쳐진 상태: 버튼은 마지막 행 남은 공간을 계산하여 배치

### 2.5 반응형 레이아웃

span 문자열 `"24 s:12 m:6"`을 파싱하여 브레이크포인트별 컬럼 수를 계산:
- 기본(모바일): 24 (1열)
- sm(640px): 12 (2열)
- md(768px): 6 (4열)

---

## 3. 마이그레이션 전략 — Vue → Rails/Hotwire 매핑

### 3.1 개념 매핑 테이블

| Vue 개념 | Rails/Hotwire 대응 | 설명 |
|----------|-------------------|------|
| `SearchFieldDef[]` props | `search_form_tag(fields:)` Helper | Ruby Hash 배열로 필드 정의 |
| `v-model` 양방향 바인딩 | HTML `<form>` + `name` 속성 | `params[:q][:field_name]`으로 서버 전달 |
| `v-if` 타입 분기 렌더링 | ERB partial 분기 (`_field_input.html.erb` 등) | `render partial: "search_form/fields/#{type}"` |
| `computed` 반응형 값 | Stimulus Values API | `collapsedValue`, `loadingValue` 등 |
| `useEnhancedSearchForm` composable | `SearchFormHelper` private 메서드 + Stimulus | 서버: 유효성 규칙 생성, 클라이언트: 상태 토글 |
| `useBreakpoints` 반응형 | CSS Grid + `@media` 쿼리 | 순수 CSS로 반응형 처리 |
| `$t()` i18n | `I18n.t()` / `t()` Rails i18n | `config/locales/` YAML 파일 |
| `emit('search')` | `<form>` submit → Turbo Frame 교체 | 검색 결과를 Turbo Frame으로 갱신 |
| `emit('reset')` | Stimulus `reset` action → 폼 초기화 | `form.reset()` + Turbo Frame 재요청 |
| Naive UI 컴포넌트 | 네이티브 HTML + CSS | `<input>`, `<select>`, `<input type="date">` 등 |

### 3.2 데이터 흐름

```
[뷰] search_form_tag(fields:)
  → SearchFormHelper가 HTML 생성
    → Stimulus search-form controller 바인딩
      → 사용자 입력 → form submit
        → Turbo Frame 요청 (GET /posts?q[title]=...)
          → 컨트롤러에서 params[:q]로 필터링
            → Turbo Frame 응답 (AG Grid 갱신)
```

---

## 4. 컴포넌트 설계

### 4.1 SearchFormHelper (`app/helpers/search_form_helper.rb`)

`AgGridHelper` 패턴을 답습하여 ALLOWED_KEYS 화이트리스트 + `content_tag` 기반 HTML 생성.

#### 허용 키 (ALLOWED_FIELD_KEYS)

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

> **리뷰 반영**: HTML5 검증/입력 UX 속성(`pattern`, `minlength`, `maxlength`, `inputmode`, `autocomplete`),
> 날짜 범위 제한(`min`, `max`), select용 `include_blank`, i18n 키(`label_key`, `placeholder_key`),
> 도움말 텍스트(`help`)를 허용 키에 추가하였다.

#### field 값 검증 (안전장치)

`field` 값은 HTML `name` 속성에 삽입되므로, 반드시 안전한 문자만 허용해야 한다:

```ruby
VALID_FIELD_NAME = /\A[a-zA-Z0-9_]+\z/

def validate_field_name!(name)
  unless name.to_s.match?(VALID_FIELD_NAME)
    raise ArgumentError, "[search_form_helper] 허용되지 않은 field 이름: #{name.inspect}"
  end
end
```

#### type 정규화 (normalize)

Vue 원본의 타입(`date-picker`, `date-range`)은 하이픈을 포함하지만, Rails partial 파일명은 언더스코어를 사용한다.
Helper 내부에서 **무조건 정규화**하여 partial lookup 실패를 방지한다:

```ruby
def normalize_field_type(type)
  type.to_s.tr("-", "_")
end
# "date-picker" → "date_picker", "date-range" → "date_range"
```

partial 렌더링: `render partial: "shared/search_form/fields/#{normalize_field_type(field[:type])}"`

#### 주요 메서드 시그니처

```ruby
# 검색 폼 생성 헬퍼
def search_form_tag(
  fields:,                    # Array<Hash> 필드 정의 (필수)
  url:,                       # String 검색 요청 URL (필수)
  turbo_frame: "main-content", # Turbo Frame 타겟
  cols: 3,                    # 기본 컬럼 수
  enable_collapse: true,      # 접기/펼치기 활성화
  collapsed_rows: 1,          # 접힌 상태 행 수
  show_buttons: true,         # 버튼 표시 여부
  **html_options
)
```

#### params 접근 헬퍼 (키 타입 안전)

Rails `params` 내부 키는 문자열(String)로 들어오므로, `dig`에 심볼을 전달하면 값을 찾지 못한다.
Helper에 아래 유틸 메서드를 두고, 모든 ERB partial에서 통일하여 사용한다:

```ruby
# 검색 쿼리 파라미터 전체를 Hash로 반환 (화면 표시용)
def q_params
  params.fetch(:q, {}).to_unsafe_h
end

# 개별 검색 파라미터 값 조회 (키 타입 자동 변환)
def q_value(name)
  q_params[name.to_s]
end
```

ERB에서는 `value="<%= q_value(field[:field]) %>"`처럼 통일한다.

#### Helper 역할

- 필드 정의 sanitize (허용되지 않은 키 제거 + 경고 로그)
- `field` 값 검증 (`VALID_FIELD_NAME` 패턴)
- `type` 정규화 (하이픈 → 언더스코어)
- Stimulus data 속성 생성 (`data-search-form-*-value`)
- 필드별 ERB partial 렌더링 위임
- 검색/초기화/접기 버튼 그룹 생성
- i18n 해석: `label` → `label_key` → `human_attribute_name` 우선순위 폴백

### 4.2 Stimulus 컨트롤러 (`app/javascript/controllers/search_form_controller.js`)

`ag_grid_controller.js` 패턴을 따르는 Stimulus 컨트롤러.

#### Targets

```javascript
static targets = [
  "form",          // <form> 요소
  "fieldGroup",    // 각 필드 래퍼 (visibility 제어용)
  "collapseBtn",   // 접기/펼치기 버튼
  "collapseBtnText", // 버튼 텍스트
  "collapseBtnIcon", // 버튼 아이콘
  "searchBtn",     // 검색 버튼
  "resetBtn"       // 초기화 버튼
]
```

#### Values

```javascript
static values = {
  collapsed: { type: Boolean, default: true },   // 접힘 상태
  loading: { type: Boolean, default: false },     // 검색 로딩
  collapsedRows: { type: Number, default: 1 },   // 접힌 상태 행 수
  cols: { type: Number, default: 3 },             // 컬럼 수
  enableCollapse: { type: Boolean, default: true } // 접기 기능
}
```

#### Actions

| Action | 트리거 | 설명 |
|--------|--------|------|
| `search` | 검색 버튼 클릭 / Enter | HTML5 유효성 검사 후 form submit (Turbo Frame) |
| `reset` | 초기화 버튼 클릭 | `form.reset()` + 빈 파라미터로 재요청 |
| `toggleCollapse` | 접기/펼치기 버튼 클릭 | `collapsedValue` 토글 → 필드 visibility 갱신 |

#### 접기/펼치기 구현 방식

> **주의**: `data-search-form-span`에 정적 숫자를 기록하는 방식은 반응형 레이아웃에서 문제가 된다.
> CSS 미디어쿼리에 의해 실제 적용되는 span이 달라지므로, **Computed Style 기반으로 실제 span을 계산**해야 한다.

1. 각 `fieldGroup` target의 **`getComputedStyle(el).gridColumn`** 에서 실제 span 값을 추출한다:
   ```javascript
   #spanOf(el) {
     const v = getComputedStyle(el).gridColumnEnd  // e.g. "span 6"
     const m = String(v).match(/span\s+(\d+)/)
     return m ? parseInt(m[1], 10) : 24
   }
   ```
2. `collapsedValueChanged()` 실행 시:
   - 접힌 상태(`collapsed === true`): `#spanOf(el)`을 누적하며 `collapsedRows * 24`를 초과하는 필드는 `hidden` 속성 추가
   - 펼쳐진 상태(`collapsed === false`): 모든 필드의 `hidden` 속성 제거
3. `window.resize` 이벤트(또는 `ResizeObserver`) 시 재계산하여 브레이크포인트 변경에 대응
4. 버튼 텍스트: "펼치기" ↔ "접기" 토글
5. 버튼 아이콘: `▼` ↔ `▲` 토글
6. 접기/펼치기 버튼에 `aria-expanded="true|false"` 속성을 항상 설정 (Phase 1부터 적용)

### 4.3 필드 타입별 ERB Partial (5개)

공통 경로: `app/views/shared/search_form/fields/`

| Partial | 대응 타입 |
|---------|----------|
| `_input.html.erb` | `input` |
| `_select.html.erb` | `select` |
| `_date_picker.html.erb` | `date_picker` |
| `_date_range.html.erb` | `date_range` |
| `_popup.html.erb` | `popup` |

### 4.4 CSS (`app/assets/stylesheets/search_form.css`)

기존 `application.css`의 CSS 변수 체계(`--bg-*`, `--text-*`, `--border`, `--accent`)를 재사용하여 다크 테마 일관성 유지.

---

## 5. 필드 타입별 상세 매핑

### 5.1 Input 필드

**Vue 원본**:
```html
<NInput v-model:value="model[field.field]" :placeholder="..." :disabled="..." :clearable="..." />
```

**Rails ERB 구조**:
```erb
<%# app/views/shared/search_form/fields/_input.html.erb %>
<%# 주의: q_value() 헬퍼로 params 접근을 통일하여 키 타입(String/Symbol) 불일치를 방지 %>
<% field_id = "q_#{field[:field]}" %>
<div class="sf-field" data-search-form-target="fieldGroup">
  <label class="sf-label" for="<%= field_id %>"><%= resolve_label(field) %></label>
  <div class="sf-control">
    <input type="text"
           id="<%= field_id %>"
           name="q[<%= field[:field] %>]"
           placeholder="<%= resolve_placeholder(field) %>"
           value="<%= q_value(field[:field]) %>"
           class="sf-input"
           <%= "disabled" if field[:disabled] %>
           <%= "required" if field[:required] %>
           <%= "pattern=#{field[:pattern]}" if field[:pattern] %>
           <%= "minlength=#{field[:minlength]}" if field[:minlength] %>
           <%= "maxlength=#{field[:maxlength]}" if field[:maxlength] %>>
  </div>
</div>
```

> **리뷰 반영**: (1) `params.dig(:q, field[:field])` → `q_value(field[:field])` 통일,
> (2) `label` → `resolve_label(field)` i18n 폴백 적용,
> (3) `<label for>` + `<input id>` 연결로 접근성 확보,
> (4) `pattern`/`minlength`/`maxlength` HTML5 검증 속성 지원

### 5.2 Select 필드

**Vue 원본**:
```html
<NSelect v-model:value="model[field.field]" :options="field.options" :clearable="..." />
```

**Rails ERB 구조**:
```erb
<%# app/views/shared/search_form/fields/_select.html.erb %>
<% field_id = "q_#{field[:field]}" %>
<div class="sf-field" data-search-form-target="fieldGroup">
  <label class="sf-label" for="<%= field_id %>"><%= resolve_label(field) %></label>
  <div class="sf-control">
    <select id="<%= field_id %>" name="q[<%= field[:field] %>]" class="sf-select" <%= "disabled" if field[:disabled] %>>
      <option value=""><%= resolve_placeholder(field) || "선택하세요" %></option>
      <% field[:options]&.each do |opt| %>
        <option value="<%= opt[:value] %>"
                <%= "selected" if q_value(field[:field]) == opt[:value].to_s %>>
          <%= opt[:label] %>
        </option>
      <% end %>
    </select>
  </div>
</div>
```

### 5.3 Date Picker 필드

**Vue 원본**:
```html
<NDatePicker v-model:value="model[field.field]" :type="getDatePickerType(field)" :format="getDateFormat(field)" />
```

**Rails ERB 구조**:
```erb
<%# app/views/shared/search_form/fields/_date_picker.html.erb %>
<% field_id = "q_#{field[:field]}" %>
<div class="sf-field" data-search-form-target="fieldGroup">
  <label class="sf-label" for="<%= field_id %>"><%= resolve_label(field) %></label>
  <div class="sf-control">
    <input type="<%= field[:date_type] == 'datetime' ? 'datetime-local' : 'date' %>"
           id="<%= field_id %>"
           name="q[<%= field[:field] %>]"
           value="<%= q_value(field[:field]) %>"
           class="sf-input sf-date"
           <%= "disabled" if field[:disabled] %>
           <%= "min=#{field[:min]}" if field[:min] %>
           <%= "max=#{field[:max]}" if field[:max] %>>
  </div>
</div>
```

**참고**: 네이티브 `<input type="date">` 사용. 커스텀 데이트 피커가 필요한 경우 Phase 3에서 Stimulus 기반 라이브러리(Flatpickr 등) 통합 검토.

### 5.4 Date Range 필드

**Vue 원본**:
```html
<NDatePicker v-model:value="model[field.field]" type="daterange" />
```

**Rails ERB 구조**:
```erb
<%# app/views/shared/search_form/fields/_date_range.html.erb %>
<% field_id_from = "q_#{field[:field]}_from" %>
<% field_id_to = "q_#{field[:field]}_to" %>
<div class="sf-field" data-search-form-target="fieldGroup">
  <label class="sf-label"><%= resolve_label(field) %></label>
  <div class="sf-control sf-date-range">
    <input type="date"
           id="<%= field_id_from %>"
           name="q[<%= field[:field] %>_from]"
           value="<%= q_value("#{field[:field]}_from") %>"
           class="sf-input sf-date">
    <span class="sf-range-sep">~</span>
    <input type="date"
           id="<%= field_id_to %>"
           name="q[<%= field[:field] %>_to]"
           value="<%= q_value("#{field[:field]}_to") %>"
           class="sf-input sf-date">
  </div>
</div>
```

**참고**: Vue의 단일 `daterange` 컴포넌트 대신, 두 개의 `<input type="date">`로 분리. 서버에서 `_from`, `_to` 접미사로 범위를 처리.

### 5.5 Popup 필드

**Vue 원본**:
```html
<SearchPopupInput v-model:value="model[field.field]" v-model:code="model[field.codeField!]" :type="field.popupType" />
```

**Rails ERB 구조**:
```erb
<%# app/views/shared/search_form/fields/_popup.html.erb %>
<% field_id = "q_#{field[:field]}" %>
<div class="sf-field" data-search-form-target="fieldGroup"
     data-controller="search-popup"
     data-search-popup-type-value="<%= field[:popup_type] %>">
  <label class="sf-label" for="<%= field_id %>"><%= resolve_label(field) %></label>
  <div class="sf-control sf-popup-control">
    <input type="hidden"
           name="q[<%= field[:code_field] %>]"
           value="<%= q_value(field[:code_field]) %>"
           data-search-popup-target="code">
    <input type="text"
           id="<%= field_id %>"
           name="q[<%= field[:field] %>]"
           value="<%= q_value(field[:field]) %>"
           class="sf-input"
           readonly
           data-search-popup-target="display"
           placeholder="<%= resolve_placeholder(field) %>">
    <button type="button" class="sf-popup-btn" data-action="search-popup#open">
      ...
    </button>
  </div>
</div>
```

> **리뷰 반영**: hidden code input에도 `value="<%= q_value(field[:code_field]) %>"`를 추가하여,
> 페이지 새로고침/뒤로가기 시 code 값이 유실되지 않도록 수정.

**참고**: Popup은 별도의 `search_popup_controller.js` Stimulus 컨트롤러로 분리. 모달/다이얼로그 내에서 Turbo Frame으로 검색 결과를 로드하고, 선택 시 code/display 값을 설정. 이 부분은 Phase 3에서 상세 설계.

---

## 6. 반응형 레이아웃

### 6.1 CSS Grid 24컬럼 시스템

Vue의 NGrid `responsive="screen" item-responsive`를 CSS Grid로 대체.

```css
.sf-grid {
  display: grid;
  grid-template-columns: repeat(24, 1fr);
  gap: 0 16px;
  align-items: end;
}

.sf-field {
  /* 기본: 전체 폭 (모바일) */
  grid-column: span 24;
}
```

### 6.2 브레이크포인트 설계

Vue의 `"24 s:12 m:6"` span 문자열을 CSS 클래스로 변환:

| CSS 클래스 | 의미 | 브레이크포인트 |
|-----------|------|-------------|
| `sf-span-24` | 전체 폭 | 기본 (모바일) |
| `sf-span-sm-12` | 1/2 폭 | `@media (min-width: 640px)` |
| `sf-span-md-8` | 1/3 폭 | `@media (min-width: 768px)` |
| `sf-span-md-6` | 1/4 폭 | `@media (min-width: 768px)` |
| `sf-span-lg-6` | 1/4 폭 | `@media (min-width: 1024px)` |

```css
/* 예시: cols: 3 기본 설정 */
@media (min-width: 640px) {
  .sf-span-sm-12 { grid-column: span 12; }
}
@media (min-width: 768px) {
  .sf-span-md-8 { grid-column: span 8; }
  .sf-span-md-6 { grid-column: span 6; }
}
```

### 6.3 Helper에서 span → CSS 클래스 변환

Helper가 필드 정의의 `span` 값(또는 `cols` 기본값)을 CSS 클래스 문자열로 변환:

- `cols: 3` → 각 필드 `sf-span-24 sf-span-sm-12 sf-span-md-8`
- `span: "24 s:12 m:6"` → `sf-span-24 sf-span-sm-12 sf-span-md-6`
- `span: 12` → `sf-span-12` (고정)

---

## 7. 접기/펼치기

### 7.1 동작 방식

Vue의 `isFieldVisible(index)` 로직을 Stimulus `collapsedValueChanged()` 콜백으로 구현.

**알고리즘:**

1. 각 `fieldGroup` target의 **실제 CSS Grid span**을 `getComputedStyle`로 읽어 누적 계산 (4.2절 참조)
2. `collapsedValueChanged()` 실행 시:
   - 접힌 상태(`collapsed === true`): span을 누적하며 `collapsedRows * 24`를 초과하는 필드는 `hidden` 속성 추가
   - 펼쳐진 상태(`collapsed === false`): 모든 필드의 `hidden` 속성 제거
3. `window.resize` / `ResizeObserver` 시 재계산하여 브레이크포인트 변경에 대응
4. 버튼 텍스트: "펼치기" ↔ "접기" 토글 + `aria-expanded` 동기화
5. 버튼 아이콘: `▼` ↔ `▲` 토글

### 7.2 접힌 상태의 버튼 배치

Vue와 동일하게, 접힌 상태에서 버튼 그룹이 필드와 같은 줄에 배치되도록 span 계산:
- 접힌 상태: 보이는 필드 span 합 + 버튼 span = 24
- 펼쳐진 상태: 마지막 행 남은 공간을 계산하여 버튼 span 결정

### 7.3 FOUC 방지 전략

서버는 클라이언트 뷰포트 너비를 모르므로, 완벽한 초기 hidden 설정이 불가능하다.

**권장 접근: 기본 브레이크포인트(md) 기준 서버 프리렌더링 + 연결 후 보정**

1. Helper가 `md`(768px) 기준 span으로 초기 hidden 속성을 설정하여 대부분의 데스크톱 환경에서 FOUC 최소화
2. Stimulus `connect()`에서 실제 뷰포트 기준으로 즉시 재계산하여 보정
3. 모바일에서는 잠시 깜빡임이 있을 수 있으나, `connect()` 직후 보정되므로 체감 영향 최소

---

## 8. 유효성 검사

### 8.1 2계층 검증 구조

| 계층 | 담당 | 방식 |
|------|------|------|
| **클라이언트** | HTML5 + Stimulus | `required` 속성, `pattern` 속성, Stimulus `search` action에서 `form.checkValidity()` |
| **서버** | Rails 컨트롤러 | `params[:q]` 파싱 시 허용된 키만 permit, 모델 수준 범위 검증 |

### 8.2 클라이언트 측 (HTML5 + Stimulus)

- `required: true` → `<input required>` 속성 (브라우저 네이티브 검증)
- Stimulus `search` action에서 `this.formTarget.checkValidity()` 호출
- 실패 시 `this.formTarget.reportValidity()`로 브라우저 네이티브 에러 메시지 표시
- 커스텀 규칙이 필요한 경우 `setCustomValidity()`로 확장

### 8.3 서버 측

- `params.fetch(:q, {}).permit(ALLOWED_SEARCH_FIELDS)` 로 안전한 파라미터 처리
- 날짜 범위의 경우 `_from <= _to` 논리 검증
- 잘못된 파라미터는 무시(에러 대신 빈 검색 수행)

### 8.4 Vue `useEnhancedSearchForm` 매핑

| Vue 기능 | Rails 대응 |
|----------|-----------|
| `required: true` → 자동 필수 규칙 | `required: true` → HTML `required` 속성 |
| `field.rules[]` → Naive UI validate | HTML5 `pattern`, `minlength`, `maxlength` 속성 |
| `validate()` → 검증 가능한 필드만 | `form.checkValidity()` (Stimulus) |
| `reset()` → null 초기화 + 검증 상태 복원 | `form.reset()` (Stimulus) |

---

## 9. 사용 예시

### 9.1 `posts/index.html.erb`에서의 호출

```erb
<%= turbo_frame_tag "main-content" do %>
  <div class="page-header">
    <h2>게시물 목록</h2>
    <div class="page-actions">
      <%= link_to "새 게시물", new_post_path, class: "btn btn-primary" %>
    </div>
  </div>

  <%# 검색 폼 %>
  <%= search_form_tag(
    url: posts_path,
    fields: [
      { field: "title", type: "input", label: "제목", placeholder: "제목 검색..." },
      { field: "status", type: "select", label: "상태",
        options: [
          { label: "전체", value: "" },
          { label: "게시됨", value: "published" },
          { label: "임시저장", value: "draft" }
        ] },
      { field: "created_at", type: "date_range", label: "작성일" }
    ],
    cols: 3,
    enable_collapse: true
  ) %>

  <%# AG Grid %>
  <%= ag_grid_tag(
    columns: [
      { field: "id", headerName: "#", maxWidth: 80, filter: false },
      { field: "title", headerName: "제목", flex: 2,
        cellRenderer: "link", cellRendererParams: { path: "/posts/${id}" } },
      { field: "content", headerName: "내용" },
      { field: "created_at", headerName: "작성일", maxWidth: 160, formatter: "date" }
    ],
    url: posts_path(format: :json),
    height: "calc(100vh - 320px)",
    page_size: 20
  ) %>
<% end %>
```

### 9.2 컨트롤러에서 검색 파라미터 처리

```ruby
# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  def index
    @posts = Post.all
    @posts = @posts.where("title LIKE ?", "%#{search_params[:title]}%") if search_params[:title].present?
    @posts = @posts.where(status: search_params[:status]) if search_params[:status].present?
    # date_range 처리
    if search_params[:created_at_from].present?
      @posts = @posts.where("created_at >= ?", search_params[:created_at_from])
    end
    if search_params[:created_at_to].present?
      @posts = @posts.where("created_at <= ?", search_params[:created_at_to])
    end

    respond_to do |format|
      format.html
      format.json { render json: @posts }
    end
  end

  private
    def search_params
      params.fetch(:q, {}).permit(:title, :status, :created_at_from, :created_at_to)
    end
end
```

### 9.3 Turbo Frame 연동 흐름

1. 검색 버튼 클릭 → `<form>` GET submit → `/posts?q[title]=foo&q[status]=published`
2. Turbo Frame(`main-content`)이 응답을 감지하여 페이지 부분 교체
3. AG Grid의 `url` 파라미터에 검색 쿼리가 포함되어 데이터 재로드
4. 초기화 버튼 → `form.reset()` + **URL 쿼리 파라미터 제거 후** 재요청

### 9.4 Reset 동작 상세

> **주의**: 단순 `form.reset()`만으로는 URL에 `?q[...]`가 남아 화면/데이터 불일치가 발생할 수 있다.
> Turbo 캐시로 인해 기대와 다른 화면이 남는 문제도 있다.

**권장 구현:**

```javascript
// search_form_controller.js
reset(event) {
  event.preventDefault()
  this.formTarget.reset()

  // URL 쿼리 파라미터를 제거하고 기본 URL로 Turbo 네비게이션
  const baseUrl = this.formTarget.action.split("?")[0]
  Turbo.visit(baseUrl, { frame: this.formTarget.dataset.turboFrame })
}
```

이렇게 하면:
- 폼 UI가 초기화되고
- URL에서 `?q[...]` 쿼리가 제거되며
- Turbo Frame이 빈 검색 결과로 갱신된다

---

## 10. 파일 구조

### 10.1 신규 파일

```
app/
├── helpers/
│   └── search_form_helper.rb              # 검색 폼 생성 헬퍼
├── javascript/
│   └── controllers/
│       ├── search_form_controller.js      # 검색 폼 Stimulus 컨트롤러
│       └── search_popup_controller.js     # 팝업 검색 Stimulus 컨트롤러 (Phase 3)
├── views/
│   └── shared/
│       └── search_form/
│           ├── _form.html.erb             # 메인 폼 래퍼 partial
│           ├── _buttons.html.erb          # 버튼 그룹 partial
│           └── fields/
│               ├── _input.html.erb        # 텍스트 입력 필드
│               ├── _select.html.erb       # 드롭다운 선택 필드
│               ├── _date_picker.html.erb  # 단일 날짜 선택 필드
│               ├── _date_range.html.erb   # 날짜 범위 선택 필드
│               └── _popup.html.erb        # 팝업 검색 필드 (Phase 3)
└── assets/
    └── stylesheets/
        └── search_form.css                # 검색 폼 전용 CSS
```

### 10.2 수정 파일

```
app/
├── assets/
│   └── stylesheets/
│       └── application.css                # search_form.css import 추가
├── views/
│   └── posts/
│       └── index.html.erb                 # search_form_tag 호출 추가
└── controllers/
    └── posts_controller.rb                # 검색 파라미터 처리 추가
```

---

## 11. 구현 우선순위

### Phase 1 — 핵심 기반 (input + select)

**목표**: 가장 빈번하게 사용되는 2가지 필드로 전체 파이프라인 검증

- `SearchFormHelper` 기본 구조 (`search_form_tag`, `sanitize_field_defs`)
- `search_form_controller.js` 기본 구조 (`search`, `reset` action)
- `_input.html.erb`, `_select.html.erb` partial
- `search_form.css` 기본 레이아웃 (CSS Grid 24컬럼)
- `posts/index.html.erb`에 통합하여 AG Grid와 연동 검증
- HTML5 기본 유효성 검사 (`required`)

### Phase 2 — 반응형 + 접기/펼치기

**목표**: 필드 수가 많은 화면에서의 UX 완성

- CSS Grid 반응형 브레이크포인트 (`sf-span-sm-*`, `sf-span-md-*`)
- Helper에서 `cols` / `span` → CSS 클래스 변환
- `search_form_controller.js`에 `toggleCollapse` action 추가
- 접기/펼치기 span 누적 계산 + visibility 토글
- 버튼 span 동적 계산 (접힘/펼침 상태별)

### Phase 3 — Date Picker + Popup

**목표**: 나머지 필드 타입 완성

- `_date_picker.html.erb`, `_date_range.html.erb` partial
- 네이티브 `<input type="date">` 기반 구현
- (선택) Flatpickr 등 서드파티 date picker 통합 검토
- `_popup.html.erb` partial + `search_popup_controller.js`
- 팝업 모달 내 Turbo Frame 검색 연동
- 코드/명칭 이중 바인딩 처리

### Phase 4 — 고도화

**목표**: 프로덕션 품질 달성

- i18n 통합 (`config/locales/ko.yml`에 검색 폼 관련 키 추가)
- 접근성(Accessibility) 강화: `aria-label`, `aria-expanded`, 키보드 네비게이션
- 테스트: Helper 유닛 테스트 + 시스템 테스트 (Capybara)
- 다크 모드 세부 스타일 조정
- 성능 최적화 (Turbo Frame 캐싱 등)

---

## 12. 제약사항 및 주의점

### 12.1 Date Picker

- 네이티브 `<input type="date">`는 브라우저마다 UI가 다름
- 다크 테마에서 네이티브 달력 위젯의 스타일 제어가 제한적
- 타임스탬프 기반(Vue) → 문자열 기반(HTML) 값 형식 차이
- Flatpickr 등 서드파티 라이브러리 도입 시 Stimulus 컨트롤러 추가 필요

### 12.2 Popup 필드

- Vue의 `SearchPopupInput`은 프리셋 시스템(DEPT, EMP 등), 커스텀 API, 가상 스크롤 등 복잡한 기능을 포함
- Rails에서는 Turbo Frame 기반 모달 + AG Grid로 대체 구현 필요
- 코드/명칭 이중 바인딩은 hidden input + display input + Stimulus로 처리
- 프리셋 시스템은 Rails 모델/헬퍼로 재구현

### 12.3 Turbo 통합

- 검색 폼 submit은 GET 요청이므로 URL에 쿼리 파라미터가 노출됨 (의도된 동작 — 북마크/공유 가능)
- Turbo Frame 내에서 form submit 시, `data-turbo-frame` 속성으로 타겟 프레임 지정 필요
- AG Grid의 데이터 URL에 검색 파라미터를 동적으로 추가해야 함 → Stimulus에서 `ag_grid_controller`의 `refresh()` 호출 또는 URL 갱신 필요
- 페이지 뒤로가기 시 검색 조건 유지: Turbo의 캐시 동작에 의존 (폼 값은 URL 파라미터로 복원)

### 12.4 i18n

Vue의 `labelKey`, `placeholderKey`는 Rails의 `I18n.t()` 호출로 대체한다.

**label/placeholder 해석 우선순위 규칙:**

| 우선순위 | 조건 | 동작 |
|---------|------|------|
| 1 | `label` 존재 | 그대로 사용 |
| 2 | `label_key` 존재 | `I18n.t(field[:label_key])` |
| 3 | 둘 다 없음 | `field[:field].to_s.humanize` (fallback) |

Helper 구현:
```ruby
def resolve_label(field)
  if field[:label].present?
    field[:label]
  elsif field[:label_key].present?
    I18n.t(field[:label_key])
  else
    field[:field].to_s.humanize
  end
end

def resolve_placeholder(field)
  if field[:placeholder].present?
    field[:placeholder]
  elsif field[:placeholder_key].present?
    I18n.t(field[:placeholder_key])
  end
end
```

- `config/locales/ko.yml`에 검색 관련 공통 키 추가 필요: `search`, `reset`, `expand`, `collapse` 등

### 12.5 기존 AG Grid 연동

- 검색 폼과 AG Grid는 같은 Turbo Frame 내에 위치
- 검색 시 전체 Turbo Frame이 교체되므로, AG Grid도 함께 재렌더링
- 또는 검색 폼 submit 시 AG Grid의 URL만 갱신하여 데이터만 리로드하는 방식 검토 (Phase 4)

**AG Grid destroy/recreate 정책 (Turbo Frame 교체 시):**

Turbo Frame 교체 시 기존 DOM이 제거되면서 Stimulus 컨트롤러의 `disconnect()`가 호출된다.
이때 AG Grid 인스턴스를 확실히 정리하지 않으면 메모리 누수/이벤트 중복이 발생한다.

체크리스트:
- `ag_grid_controller.disconnect()`에서 `gridApi.destroy()` + `gridApi = null` 처리 (이미 구현됨)
- `connect()`에서 중복 생성 방지: `this.gridApi`가 이미 존재하면 `destroy()` 후 재생성
- `turbo:before-cache` 이벤트 리스너 정리 (이미 구현됨)

---

## 13. 리뷰 체크리스트 요약

구현 시 아래 항목을 반드시 확인한다:

| # | 항목 | 심각도 | 관련 섹션 |
|---|------|--------|----------|
| 1 | `params` 접근을 `q_value()` 헬퍼로 통일 (키 타입 불일치 방지) | 필수 | 4.1, 5.1~5.5 |
| 2 | `type` 정규화: 하이픈 → 언더스코어 (`date-picker` → `date_picker`) | 필수 | 4.1 |
| 3 | collapse span 계산은 `getComputedStyle` 기반 (반응형 대응) | 필수 | 4.2, 7.1 |
| 4 | popup hidden code input에 `value` 바인딩 (값 유실 방지) | 필수 | 5.5 |
| 5 | `ALLOWED_FIELD_KEYS` 확장 (pattern/minlength/maxlength 등) | 강력권장 | 4.1 |
| 6 | `field` 값 검증 (`/\A[a-zA-Z0-9_]+\z/`) | 강력권장 | 4.1 |
| 7 | AG Grid destroy/recreate 정책 확정 | 강력권장 | 12.5 |
| 8 | reset 시 URL 쿼리 파라미터 제거 (`Turbo.visit(baseUrl)`) | 강력권장 | 9.4 |
| 9 | `aria-expanded` + `<label for>` 접근성 (Phase 1부터) | 권장 | 4.2, 5.1~5.5 |
| 10 | i18n `label` → `label_key` → `humanize` 우선순위 명시 | 권장 | 12.4 |
