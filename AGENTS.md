# Repository Guidelines

## Project Structure & Module Organization
This is a Ruby 4.0.1 / Rails 8.1 app. Core code lives in `app/` (controllers, models, views, jobs, mailers). Configuration is in `config/`, database schema and migrations in `db/`, and tests in `test/`. Frontend assets are split between `app/assets/` (CSS via Propshaft) and `app/javascript/` (Hotwire/Stimulus). Public/static files live in `public/`. SQLite database files are stored under `storage/`. Docs and templates live in `doc/` (see `doc/starter_template/README.md` for patterns).

## Build, Test, and Development Commands
- `bin/rails server`: run the local dev server.
- `bin/rails db:migrate`: apply database migrations.
- `bin/rails db:test:prepare test`: run the full test suite.
- `bin/rails test test/models/post_test.rb`: run a single test file.
- `bin/rails test:system`: run system tests.
- `bin/rubocop`: lint Ruby code (Rails Omakase rules).
- `bin/brakeman --no-pager`: static security scan for Ruby/Rails.
- `bin/bundler-audit`: scan gem vulnerabilities.
- `bin/importmap audit`: audit JS dependencies.

## Coding Style & Naming Conventions
Follow `STYLE.md` and `STYLE_GUIDE.md`. Use 2-space indentation for Ruby. Prefer expanded conditionals over guard clauses except for early returns at the top of a method. Order methods as: class methods, public (with `initialize` at the top), then `private`. Indent under visibility modifiers and do not add a blank line after `private`. Favor thin controllers calling rich model APIs; avoid service objects unless justified. Name async methods with `_later` and sync counterparts with `_now`.

## Testing Guidelines
Tests are Minitest-based under `test/` with fixtures in `test/fixtures/`. Model, controller, and system tests should follow Rails naming conventions (e.g., `test/models/post_test.rb`). Use `bin/rails test` for unit/integration and `bin/rails test:system` for browser/system coverage. No explicit coverage threshold is configured.

## Commit & Pull Request Guidelines
Git history is minimal and does not show a formal commit style. Use concise, imperative subjects (e.g., "Add reports filter") and keep commits focused. For PRs, include a clear description, steps to verify, linked issues (if any), and screenshots or GIFs for UI changes. Ensure linting and security scans pass before requesting review.

## Security & Deployment Notes
Security tooling is part of the workflow (`brakeman`, `bundler-audit`, `importmap audit`). Deployment is containerized with Docker and Kamal (`config/deploy.yml`); keep changes compatible with that setup.
# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 언어 규칙

모든 답변은 반드시 한국어로 작성합니다.

## 프로젝트 개요

Ruby / Rails 8.1 기반 WMS(창고관리시스템) 관리자 애플리케이션입니다. SQLite3 데이터베이스, Propshaft + Importmap + Hotwire(Turbo/Stimulus) 프론트엔드 스택을 사용합니다. UI는 한국어입니다.

## 주요 명령어

```bash
# 개발 서버 실행
bin/rails server

# 데이터베이스 마이그레이션
bin/rails db:migrate

# 테스트 실행 (전체)
bin/rails db:test:prepare test

# 단일 테스트 파일 실행
bin/rails test test/models/post_test.rb

# 시스템 테스트
bin/rails db:test:prepare test:system

# 린트 (RuboCop - Rails Omakase 스타일)
bin/rubocop

# 보안 취약점 스캔
bin/brakeman --no-pager       # Ruby/Rails 정적 분석
bin/bundler-audit              # 젬 보안 취약점
bin/importmap audit            # JavaScript 의존성 취약점

# Rails 콘솔
bin/rails console

# Tailwind CSS 재빌드 방법
bin/rails tailwindcss:build
```

> **Windows 환경 주의:** `bin/rails` 실행 시 파일 내용이 출력되는 경우 `ruby`를 명시적으로 앞에 붙여 실행합니다.
>
> ```bash
> ruby bin/rails server
> ruby bin/rails db:migrate
> ruby bin/rails tailwindcss:build
> ruby bin/rails console
> # 또는
> bundle exec rails tailwindcss:build
> ```

## 아키텍처

### 네임스페이스 구조

