# WMS 스타일 대시보드 메인화면 구현 정리

> **구현 날짜**: 2026-02-12
> **기술 스택**: Ruby 4.0.1 / Rails 8.1 / Importmap / Hotwire (Turbo + Stimulus) / SQLite3

---

## 1. 개요

기존의 `"Hello, Rails!"` 텍스트 수준의 메인 화면을 **탭 기반 WMS 스타일 대시보드**로 전환한 작업입니다.
참고 문서: `doc/RAILS_GUIDE_v2-6.md`

### 핵심 동작 원리

```
사이드바 메뉴 클릭
    ↓
Stimulus tabs#openTab
    ↓
POST /tabs  (fetch + CSRF)
    ↓
TabsController#create
  ├─ TabRegistry 검증 (화이트리스트)
  ├─ session[:open_tabs] 업데이트
  └─ Turbo Stream 응답
       ├─ turbo_stream.update("tab-bar")       → 탭바 내부 교체
       └─ turbo_stream.replace("main-content") → src 변경 → 브라우저 자동 로드
    ↓
각 뷰의 turbo_frame_tag("main-content") 응답
    ↓
✅ 전체 페이지 리로드 없이 탭바 + 본문 동시 갱신
```

---

## 2. 아키텍처 패턴

| 레이어 | 패턴 | 설명 |
|--------|------|------|
| 레이아웃 | **App Shell** | 사이드바·헤더·탭바는 고정, 본문만 교체 |
| 탭바 갱신 | **Turbo Stream `update`** | `<turbo-frame id="tab-bar">` 내부만 교체 (프레임 유지) |
| 본문 갱신 | **Turbo Stream `replace`** | 프레임→프레임 교체, `src` 변경으로 자동 로드 트리거 |
| JS 이벤트 | **Stimulus** | `tabs` 컨트롤러, `sidebar` 컨트롤러 |
| 메뉴 관리 | **TabRegistry** | 단일 진실 소스, 클라이언트 입력 불신뢰 |
| 상태 관리 | **Rails Session** | `open_tabs` 배열 + `active_tab` 문자열 |

---

## 3. 생성/수정 파일 목록

### 수정된 파일

| 파일 | 변경 내용 |
|------|-----------|
| `config/routes.rb` | `root "dashboard#show"`, `resources :tabs`, `resources :posts`, `resources :reports` |
| `app/controllers/application_controller.rb` | `ensure_tab_session` before_action 추가 |
| `app/views/layouts/application.html.erb` | App Shell 3층 구조 + `javascript_importmap_tags` |
| `app/assets/stylesheets/application.css` | 다크 테마 WMS 스타일 전면 교체 |

### 신규 생성 파일

| 파일 | 역할 |
|------|------|
| `config/importmap.rb` | Turbo/Stimulus/controllers 핀 설정 |
| `app/models/tab_registry.rb` | 메뉴 메타데이터 단일 진실 소스 |
| `app/controllers/dashboard_controller.rb` | 대시보드 통계 |
| `app/controllers/tabs_controller.rb` | 탭 CRUD (create/activate/destroy) |
| `app/controllers/posts_controller.rb` | 게시물 CRUD |
| `app/controllers/reports_controller.rb` | 월별 통계 |
| `app/helpers/sidebar_helper.rb` | `sidebar_menu_button` 헬퍼 |
| `app/views/shared/_sidebar.html.erb` | 사이드바 파셜 |
| `app/views/shared/_tab_bar.html.erb` | 탭바 파셜 |
| `app/views/shared/_header.html.erb` | 헤더/브레드크럼 파셜 |
| `app/views/dashboard/show.html.erb` | 대시보드 통계 화면 |
| `app/views/posts/index.html.erb` | 게시물 목록 |
| `app/views/posts/show.html.erb` | 게시물 상세 |
| `app/views/posts/new.html.erb` | 게시물 작성 |
| `app/views/posts/edit.html.erb` | 게시물 수정 |
| `app/views/posts/_form.html.erb` | 게시물 폼 파셜 |
| `app/views/reports/index.html.erb` | 월별 통계 화면 |
| `app/javascript/application.js` | Turbo + Stimulus 진입점 |
| `app/javascript/controllers/application.js` | Stimulus Application 초기화 |
| `app/javascript/controllers/index.js` | 컨트롤러 등록 |
| `app/javascript/controllers/sidebar_controller.js` | 사이드바 트리 토글 |
| `app/javascript/controllers/tabs_controller.js` | 탭 열기/활성화/닫기 |

