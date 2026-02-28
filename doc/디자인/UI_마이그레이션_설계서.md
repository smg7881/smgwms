# UI 마이그레이션 설계서

> 작성일: 2026-02-28
> 대상 브랜치: main
> 작성자: 설계 검토 기반 자동 생성

---

## 1. 개요 및 목적

### 1.1 현황 문제

현재 WMS 프로젝트는 다음과 같은 비효율이 있습니다.

| 항목 | 현재 상태 | 문제점 |
|------|----------|--------|
| 알림 | `window.alert()` / `window.confirm()` 래퍼 | 브라우저 기본 다이얼로그, 스타일 적용 불가 |
| 날짜 입력 | `<input type="date">` 브라우저 기본 | OS별 UI 불일치, 날짜 범위 선택 UX 열악 |
| Select Box | `<select>` 브라우저 기본 | 검색 불가, 다중 선택 불가, 다크 테마 불일치 |
| Radio Button | `.radio-input` 클래스, CSS 정의 없음 | OS 기본 스타일 그대로 표시, 다크 테마 미적용 |
| Checkbox | `bg-[#1f2937]` 등 하드코딩 색상 | CSS 변수 체계 불일치, 유지보수 어려움 |
| Toggle Switch | `.rf-switch` CSS 존재 | 구현됨 — 설계서 미기재 상태 |
| Text Input (아이콘) | `_input.html.erb` 아이콘 prefix 미지원 | 이미지의 검색 아이콘 포함 입력 필드 구현 불가 |
| 모달 | 커스텀 `.app-modal-*` CSS 클래스 | 접근성(focus trap) 미흡, `hidden` 속성 기반 제어 |
| 탭바 | 커스텀 `.tab-item` CSS | 일관된 컴포넌트 체계 부재 |
| 탭 컨텍스트 메뉴 | 커스텀 `.tab-context-menu` CSS | 포지셔닝, 키보드 접근성 직접 구현 |
| 사이드바 메뉴 | 커스텀 `.nav-item` CSS | 컴포넌트 추상화 부재 |
| 레이아웃 | CSS Grid + 커스텀 사이드바 토글 | 반응형 대응 직접 구현 |

### 1.2 도입 목표

- **Toast 알림**: 브라우저 기본 alert/confirm → 우하단 자동소멸 Toast + Confirm 모달
- **Flatpickr**: `<input type="date">` → 캘린더 팝업, 날짜 범위 선택, 한국어 로케일
- **Tom Select**: `<select>` opt-in 검색 가능 / 다중 선택 지원
- **Radio / Checkbox**: OS 기본 → `accent-color` CSS 변수 적용, 커스텀 Checkbox
- **Toggle Switch**: 기존 `.rf-switch` CSS 확인 및 설계서 정식 기재
- **Text Input (아이콘)**: prefix 아이콘 지원 — `.form-grid-input-with-icon` CSS + `_input.html.erb` 수정
- **DaisyUI v5**: 모달·탭·메뉴·레이아웃의 CSS 컴포넌트 체계화, 접근성 향상

### 1.3 변경하지 않는 것

아래 항목은 **이미 완성도가 높으므로 변경하지 않습니다.**

- GitHub Dark 테마 CSS 변수 체계 (`--color-*`, `--spacing-*`)
- `.btn`, `.btn-primary`, `.btn-secondary` 등 버튼 클래스
- `.form-grid-input`, `.form-grid-select` 기반 폼 클래스
- `app-modal-*` 기반 모달 CSS
- `BaseCrudController`, `BaseGridController` 등 핵심 Stimulus 컨트롤러
- `Ui::ModalShellComponent`, `Ui::SearchFormComponent` 등 ViewComponent
- `tabs_controller.js`, `lucide_controller.js` 등 인프라 컨트롤러

---

### 1.4 DaisyUI v5 도입 배경

현재 프로젝트는 Tailwind v4(`@import "tailwindcss"`) 기반입니다.
DaisyUI v5는 Tailwind v4 전용으로 설계되어 `@plugin "daisyui"` 한 줄로 통합됩니다.

DaisyUI가 제공하는 것:
- `modal`, `modal-box`, `modal-backdrop` — `<dialog>` 기반 접근성 모달
- `tab`, `tab-active` — 탭 바 클래스
- `menu`, `menu-title` — 사이드바 네비게이션 및 드롭다운 메뉴
- `drawer`, `drawer-side`, `drawer-toggle` — 사이드바 레이아웃

DaisyUI를 도입하더라도 기존 `--color-*` CSS 변수 체계는 **그대로 유지**합니다.
DaisyUI의 테마 변수를 현재 변수로 오버라이드하여 이중 관리를 방지합니다.

---

## 2. 라이브러리 도입 방법

### 2.1 importmap.rb 추가

```ruby
# config/importmap.rb 에 추가

# Tom Select
pin "tom-select", to: "https://cdn.jsdelivr.net/npm/tom-select@2.4.3/dist/esm/tom-select.complete.min.js"

# Flatpickr + 한국어 로케일
pin "flatpickr", to: "https://cdn.jsdelivr.net/npm/flatpickr@4.6.13/dist/esm/index.js"
pin "flatpickr/dist/l10n/ko", to: "https://cdn.jsdelivr.net/npm/flatpickr@4.6.13/dist/l10n/ko.js"
```

### 2.2 CSS 링크 추가 (application.html.erb)

```erb
<%# app/views/layouts/application.html.erb <head> 내 추가 %>

<%# Tom Select CSS %>
<link rel="stylesheet"
      href="https://cdn.jsdelivr.net/npm/tom-select@2.4.3/dist/css/tom-select.min.css">

<%# Flatpickr CSS %>
<link rel="stylesheet"
      href="https://cdn.jsdelivr.net/npm/flatpickr@4.6.13/dist/flatpickr.min.css">
```

---

## 3. Phase별 마이그레이션 계획

```
Phase 0: CSS 오버라이드 추가
         — Tom Select / Flatpickr 다크모드
         — Radio / Checkbox / Toggle Switch CSS 변수 적용
         — Text Input 아이콘 prefix 지원 (form-grid-input-with-icon)
Phase 1: Toast / Confirm 교체         (alert.js 수정)
Phase 2: Flatpickr 날짜 컨트롤러 추가  (신규 Stimulus 컨트롤러 + ERB partial 수정)
Phase 3: Tom Select 컨트롤러 추가      (신규 Stimulus 컨트롤러 + ERB partial 수정)
Phase 4: resource_form_component 확장  (ALLOWED_FIELD_KEYS 추가 + _input.html.erb icon 옵션)
Phase 5: DaisyUI 도입 — 모달·탭·메뉴·레이아웃 (application.css, ERB, BaseCrudController)
```

---

## 4. Phase 0 — 다크모드 CSS 오버라이드

두 라이브러리의 기본 CSS를 프로젝트 다크 테마에 맞게 오버라이드합니다.
`app/assets/tailwind/application.css` 하단에 추가합니다.

### 4.1 Radio Button CSS

#### 현재 문제

`_radio.html.erb`에서 `.radio-input` 클래스를 사용하지만 `application.css`에 해당 CSS가 없어
OS 기본 라디오 버튼이 그대로 노출됩니다. 이미지의 파란 원형 라디오 버튼을 구현합니다.

```css
/* ── Radio Button: 다크 테마 커스텀 ── */
.radio-input {
  appearance: none;
  -webkit-appearance: none;
  width: 16px;
  height: 16px;
  border: 2px solid var(--color-border);
  border-radius: 50%;
  background-color: var(--color-bg-tertiary);
  cursor: pointer;
  position: relative;
  flex-shrink: 0;
  transition: border-color 0.15s, background-color 0.15s;
  vertical-align: middle;
}

.radio-input:hover {
  border-color: var(--color-accent);
}

.radio-input:checked {
  border-color: var(--color-accent);
  background-color: var(--color-accent);
}

/* 내부 흰 점 */
.radio-input:checked::after {
  content: "";
  display: block;
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: #0f1117;
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
}

.radio-input:focus {
  outline: none;
  box-shadow: 0 0 0 3px rgba(88, 166, 255, 0.2);
}

.radio-input:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}
```

---

### 4.2 Checkbox CSS

#### 현재 문제

`_checkbox.html.erb`에서 하드코딩 색상을 인라인 Tailwind 유틸리티로 사용합니다:
```html
class="w-4 h-4 text-[#3b82f6] bg-[#1f2937] border-[#374151] ..."
```
이는 CSS 변수 체계(`--color-*`)를 우회하므로 CSS 변수 기반으로 교체합니다.

#### 변경: _checkbox.html.erb 클래스 교체

```erb
<%# 변경 전 %>
class: "w-4 h-4 text-[#3b82f6] bg-[#1f2937] border-[#374151] focus:ring-[#3b82f6] focus:ring-2 cursor-pointer rounded"

<%# 변경 후 %>
class: "checkbox-input"
```

#### CSS 추가 (application.css)