| 네임스페이스 | 용도 |
|---|---|
| `system/` | 시스템 관리 (사용자, 메뉴, 부서, 코드, 권한) |
| `std/` | 기준정보 (거래처, 품목, 국가, 환율, 계약 등) |
| `wm/` | 창고관리 (작업장, 구역, 로케이션, 입고, 재고) |
| `om/` | 오더관리 (수주, 발주, 주문처리, 배송지시) |

### 라우팅

- `/` → `DashboardController#show`
- `/session` → `SessionsController` (로그인/로그아웃)
- `/tabs` → `TabsController` + `Tabs::ActivationsController` (탭 네비게이션)
- `/search_popups/:type` → `SearchPopupsController#show` (팝업 검색, type: workplace/customer 등)
- `/system/*` → System 네임스페이스 (JSON API + multipart)
- `/std/*` → Std 네임스페이스 (JSON API)
- `/wm/*` → Wm 네임스페이스 (JSON API)
- `/om/*` → Om 네임스페이스 (JSON API)

### 인증 및 권한

- `Authentication` concern — cookie 기반 세션 인증, `Session` 모델이 토큰 관리
- `Current` (`ActiveSupport::CurrentAttributes`) — `Current.user`, `Current.session` 스레드 로컬 컨텍스트
- `admin?` — `Current.user.role_cd == "ADMIN"` (ApplicationController 헬퍼)
- `AdmUserMenuPermission` — 메뉴별 접근 권한 테이블. 각 네임스페이스 BaseController의 `require_menu_permission!`이 검사
- 각 하위 컨트롤러는 `menu_code_for_permission`을 반드시 구현해야 함

### 탭 시스템

`TabRegistry` (plain Ruby, `app/models/tab_registry.rb`)는 `Data.define`으로 불변 Entry를 정의합니다. 탭 상태는 `session[:open_tabs]`와 `session[:active_tab]`으로 관리되며, `TabsController`와 `Tabs::ActivationsController`가 Turbo Stream으로 탭 바·사이드바·콘텐츠를 동시 업데이트합니다.

### 화면 구현 패턴 (3-레이어)

모든 관리 화면은 동일한 3-레이어 구조를 따릅니다:

1. **ViewComponent 페이지** (`app/components/<ns>/<module>/page_component.rb`)
   - `<Ns>::BasePageComponent` 상속 → `BasePageComponent` 상속
   - `collection_path`, `member_path` 구현 필수
   - `search_fields`, `grid_columns`, `grid_url` 등 화면 설정 선언
   - `common_code_options("숫자코드")` / `common_code_values("숫자코드")` — 공통코드 조회
   - `record_options(Model, code_field:, name_field:)` — 모델 기반 셀렉트 옵션

2. **Stimulus 그리드 컨트롤러** (`app/javascript/controllers/<ns>_<module>_grid_controller.js`)
   - `BaseGridController` 상속
   - **단일 그리드**: `configureManager()` 오버라이드 → `GridCrudManager` config 반환
   - **다중 그리드(마스터-디테일)**: `gridRoles()` 오버라이드 → role별 target·manager·parentGrid·detailLoader 선언, `onAllGridsReady()` 구현
   - `postAction(url, body, { confirmMessage, onSuccess })` — 공통 POST 처리

3. **Rails 컨트롤러** (`app/controllers/<ns>/<module>_controller.rb`)
   - `<Ns>::BaseController` 상속
   - `index`: HTML/JSON 분기, JSON은 scope → map → render json
   - 일괄저장: `post :batch_save, on: :collection` → operations 배열 처리
   - 복합 트랜잭션 액션: member POST (save_gr, confirm, cancel 등)
   - 검색: `params.fetch(:q, {}).permit(...)` 패턴, 조건별 `if field.present?` 체인

### GridCrudManager 설정 스키마

```js
configureManager() {
  return {
    pkFields: ["code"],           // PK 필드 배열
    fields: { code: "trimUpper", name: "trim", qty: "number" },  // 정규화 규칙
    defaultRow: { use_yn: "Y" },  // 신규행 기본값
    blankCheckFields: ["code"],   // 빈 행 판별 필드
    comparableFields: ["name", "use_yn"],  // 변경 감지 대상 필드
    firstEditCol: "code",         // 신규행 포커스 컬럼
    // --- 프론트 Validation (선택) ---
    validationRules: {
      requiredFields: ["code", "name"],   // 단순 필수값
      fieldRules: {
        bizman_no: [{ type: "pattern", pattern: /^\d{10}$/, message: "사업자번호는 10자리 숫자입니다." }],
        use_yn: [{ type: "enum", values: ["Y", "N"] }],
        email: [{ type: "pattern", pattern: /^[^@]+@[^@]+$/, message: "이메일 형식이 올바르지 않습니다." }]
      },
      rowRules: [
        ({ row }) => row.end_date && row.start_date > row.end_date
          ? { field: "end_date", message: "종료일은 시작일 이후여야 합니다." }
          : null
      ]
    }
  }
}
```