---

## 4. 라우팅

```ruby
root "dashboard#show"

resources :tabs, only: [:create, :destroy], param: :tab_id do
  member { patch :activate }
end

resources :posts
resources :reports, only: [:index]

get "up" => "rails/health#show", as: :rails_health_check
```

생성되는 주요 라우트:

| HTTP | Path | Controller#Action | 역할 |
|------|------|-------------------|------|
| GET | `/` | `dashboard#show` | 대시보드 개요 |
| POST | `/tabs` | `tabs#create` | 탭 열기 |
| PATCH | `/tabs/:tab_id/activate` | `tabs#activate` | 탭 활성화 |
| DELETE | `/tabs/:tab_id` | `tabs#destroy` | 탭 닫기 |
| GET | `/posts` | `posts#index` | 게시물 목록 |
| GET | `/posts/new` | `posts#new` | 게시물 작성 |
| GET | `/reports` | `reports#index` | 통계 |

---

## 5. TabRegistry

`app/models/tab_registry.rb`
메뉴 항목을 **서버에서만** 관리하는 단일 진실 소스입니다.
클라이언트가 보낸 `label`, `url`은 무시하고 여기서 가져옵니다.

```ruby
ENTRIES = [
  Entry.new(id: "overview",   label: "개요",      icon: "📊", url: "/",          color_group: :primary),
  Entry.new(id: "posts-list", label: "게시물 목록", icon: "📋", url: "/posts",     color_group: :green),
  Entry.new(id: "posts-new",  label: "게시물 작성", icon: "✏️", url: "/posts/new", color_group: :cyan),
  Entry.new(id: "reports",    label: "통계",       icon: "📈", url: "/reports",   color_group: :amber),
]
```

제공 메서드: `find(id)`, `valid?(id)`, `url_for(id)`, `color_css(id)`

---

## 6. 세션 구조

`ApplicationController#ensure_tab_session` (모든 요청에서 실행)

```ruby
session[:open_tabs]  # Array — 열린 탭 목록
# 예: [{"id"=>"overview","label"=>"개요","url"=>"/"},
#      {"id"=>"posts-list","label"=>"게시물 목록","url"=>"/posts"}]

session[:active_tab] # String — 현재 활성 탭 id
# 예: "posts-list"
```

- `overview` 탭은 항상 첫 번째에 고정 (핀 고정, 닫기 불가)
- 세션이 꼬여도 `overview`가 없으면 자동 복원

---

## 7. 레이아웃 구조

```erb
<div class="app-layout" data-controller="tabs">   ← Stimulus tabs 스코프 (최상위)
  <aside class="sidebar" data-controller="sidebar"> ← Stimulus sidebar 스코프
    ...
  </aside>

  <main class="main-area">
    <header class="main-header">...</header>         ← 브레드크럼, 검색

    <turbo-frame id="tab-bar">                       ← update 대상
      <%= render "shared/tab_bar" %>
    </turbo-frame>

    <div class="content-area">
      <%= yield %>                                   ← 각 뷰의 turbo_frame_tag("main-content")
    </div>
  </main>
</div>
```

> **핵심 주의사항**: `data-controller="tabs"`는 반드시 `app-layout` (최상위)에 붙어야 합니다.
> 사이드바 안에만 두면 탭바의 `activateTab`/`closeTab` 이벤트가 컨트롤러를 찾지 못합니다.

---

## 8. Turbo Stream 응답 원리

```ruby
def render_tab_update
  active_id  = session[:active_tab]
  active_url = TabRegistry.url_for(active_id) || "/"

  render turbo_stream: [
    # (1) 탭바: 프레임은 유지하고 내부만 교체
    turbo_stream.update("tab-bar",
      partial: "shared/tab_bar",
      locals: { tabs: open_tabs, active: active_id }
    ),

    # (2) 본문: 프레임→프레임 교체 (src 변경 → 브라우저 자동 로드)
    turbo_stream.replace("main-content",
      helpers.turbo_frame_tag("main-content", src: active_url, loading: :eager) { ... }
    )
  ]
end
```

| 대상 | 방식 | 이유 |
|------|------|------|
| `tab-bar` | `update` | 프레임 태그 자체 유지, 내부만 교체 |
| `main-content` | `replace` | `src` 속성을 변경해야 자동 로드 트리거됨 |

---

## 9. 각 뷰의 필수 패턴