```css
/* ── Checkbox: 다크 테마 커스텀 ── */
.checkbox-input {
  appearance: none;
  -webkit-appearance: none;
  width: 16px;
  height: 16px;
  border: 2px solid var(--color-border);
  border-radius: 4px;
  background-color: var(--color-bg-tertiary);
  cursor: pointer;
  flex-shrink: 0;
  position: relative;
  transition: border-color 0.15s, background-color 0.15s;
  vertical-align: middle;
}

.checkbox-input:hover {
  border-color: var(--color-accent);
}

.checkbox-input:checked {
  border-color: var(--color-accent);
  background-color: var(--color-accent);
}

/* 체크 표시 (SVG path 방식) */
.checkbox-input:checked::after {
  content: "";
  display: block;
  width: 9px;
  height: 6px;
  border-left: 2px solid #0f1117;
  border-bottom: 2px solid #0f1117;
  position: absolute;
  top: 45%;
  left: 50%;
  transform: translate(-50%, -60%) rotate(-45deg);
}

.checkbox-input:focus {
  outline: none;
  box-shadow: 0 0 0 3px rgba(88, 166, 255, 0.2);
}

.checkbox-input:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}
```

---

### 4.3 Toggle Switch CSS (현황 확인 및 정식 기재)

#### 현재 상태: 이미 구현됨

`application.css`에 `.rf-switch` / `.rf-switch-input` / `.rf-switch-slider` CSS가 구현되어 있으며
이미지의 토글 스위치와 동일한 디자인입니다. **추가 변경 불필요.**

```
현재 구현 확인:
- ON 상태: bg-accent(#58a6ff) 배경 + 흰 원형 슬라이더
- OFF 상태: bg-bg-tertiary 배경 + text-secondary 원형 슬라이더
- 비활성: opacity-50 + cursor-not-allowed
- 포커스: box-shadow accent glow
```

`_switch.html.erb` 및 `.rf-switch` CSS는 **변경 없이 유지**합니다.

---

### 4.4 Text Input — 아이콘 Prefix 지원

#### 현재 문제

`_input.html.erb`는 `class="form-grid-input"` 단순 텍스트 입력만 지원하며
이미지의 검색 아이콘(`🔍`) + 텍스트 조합 입력 필드를 표현할 수 없습니다.

#### CSS 추가 (application.css)

```css
/* ── Text Input with prefix icon ── */
.form-grid-input-wrapper {
  position: relative;
  display: flex;
  align-items: center;
  width: 100%;
}

.form-grid-input-wrapper .form-grid-input-icon {
  position: absolute;
  left: 10px;
  color: var(--color-text-muted);
  pointer-events: none;
  display: flex;
  align-items: center;
  width: 16px;
  height: 16px;
}

.form-grid-input-wrapper .form-grid-input {
  padding-left: 32px;   /* 아이콘 공간 확보 */
}

/* suffix 아이콘 (우측) */
.form-grid-input-wrapper .form-grid-input-icon-suffix {
  position: absolute;
  right: 10px;
  color: var(--color-text-muted);
  pointer-events: none;
  display: flex;
  align-items: center;
  width: 16px;
  height: 16px;
}

.form-grid-input-wrapper .form-grid-input.has-suffix {
  padding-right: 32px;
}
```

#### _input.html.erb 수정 (icon 옵션 추가)

```erb
<%# app/views/shared/resource_form/fields/_input.html.erb %>
<%
  param_key = model&.model_name&.param_key || 'resource'
  error_message = model&.errors&.[](field[:field].to_sym)&.first
  has_icon = field[:icon].present?
%>
<div class="flex flex-col gap-1 col-span-24 min-w-0 <%= span_classes_for(field, cols: cols) %>"
     data-resource-form-target="fieldGroup"
     data-field-name="<%= field[:field] %>">
  <label class="text-sm font-medium text-text-secondary" for="<%= "#{param_key}_#{field[:field]}" %>">
    <%= resolve_label(field) %>
    <% if field[:required] %><span class="text-accent-rose ml-0.5 font-semibold">*</span><% end %>
  </label>
  <div class="flex relative <%= 'form-grid-input-wrapper' if has_icon %>">
    <% if has_icon %>
      <span class="form-grid-input-icon">
        <%= lucide_icon(field[:icon], css_class: "w-4 h-4") %>
      </span>
    <% end %>
    <%= f.text_field field[:field].to_sym,
          id: "#{param_key}_#{field[:field]}",
          class: "form-grid-input #{'rf-field-error' if error_message.present?}",
          placeholder: resolve_placeholder(field),
          required: field[:required],
          disabled: field[:disabled],
          readonly: field[:readonly],
          data: {
            resource_form_target: "input",
            action: "blur->resource-form#validateField"
          }.merge(field[:target].present? && local_assigns[:target_controller].present? ? { "#{local_assigns[:target_controller]}_target" => field[:target] } : {}) %>
  </div>
  <span class="rf-error-msg <%= 'invisible' if error_message.blank? %>"><%= error_message.presence || " " %></span>
  <% if field[:help].present? %>
    <span class="text-xs text-text-muted mt-0.5"><%= field[:help] %></span>
  <% end %>
</div>
```

#### 사용 예시 (PageComponent의 form_fields)

```ruby
{
  field: :sku_code,
  label: "SKU 검색",
  type: :input,
  icon: "search",         # lucide 아이콘 이름
  placeholder: "Search SKU or Location...",
  span: 12
}
```

#### ALLOWED_FIELD_KEYS에 `:icon` 추가 (Phase 4와 동시 처리)

```ruby
ALLOWED_FIELD_KEYS = %i[
  field label type required disabled placeholder
  options include_blank depends_on depends_filter
  min max help date_type span target
  searchable multi
  icon                   # ← Phase 4에서 함께 추가
].freeze
```

---

### 4.5 Tom Select 다크모드 오버라이드

```css
/* ── Tom Select: Dark theme override ── */
.ts-wrapper .ts-control {
  background-color: var(--color-bg-tertiary);
  border: 1px solid var(--color-border);
  border-radius: 6px;
  color: var(--color-text-primary);
  font-size: 0.875rem;
  min-height: 34px;
  padding: 4px 8px;
  box-shadow: none;
  transition: border-color 0.15s, box-shadow 0.15s;
}

.ts-wrapper .ts-control:focus-within,
.ts-wrapper.focus .ts-control {
  border-color: var(--color-accent);
  box-shadow: 0 0 0 3px rgba(88, 166, 255, 0.2);
  outline: none;
}

.ts-wrapper .ts-dropdown {
  background-color: var(--color-bg-secondary);
  border: 1px solid var(--color-border);
  border-radius: 6px;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.5);
  margin-top: 2px;
  z-index: 9999;
}

.ts-wrapper .ts-dropdown .option {
  color: var(--color-text-primary);
  padding: 6px 10px;
  font-size: 0.875rem;
  cursor: pointer;
}

.ts-wrapper .ts-dropdown .option:hover,
.ts-wrapper .ts-dropdown .option.active {
  background-color: var(--color-bg-hover);
  color: var(--color-accent);
}

.ts-wrapper .ts-dropdown .option.selected {
  background-color: rgba(88, 166, 255, 0.15);
  color: var(--color-accent);
}

.ts-wrapper .ts-control input {
  color: var(--color-text-primary);
  background: transparent;
  caret-color: var(--color-accent);
}

.ts-wrapper .ts-control input::placeholder {
  color: var(--color-text-muted);
}

/* 다중 선택 태그 */
.ts-wrapper .ts-control .item {
  background-color: rgba(88, 166, 255, 0.15);
  border: 1px solid rgba(88, 166, 255, 0.3);
  border-radius: 4px;
  color: var(--color-accent);
  font-size: 0.8rem;
  padding: 1px 6px;
}

.ts-wrapper .ts-control .item .remove {
  color: var(--color-text-secondary);
  border-left: 1px solid rgba(88, 166, 255, 0.3);
  margin-left: 4px;
  padding-left: 4px;
}

.ts-wrapper .ts-control .item .remove:hover {
  color: var(--color-accent-rose);
}

/* 검색 하이라이트 */
.ts-wrapper .ts-dropdown .highlight {
  background-color: rgba(88, 166, 255, 0.2);
  color: var(--color-accent);
  border-radius: 2px;
}

/* 비어있음 메시지 */
.ts-wrapper .ts-dropdown .no-results {
  color: var(--color-text-muted);
  padding: 8px 10px;
  font-size: 0.875rem;
}

/* search form 내부 Tom Select 높이 맞춤 */
[data-controller="search-form"] .ts-wrapper .ts-control {
  min-height: 30px;
  padding: 3px 8px;
  font-size: 0.8rem;
}
```

### 4.2 Flatpickr 다크모드 오버라이드

