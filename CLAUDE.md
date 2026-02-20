# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 언어 규칙

모든 답변은 반드시 한국어로 작성합니다.

## 프로젝트 개요

Ruby 4.0.1 / Rails 8.1 기반 WMS(창고관리시스템) 관리자 애플리케이션입니다. SQLite3 데이터베이스, Propshaft + Importmap + Hotwire(Turbo/Stimulus) 프론트엔드 스택을 사용합니다. UI는 한국어입니다.

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
```

## 아키텍처

### 라우팅

- `/` → `DashboardController#show`
- `/session` → `SessionsController` (로그인/로그아웃)
- `/posts` → `PostsController` (CRUD)
- `/reports` → `ReportsController#index`
- `/tabs` → `TabsController` + `Tabs::ActivationsController` (탭 네비게이션)
- `/system/dept` → `System::DeptController` (부서 관리, JSON API)
- `/system/menus` → `System::MenusController` (메뉴 관리, JSON API)
- `/system/users` → `System::UsersController` (사용자 관리, multipart)

### 인증

`Authentication` concern (`app/controllers/concerns/authentication.rb`)이 cookie 기반 세션 인증을 처리합니다. `Session` 모델이 토큰을 관리하고, `Current` (`ActiveSupport::CurrentAttributes`)가 요청 스레드 로컬 컨텍스트를 제공합니다.

### 탭 시스템

`TabRegistry` (plain Ruby, `app/models/tab_registry.rb`)는 `Data.define`으로 불변 Entry를 정의합니다. 탭 상태는 `session[:open_tabs]`와 `session[:active_tab]`으로 관리되며, `TabsController`와 `Tabs::ActivationsController`가 Turbo Stream으로 탭 바·사이드바·콘텐츠를 동시 업데이트합니다.

### 시스템 관리 모듈 패턴 (Dept, Menus, Users)

각 관리 화면은 동일한 3-레이어 구조를 따릅니다:

1. **ViewComponent 페이지** (`app/components/system/<module>/page_component.rb`) — `System::BasePageComponent` 상속, 검색 필드, 그리드 컬럼, 폼 필드, 모달을 하나의 컴포넌트에서 정의
2. **Stimulus CRUD 컨트롤러** (`app/javascript/controllers/<module>_crud_controller.js`) — `BaseCrudController` 상속, static config(`resourceName`, `deleteConfirmKey`, `entityLabel`) 선언, 화면별 이벤트 핸들러
3. **Rails 컨트롤러** (`app/controllers/system/<module>_controller.rb`) — JSON 응답, 검색 파라미터 처리

새 시스템 관리 화면을 추가할 때 이 패턴을 복제합니다.

### 재사용 가능 UI

| 종류 | 이름 | Stimulus 컨트롤러 | 용도 |
|---|---|---|---|
| 헬퍼 | `ag_grid_tag` | `ag_grid_controller` | AG Grid (CDN v35.1.0, 한국어 로케일) |
| 헬퍼 | `search_form_tag` | `search_form_controller` | 검색 폼 (접기/펼치기, 24컬럼 그리드) |
| 헬퍼 | `resource_form_tag` | `resource_form_controller` | 리소스 폼 (유효성 검증, 의존 필드 연동) |
| ViewComponent | `Ui::ModalShellComponent` | (BaseCrudController) | 드래그 가능한 모달 |
| ViewComponent | `Ui::GridToolbarComponent` | — | 그리드 상단 툴바 |

### AG Grid 커스텀 렌더러

`app/javascript/controllers/ag_grid/renderers.js`의 `RENDERER_REGISTRY`에 트리 렌더러, 상태 뱃지, 액션 버튼 등이 정의되어 있습니다. 새 렌더러는 여기에 추가합니다.

### Stimulus 컨트롤러 구조

- `BaseCrudController` (`base_crud_controller.js`) — 모달, 드래그, JSON fetch, 이벤트 관리, `handleDelete`/`save`/`submit` 공통 로직
- 도메인 컨트롤러(`dept_crud`, `menu_crud`, `user_crud`)는 `BaseCrudController`를 상속하고 static config(`resourceName`, `deleteConfirmKey`, `entityLabel`)로 차이점만 선언
- `tabs_controller` — Turbo Stream 기반 탭 열기/닫기/활성화 + 사이드바 동기화
- `lucide_controller` — Turbo 네비게이션 시 아이콘 재렌더링

### 모델

- `User` — `adm_users` 테이블, `has_secure_password`, Active Storage 사진 첨부
- `AdmDept` — `dept_code` 문자열 PK, 자기참조 트리 구조, `tree_ordered` DFS
- `AdmMenu` — 최대 3레벨 메뉴 트리, `sidebar_tree` 헬퍼, `tree_ordered` DFS
- `Post` — 기본 CRUD 예시 모델
- `TabRegistry` — ActiveRecord 아님, 정적 탭 정의

### 데이터베이스

- SQLite3, 환경별 분리 (`storage/` 디렉토리)
- 프로덕션: `solid_cache`, `solid_queue`, `solid_cable`용 DB 각각 분리

### 배포

- Kamal (`config/deploy.yml`) + Docker + Puma + Thruster

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