모든 본문 뷰는 반드시 `turbo_frame_tag "main-content"`로 감싸야 합니다.

```erb
<%= turbo_frame_tag "main-content" do %>
  <!-- 실제 콘텐츠 -->
<% end %>
```

이렇게 해야 `<turbo-frame id="main-content" src="/posts">` 요청에 대해
Turbo가 응답에서 해당 프레임만 추출해 렌더링합니다.

---

## 10. JavaScript 구조

```
app/javascript/
├── application.js                    # import turbo-rails + controllers
└── controllers/
    ├── application.js                # Stimulus.start()
    ├── index.js                      # 컨트롤러 등록
    ├── sidebar_controller.js         # toggleTree (트리 메뉴 열기/닫기)
    └── tabs_controller.js            # openTab / activateTab / closeTab
```

### tabs_controller.js 핵심 포인트

```javascript
import { Turbo } from "@hotwired/turbo-rails"  // ← 반드시 명시적 import

// 서버 응답 성공 후에만 UI 동기화
_turboStreamRequest(method, url, body)
  .then(html => Turbo.renderStreamMessage(html))
  .then(() => this._syncUI(tabId))   // 사이드바 active + breadcrumb

// 탭 닫기 후: DOM에서 새 active 탭 역참조
_syncUIFromActiveTab() {
  queueMicrotask(() => {             // ← Turbo DOM 갱신 완료 후 읽기
    const activeTab = document.querySelector(".tab-item.active")
    this._syncUI(activeTab?.dataset?.tabId)
  })
}
```

---

## 11. CSS 주요 변수 (다크 테마)

```css
:root {
  --bg-primary:    #0f1117;   /* 본문 배경 */
  --bg-secondary:  #161b22;   /* 사이드바, 카드 배경 */
  --bg-tertiary:   #1c2333;   /* 테이블 헤더 */
  --text-primary:  #e6edf3;
  --text-secondary: #8b949e;
  --text-muted:    #484f58;
  --accent:        #58a6ff;   /* 기본 포인트 (파란색) */
  --accent-green:  #3fb950;
  --accent-cyan:   #39d353;
  --accent-amber:  #d29922;
  --accent-rose:   #f85149;
  --sidebar-w:     240px;
  --header-h:      56px;
  --tab-bar-h:     44px;
}
```

---

## 12. 알려진 설계 결정 및 트레이드오프

| 결정 | 선택 | 이유 |
|------|------|------|
| TabRegistry 위치 | `app/models/tab_registry.rb` | Rails 자동로딩, 검증 로직 서버 집중 |
| 세션 저장소 | Rails Session (쿠키) | MVP 단계, Redis 전환 1줄 변경으로 가능 |
| `tab-id` 데이터 키 | 문자열 `"tab-id"` | `data: { tab_id: }` → `data-tab_id` 불일치 방지 |
| `data-controller="tabs"` | `app-layout` div | Stimulus 스코프: 탭바/사이드바 모두 접근 |
| 본문 Turbo 방식 | `replace` (프레임→프레임) | `src` 변경으로 자동 로드 트리거 |
| ES private field | `_method` prefix | 구형 브라우저 호환성 |

---

## 13. 검증 방법

```bash
# 서버 실행
bin/rails server

# 접속 후 확인 항목:
# 1. http://localhost:3000 → 대시보드 통계 표시
# 2. 사이드바 "게시물 관리" 클릭 → 트리 펼쳐짐
# 3. "게시물 목록" 클릭 → 탭 열림, 본문 교체 (URL 변경 없음)
# 4. 탭 ✕ 버튼 → 탭 닫힘, 이전 탭으로 복귀
# 5. overview 탭 → 닫기 버튼 없음 확인
# 6. breadcrumb → 활성 탭 이름으로 갱신 확인

# 테스트
bin/rails db:test:prepare test
```

---

## 14. 향후 확장 포인트

- **세션 → Redis 전환**: `config/initializers/session_store.rb` 1줄 변경
- **새 메뉴 추가**: `TabRegistry::ENTRIES`에 항목 추가 + 해당 컨트롤러/뷰 생성 (TabsController 수정 불필요)
- **모달 지원**: `turbo_frame_tag "modal"`로 별도 레이어 추가 가능
- **페이지네이션**: `turbo_frame_tag "main-content"` 안에서 동작하므로 추가만 하면 됨
- **인증 추가**: `ApplicationController`에 `before_action :authenticate_user!` 추가