```css
/* ── Flatpickr: Dark theme override ── */
.flatpickr-calendar {
  background-color: var(--color-bg-secondary) !important;
  border: 1px solid var(--color-border) !important;
  border-radius: 8px !important;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.5) !important;
  color: var(--color-text-primary) !important;
}

.flatpickr-calendar .flatpickr-month {
  background-color: var(--color-bg-tertiary) !important;
  color: var(--color-text-primary) !important;
  border-radius: 8px 8px 0 0;
}

.flatpickr-calendar .flatpickr-monthDropdown-months,
.flatpickr-calendar .numInput {
  background-color: var(--color-bg-tertiary) !important;
  color: var(--color-text-primary) !important;
  border: 1px solid var(--color-border) !important;
  border-radius: 4px;
}

.flatpickr-calendar .flatpickr-weekday {
  color: var(--color-text-secondary) !important;
  background-color: var(--color-bg-tertiary) !important;
  font-size: 0.8rem;
}

.flatpickr-calendar .flatpickr-day {
  color: var(--color-text-primary) !important;
  border-radius: 4px;
}

.flatpickr-calendar .flatpickr-day:hover {
  background-color: var(--color-bg-hover) !important;
  border-color: var(--color-border) !important;
}

.flatpickr-calendar .flatpickr-day.selected,
.flatpickr-calendar .flatpickr-day.startRange,
.flatpickr-calendar .flatpickr-day.endRange {
  background-color: var(--color-accent) !important;
  border-color: var(--color-accent) !important;
  color: #0f1117 !important;
}

.flatpickr-calendar .flatpickr-day.inRange {
  background-color: rgba(88, 166, 255, 0.15) !important;
  border-color: transparent !important;
  box-shadow: -5px 0 0 rgba(88, 166, 255, 0.15), 5px 0 0 rgba(88, 166, 255, 0.15);
}

.flatpickr-calendar .flatpickr-day.today {
  border-color: var(--color-accent) !important;
  color: var(--color-accent) !important;
}

.flatpickr-calendar .flatpickr-day.today.selected {
  color: #0f1117 !important;
}

.flatpickr-calendar .flatpickr-day.flatpickr-disabled {
  color: var(--color-text-muted) !important;
}

.flatpickr-calendar .flatpickr-prev-month,
.flatpickr-calendar .flatpickr-next-month {
  color: var(--color-text-secondary) !important;
  fill: var(--color-text-secondary) !important;
}

.flatpickr-calendar .flatpickr-prev-month:hover,
.flatpickr-calendar .flatpickr-next-month:hover {
  color: var(--color-accent) !important;
  fill: var(--color-accent) !important;
}

/* 시간 선택 영역 */
.flatpickr-calendar .flatpickr-time {
  background-color: var(--color-bg-tertiary) !important;
  border-top: 1px solid var(--color-border) !important;
}

.flatpickr-calendar .flatpickr-time input {
  background-color: transparent !important;
  color: var(--color-text-primary) !important;
}

.flatpickr-calendar .flatpickr-time .flatpickr-time-separator,
.flatpickr-calendar .flatpickr-time .flatpickr-am-pm {
  color: var(--color-text-secondary) !important;
}

/* 입력 필드 — 기존 form-grid-input과 동일한 스타일 상속 */
.flatpickr-input {
  width: 100%;
  background-color: var(--color-bg-tertiary);
  border: 1px solid var(--color-border);
  border-radius: 6px;
  color: var(--color-text-primary);
  font-size: 0.875rem;
  padding: 5px 10px;
  transition: border-color 0.15s, box-shadow 0.15s;
  cursor: pointer;
}

.flatpickr-input:focus {
  border-color: var(--color-accent);
  box-shadow: 0 0 0 3px rgba(88, 166, 255, 0.2);
  outline: none;
}
```

---

## 5. Phase 1 — Toast / Confirm 교체

### 5.1 변경 파일

`app/javascript/components/ui/alert.js` — **전체 교체**

기존 `showAlert()` / `confirmAction()` 시그니처를 **그대로 유지**하면서 내부 구현만 교체합니다.
기존 호출 코드(60개 이상 컨트롤러)는 변경하지 않아도 됩니다.

### 5.2 신규 alert.js 코드

```javascript
/**
 * UI Alert / Confirm 유틸리티 — Toast + Confirm Modal 구현
 *
 * showAlert      : 우하단 자동소멸 Toast 알림
 * confirmAction  : 커스텀 Confirm 모달 (Promise 반환)
 *
 * 기존 호출 인터페이스 동일 유지:
 *   showAlert("메시지")
 *   showAlert("제목", "메시지", "success" | "error" | "warning" | "info")
 *   confirmAction("메시지")
 *   confirmAction("제목", "메시지")
 */

// ── Toast 컨테이너 싱글턴 ──────────────────────────────────────────────────
function getToastContainer() {
  let container = document.getElementById("wms-toast-container")
  if (!container) {
    container = document.createElement("div")
    container.id = "wms-toast-container"
    container.style.cssText = `
      position: fixed; bottom: 24px; right: 24px;
      display: flex; flex-direction: column; gap: 8px;
      z-index: 99999; pointer-events: none;
    `
    document.body.appendChild(container)
  }
  return container
}

// ── 아이콘 SVG ────────────────────────────────────────────────────────────
const ICONS = {
  success: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none"
    stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
    <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/>
  </svg>`,
  error: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none"
    stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
    <circle cx="12" cy="12" r="10"/><line x1="15" y1="9" x2="9" y2="15"/>
    <line x1="9" y1="9" x2="15" y2="15"/>
  </svg>`,
  warning: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none"
    stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
    <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/>
    <line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/>
  </svg>`,
  info: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none"
    stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
    <circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/>
    <line x1="12" y1="16" x2="12.01" y2="16"/>
  </svg>`,
}

const TYPE_COLORS = {
  success: { bg: "#1c2b1c", border: "#3fb950", text: "#3fb950" },
  error:   { bg: "#2b1b1b", border: "#f85149", text: "#f85149" },
  warning: { bg: "#2b2410", border: "#d29922", text: "#d29922" },
  info:    { bg: "#161e2e", border: "#58a6ff", text: "#58a6ff" },
}

// ── showAlert ─────────────────────────────────────────────────────────────
export function showAlert(titleOrMessage, message, type = "info") {
  let title, body
  if (message === undefined || message === null) {
    title = null
    body  = titleOrMessage
  } else {
    title = titleOrMessage
    body  = message
  }

  const safeType = TYPE_COLORS[type] ? type : "info"
  const colors   = TYPE_COLORS[safeType]
  const container = getToastContainer()

  const toast = document.createElement("div")
  toast.style.cssText = `
    display: flex; align-items: flex-start; gap: 10px;
    background: ${colors.bg}; border: 1px solid ${colors.border};
    border-left: 3px solid ${colors.border};
    border-radius: 6px; padding: 12px 16px;
    min-width: 280px; max-width: 400px;
    color: #e6edf3; font-size: 0.875rem; line-height: 1.4;
    box-shadow: 0 4px 16px rgba(0,0,0,0.4);
    pointer-events: auto; cursor: pointer;
    transform: translateX(120%); transition: transform 0.25s ease;
  `

  toast.innerHTML = `
    <span style="color:${colors.text}; flex-shrink:0; margin-top:1px;">${ICONS[safeType]}</span>
    <div style="flex:1; min-width:0;">
      ${title ? `<div style="font-weight:600; color:${colors.text}; margin-bottom:2px;">${title}</div>` : ""}
      <div style="color:#8b949e;">${body}</div>
    </div>
    <span style="color:#484f58; font-size:1rem; line-height:1; flex-shrink:0; margin-left:4px;">✕</span>
  `

  container.appendChild(toast)

  // 슬라이드 인
  requestAnimationFrame(() => {
    toast.style.transform = "translateX(0)"
  })

  // 클릭 시 즉시 닫기
  toast.addEventListener("click", () => dismissToast(toast))

  // 3초 후 자동 소멸
  setTimeout(() => dismissToast(toast), 3000)
}

function dismissToast(toast) {
  toast.style.transform = "translateX(120%)"
  toast.style.opacity = "0"
  setTimeout(() => toast.remove(), 280)
}

// ── confirmAction ─────────────────────────────────────────────────────────
export function confirmAction(titleOrMessage, message) {
  let title, body
  if (message === undefined || message === null) {
    title = "확인"
    body  = titleOrMessage
  } else {
    title = titleOrMessage
    body  = message
  }

  return new Promise((resolve) => {
    // 기존 모달 제거
    document.getElementById("wms-confirm-overlay")?.remove()

    const overlay = document.createElement("div")
    overlay.id = "wms-confirm-overlay"
    overlay.style.cssText = `
      position: fixed; inset: 0;
      background: rgba(0,0,0,0.6); backdrop-filter: blur(2px);
      display: flex; align-items: center; justify-content: center;
      z-index: 99998;
    `

    overlay.innerHTML = `
      <div style="
        background: #1c2333; border: 1px solid #30363d;
        border-radius: 10px; padding: 28px 32px;
        min-width: 320px; max-width: 480px; width: 90%;
        box-shadow: 0 16px 40px rgba(0,0,0,0.6);
      ">
        <div style="font-size:1rem; font-weight:600; color:#e6edf3; margin-bottom:10px;">${title}</div>
        <div style="font-size:0.875rem; color:#8b949e; line-height:1.5;">${body}</div>
        <div style="display:flex; justify-content:flex-end; gap:8px; margin-top:24px;">
          <button id="wms-confirm-cancel" style="
            padding: 6px 18px; border-radius:6px; font-size:0.875rem;
            background:#21262d; border:1px solid #30363d; color:#8b949e;
            cursor:pointer; transition: background 0.15s;
          ">취소</button>
          <button id="wms-confirm-ok" style="
            padding: 6px 18px; border-radius:6px; font-size:0.875rem;
            background:#58a6ff; border:none; color:#0f1117;
            cursor:pointer; font-weight:600; transition: background 0.15s;
          ">확인</button>
        </div>
      </div>
    `

    document.body.appendChild(overlay)

    const close = (result) => {
      overlay.remove()
      resolve(result)
    }

    overlay.querySelector("#wms-confirm-ok").addEventListener("click", () => close(true))
    overlay.querySelector("#wms-confirm-cancel").addEventListener("click", () => close(false))
    // ESC 키
    const onKey = (e) => { if (e.key === "Escape") { document.removeEventListener("keydown", onKey); close(false) } }
    document.addEventListener("keydown", onKey)
    // 배경 클릭
    overlay.addEventListener("click", (e) => { if (e.target === overlay) close(false) })
  })
}
```