`validationRules`가 선언된 manager는 `saveRowsWith()` 호출 시 저장 API 전에 자동 검증됩니다. 실패 시 첫 오류 셀로 포커스가 이동하고, 컨트롤러에 `showValidationErrors()` / `clearValidationErrors()`가 구현되어 있으면 인라인 오류 UI가 렌더링됩니다.

### 다중 그리드(마스터-디테일) gridRoles 패턴

```js
gridRoles() {
  return {
    master: {
      target: "masterGrid",
      manager: "configureManager",  // 문자열로 메서드명 참조
      masterKeyField: "gr_prar_no", // 중복 디스패치 방지 키
      isMaster: true                // 명시적 마스터 선언 (parentGrid 없어도)
    },
    detail: {
      target: "detailGrid",
      parentGrid: "master",         // 마스터 행 변경 시 자동 로드
      detailLoader: async (rowData) => { /* fetch and return rows array */ }
    }
  }
}
```

### 재사용 가능 UI

| 종류 | 이름 | Stimulus 컨트롤러 | 용도 |
|---|---|---|---|
| ViewComponent | `Ui::AgGridComponent` | `ag_grid_controller` | AG Grid (CDN v35.1.0, 한국어 로케일) |
| ViewComponent | `Ui::SearchFormComponent` | `search_form_controller` | 검색 폼 (접기/펼치기, 24컬럼 그리드) |
| ViewComponent | `Ui::ResourceFormComponent` | `resource_form_controller` | 리소스 폼 (유효성 검증, 의존 필드 연동) |
| ViewComponent | `Ui::ModalShellComponent` | — | 드래그 가능한 모달 |
| ViewComponent | `Ui::GridToolbarComponent` | — | 그리드 상단 툴바 |
| ViewComponent | `Ui::GridActionsComponent` | — | 그리드 액션 버튼 모음 |

### UI 컴포넌트 / 라이브러리

#### CDN 로드 순서 (`application.html.erb`)
Tom Select CSS → Flatpickr CSS → DaisyUI CSS → Tailwind CSS → Flatpickr JS → Tom Select JS 순서로 로드됩니다. 라이브러리 버전: Tom Select 2.4.3, Flatpickr 4.6.13, DaisyUI v5.

#### Toast 알림 / Confirm 모달 (`app/javascript/components/ui/alert.js`)

브라우저 기본 `alert()`·`confirm()` 대신 이 모듈을 사용합니다.

```js
import { showAlert, confirmAction } from "components/ui/alert"

showAlert("저장되었습니다.")                          // info 타입 기본
showAlert("오류", "필수값이 없습니다.", "error")      // title + message + type
// type: "success" | "error" | "warning" | "info"
// 우하단 Toast, 3초 자동소멸

const ok = await confirmAction("삭제하시겠습니까?")  // Promise<boolean>
const ok = await confirmAction("제목", "내용")        // title + message
// 커스텀 모달 (ESC·배경클릭 → false, 확인 → true)
```

#### Flatpickr — 날짜 피커 (`flatpickr_controller.js`)

`window.flatpickr`로 전역 로드됩니다. `<dialog>` 내부에서는 `appendTo: dialogEl`이 자동 적용됩니다.

```erb
<%# 단일 날짜 %>
<div data-controller="flatpickr">
  <input class="form-grid-input" type="text">
</div>

<%# 날짜 범위 (from/to hidden 연동) %>
<div data-controller="flatpickr" data-flatpickr-mode-value="range">
  <input class="form-grid-input" type="text">
  <input type="hidden" data-flatpickr-target="from" name="q[date_from]">
  <input type="hidden" data-flatpickr-target="to"   name="q[date_to]">
</div>

<%# 날짜+시간 %>
<div data-controller="flatpickr" data-flatpickr-mode-value="datetime">
  <input class="form-grid-input" type="text">
</div>
```

