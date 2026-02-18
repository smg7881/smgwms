# Tailwind CSS v4 마이그레이션 가이드

> 작업일: 2026-02-19
> 기존: 커스텀 CSS 5개 파일 (~1,850줄) → Tailwind CSS v4.1 + tailwindcss-rails v4.4

---

## 1. 개요

### 마이그레이션 목적
- 커스텀 CSS 유지보수 부담 제거
- Tailwind 유틸리티 클래스 기반 일관된 스타일링
- 다크 테마 디자인 토큰을 `@theme`으로 중앙 관리

### 기술 스택
| 항목 | 값 |
|---|---|
| Tailwind CSS | v4.1.18 (standalone CLI) |
| tailwindcss-rails | v4.4.0 |
| 에셋 파이프라인 | Propshaft |
| JS 번들러 | Importmap (Node.js 없음) |

---

## 2. 설치 및 설정

### 2.1 Gem 설치

```ruby
# Gemfile
gem "tailwindcss-rails", "~> 4.2"
```

```bash
bundle install
rails tailwindcss:install
```

설치 후 자동 생성되는 파일:
- `app/assets/tailwind/application.css` — Tailwind 입력 파일
- `app/assets/builds/tailwind.css` — 컴파일 출력
- `Procfile.dev` — `css: bin/rails tailwindcss:watch` 추가

### 2.2 레이아웃 stylesheet 변경

```erb
<%# 변경 전 (application.html.erb) %>
<%= stylesheet_link_tag :app, "data-turbo-track": "reload" %>
<%= stylesheet_link_tag "form_grid", "data-turbo-track": "reload" %>
<%= stylesheet_link_tag "search_form", "data-turbo-track": "reload" %>
<%= stylesheet_link_tag "resource_form", "data-turbo-track": "reload" %>
<%= stylesheet_link_tag "menu_modal", "data-turbo-track": "reload" %>

<%# 변경 후 %>
<%= stylesheet_link_tag "tailwind", "data-turbo-track": "reload" %>
```

### 2.3 개발 서버 실행

```bash
bin/dev  # foreman으로 rails server + tailwindcss:watch 동시 실행
```

---

## 3. Tailwind 설정 파일 구조

**파일**: `app/assets/tailwind/application.css`

### 3.1 Content paths (소스 스캔 경로)

```css
@import "tailwindcss";

@source "../../views";
@source "../../components";
@source "../../helpers";
@source "../../javascript";
```

### 3.2 @theme — 디자인 토큰

기존 CSS 변수를 Tailwind 토큰으로 매핑:

```css
@theme {
  /* 배경색 → bg-bg-primary, bg-bg-secondary 등 */
  --color-bg-primary: #0f1117;
  --color-bg-secondary: #161b22;
  --color-bg-tertiary: #1c2333;
  --color-bg-hover: #21262d;

  /* 텍스트색 → text-text-primary, text-text-secondary 등 */
  --color-text-primary: #e6edf3;
  --color-text-secondary: #8b949e;
  --color-text-muted: #484f58;

  /* 강조색 → text-accent, bg-accent, border-accent 등 */
  --color-accent: #58a6ff;
  --color-accent-hover: #79b8ff;
  --color-accent-green: #3fb950;
  --color-accent-cyan: #39d353;
  --color-accent-amber: #d29922;
  --color-accent-rose: #f85149;

  /* 테두리색 → border-border, border-border-muted */
  --color-border: #30363d;
  --color-border-muted: #21262d;

  /* 레이아웃 크기 → spacing-sidebar, spacing-header 등 */
  --spacing-sidebar: 240px;
  --spacing-header: 56px;
  --spacing-tab-bar: 44px;

  /* 24컬럼 그리드 → grid-cols-24 */
  --grid-template-columns-24: repeat(24, minmax(0, 1fr));

  /* 폰트 → font-sans, font-mono */
  --font-sans: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
  --font-mono: "SF Mono", Consolas, monospace;
}
```

### 3.3 @utility — 24컬럼 그리드 span