---

## 6. Phase 2 — Flatpickr 날짜 컨트롤러

### 6.1 신규 Stimulus 컨트롤러

`app/javascript/controllers/flatpickr_controller.js` (신규 생성)

```javascript
// app/javascript/controllers/flatpickr_controller.js
import { Controller } from "@hotwired/stimulus"
import flatpickr from "flatpickr"
import { Korean } from "flatpickr/dist/l10n/ko"

/**
 * Flatpickr 날짜/날짜-시간/날짜-범위 Stimulus 컨트롤러
 *
 * data-controller="flatpickr"
 * data-flatpickr-mode-value="date" | "datetime" | "range"
 * data-flatpickr-format-value="Y-m-d"   (기본값)
 * data-flatpickr-min-value="2024-01-01" (선택)
 * data-flatpickr-max-value="2026-12-31" (선택)
 *
 * range 모드:
 *   data-flatpickr-from-target="input"   (숨겨진 from 값 input)
 *   data-flatpickr-to-target="input"     (숨겨진 to 값 input)
 */
export default class extends Controller {
  static values = {
    mode:   { type: String, default: "date" },
    format: { type: String, default: "Y-m-d" },
    min:    { type: String, default: "" },
    max:    { type: String, default: "" },
  }
  static targets = ["from", "to"]

  connect() {
    const config = {
      locale: Korean,
      dateFormat: this.formatValue,
      allowInput: true,
      disableMobile: true,
    }

    if (this.minValue) config.minDate = this.minValue
    if (this.maxValue) config.maxDate = this.maxValue

    if (this.modeValue === "datetime") {
      config.enableTime = true
      config.dateFormat = this.formatValue === "Y-m-d" ? "Y-m-d H:i" : this.formatValue
    }

    if (this.modeValue === "range") {
      config.mode = "range"
      config.onClose = (selectedDates) => this.#onRangeClose(selectedDates)
    }

    this.#fp = flatpickr(this.element, config)
  }

  disconnect() {
    this.#fp?.destroy()
    this.#fp = null
  }

  // range 모드: 닫힐 때 숨겨진 from/to 필드에 값 채움
  #onRangeClose(selectedDates) {
    if (!this.hasFromTarget || !this.hasToTarget) return
    if (selectedDates.length >= 1) {
      this.fromTarget.value = flatpickr.formatDate(selectedDates[0], "Y-m-d")
    }
    if (selectedDates.length >= 2) {
      this.toTarget.value = flatpickr.formatDate(selectedDates[1], "Y-m-d")
    }
  }

  #fp = null
}
```

### 6.2 ERB partial 수정

#### `app/views/shared/resource_form/fields/_date_picker.html.erb` 수정

```erb
<%# app/views/shared/resource_form/fields/_date_picker.html.erb %>
<%
  param_key = model&.model_name&.param_key || 'resource'
  error_message = model&.errors&.[](field[:field].to_sym)&.first
  date_mode = field[:date_type] == "datetime" ? "datetime" : "date"
%>
<div class="flex flex-col gap-1 col-span-24 min-w-0 <%= span_classes_for(field, cols: cols) %>"
     data-resource-form-target="fieldGroup"
     data-field-name="<%= field[:field] %>">
  <label class="text-sm font-medium text-text-secondary" for="<%= "#{param_key}_#{field[:field]}" %>">
    <%= resolve_label(field) %>
    <% if field[:required] %><span class="text-accent-rose ml-0.5 font-semibold">*</span><% end %>
  </label>
  <div class="flex relative">
    <%= f.text_field field[:field].to_sym,
          id: "#{param_key}_#{field[:field]}",
          class: "form-grid-input #{'rf-field-error' if error_message.present?}",
          required: field[:required],
          disabled: field[:disabled],
          placeholder: date_mode == "datetime" ? "YYYY-MM-DD HH:MM" : "YYYY-MM-DD",
          data: {
            controller: "flatpickr",
            flatpickr_mode_value: date_mode,
            flatpickr_min_value: field[:min],
            flatpickr_max_value: field[:max],
            resource_form_target: "input",
            action: "blur->resource-form#validateField"
          }.merge(field[:target].present? && local_assigns[:target_controller].present? ? { "#{local_assigns[:target_controller]}_target" => field[:target] } : {}) %>
  </div>
  <span class="rf-error-msg <%= 'invisible' if error_message.blank? %>"><%= error_message.presence || " " %></span>
  <% if field[:help].present? %>
    <span class="text-xs text-text-muted mt-0.5"><%= field[:help] %></span>
  <% end %>
</div>
```

#### `app/views/shared/search_form/fields/_date_range.html.erb` 수정

```erb
<%# app/views/shared/search_form/fields/_date_range.html.erb %>
<% field_id_from = "q_#{field[:field]}_from" %>
<% field_id_to   = "q_#{field[:field]}_to" %>
<div class="flex flex-col gap-1 col-span-24 min-w-0 <%= span_classes_for(field, cols: cols) %>"
     data-search-form-target="fieldGroup">
  <label class="text-sm font-medium text-text-secondary"><%= resolve_label(field) %></label>
  <div class="flex items-center gap-2 min-w-0"
       data-controller="flatpickr"
       data-flatpickr-mode-value="range">
    <%# 표시용 텍스트 입력 (Flatpickr가 range 선택 UI 담당) %>
    <input type="text"
           class="form-grid-input flex-1 min-w-0"
           placeholder="날짜 범위 선택"
           data-flatpickr-target="display"
           readonly>
    <%# 실제 값은 숨겨진 hidden input으로 서버에 전송 %>
    <input type="hidden"
           id="<%= field_id_from %>"
           name="q[<%= field[:field] %>_from]"
           value="<%= q_value("#{field[:field]}_from") %>"
           data-flatpickr-target="from">
    <input type="hidden"
           id="<%= field_id_to %>"
           name="q[<%= field[:field] %>_to]"
           value="<%= q_value("#{field[:field]}_to") %>"
           data-flatpickr-target="to">
  </div>
</div>
```

> **주의**: `_date_range.html.erb` 수정 시 `flatpickr_controller.js`의 `#onRangeClose` 로직과
> `targets: ["from", "to"]` 설정이 연동됩니다. 표시용 input의 `data-flatpickr-target="display"` 속성을
> controller에서 `this.element`로 처리하도록 컨트롤러는 `<div>` 가 아닌 표시 input에 `data-controller`를
> 직접 붙이는 방식으로 변경할 수 있습니다.

---

## 7. Phase 3 — Tom Select 컨트롤러

### 7.1 신규 Stimulus 컨트롤러

`app/javascript/controllers/tom_select_controller.js` (신규 생성)

```javascript
// app/javascript/controllers/tom_select_controller.js
import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select"

/**
 * Tom Select Stimulus 컨트롤러
 *
 * data-controller="tom-select"
 * data-tom-select-searchable-value="true"   검색 활성화 (기본 false)
 * data-tom-select-multi-value="true"        다중 선택 (기본 false)
 * data-tom-select-placeholder-value="선택"  placeholder
 *
 * 사용 예:
 *   <select data-controller="tom-select"
 *           data-tom-select-searchable-value="true">
 *     <option value="">선택하세요</option>
 *     <option value="A">항목 A</option>
 *   </select>
 */
export default class extends Controller {
  static values = {
    searchable:  { type: Boolean, default: false },
    multi:       { type: Boolean, default: false },
    placeholder: { type: String,  default: "선택하세요" },
  }

  connect() {
    const config = {
      plugins: [],
      placeholder: this.placeholderValue,
      allowEmptyOption: true,
      // 검색 비활성화 시 키 입력 막기
      controlInput: this.searchableValue ? undefined : null,
    }

    if (this.multiValue) {
      config.plugins.push("remove_button")
      config.maxItems = null
    } else {
      config.maxItems = 1
    }

    if (!this.searchableValue) {
      config.sortField = { field: "$order", direction: "asc" }
    }

    this.#ts = new TomSelect(this.element, config)
  }

  disconnect() {
    this.#ts?.destroy()
    this.#ts = null
  }

  #ts = null
}
```

### 7.2 ERB partial 수정

#### `app/views/shared/resource_form/fields/_select.html.erb` 수정

`data-controller="tom-select"` 속성을 조건부로 추가합니다.
기존 `depends_on` 연동 로직은 그대로 유지합니다.