Values: `mode` ("date"|"datetime"|"range"), `format` (기본 "Y-m-d"), `min`, `max`.
달력 토글 버튼은 `data-action="click->flatpickr#open"`으로 연결합니다.
CSS: `.date-picker-wrapper` + `.date-picker-btn`으로 래핑하면 오른쪽 아이콘 버튼 스타일이 적용됩니다.

#### Tom Select — 향상된 Select (`tom_select_controller.js`)

`window.TomSelect`으로 전역 로드됩니다. Turbo 캐시 전 자동 정리, `overflow:hidden` 컨테이너에서 `fixed` 포지셔닝으로 드롭다운 표시.

```erb
<%# 검색 가능 단일 선택 (기본) %>
<select data-controller="tom-select" class="form-grid-select">
  <option value="">전체</option>
  ...
</select>

<%# 검색 비활성화 %>
<select data-controller="tom-select" data-tom-select-searchable-value="false">

<%# 다중 선택 (remove_button 플러그인 자동 포함) %>
<select data-controller="tom-select" data-tom-select-multi-value="true">
```

Values: `searchable` (기본 true), `multi` (기본 false), `placeholder`.
유효성 오류 시 `.ts-wrapper`에 `.rf-field-error` 클래스를 추가하면 빨간 테두리가 적용됩니다.

#### Toggle Switch (`.rf-switch`)

`resource_form_controller`와 함께 사용합니다.

```erb
<label class="rf-switch">
  <input type="checkbox" class="rf-switch-input" name="resource[active]" value="1">
  <span class="rf-switch-slider"></span>
</label>
```

CSS 클래스: `.rf-switch` (wrapper) → `.rf-switch-input` (숨김 checkbox) → `.rf-switch-slider` (시각적 트랙+핸들). 체크 시 accent 색상, disabled 시 opacity 0.5.

#### Input 아이콘 prefix (`.form-grid-input-wrapper`)

`resource_form` 필드 정의에 `icon:` 키를 추가하면 자동으로 prefix 아이콘이 렌더링됩니다.

```ruby
# page_component.rb의 form_fields 정의
{ field: "bzac_nm", label: "거래처명", icon: "building-2" }
```

내부적으로 `_input.html.erb`가 `form-grid-input-wrapper` + `form-grid-input-icon`으로 래핑합니다. 아이콘은 `lucide_icon(field[:icon])` 헬퍼로 렌더링됩니다.

#### DaisyUI v5 통합

`data-theme="dark"` 속성이 `<html>` 태그에 설정되어 있습니다. DaisyUI CSS 변수가 프로젝트 디자인 토큰(`--color-bg-primary` 등)에 맞게 오버라이드되었습니다.

| DaisyUI 클래스 | 사용처 | 오버라이드 |
|---|---|---|
| `.tab` / `.tab-active` | 화면 내부 탭 전환 | `.tab-item`과 동일한 스타일로 맞춤 |
| `.menu` / `ul.menu` | 사이드바 네비게이션 | padding·border-radius 제거, `.nav-item` 스타일 유지 |
| `.dropdown-content.menu` | 헤더 드롭다운 | 다크 배경 그라디언트 + border 오버라이드 |

DaisyUI 모달은 `dialog.app-modal-dialog` + `::backdrop`으로 구현합니다 (기존 `.app-modal-overlay` div 방식 대신).

### AG Grid 커스텀 렌더러

`app/javascript/controllers/ag_grid/renderers.js`의 `RENDERER_REGISTRY`에 트리 렌더러, 상태 뱃지, 액션 버튼 등이 정의되어 있습니다. 새 렌더러는 여기에 추가합니다.

### Stimulus 컨트롤러 구조