Tailwind 기본 `col-span`은 1~12까지만 지원. Ruby 헬퍼가 동적으로 생성하는 클래스를 위해 `@utility`로 정의:

```css
@utility col-span-24 { grid-column: span 24 / span 24; }
@utility col-span-8  { grid-column: span 8 / span 8; }
@utility col-span-6  { grid-column: span 6 / span 6; }
@utility col-span-4  { grid-column: span 4 / span 4; }
```

`@utility`로 정의하면 `sm:col-span-8`, `md:col-span-6` 등 반응형 변형이 자동 생성됨.

### 3.4 커스텀 CSS 영역

Tailwind 유틸리티로 표현할 수 없는 스타일은 동일 파일에 유지:

| 카테고리 | 클래스/셀렉터 | 이유 |
|---|---|---|
| 스크롤바 | `::-webkit-scrollbar` 등 | 의사 요소 |
| Turbo frame | `turbo-frame { display: contents }` | 요소 리셋 |
| Lucide 아이콘 | `.lucide-icon` | SVG 기본 스타일 |
| 사이드바 접힘 | `.sidebar-collapsed` | Stimulus JS 토글 |
| 네비게이션 | `.nav-item`, `.nav-tree-children` | Stimulus + Helper 참조 |
| 탭 바 | `.tab-item`, `.tab-item.active` | Stimulus JS 토글 |
| 폼 검증 | `.rf-field-error`, `.rf-error-msg` | Stimulus JS 토글 |
| 스위치 | `.rf-switch-*` | pseudo-element 기반 |
| AG Grid | `.ag-grid-link`, `.grid-action-btn` 등 | CDN 렌더러 클래스 |
| 로그인 배경 | `.login-bg` | radial-gradient |
| 날짜 입력 | `[type="date"]::-webkit-calendar-picker-indicator` | 의사 요소 |
| 구분선 | `.form-grid-divider` | ::before/::after |

### 3.5 버튼 컴포넌트 (@apply)

헬퍼, ViewComponent, AG Grid 렌더러 등 여러 곳에서 사용되므로 `@apply`로 정의:

```css
.btn {
  @apply inline-flex items-center gap-1.5 px-3.5 py-[7px] rounded-md border
         border-transparent cursor-pointer text-[13px] font-semibold no-underline font-sans;
  transition: background 0.15s, border-color 0.15s;
}
.btn-primary { @apply bg-accent text-white border-accent; }
.btn-secondary { @apply bg-bg-tertiary text-text-primary border-border; }
.btn-success { @apply bg-transparent text-accent-green border-accent-green; }
.btn-danger { @apply bg-transparent text-accent-rose border-accent-rose; }
.btn-sm { @apply px-2.5 py-1 text-xs; }
```

### 3.6 폼 input/select 컴포넌트 (@apply)

```css
.form-grid-input,
.form-grid-select {
  @apply w-full py-2 px-3 border border-border rounded-md bg-bg-primary text-text-primary;
  font-size: 0.95rem;
  transition: border-color 0.2s, box-shadow 0.2s;
}
.form-grid-input:focus,
.form-grid-select:focus {
  @apply outline-none border-accent;
  box-shadow: 0 0 0 2px rgba(88, 166, 255, 0.2);
}
```

---

## 4. 주요 변환 패턴

### 4.1 레이아웃 CSS 클래스 매핑

| 기존 클래스 | Tailwind 유틸리티 |
|---|---|
| `.app-layout` | `grid grid-cols-[var(--spacing-sidebar)_1fr] h-screen overflow-hidden transition-[grid-template-columns] duration-250` |
| `.main-area` | `flex flex-col h-screen overflow-hidden` |
| `.content-area` | `flex-1 overflow-y-auto p-6 bg-bg-primary` |
| `.sidebar` | `bg-bg-secondary border-r border-border flex flex-col h-screen overflow-y-auto overflow-x-hidden` |
| `.sidebar-logo` | `flex items-center gap-2.5 p-4 border-b border-border font-bold text-base text-text-primary` |
| `.main-header` | `h-[var(--spacing-header)] bg-bg-secondary border-b border-border flex items-center px-5 shrink-0` |
| `.page-header` | `flex items-center justify-between mb-6` |