```erb
<%# app/views/shared/resource_form/fields/_select.html.erb %>
<%
  param_key     = model&.model_name&.param_key || 'resource'
  field_id      = "#{param_key}_#{field[:field]}"
  has_dependency = field[:depends_on].present?
  current_value  = model&.send(field[:field].to_sym) rescue nil
  error_message  = model&.errors&.[](field[:field].to_sym)&.first
  use_tom_select = field[:searchable] || field[:multi]
%>
<div class="flex flex-col gap-1 col-span-24 min-w-0 <%= span_classes_for(field, cols: cols) %>"
     data-resource-form-target="fieldGroup <%= 'dependentField' if has_dependency %>"
     data-field-name="<%= field[:field] %>">
  <label class="text-sm font-medium text-text-secondary" for="<%= field_id %>">
    <%= resolve_label(field) %>
    <% if field[:required] %><span class="text-accent-rose ml-0.5 font-semibold">*</span><% end %>
  </label>
  <div class="flex relative">
    <select id="<%= field_id %>"
            name="<%= "#{param_key}[#{field[:field]}]" %>"
            class="form-grid-select <%= 'rf-field-error' if error_message.present? %>"
            <%= "required" if field[:required] %>
            <%= "disabled" if field[:disabled] %>
            <%= "multiple" if field[:multi] %>
            <% if has_dependency %>
              data-all-options="<%= (field[:options] || []).to_json %>"
              data-depends-on="<%= field[:depends_on] %>"
              data-depends-filter="<%= field[:depends_filter] || field[:depends_on] %>"
            <% end %>
            <% if field[:target].present? && local_assigns[:target_controller].present? %>
              data-<%= local_assigns[:target_controller].to_s.dasherize %>-target="<%= field[:target] %>"
            <% end %>
            data-resource-form-target="input"
            data-action="<%= has_dependency ? '' : 'change->resource-form#onSelectChange' %> blur->resource-form#validateField"
            <% if use_tom_select %>
              data-controller="tom-select"
              data-tom-select-searchable-value="<%= field[:searchable] ? 'true' : 'false' %>"
              data-tom-select-multi-value="<%= field[:multi] ? 'true' : 'false' %>"
            <% end %>>
      <% if !field[:multi] && field[:include_blank] != false %>
        <option value=""><%= resolve_placeholder(field) || "선택하세요" %></option>
      <% end %>
      <% (field[:options] || []).each do |opt| %>
        <%
          label, value = if opt.is_a?(Hash)
            [opt[:label] || opt["label"], opt[:value] || opt["value"]]
          elsif opt.is_a?(Array)
            [opt.first, opt.last]
          else
            [opt, opt]
          end
        %>
        <option value="<%= value %>" <%= "selected" if current_value.to_s == value.to_s %>><%= label %></option>
      <% end %>
    </select>
  </div>
  <span class="rf-error-msg <%= 'invisible' if error_message.blank? %>"><%= error_message.presence || " " %></span>
  <% if field[:help].present? %>
    <span class="text-xs text-text-muted mt-0.5"><%= field[:help] %></span>
  <% end %>
</div>
```

---

## 8. Phase 4 — resource_form_component 확장

### 8.1 ALLOWED_FIELD_KEYS 추가

`app/components/ui/resource_form_component.rb`의 `ALLOWED_FIELD_KEYS` 상수에 `:searchable`, `:multi` 추가:

```ruby
# 변경 전
ALLOWED_FIELD_KEYS = %i[
  field label type required disabled placeholder
  options include_blank depends_on depends_filter
  min max help date_type span target
].freeze

# 변경 후
ALLOWED_FIELD_KEYS = %i[
  field label type required disabled placeholder
  options include_blank depends_on depends_filter
  min max help date_type span target
  searchable multi
].freeze
```

### 8.2 사용 예시

```ruby
# PageComponent의 form_fields 정의에서 Tom Select 활성화
{
  field: :dept_code,
  label: "부서",
  type: :select,
  options: dept_options,
  searchable: true,   # Tom Select 검색 활성화
  span: 12
}

{
  field: :permission_codes,
  label: "권한",
  type: :select,
  options: permission_options,
  multi: true,        # Tom Select 다중 선택
  span: 24
}
```

---

## 9. 파일 변경 목록 요약

### 신규 생성

| 파일 | 설명 |
|------|------|
| `app/javascript/controllers/flatpickr_controller.js` | Flatpickr Stimulus 컨트롤러 |
| `app/javascript/controllers/tom_select_controller.js` | Tom Select Stimulus 컨트롤러 |

### 수정 파일

| 파일 | 변경 내용 |
|------|----------|
| `config/importmap.rb` | tom-select, flatpickr pin 추가 |
| `app/views/layouts/application.html.erb` | CDN CSS link 2개 + `data-theme="dark"` 추가 |
| `app/assets/tailwind/application.css` | Tom Select / Flatpickr / Radio / Checkbox / Input icon / DaisyUI 다크모드 CSS 추가 |
| `app/javascript/components/ui/alert.js` | Toast + Confirm Modal로 전체 교체 |
| `app/views/shared/resource_form/fields/_date_picker.html.erb` | Flatpickr 연동 |
| `app/views/shared/search_form/fields/_date_range.html.erb` | Flatpickr range 연동 |
| `app/views/shared/resource_form/fields/_select.html.erb` | Tom Select opt-in 추가 |
| `app/views/shared/resource_form/fields/_checkbox.html.erb` | `checkbox-input` 클래스로 교체 (하드코딩 색상 제거) |
| `app/views/shared/resource_form/fields/_input.html.erb` | `icon` 옵션 지원 (`form-grid-input-wrapper`) |
| `app/components/ui/resource_form_component.rb` | ALLOWED_FIELD_KEYS에 `:searchable`, `:multi`, `:icon` 추가 |

### 변경 없음 (유지)

| 파일 | 이유 |
|------|------|
| `app/javascript/controllers/base_grid_controller.js` | 인터페이스 불변 |
| `app/assets/tailwind/application.css` (기존 `.btn-*`, `.form-grid-*`) | 기존 CSS 변수 체계 유지 |
| `app/components/ui/search_form_component.rb` | 구조 불변 |
| 모든 도메인 컨트롤러 (`dept_crud`, `menu_crud` 등) | `showAlert` 시그니처 유지이므로 무변경 |

### Phase 5 추가 수정 파일

| 파일 | 변경 내용 |
|------|----------|
| `app/assets/tailwind/application.css` | DaisyUI 플러그인 추가 + 테마 변수 매핑 |
| `app/views/layouts/application.html.erb` | `data-theme="dark"` 추가 |
| `app/components/ui/modal_shell_component.html.erb` | `<dialog>` + DaisyUI modal 클래스로 교체 |
| `app/components/ui/modal_shell_component.rb` | `open?` 헬퍼 메서드 추가 |
| `app/javascript/controllers/base_crud_controller.js` | `openModal()` / `closeModal()` → `<dialog>` API로 변경 |
| `app/views/shared/_tab_bar.html.erb` | `tab-item` → DaisyUI `tab` |
| `app/views/shared/_sidebar.html.erb` | `nav-item` → DaisyUI `menu` |
| `app/views/shared/_header.html.erb` | DaisyUI `navbar` 적용 |

---

## 10. Phase 5 — DaisyUI 모달·탭·메뉴·레이아웃

### 10.1 DaisyUI v5 설치

#### application.css 상단 수정

```css
/* 기존 */
@import "tailwindcss";

/* 변경 후 */
@import "tailwindcss";
@plugin "daisyui";
```

> DaisyUI를 npm 없이 CDN으로만 쓸 경우 `application.html.erb`에 아래 링크 추가:
> ```html
> <link href="https://cdn.jsdelivr.net/npm/daisyui@5/dist/full.min.css" rel="stylesheet">
> ```
> 단, `@plugin "daisyui"` 방식이 Tailwind v4와 완전 통합되므로 **플러그인 방식 권장**.

#### DaisyUI 테마 변수 매핑 (application.css)

DaisyUI의 컴포넌트 스타일은 내부적으로 `--color-base-*`, `--color-primary` 등의 변수를 사용합니다.
기존 `--color-*` 변수를 DaisyUI 변수에 매핑하여 색상 이중 관리를 방지합니다.

```css
/* ── DaisyUI 다크 테마 변수 매핑 ── */
/* application.css @theme 블록 아래에 추가 */

[data-theme="dark"] {
  /* 배경 */
  --color-base-100: #0f1117;   /* --color-bg-primary */
  --color-base-200: #161b22;   /* --color-bg-secondary */
  --color-base-300: #1c2333;   /* --color-bg-tertiary */

  /* 텍스트 */
  --color-base-content: #e6edf3;   /* --color-text-primary */

  /* 주 색상 */
  --color-primary: #58a6ff;        /* --color-accent */
  --color-primary-content: #0f1117;

  /* 성공/경고/오류 */
  --color-success: #3fb950;        /* --color-accent-green */
  --color-warning: #d29922;        /* --color-accent-amber */
  --color-error:   #f85149;        /* --color-accent-rose */

  /* 테두리 */
  --color-border: #30363d;         /* --color-border */

  /* 모달 배경 */
  --modal-backdrop: rgba(0, 0, 0, 0.6);
}
```

### 10.2 HTML 다크 테마 활성화

`app/views/layouts/application.html.erb`의 `<html>` 태그에 `data-theme` 추가:

```erb
<%# 변경 전 %>
<html lang="ko">

<%# 변경 후 %>
<html lang="ko" data-theme="dark">
```

---

### 10.3 모달 — DaisyUI `<dialog>` 기반으로 교체

#### 현재 구조 분석