- `BaseGridController` (`base_grid_controller.js`) — 단일/다중 그리드 모드, GridCrudManager 연결, 저장/삭제/행추가 공통 로직. `ModalMixin` + `ExcelDownloadable` mixin을 `Object.assign`으로 합성
- `GridCrudManager` (`grid/grid_crud_manager.js`) — 단일 AG Grid의 CRUD 상태(신규/수정/삭제) 추적, 배치 operations 빌드, `validateRows()` / `focusValidationError()` / `formatValidationSummary()` 공통 Validation 엔진 포함
- `ModalMixin` (`concerns/modal_mixin.js`) — 모달 열기/닫기/드래그, JSON 폼 페이로드 빌드, `handleDelete`/`save`/`submit` 공통 핸들러. 모달 CRUD 화면(system/* 등)에서 사용
- `ExcelDownloadable` (`concerns/excel_downloadable.js`) — 엑셀 업로드(`openExcelImport`, `submitExcelImport`) / 이력 조회(`openImportHistory`) 믹스인
- `grid_actions_controller` — `Ui::GridActionsComponent`와 연동. `data-grid-actions-grid-id-value`로 대상 그리드를 역탐색하여 필터초기화·컬럼저장/초기화·엑셀다운을 `ag_grid_controller`에 위임
- `ag_grid_controller` — AG Grid 생성/제어 메인 컨트롤러. `saveColumnState(gridId)` / `resetColumnState(gridId)` / `exportExcel(gridId)` / `clearFilter()` / `refresh()` 제공
- `tabs_controller` — Turbo Stream 기반 탭 열기/닫기/활성화 + 사이드바 동기화
- `search_form_controller` / `resource_form_controller` — 검색/폼 로직
- `search_popup_controller` / `search_popup_grid_controller` — 공통 팝업 검색 (작업장, 거래처 등)

### 모델

- `User` — `adm_users` 테이블, `has_secure_password`, Active Storage 사진 첨부, `role_cd` (ADMIN 등)
- `AdmDept` — `dept_code` 문자열 PK, 자기참조 트리 구조, `tree_ordered` DFS
- `AdmMenu` — 최대 3레벨 메뉴 트리, `sidebar_tree` 헬퍼, `tree_ordered` DFS, `parent_cd` 사용
- `AdmCodeHeader` / `AdmCodeDetail` — 공통 코드, `select_options_for(code)` / `select_values_for(code)` 클래스 메서드
- `AdmUserMenuPermission` — 사용자-메뉴 권한, `active` 스코프
- WM 모델: `Wm::GrPrar`(입고예정), `Wm::StockAttr`(재고속성), `Wm::StockAttrQty/LocQty`(재고수량) 등 — `upsert_qty` 패턴
- 감사필드: `create_by`, `create_time`, `update_by`, `update_time` — `Current.user` 기반
- 시퀀스 채번: `Time.current.strftime + rand()` 패턴 (SQLite3 시퀀스 미지원)

### 데이터베이스

- SQLite3, 환경별 분리 (`storage/` 디렉토리)
- 프로덕션: `solid_cache`, `solid_queue`, `solid_cable`용 DB 각각 분리

### 배포

Kamal (`config/deploy.yml`) + Docker + Puma + Thruster

### CI (GitHub Actions)

PR/`master` 푸시 시: `scan_ruby`, `scan_js`, `lint`, `test`, `system-test`

## 코딩 스타일 핵심 규칙

전체 규칙은 `STYLE.md`와 `STYLE_GUIDE.md`를 참조합니다.

### guard clause 대신 expanded conditional

```ruby
# Bad
def todos_for_new_group
  return [] unless ids
  find(ids)
end

# Good
def todos_for_new_group
  if ids
    find(ids)
  else
    []
  end
end
```

예외: 메서드 상단의 짧은 early return은 허용됩니다.

### private 들여쓰기

```ruby
class Foo
  def bar; end

  private
    def baz; end
end
```

### 커스텀 액션 대신 새 리소스

```ruby
# Bad
resources :cards do
  post :close
end

# Good
resources :cards do
  scope module: :cards do
    resource :closure
  end
end
```

### 얇은 컨트롤러 + 풍부한 도메인 모델

서비스 객체를 만들지 않습니다. 복잡한 로직은 모델 메서드로 표현합니다.

### 백그라운드 잡 명명

비동기: `_later`, 동기: `_now` 접미사.

### 메서드 순서

class methods → public (initialize 우선) → private. 호출 순서대로 배치합니다.

### Stimulus 컨트롤러 컨벤션

`#` 접두사로 private 필드 표시. 순서: lifecycle → actions → private.

## 개발 템플릿 참조 (필수)

새 기능 구현이나 구조 설계 시 `doc/starter_template/README.md`의 패턴과 컨벤션을 따릅니다.