### 4.2 폼 관련 클래스 매핑

| 기존 클래스 | Tailwind 유틸리티 |
|---|---|
| `.form-grid-wrapper` | `max-w-full overflow-x-hidden bg-bg-secondary border border-border rounded-lg p-4 mb-4` |
| `.form-grid-grid` | `grid grid-cols-24 gap-4 items-end min-w-0` |
| `.form-grid-field` | `flex flex-col gap-1 col-span-24 min-w-0` |
| `.form-grid-label` | `text-sm font-medium text-text-secondary` |
| `.form-grid-control` | `flex relative` |
| `.form-grid-buttons` | `flex justify-end gap-2 mt-2 col-[1/-1] min-w-0` |
| `.rf-required` | `text-accent-rose ml-0.5 font-semibold` |
| `.rf-help` | `text-xs text-text-muted mt-0.5` |

### 4.3 모달 클래스 매핑

| 기존 클래스 | Tailwind 유틸리티 |
|---|---|
| `.modal-overlay` | `fixed inset-0 bg-black/50 flex items-center justify-center z-[1000]` |
| `.modal-content` | `bg-bg-primary border border-border rounded-lg w-[480px] max-w-[calc(100vw-32px)] max-h-[90vh] flex flex-col overflow-hidden shadow-[0_4px_24px_rgba(0,0,0,0.15)]` |
| `.modal-header` | `flex justify-between items-center px-5 py-4 border-b border-border sticky top-0 z-[2] bg-bg-primary cursor-move` |
| `.modal-body` | `px-5 py-5 overflow-y-auto flex-1 min-h-0` |
| `.modal-footer` | `flex justify-end gap-2 px-5 py-3 border-t border-border sticky bottom-0 z-[2] bg-bg-primary` |

### 4.4 그리드 toolbar 매핑

| 기존 클래스 | Tailwind 유틸리티 |
|---|---|
| `.grid-toolbar` | `flex justify-end my-3` |
| `.grid-toolbar-buttons` | `flex gap-2` |

---

## 5. Ruby 헬퍼 변경

### SearchFormHelper — span 클래스 생성

**파일**: `app/helpers/search_form_helper.rb`

```ruby
# 변경 전
prefix_map = { "" => "form-grid-span", "s" => "form-grid-span-sm",
               "m" => "form-grid-span-md", "l" => "form-grid-span-lg" }

# 변경 후
prefix_map = { "" => "col-span", "s" => "sm:col-span",
               "m" => "md:col-span", "l" => "lg:col-span" }
```

**span 문자열 → CSS 클래스 변환 예시:**

| span 문자열 | 변경 전 | 변경 후 |
|---|---|---|
| `"24"` | `form-grid-span-24` | `col-span-24` |
| `"24 s:12 m:8"` | `form-grid-span-24 form-grid-span-sm-12 form-grid-span-md-8` | `col-span-24 sm:col-span-12 md:col-span-8` |

**cols 기반 기본값:**

| cols | 변경 전 | 변경 후 |
|---|---|---|
| 1 | `form-grid-span-24` | `col-span-24` |
| 2 | `form-grid-span-24 form-grid-span-sm-12` | `col-span-24 sm:col-span-12` |
| 3 | `form-grid-span-24 form-grid-span-sm-12 form-grid-span-md-8` | `col-span-24 sm:col-span-12 md:col-span-8` |
| 4 | `form-grid-span-24 form-grid-span-sm-12 form-grid-span-md-6` | `col-span-24 sm:col-span-12 md:col-span-6` |

---

## 6. ViewComponent 변경

### 6.1 SearchFormComponent

**파일**: `app/components/ui/search_form_component.rb`

```ruby
# wrapper_attrs 변경
# 변경 전
opts.merge(class: "form-grid-wrapper", ...)

# 변경 후
opts.merge(class: "max-w-full overflow-x-hidden bg-bg-secondary border border-border rounded-lg p-4 mb-4", ...)
```