| 항목 | 현재 방식 | 문제점 |
|------|----------|--------|
| 표시/숨김 | `hidden` 속성 추가/제거 | 브라우저 focus trap 없음 |
| backdrop | `bg-black/50` CSS div | `<dialog>` backdrop보다 접근성 열악 |
| 드래그 | `BaseCrudController#startDrag` | 유지 (DaisyUI 미제공, 직접 구현 유지) |

#### 변경 후: modal_shell_component.html.erb

```erb
<%# app/components/ui/modal_shell_component.html.erb %>
<dialog class="modal"
        data-<%= controller %>-target="overlay"
        data-action="click-><%= controller %>#onBackdropClick">
  <div class="modal-box bg-base-100 border border-border rounded-lg max-w-[calc(100vw-32px)] max-h-[90vh] flex flex-col overflow-hidden shadow-2xl p-0"
       style="<%= modal_style %>"
       data-<%= controller %>-target="modal"
       data-action="click-><%= controller %>#stopPropagation">

    <div class="modal-header flex justify-between items-center px-5 py-4 border-b border-border bg-base-100 cursor-move"
         data-action="mousedown-><%= controller %>#startDrag">
      <h3 class="m-0 text-base text-base-content" data-<%= controller %>-target="modalTitle"><%= title %></h3>
      <button type="button"
              class="btn btn-ghost btn-sm btn-circle text-base-content/60 hover:text-base-content"
              data-action="click-><%= controller %>#closeModal">✕</button>
    </div>

    <div class="modal-body px-5 py-5 overflow-y-auto flex-1 min-h-0">
      <%= body %>
    </div>

    <div class="modal-action px-5 py-3 border-t border-border bg-base-100 justify-end m-0">
      <button type="button" class="btn btn-sm btn-ghost"
              <%= cancel_role_attr&.html_safe %>
              data-action="click-><%= controller %>#closeModal"><%= cancel_text %></button>
      <button type="submit" class="btn btn-sm btn-primary"
              form="<%= save_form_id %>"
              <%= save_role_attr&.html_safe %>><%= save_text %></button>
    </div>
  </div>
</dialog>
```

#### 변경 후: BaseCrudController openModal / closeModal

```javascript
// base_crud_controller.js — openModal / closeModal 부분만 교체
openModal() {
  this.overlayTarget.showModal()   // <dialog>.showModal() — focus trap 자동
}

closeModal() {
  this.overlayTarget.close()       // <dialog>.close()
  this.#resetForm()
}

// backdrop 클릭 처리 (dialog 외부 클릭 감지)
onBackdropClick(event) {
  if (event.target === this.overlayTarget) {
    this.closeModal()
  }
}
```

#### CSS 정리 (application.css)

DaisyUI `modal` 클래스가 `.app-modal-overlay` 역할을 대체하므로
기존 `.app-modal-*` CSS는 **유지하되** 신규 화면에는 DaisyUI 클래스를 사용합니다.
이후 기존 화면도 점진적으로 교체합니다.

---

### 10.4 탭바 — DaisyUI `tab` 클래스

#### 현재 구조 분석

```html
<!-- 현재: _tab_bar.html.erb -->
<button class="tab-item active">대시보드</button>
<button class="tab-item">입고관리</button>
```

#### 변경 후

```erb
<%# app/views/shared/_tab_bar.html.erb — tab 버튼 부분만 변경 %>
<button class="tab tab-bordered <%= 'tab-active' if is_active %> <%= 'tab-pinned' if is_pinned %>"
        type="button"
        title="<%= is_pinned ? '고정 탭' : label %>"
        data-action="click->tabs#activateTab contextmenu->tabs#openContextMenu"
        data-tab-id="<%= tab_id %>"
        data-tab-label="<%= label %>">
  <span class="w-[7px] h-[7px] rounded-full shrink-0 bg-base-content/30 transition-colors duration-150
               <%= 'bg-primary!' if is_active %>"></span>
  <%= label %>

  <% if is_pinned %>
    <span class="tab-pin" aria-hidden="true"><%= lucide_icon("pin", css_class: "w-3 h-3") %></span>
  <% else %>
    <span class="ml-1 w-4 h-4 inline-flex items-center justify-center rounded-sm cursor-pointer
                 text-base-content/40 hover:bg-error hover:text-white transition-colors duration-150"
          data-action="click->tabs#closeTab:stop"
          data-tab-id="<%= tab_id %>">
      <%= lucide_icon("x", css_class: "w-3 h-3") %>
    </span>
  <% end %>
</button>
```

#### CSS 업데이트 (application.css)

```css
/* ── Tab item: DaisyUI tab 클래스 위에 프로젝트 커스텀 스타일 오버라이드 ── */
.tab {
  height: var(--spacing-tab-bar);
  padding-inline: 0.875rem;
  font-size: 0.8125rem;
  color: var(--color-text-secondary);
  border-bottom: 2px solid transparent;
  background: transparent;
  white-space: nowrap;
  gap: 0.375rem;
  transition: color 0.15s, border-color 0.15s, background 0.15s;
}

.tab:hover {
  background: var(--color-bg-hover);
  color: var(--color-text-primary);
}

.tab.tab-active {
  color: var(--color-text-primary);
  border-bottom-color: var(--color-accent);
  background: rgba(88, 166, 255, 0.05);
}

/* 기존 .tab-item, .tab-item.active 는 레거시 호환용으로 유지 */
```

---

### 10.5 탭 컨텍스트 메뉴 — DaisyUI `dropdown` + `menu`

#### 현재 구조 분석

```html
<!-- 현재: 커스텀 .tab-context-menu -->
<div class="tab-context-menu" data-tabs-target="contextMenu">
  <div class="tab-context-menu__item" data-menu-action="close-all">...</div>
</div>
```

#### 변경 후

```erb
<%# app/views/shared/_tab_bar.html.erb — 탭 액션 메뉴 부분 %>
<div class="dropdown dropdown-end" data-tabs-target="actionsDropdown">
  <button type="button"
          tabindex="0"
          class="tab-actions-trigger btn btn-ghost btn-sm btn-square"
          aria-label="탭 메뉴"
          data-tabs-target="menuToggle"
          data-action="click->tabs#openActionsMenu">
    <%= lucide_icon("more-horizontal", css_class: "w-4 h-4") %>
  </button>

  <ul tabindex="0"
      class="dropdown-content menu bg-base-200 border border-border rounded-lg shadow-xl z-[100] w-44 p-1 text-sm"
      role="menu"
      data-tabs-target="contextMenu">
    <li role="menuitem" data-menu-action="close-all"
        data-action="click->tabs#closeAllTabs keydown->tabs#handleMenuItemKeydown">
      <a class="gap-2">
        <%= lucide_icon("x", css_class: "w-3.5 h-3.5") %>모두 닫기
      </a>
    </li>
    <li role="menuitem" data-menu-action="close-others"
        data-action="click->tabs#closeOtherTabs keydown->tabs#handleMenuItemKeydown">
      <a class="gap-2">
        <%= lucide_icon("circle-off", css_class: "w-3.5 h-3.5") %>현재 탭 제외 닫기
      </a>
    </li>
    <li class="divider my-0.5"></li>
    <li role="menuitem" data-menu-action="move-left"
        data-action="click->tabs#moveTabLeft keydown->tabs#handleMenuItemKeydown">
      <a class="gap-2">
        <%= lucide_icon("arrow-left-to-line", css_class: "w-3.5 h-3.5") %>왼쪽이동
      </a>
    </li>
    <li role="menuitem" data-menu-action="move-right"
        data-action="click->tabs#moveTabRight keydown->tabs#handleMenuItemKeydown">
      <a class="gap-2">
        <%= lucide_icon("arrow-right-to-line", css_class: "w-3.5 h-3.5") %>오른쪽이동
      </a>
    </li>
  </ul>
</div>
```

#### DaisyUI menu 다크 오버라이드 (application.css)

```css
/* ── DaisyUI dropdown menu: 다크 테마 오버라이드 ── */
.dropdown-content.menu {
  background-color: var(--color-bg-secondary);
  border: 1px solid var(--color-border);
}

.dropdown-content.menu li > a {
  color: var(--color-text-primary);
  font-size: 0.8125rem;
  border-radius: 4px;
  padding: 6px 10px;
}

.dropdown-content.menu li > a:hover,
.dropdown-content.menu li > a:focus {
  background-color: var(--color-bg-hover);
  color: var(--color-accent);
}

.dropdown-content.menu .divider {
  border-color: var(--color-border);
}
```

---

### 10.6 사이드바 — DaisyUI `menu` 컴포넌트

#### 현재 구조 분석

```html
<!-- 현재: .nav-item 커스텀 CSS -->
<button class="nav-item has-children expanded">...</button>
<div class="nav-tree-children open">
  <button class="nav-item">메뉴항목</button>
</div>
```

#### 변경 후 (_sidebar.html.erb nav 영역)

```erb
<%# app/views/shared/_sidebar.html.erb — nav 내부 %>
<nav class="flex-1 py-2 overflow-y-auto">
  <ul class="menu menu-sm w-full px-0 gap-0.5">
    <% if dynamic_sidebar_available? %>
      <%# 기존 render_sidebar_folder_tree / sidebar_menu_button_from_record 헬퍼 유지 %>
      <%# 헬퍼 내부 클래스만 nav-item → DaisyUI menu-item 으로 변경 %>
      <% grouped = AdmMenu.sidebar_tree %>
      <% (grouped[nil] || []).each do |menu| %>
        <% if menu.menu_type == "FOLDER" %>
          <%= render_sidebar_folder_tree(menu, grouped) %>
        <% else %>
          <%= sidebar_menu_button_from_record(menu) %>
        <% end %>
      <% end %>
    <% end %>
  </ul>
</nav>
```