### 6.2 ResourceFormComponent

**파일**: `app/components/ui/resource_form_component.rb`

```ruby
# wrapper_attrs 변경
# 변경 전
opts[:class] = ["form-grid-wrapper", "rf-wrapper", opts[:class]].compact.join(" ")

# 변경 후
opts[:class] = ["max-w-full overflow-x-hidden bg-bg-secondary border border-border rounded-lg p-5 mb-4", opts[:class]].compact.join(" ")
```

에러 요약 블록도 변경:
```erb
<%# 변경 전 %>
<div class="rf-errors" ...>

<%# 변경 후 %>
<div class="bg-accent-rose/10 border border-accent-rose rounded-md px-4 py-3 mb-4" ...>
```

### 6.3 ModalShellComponent

모든 CSS 클래스를 Tailwind 유틸리티로 인라인 교체. `modal-body` 클래스만 커스텀 스크롤바 스타일을 위해 유지.

### 6.4 GridToolbarComponent

`.grid-toolbar` → `flex justify-end my-3`, `.grid-toolbar-buttons` → `flex gap-2`

### 6.5 시스템 페이지 컴포넌트

- `dept`, `menus`, `users` — 변경 없음 (UI 컴포넌트만 렌더링)
- `code` — 듀얼 패널 레이아웃 클래스 변환: `.code-page-panels` → `grid grid-cols-2 gap-3 max-[1200px]:grid-cols-1`

---

## 7. Stimulus 컨트롤러 — 변경 없음

모든 동적 토글 클래스는 커스텀 CSS(`@apply` 포함)로 유지하여 **JS 파일 수정이 불필요**:

| 컨트롤러 | 토글 클래스 | 처리 방식 |
|---|---|---|
| `tabs_controller.js` | `.sidebar-collapsed`, `.active` | 커스텀 CSS 유지 |
| `sidebar_controller.js` | `.expanded`, `.open` | 커스텀 CSS 유지 |
| `resource_form_controller.js` | `.rf-field-error`, `.rf-error-msg` | 커스텀 CSS 유지 |
| `ag_grid/renderers.js` | `.grid-action-btn`, `.ag-grid-link` | 커스텀 CSS 유지 |

---

## 8. 삭제된 파일

| 파일 | 줄 수 | 내용 |
|---|---|---|
| `app/assets/stylesheets/application.css` | 897줄 | 레이아웃, 사이드바, 헤더, 탭, 버튼, 테이블, 로그인 |
| `app/assets/stylesheets/form_grid.css` | 206줄 | 24컬럼 그리드, input/select, 반응형 span |
| `app/assets/stylesheets/search_form.css` | 23줄 | 구분선 |
| `app/assets/stylesheets/resource_form.css` | 250줄 | 폼 검증, 스위치, 체크박스, 라디오, 사진 업로드 |
| `app/assets/stylesheets/menu_modal.css` | 185줄 | 모달, 그리드 액션 버튼, 툴바 |

---

## 9. 변경 파일 전체 목록

### 신규 (1)
- `app/assets/tailwind/application.css`

### 설정 (2)
- `Gemfile` — `tailwindcss-rails` 추가
- `Procfile.dev` — `css: bin/rails tailwindcss:watch` (자동 생성)

### 레이아웃 (2)
- `app/views/layouts/application.html.erb`
- `app/views/layouts/session.html.erb`

### 공유 파셜 (3)
- `app/views/shared/_sidebar.html.erb`
- `app/views/shared/_header.html.erb`
- `app/views/shared/_tab_bar.html.erb`

### 검색폼 파셜 (6)
- `app/views/shared/search_form/_buttons.html.erb`
- `app/views/shared/search_form/fields/_input.html.erb`
- `app/views/shared/search_form/fields/_select.html.erb`
- `app/views/shared/search_form/fields/_date_picker.html.erb`
- `app/views/shared/search_form/fields/_date_range.html.erb`
- `app/views/shared/search_form/fields/_popup.html.erb`