#### sidebar_helper.rb 변경 포인트

```ruby
# app/helpers/sidebar_helper.rb — sidebar_menu_button 메서드 클래스 변경

# 변경 전
def sidebar_menu_button(label, tab_id:, icon:, url:)
  content_tag(:button, class: "nav-item #{active_class}", ...) do
    ...
  end
end

# 변경 후 (DaisyUI menu item 구조)
def sidebar_menu_button(label, tab_id:, icon:, url:)
  content_tag(:li) do
    content_tag(:button, class: "flex items-center gap-2 w-full #{active_class}", ...) do
      ...
    end
  end
end
```

#### CSS 업데이트 (application.css)

```css
/* ── DaisyUI menu: 사이드바 스타일 오버라이드 ── */
.menu li > button,
.menu li > a {
  color: var(--color-text-secondary);
  border-radius: 0;
  padding: 8px 16px;
  font-size: 0.875rem;
  transition: background 0.15s, color 0.15s;
}

.menu li > button:hover,
.menu li > a:hover {
  background: var(--color-bg-hover);
  color: var(--color-text-primary);
}

.menu li > button.active,
.menu li > a.active {
  background: rgba(88, 166, 255, 0.1);
  color: var(--color-accent);
}

/* 접기/펼치기 폴더 */
.menu details > summary {
  color: var(--color-text-secondary);
  padding: 8px 16px;
  font-size: 0.875rem;
}

.menu details > summary:hover {
  background: var(--color-bg-hover);
  color: var(--color-text-primary);
}

/* 2단계 들여쓰기 */
.menu details ul {
  padding-left: 1rem;
}

/* 기존 .nav-item, .nav-tree-children 는 레거시 호환용으로 유지 */
```

---

### 10.7 레이아웃 — DaisyUI `drawer` 검토 결과

#### 현재 구조

```html
<div class="grid grid-cols-[var(--spacing-sidebar)_1fr] h-screen" data-controller="tabs">
  <aside class="sidebar ...">...</aside>
  <main class="flex flex-col ...">...</main>
</div>
```

CSS Grid로 `sidebar-collapsed` 클래스를 통해 `grid-template-columns: 0 1fr`으로 전환합니다.

#### DaisyUI drawer 도입 여부 검토

| 항목 | 현재 CSS Grid | DaisyUI drawer |
|------|-------------|----------------|
| 사이드바 토글 | JS에서 CSS Grid 컬럼 크기 변경 | `<input type="checkbox">` 토글 |
| 반응형 | 직접 구현 | `drawer-mobile` 속성으로 자동 처리 |
| Stimulus 연동 | `tabs_controller.js#toggleSidebar` 로 직접 클래스 조작 | checkbox 상태 기반 CSS-only 가능 |
| 현재 코드 변경량 | — | `application.html.erb`, `_header.html.erb`, `_sidebar.html.erb`, `tabs_controller.js` 전면 수정 필요 |

#### 결론: **레이아웃은 현재 CSS Grid 방식 유지**

이유:
1. `tabs_controller.js`가 사이드바 토글 외에 탭 관리까지 통합 담당 — 분리 시 복잡도 증가
2. CSS Grid + `grid-template-columns` 애니메이션이 이미 `transition: grid-template-columns 250ms`로 동작 중
3. DaisyUI drawer의 checkbox 기반 토글은 Turbo Drive 페이지 전환 시 상태 초기화 위험

DaisyUI `drawer` 도입은 **향후 모바일 대응이 필요할 때** 별도 Phase로 검토합니다.

---

## 11. 위험 요소 및 대응

| 위험 | 발생 가능성 | 대응 방안 |
|------|-----------|----------|
| `depends_on` 의존 필드와 Tom Select 충돌 | 중간 | `resource-form` 컨트롤러의 `onDependencyChange`가 `.value`를 직접 변경 → Tom Select 인스턴스에 `setValue()` 호출로 동기화 필요 |
| Turbo Drive 페이지 전환 시 Flatpickr / Tom Select 미해제 | 높음 | Stimulus `disconnect()` 훅에서 `.destroy()` 호출로 완전 정리 (이미 코드에 포함) |
| Flatpickr range 모드에서 hidden input 값 미전송 | 중간 | `onClose` 콜백에서 from/to target에 명시적 값 세팅 (이미 코드에 포함) |
| importmap CDN 오프라인 환경 | 낮음 | 필요 시 `vendor/javascript/`에 파일 복사 후 로컬 pin으로 변경 |
| Tom Select + `multiple` select Rails 파라미터 파싱 | 중간 | `name="model[field][]"` 형태로 변경 필요 (multi 모드 시 _select.html.erb에서 처리) |
| DaisyUI `<dialog>` + 기존 `hidden` 속성 혼용 | 높음 | Phase 5 적용 시 `BaseCrudController#openModal` / `closeModal` 반드시 동시에 교체, 레거시 화면은 단계적 마이그레이션 |
| DaisyUI CSS 변수와 기존 `--color-*` 변수 충돌 | 중간 | `[data-theme="dark"]` 블록 내에서 DaisyUI 변수를 기존 값으로 명시적 오버라이드. `!important` 사용 금지 |
| DaisyUI `menu` 클래스와 기존 `.nav-item` CSS 선택자 충돌 | 낮음 | `.nav-item` 기존 CSS 유지 + DaisyUI menu 오버라이드를 하위에 선언하여 specificity로 해결 |

---

## 12. 검증 체크리스트

> 구현 완료: 2026-02-28
> 미완 항목은 별도 이슈로 관리합니다.

### Phase 0 완료 기준
- [x] Tom Select 드롭다운이 다크 배경으로 표시됨
- [x] Flatpickr 캘린더가 다크 배경으로 표시됨
- [x] 선택된 날짜가 `--color-accent` 파란색으로 표시됨
- [x] Radio Button — 미선택: 어두운 테두리 원형 / 선택: `#58a6ff` 파란 원형 내부 흰 점
- [x] Checkbox — 미체크: 어두운 테두리 정사각 / 체크: `#58a6ff` 파란 배경 + 흰 체크 표시
- [x] Toggle Switch — 기존 `.rf-switch` CSS 동작 유지 확인 (ON: 파란, OFF: 회색)
- [x] Text Input + 아이콘 — `icon: "search"` 옵션 지정 시 루사이드 아이콘이 입력 필드 좌측에 표시됨
- [x] `_checkbox.html.erb` 하드코딩 색상(`text-[#3b82f6]` 등) 제거 후 `checkbox-input` 클래스로 동일 렌더링 확인

### Phase 1 완료 기준
- [x] `showAlert("저장 완료", null, "success")` → 우하단 초록 Toast 3초 후 소멸
- [x] `showAlert("오류", "저장에 실패했습니다", "error")` → 우하단 빨간 Toast
- [x] `confirmAction("삭제하시겠습니까?")` → 커스텀 모달 표시, 확인 클릭 시 `true` 반환
- [x] ESC 키 및 배경 클릭 시 `false` 반환
- [x] 기존 도메인 컨트롤러 (`dept_crud` 등)에서 `showAlert` 호출 정상 동작

### Phase 2 완료 기준
- [x] resource_form의 `date` 타입 필드 → Flatpickr 캘린더 표시
- [x] resource_form의 `datetime` 타입 필드 → 날짜+시간 선택
- [x] 검색폼 날짜 범위 필드 → 범위 선택 후 `q[field_from]`, `q[field_to]` 값 전송

### Phase 3 완료 기준
- [x] `searchable: true` 필드 → 키 입력으로 옵션 필터링
- [x] `multi: true` 필드 → 복수 선택, 태그 표시, Rails에 배열 파라미터 전송
- [ ] `depends_on` 연동 필드 + Tom Select 동작 정상 ← 별도 이슈 (구현 범위 외)

### Phase 4 완료 기준
- [x] `ALLOWED_FIELD_KEYS` 에 `:searchable`, `:multi` 포함 확인
- [x] 기존 form_fields 정의(`searchable`/`multi` 없는 것) 정상 동작 확인

### Phase 5 완료 기준
- [x] `<html data-theme="dark">` 적용 후 기존 CSS 변수 색상 유지 확인
- [x] DaisyUI 변수 매핑 후 `--color-accent`, `--color-bg-primary` 등 변수 값 불변 확인
- [x] `<dialog>` 기반 모달 — ESC 키로 닫힘, 외부 클릭으로 닫힘 동작
- [x] `<dialog>.showModal()` 호출 시 스크롤 잠금 및 focus trap 동작
- [x] 탭바 `.tab.tab-active` 스타일이 기존 `.tab-item.active`와 동일하게 표시
- [x] 사이드바 메뉴 hover / active 상태 색상이 기존과 동일
- [ ] 탭 컨텍스트 메뉴가 `dropdown` 클래스로 올바른 위치에 표시 ← 별도 이슈 (`tabs_controller.js` 의존성)
- [x] 기존 `.app-modal-*` 레거시 화면(비 BaseCrudController 사용 화면)에서 스타일 깨지지 않음