### 리소스폼 파셜 (8)
- `app/views/shared/resource_form/_buttons.html.erb`
- `app/views/shared/resource_form/fields/_input.html.erb`
- `app/views/shared/resource_form/fields/_number.html.erb`
- `app/views/shared/resource_form/fields/_select.html.erb`
- `app/views/shared/resource_form/fields/_date_picker.html.erb`
- `app/views/shared/resource_form/fields/_textarea.html.erb`
- `app/views/shared/resource_form/fields/_checkbox.html.erb`
- `app/views/shared/resource_form/fields/_radio.html.erb`
- `app/views/shared/resource_form/fields/_switch.html.erb`
- `app/views/shared/resource_form/fields/_photo.html.erb`

### Ruby 헬퍼 (1)
- `app/helpers/search_form_helper.rb`

### ViewComponent Ruby (2)
- `app/components/ui/search_form_component.rb`
- `app/components/ui/resource_form_component.rb`

### ViewComponent 템플릿 (4)
- `app/components/ui/search_form_component.html.erb`
- `app/components/ui/resource_form_component.html.erb`
- `app/components/ui/modal_shell_component.html.erb`
- `app/components/ui/grid_toolbar_component.html.erb`

### 시스템 페이지 (1)
- `app/components/system/code/page_component.html.erb`

### 페이지 뷰 (6)
- `app/views/sessions/new.html.erb`
- `app/views/dashboard/show.html.erb`
- `app/views/posts/index.html.erb`
- `app/views/posts/show.html.erb`
- `app/views/posts/new.html.erb`
- `app/views/posts/edit.html.erb`

### 테스트 (2)
- `test/components/ui/search_form_component_test.rb`
- `test/components/ui/resource_form_component_test.rb`

### 삭제 (5)
- `app/assets/stylesheets/application.css`
- `app/assets/stylesheets/form_grid.css`
- `app/assets/stylesheets/search_form.css`
- `app/assets/stylesheets/resource_form.css`
- `app/assets/stylesheets/menu_modal.css`

---

## 10. 새 컴포넌트 추가 시 가이드

### 10.1 새 색상/토큰 추가

`app/assets/tailwind/application.css`의 `@theme` 블록에 추가:

```css
@theme {
  --color-my-new-color: #ff0000;
}
```

→ `text-my-new-color`, `bg-my-new-color`, `border-my-new-color` 등 자동 사용 가능.

### 10.2 새 그리드 span 값 추가

`@utility`로 정의:

```css
@utility col-span-16 { grid-column: span 16 / span 16; }
```

### 10.3 Stimulus에서 토글할 클래스

동적으로 classList.add/remove하는 클래스는 Tailwind 스캐너가 감지하지 못함.
커스텀 CSS로 `app/assets/tailwind/application.css`에 정의:

```css
.my-active-state {
  @apply bg-accent text-white;
}
```

### 10.4 빌드 명령

```bash
# 1회 빌드
bin/rails tailwindcss:build

# watch 모드 (개발)
bin/rails tailwindcss:watch

# 프로덕션 빌드
bin/rails tailwindcss:build
bin/rails assets:precompile
```

---

## 11. 검증 체크리스트

- [x] `bin/rails tailwindcss:build` — 빌드 성공
- [x] `bin/rails test` — 72개 테스트 전체 통과 (0 failures)
- [ ] 로그인 페이지 UI 확인
- [ ] 사이드바 접기/펼치기 동작
- [ ] 탭 열기/닫기/활성화 동작
- [ ] 시스템 관리 화면 (부서/메뉴/사용자/코드) CRUD
- [ ] 검색폼 접기/펼치기 동작
- [ ] 리소스폼 유효성 검증 + 에러 표시
- [ ] 모달 드래그 동작
- [ ] 대시보드 stat 카드 + 데이터 테이블
- [ ] 게시물 CRUD (목록/상세/작성/수정)
- [ ] 반응형 레이아웃 (폼 그리드 breakpoint)