---

## 13. 트러블슈팅 & 구현 변경 기록 (2026-02-28)

> 설계서 초안과 실제 구현 과정에서 발생한 문제들과 최종 해결 방법을 기록합니다.

---

### 13.1 라이브러리 로딩 방식 변경: ESM CDN → UMD Global Script

#### 문제

설계서 2.1절의 `importmap.rb` ESM CDN 방식으로 Flatpickr·Tom Select를 등록했을 때, Stimulus 컨트롤러가 동적 import(`import()`)로 로드되면 **연쇄 실패**가 발생했습니다.

```
TypeError: Failed to fetch dynamically imported module:
  http://localhost:3000/assets/controllers/flatpickr_controller-188b60b8.js
```

#### 원인 분석

1. Stimulus `controllers/index.js`의 `CONTROLLERS` 배열에서 컨트롤러를 `import(modulePath)`로 **동적** 로드
2. `flatpickr_controller.js`가 `import flatpickr from "flatpickr"` → CDN ESM 빌드 로드
3. CDN ESM 빌드(`flatpickr@4.6.13/dist/esm/index.js`) 내부에서 `./l10n/default.js` 등 **상대 경로 모듈**을 import
4. 브라우저의 importmap은 bare specifier(`flatpickr`)만 처리하고, 상대 경로 해석 불가 → 연쇄 실패
5. `fetch()`로 컨트롤러 파일을 요청하면 200이지만, `import()`는 **의존 체인** 전체가 해결되어야 성공하므로 실패

Tom Select도 동일 원인:
- `tom-select.complete.min.js`가 `@orchidjs/sifter`, `@orchidjs/unicode-variants`를 내부 import
- importmap에 추가해도 CDN ESM의 상대 경로 import가 끊어짐

#### 해결: UMD 빌드를 `<script>` 태그로 전역 로드

```erb
<%# app/views/layouts/application.html.erb — CSS 링크 이후, importmap_tags 이전 %>

<%# UMD 빌드: 단일 파일, 외부 의존성 없음. window.flatpickr / window.TomSelect 전역 등록 %>
<script src="https://cdn.jsdelivr.net/npm/flatpickr@4.6.13/dist/flatpickr.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/tom-select@2.4.3/dist/js/tom-select.complete.min.js"></script>
<%= javascript_importmap_tags %>
```

```ruby
# config/importmap.rb — 아래 핀 제거 (UMD 전역 사용으로 불필요)
# pin "flatpickr", ...              ← 제거
# pin "tom-select", ...             ← 제거
# pin "@orchidjs/sifter", ...       ← 제거
# pin "@orchidjs/unicode-variants", ... ← 제거
```

#### Stimulus 컨트롤러 수정

```js
// flatpickr_controller.js — import 제거 → window.flatpickr 사용
// import flatpickr from "flatpickr"  ← 이 줄 제거

connect() {
  const fp = window.flatpickr   // UMD 전역 참조
  if (!fp) { console.error("[flatpickr] not loaded"); return }
  // ...
}
```

```js
// tom_select_controller.js — import 제거 → window.TomSelect 사용
// import TomSelect from "tom-select"  ← 이 줄 제거

connect() {
  const TS = window.TomSelect   // UMD 전역 참조
  if (!TS) { console.error("[tom-select] not loaded"); return }
  // ...
}
```

> **원칙**: Stimulus 동적 import 체인 내에서 CDN ESM을 사용하려면 esm.sh 등 단일 번들 CDN이 필요합니다. 프로젝트에서는 단순성과 안정성을 위해 UMD 전역 방식을 선택합니다.

---

### 13.2 달력 아이콘 버튼 추가

#### 변경 이유

`_date_picker.html.erb`에 달력 아이콘이 없어 사용자가 날짜 입력 필드임을 직관적으로 인식하기 어렵습니다.

#### 구현

입력 필드를 `.date-picker-wrapper` div로 감싸고 오른쪽에 SVG 아이콘 버튼을 배치합니다.

**CSS (`application.css`)**

```css
/* ── Date picker: 오른쪽 아이콘 버튼 ── */
.date-picker-wrapper {
  position: relative;
  display: flex;
  align-items: stretch;
}

.date-picker-wrapper .form-grid-input {
  padding-right: 32px !important;   /* 아이콘 버튼 공간 확보 */
}

.date-picker-btn {
  position: absolute;
  right: 0;
  top: 0;
  bottom: 0;
  display: flex;
  align-items: center;
  padding: 0 8px;
  color: #6b7280;
  cursor: pointer;
  background: transparent;
  border: none;
  outline: none;
}

.date-picker-btn:hover  { color: #e6edf3; }
.date-picker-btn:disabled { opacity: 0.3; cursor: not-allowed; }
```

> **왜 Tailwind 클래스 대신 전용 CSS?**
> `.form-grid-input`에 `padding: 4px 10px !important`가 선언되어 있어 Tailwind `pr-*` 유틸리티가 무시됩니다. 전용 CSS 클래스로 `!important`를 덮어씁니다.

**ERB (`_date_picker.html.erb`)**

```erb
<%# data-controller를 래퍼 div로 이동, 버튼에 data-action 추가 %>
<div class="date-picker-wrapper"
     data-controller="flatpickr"
     data-flatpickr-mode-value="<%= fp_mode %>"
     data-flatpickr-format-value="Y-m-d">
  <%= f.text_field field[:field].to_sym,
        class: "form-grid-input",
        data: { resource_form_target: "input", action: "blur->resource-form#validateField" } %>
  <button type="button"
          class="date-picker-btn"
          tabindex="-1"
          data-action="click->flatpickr#open">
    <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24"
         fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
      <rect x="3" y="4" width="18" height="18" rx="2" ry="2"/>
      <line x1="16" y1="2" x2="16" y2="6"/>
      <line x1="8" y1="2" x2="8" y2="6"/>
      <line x1="3" y1="10" x2="21" y2="10"/>
    </svg>
  </button>
</div>
```

**Stimulus 컨트롤러 (`flatpickr_controller.js`)에 `open()` 액션 추가**

```js
// 달력 토글 버튼에서 호출 (data-action="click->flatpickr#open")
open() {
  this.#fp?.open()
}
```

---

### 13.3 `<dialog>` Top Layer 문제 — 달력이 모달 뒤에 숨는 현상

#### 문제

사용자 수정 팝업(`<dialog>`)에서 달력 아이콘을 클릭하면, flatpickr 달력이 열리지만 **모달 뒤에 숨어서 보이지 않는** 현상이 발생했습니다.

#### 원인: CSS Top Layer

HTML `<dialog>` 요소는 `showModal()` 호출 시 **CSS Top Layer**에 배치됩니다. Top Layer는 일반 문서 흐름과 별개의 렌더링 레이어로, `z-index`가 아무리 높아도 Top Layer 요소 위에 표시할 수 없습니다.

```
document body
├── 일반 DOM 요소 (z-index로 쌓임)
│   └── .flatpickr-calendar (z-index: 99999) ← body에 append됨
└── CSS Top Layer  ← showModal()로 올라옴
    └── <dialog>  ← 항상 일반 DOM 전체 위에 위치
```

`z-index: 99999 !important`를 추가해도 flatpickr 달력은 `<dialog>` 아래에 그려집니다.

#### 해결: `appendTo` 옵션으로 달력을 `<dialog>` 내부에 렌더링

flatpickr의 `appendTo` 옵션을 사용해 달력 요소를 `<dialog>` 내부에 직접 추가합니다. 달력이 Top Layer 내부에 위치하므로 모달 앞에 표시됩니다.

```js
// flatpickr_controller.js — connect() 내부
connect() {
  const config = { /* ... */ }

  // <dialog> 내부에서 사용 시: 달력을 dialog에 append해야 Top Layer 위에 표시됨
  const dialogEl = this.element.closest("dialog")
  if (dialogEl) {
    config.appendTo = dialogEl
  }

  const inputEl = this.element.tagName === "INPUT"
    ? this.element
    : this.element.querySelector("input:not([type='hidden'])")

  if (inputEl) {
    this.#fp = fp(inputEl, config)
  }
}
```

#### 왜 `overflow: hidden`이 문제가 되지 않는가

```
<dialog>  ← appendTo 대상. position: fixed; inset: 0; (풀스크린)
  ├── .app-modal-shell  ← overflow: hidden (달력과 무관)
  │   └── .app-modal-body  ← overflow-y: auto
  └── .flatpickr-calendar  ← dialog 직계 자식으로 추가됨 (overflow 클리핑 없음)
```

달력은 `.app-modal-shell` 바깥, `<dialog>` 바로 아래에 append되므로 `overflow: hidden`의 영향을 받지 않습니다. flatpickr는 입력 필드의 `getBoundingClientRect()`를 기준으로 달력 위치를 계산하므로 정확한 위치에 표시됩니다.

#### 최종 동작 확인

| 항목 | 결과 |
|------|------|
| 달력 아이콘 위치 | 입력 필드 **오른쪽** 끝 |
| 달력 표시 | 모달 **앞**에 정상 표시 |
| 날짜 선택 | 클릭 시 `YYYY-MM-DD` 형식으로 입력 |
| 한국어 로케일 | 월·요일 한국어 표시 확인 |
| 비활성화 필드 | 아이콘 버튼 `disabled` 처리 |
