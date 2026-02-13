# Rails 8 + Hotwire WMS 대시보드 — 완성본 가이드

> **핵심 패턴**: App Shell(고정) + Turbo Stream(탭바 갱신) + Turbo Frame `src`(본문 로딩)
>
> 사이드바 클릭 → `POST /tabs` → Turbo Stream으로 탭바 `update` + `main-content`에 `src` 주입 → 브라우저가 해당 URL을 Turbo Frame으로 자동 로드

---

## 아키텍처 개요

```
app/
├── controllers/
│   ├── dashboard_controller.rb          # GET /  (개요 패널)
│   ├── tabs_controller.rb              # POST/DELETE/PATCH (탭 CRUD)
│   ├── inbound/
│   │   ├── orders_controller.rb        # GET /inbound/orders
│   │   ├── inspections_controller.rb
│   │   └── putaways_controller.rb
│   ├── outbound/
│   │   ├── orders_controller.rb
│   │   ├── pickings_controller.rb
│   │   ├── packings_controller.rb
│   │   └── shipments_controller.rb
│   └── inventory/
│       ├── stocks_controller.rb
│       ├── movements_controller.rb
│       ├── adjustments_controller.rb
│       └── counts_controller.rb
├── models/
│   └── tab_registry.rb                 # 탭 메타데이터 레지스트리
├── views/
│   ├── layouts/
│   │   └── application.html.erb
│   ├── shared/
│   │   ├── _sidebar.html.erb
│   │   ├── _tab_bar.html.erb
│   │   └── _header.html.erb
│   ├── dashboard/
│   │   └── show.html.erb               # turbo_frame_tag("main-content") 안에서 렌더
│   └── inbound/orders/
│       └── index.html.erb              # turbo_frame_tag("main-content") 안에서 렌더
├── helpers/
│   ├── sidebar_helper.rb
│   └── tab_helper.rb
└── javascript/
    └── controllers/
        ├── sidebar_controller.js        # 트리 토글
        └── tabs_controller.js           # 탭 열기/활성화/닫기
```

---

## 1. 라우팅

```ruby
# config/routes.rb
Rails.application.routes.draw do
  root "dashboard#show"

  # ── 탭 관리 ──
  resources :tabs, only: [:create, :destroy], param: :tab_id do
    member do
      patch :activate
    end
  end
  # 생성되는 라우트:
  #   POST   /tabs                → tabs#create
  #   DELETE /tabs/:tab_id        → tabs#destroy
  #   PATCH  /tabs/:tab_id/activate → tabs#activate

  # ── 업무 모듈 ──
  namespace :inbound do
    resources :orders,      only: [:index, :show, :new, :create, :edit, :update]
    resources :inspections,  only: [:index, :show, :new, :create]
    resources :putaways,     only: [:index, :show, :new, :create]
  end

  namespace :outbound do
    resources :orders,    only: [:index, :show, :new, :create, :edit, :update]
    resources :pickings,  only: [:index, :show]
    resources :packings,  only: [:index, :show]
    resources :shipments, only: [:index, :show, :new, :create]
  end

  namespace :inventory do
    resources :stocks,      only: [:index, :show]
    resources :movements,   only: [:index, :show, :new, :create]
    resources :adjustments, only: [:index, :show, :new, :create]
    resources :counts,      only: [:index, :show, :new, :create]
  end

  namespace :master do
    resources :items
    resources :locations
    resources :customers
  end

  resources :reports, only: [:index, :show]
end
```

---

## 2. TabRegistry — God Controller 방지

`resolve_partial` 해시 매핑을 Controller에서 분리합니다.
**단, 이 가이드에서는 URL 로드 방식을 사용하므로 TabRegistry는 "화이트리스트 검증"과 "메타데이터 조회"용으로만 사용됩니다.**

```ruby
# app/models/tab_registry.rb
class TabRegistry
  Entry = Data.define(:id, :label, :icon, :url, :color_group)

  ENTRIES = [
    Entry.new(id: "overview",         label: "개요",        icon: "📊", url: "/",                     color_group: :primary),
    # 입고
    Entry.new(id: "inbound-orders",   label: "입고 오더",   icon: "📋", url: "/inbound/orders",       color_group: :green),
    Entry.new(id: "inbound-inspect",  label: "입고 검수",   icon: "🔍", url: "/inbound/inspections",  color_group: :green),
    Entry.new(id: "inbound-putaway",  label: "적치",        icon: "📥", url: "/inbound/putaways",     color_group: :green),
    # 출고
    Entry.new(id: "outbound-orders",  label: "출고 오더",   icon: "📄", url: "/outbound/orders",      color_group: :cyan),
    Entry.new(id: "outbound-pick",    label: "피킹",        icon: "🎯", url: "/outbound/pickings",    color_group: :cyan),
    Entry.new(id: "outbound-pack",    label: "패킹",        icon: "📦", url: "/outbound/packings",    color_group: :cyan),
    Entry.new(id: "outbound-ship",    label: "출하",        icon: "🚛", url: "/outbound/shipments",   color_group: :cyan),
    # 재고
    Entry.new(id: "stock-current",    label: "현재고 조회", icon: "📊", url: "/inventory/stocks",     color_group: :amber),
    Entry.new(id: "stock-move",       label: "재고 이동",   icon: "🔄", url: "/inventory/movements",  color_group: :amber),
    Entry.new(id: "stock-adjust",     label: "재고 조정",   icon: "✏️", url: "/inventory/adjustments", color_group: :amber),
    Entry.new(id: "stock-count",      label: "재고 실사",   icon: "📝", url: "/inventory/counts",     color_group: :amber),
    # 기준정보
    Entry.new(id: "master-items",     label: "품목 관리",   icon: "📦", url: "/master/items",         color_group: :rose),
    Entry.new(id: "master-locations", label: "로케이션",    icon: "📍", url: "/master/locations",     color_group: :rose),
    Entry.new(id: "master-customers", label: "거래처",      icon: "🏢", url: "/master/customers",     color_group: :rose),
    # 리포트
    Entry.new(id: "reports",          label: "리포트",      icon: "📈", url: "/reports",              color_group: :primary),
  ].freeze

  INDEX = ENTRIES.index_by(&:id).freeze

  class << self
    def find(tab_id)
      INDEX[tab_id]
    end

    def valid?(tab_id)
      INDEX.key?(tab_id)
    end

    def url_for(tab_id)
      INDEX[tab_id]&.url
    end

    def color_css(tab_id)
      entry = INDEX[tab_id]
      return "var(--text-muted)" unless entry

      {
        primary: "var(--accent)",
        green:   "var(--accent-green)",
        cyan:    "var(--accent-cyan)",
        amber:   "var(--accent-amber)",
        rose:    "var(--accent-rose)",
      }[entry.color_group] || "var(--text-muted)"
    end
  end
end
```

---

## 3. TabsController — 버그 수정 완료

### 수정 포인트 (v2 → v3.2 최종)

| # | 이슈 | v2 수정 | v3.x 패치 |
|---|------|---------|---------|
| 1 | `replace` → 프레임 소실 | tab-bar: `update` | main-content: `replace`(프레임→프레임) |
| 2 | `activate` 미구현 | 서버 + JS 구현 | — |
| 3 | 사이드바 중복 요청 | `<button>` 통일 | `data-role` 선택자 |
| 4 | `resolve_partial` 매핑 | URL 로드 방식 | — |
| 5 | 세션 한계 | 전략 가이드 | — |
| 6 | `params.expect` | `require/permit` | — |
| A | `url_for` dig 버그 | — | `INDEX[tab_id]&.url` |
| B | loader frame id 불일치 | — | `main-content` id 통일 |
| C | label/url 클라이언트 신뢰 | — | TabRegistry 단일 진실 소스 |
| D | html fallback 없음 | — | `format.html { redirect_to }` |
| E | JS 선택자 취약 | — | `data-role="sidebar-menu-item"` |
| F | main-content 프레임 중복 | — | 레이아웃 outer frame 제거 |
| G | 첫 진입 세션 미초기화 | — | ApplicationController로 이동 |
| H | overview 닫기 가능 | — | 핀 고정, 서버 차단 |
| I | destroy 시 nil | — | `\|\| "overview"` fallback |
| J | JS 실패 시 불일치 | — | 성공 후에만 `_syncUI` |
| K | `#method` 호환성 | — | `_method` prefix |
| **L** | **tabs 스코프 — 탭바 클릭 불가** | — | **`data-controller="tabs"` → app-layout** |
| **M** | **탭 닫기 후 sidebar 미동기화** | — | **`_syncUIFromActiveTab()` DOM 역참조** |
| **N** | **breadcrumb 미갱신** | — | **`_updateBreadcrumb` + `_syncUI` 통합** |

```ruby
# app/controllers/tabs_controller.rb
class TabsController < ApplicationController
  # ensure_tab_session은 ApplicationController에서 상속 (모든 요청에서 보장)

  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  # POST /tabs
  # 사이드바 메뉴 클릭 → 탭 열기(또는 이미 열려있으면 활성화)
  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  def create
    tab_id = tab_params[:id]

    # 화이트리스트 검증
    entry = TabRegistry.find(tab_id)
    unless entry
      head :unprocessable_entity
      return
    end

    # 세션에 추가 (중복 방지)
    # ⚠️ label/url은 클라이언트 입력이 아닌 TabRegistry에서 가져옴 (단일 진실 소스)
    unless open_tabs.any? { |t| t["id"] == tab_id }
      open_tabs << { "id" => entry.id, "label" => entry.label, "url" => entry.url }
    end
    session[:active_tab] = tab_id

    respond_to do |format|
      format.turbo_stream { render_tab_update }
      format.html { redirect_to entry.url }
    end
  end

  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  # PATCH /tabs/:tab_id/activate
  # 탭 클릭 → 활성 탭 전환
  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  def activate
    tab_id = params[:tab_id]

    unless open_tabs.any? { |t| t["id"] == tab_id }
      head :not_found
      return
    end

    session[:active_tab] = tab_id

    respond_to do |format|
      format.turbo_stream { render_tab_update }
      format.html { redirect_to TabRegistry.url_for(tab_id) || root_path }
    end
  end

  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  # DELETE /tabs/:tab_id
  # 탭 닫기
  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  def destroy
    tab_id = params[:tab_id]

    # overview는 삭제 불가 (핀 고정)
    if tab_id == "overview"
      head :unprocessable_entity
      return
    end

    open_tabs.reject! { |t| t["id"] == tab_id }

    # 활성 탭이 닫혔으면 마지막 탭으로, 없으면 overview로 강제
    if session[:active_tab] == tab_id
      session[:active_tab] = open_tabs.last&.dig("id") || "overview"
    end

    respond_to do |format|
      format.turbo_stream { render_tab_update }
      format.html { redirect_to TabRegistry.url_for(session[:active_tab]) || root_path }
    end
  end

  private

  def open_tabs
    session[:open_tabs]
  end

  # ── 파라미터 ──
  # label/url은 TabRegistry에서 가져오므로 id만 필수.
  # 하지만 기존 프론트가 보내는 값은 무시하되 permit은 유지 (로그/디버깅용)
  def tab_params
    params.require(:tab).permit(:id, :label, :url)
  end

  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  # 핵심: Turbo Stream 응답
  #
  # (1) tab-bar:      turbo_stream.update → <turbo-frame> 유지, 내부만 교체
  # (2) main-content: turbo_stream.replace → 프레임을 "같은 id의 프레임"으로 교체
  #     → src 속성이 변경되면 브라우저가 해당 URL을 Turbo Frame으로 자동 로드
  #     → 응답 뷰의 turbo_frame_tag("main-content")와 id가 일치해야 함!
  #     → resolve_partial 매핑 불필요!
  #
  # ⚠️  tab-bar는 update (내부만 교체, 프레임 유지)
  # ⚠️  main-content는 replace (프레임→프레임 교체, src 트리거를 위해)
  #     replace가 위험한 건 "프레임을 비-프레임으로 교체"할 때뿐입니다.
  #     프레임을 프레임으로 교체하는 건 안전합니다.
  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  def render_tab_update
    active_id  = session[:active_tab]
    active_url = TabRegistry.url_for(active_id) || "/"

    render turbo_stream: [
      # (1) 탭바 내부만 갱신 — <turbo-frame id="tab-bar">는 그대로 유지됨
      turbo_stream.update("tab-bar",
        partial: "shared/tab_bar",
        locals: { tabs: open_tabs, active: active_id }
      ),

      # (2) main-content 프레임 자체를 새 프레임(같은 id + 새 src)으로 교체
      #     → id="main-content" 일치 → 응답 뷰의 turbo_frame_tag("main-content")를 찾아 로딩
      turbo_stream.replace("main-content",
        helpers.turbo_frame_tag("main-content", src: active_url, loading: :eager) {
          helpers.content_tag(:div, class: "loading-state") {
            helpers.content_tag(:div, "", class: "spinner") +
            helpers.content_tag(:span, "로딩 중...")
          }
        }
      )
    ]
  end
end
```

> **왜 tab-bar는 `update`이고 main-content는 `replace`인가?**
>
> - `tab-bar`: 프레임 자체는 유지하고 **내부 콘텐츠만** 교체하면 됩니다. → `update`
> - `main-content`: `src` 속성을 변경해야 Turbo가 새 URL을 로딩합니다.
>   `update`는 내부만 바꾸고 프레임의 `src` 속성은 건드리지 않으므로,
>   **프레임 자체를 새 프레임(같은 id + 새 src)으로 교체**해야 합니다. → `replace`
>
> `replace`가 위험한 건 "프레임을 비-프레임 HTML로 교체"할 때뿐입니다.
> **프레임을 같은 id의 프레임으로 교체하는 것은 안전합니다.**
>
> 이렇게 하면 응답 뷰의 `turbo_frame_tag("main-content")`와 id가 정확히 일치하여
> `TurboFrameMissingError` 없이 정상 로딩됩니다.

---

## 4. ApplicationController — 세션 초기화 (전역)

모든 요청에서 탭 세션이 보장되어야 합니다. `TabsController`에만 두면 첫 진입(`dashboard#show`)에서
탭바가 비어 보이고, 사이드바 active 상태가 초기화되지 않습니다.

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :ensure_tab_session

  private

  # 모든 요청에서 탭 세션 보장
  # → 첫 진입 시에도 탭바/사이드바/브레드크럼 상태가 일관됨
  #
  # ⚠️ overview 탭 존재를 매번 검증하는 이유:
  #    세션이 꼬이거나(쿠키 만료, Redis 플러시 등) 비정상 상태가 되면
  #    open_tabs에 overview가 없는데 active_tab은 "overview"인 불일치가 생길 수 있음.
  #    이 경우 탭바에 아무것도 표시되지 않거나, 사이드바 active가 꼬임.
  def ensure_tab_session
    session[:open_tabs] ||= []

    # overview 탭이 반드시 존재하도록 보장 (핀 고정 정책)
    unless session[:open_tabs].any? { |t| t["id"] == "overview" }
      session[:open_tabs].unshift({ "id" => "overview", "label" => "개요", "url" => "/" })
    end

    session[:active_tab] ||= "overview"
  end
end
```

---

## 5. 레이아웃 — 프레임 중복 방지 + Stimulus 스코프

```erb
<%# app/views/layouts/application.html.erb %>
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>WMS Pro</title>
  <%= csrf_meta_tags %>
  <%= csp_meta_tag %>
  <%= stylesheet_link_tag "application", data: { turbo_track: "reload" } %>
  <%= javascript_importmap_tags %>
</head>
<body>
  <%# ═══════════════════════════════════════════════════════════════════ %>
  <%# ⚠️ data-controller="tabs" 는 반드시 여기(app-layout)에 붙여야 함   %>
  <%#                                                                     %>
  <%# 이유: Stimulus는 액션이 발생한 요소의 "상위 DOM"에서 컨트롤러를     %>
  <%# 찾습니다. tabs 컨트롤러가 사이드바에만 붙어있으면, 사이드바 밖에    %>
  <%# 있는 탭바의 activateTab/closeTab 액션이 컨트롤러를 찾지 못해       %>
  <%# 아예 실행되지 않습니다.                                             %>
  <%#                                                                     %>
  <%# app-layout은 사이드바 + 헤더 + 탭바 + 본문을 모두 포함하므로,      %>
  <%# 어디서든 tabs#openTab, tabs#activateTab, tabs#closeTab이 동작합니다.%>
  <%# ═══════════════════════════════════════════════════════════════════ %>
  <div class="app-layout" data-controller="tabs">

    <%# ═══ 사이드바: sidebar 컨트롤러만 (트리 토글 전용) ═══ %>
    <%= render "shared/sidebar" %>

    <main class="main-area">
      <%# ═══ 헤더 (breadcrumb 포함) ═══ %>
      <%= render "shared/header" %>

      <%# ═══ 탭 바: Turbo Frame (update 대상) ═══ %>
      <turbo-frame id="tab-bar">
        <%= render "shared/tab_bar",
              tabs: session[:open_tabs] || [],
              active: session[:active_tab] || "overview" %>
      </turbo-frame>

      <%# ═══ 본문 ═══ %>
      <%# ⚠️ 여기에 <turbo-frame>을 두지 않음! %>
      <%# 각 뷰가 turbo_frame_tag("main-content")를 직접 감쌈 %>
      <div class="content-area">
        <%= yield %>
      </div>
    </main>
  </div>
</body>
</html>
```

---

## 6. 사이드바 — `<button>` 통일 (이슈 #3 수정)

**문제**: `<a href>` + `click→openTab` 조합은 요청이 2번 나감
**수정**: `<button>` 으로 통일. Stimulus만 동작, Turbo Frame 네비게이션 없음.

```erb
<%# app/views/shared/_sidebar.html.erb %>
<%# ⚠️ data-controller="sidebar" 만 — tabs는 상위 app-layout에 있음 %>
<aside class="sidebar" data-controller="sidebar">
  <div class="sidebar-logo">
    <div class="logo-icon">W</div>
    <span>WMS Pro</span>
  </div>

  <nav class="sidebar-nav">
    <div class="nav-section-label">메인</div>

    <%= sidebar_menu_button "개요", tab_id: "overview",
        icon: "📊", url: "/" %>

    <%# ── 입고관리 (트리) ── %>
    <button class="nav-item has-children" type="button"
            data-action="click->sidebar#toggleTree">
      <span class="icon">📦</span> 입고관리
      <span class="chevron">▶</span>
    </button>
    <div class="nav-tree-children" data-sidebar-target="treeChildren">
      <%= sidebar_menu_button "입고 오더", tab_id: "inbound-orders",
          icon: "📋", url: "/inbound/orders" %>
      <%= sidebar_menu_button "입고 검수", tab_id: "inbound-inspect",
          icon: "🔍", url: "/inbound/inspections" %>
      <%= sidebar_menu_button "적치", tab_id: "inbound-putaway",
          icon: "📥", url: "/inbound/putaways" %>
    </div>

    <%# ── 출고관리 (트리) ── %>
    <button class="nav-item has-children" type="button"
            data-action="click->sidebar#toggleTree">
      <span class="icon">🚚</span> 출고관리
      <span class="chevron">▶</span>
    </button>
    <div class="nav-tree-children" data-sidebar-target="treeChildren">
      <%= sidebar_menu_button "출고 오더", tab_id: "outbound-orders",
          icon: "📄", url: "/outbound/orders" %>
      <%= sidebar_menu_button "피킹", tab_id: "outbound-pick",
          icon: "🎯", url: "/outbound/pickings" %>
      <%= sidebar_menu_button "패킹", tab_id: "outbound-pack",
          icon: "📦", url: "/outbound/packings" %>
      <%= sidebar_menu_button "출하", tab_id: "outbound-ship",
          icon: "🚛", url: "/outbound/shipments" %>
    </div>

    <%# ── 재고관리 (트리) ── %>
    <button class="nav-item has-children" type="button"
            data-action="click->sidebar#toggleTree">
      <span class="icon">🏷️</span> 재고관리
      <span class="chevron">▶</span>
    </button>
    <div class="nav-tree-children" data-sidebar-target="treeChildren">
      <%= sidebar_menu_button "현재고 조회", tab_id: "stock-current",
          icon: "📊", url: "/inventory/stocks" %>
      <%= sidebar_menu_button "재고 이동", tab_id: "stock-move",
          icon: "🔄", url: "/inventory/movements" %>
      <%= sidebar_menu_button "재고 조정", tab_id: "stock-adjust",
          icon: "✏️", url: "/inventory/adjustments" %>
      <%= sidebar_menu_button "재고 실사", tab_id: "stock-count",
          icon: "📝", url: "/inventory/counts" %>
    </div>

    <div class="nav-section-label">관리</div>

    <%# ── 기준정보 (트리) ── %>
    <button class="nav-item has-children" type="button"
            data-action="click->sidebar#toggleTree">
      <span class="icon">🏗️</span> 기준정보
      <span class="chevron">▶</span>
    </button>
    <div class="nav-tree-children" data-sidebar-target="treeChildren">
      <%= sidebar_menu_button "품목 관리", tab_id: "master-items",
          icon: "📦", url: "/master/items" %>
      <%= sidebar_menu_button "로케이션", tab_id: "master-locations",
          icon: "📍", url: "/master/locations" %>
      <%= sidebar_menu_button "거래처", tab_id: "master-customers",
          icon: "🏢", url: "/master/customers" %>
    </div>

    <%= sidebar_menu_button "리포트", tab_id: "reports",
        icon: "📈", url: "/reports", badge: 3 %>
  </nav>

  <div class="sidebar-footer">
    <div class="avatar">MG</div>
    <div class="user-info">
      <div class="user-name"><%= current_user&.name || "송명근" %></div>
      <div class="user-email"><%= current_user&.email || "mg@wms-pro.kr" %></div>
    </div>
  </div>
</aside>
```

---

## 7. SidebarHelper — `<button>` 기반 메뉴 항목

```ruby
# app/helpers/sidebar_helper.rb
module SidebarHelper
  # <button> で렌더링 — Turbo Frame 네비게이션 없음, Stimulus만 동작
  # data-role="sidebar-menu-item" 으로 JS 선택자를 CSS 클래스와 분리 (견고성 확보)
  #
  # ⚠️ data 키를 문자열 "tab-id" 형태로 명시하는 이유:
  #    Rails의 content_tag는 data: { tab_id: "x" } → data-tab_id="x" 로 렌더하는 경우가 있고,
  #    이는 브라우저 dataset에서 dataset.tab_id가 되어
  #    JS의 dataset.tabId (= data-tab-id) 와 불일치합니다.
  #
  #    문자열 키 "tab-id" 를 사용하면 확정적으로 data-tab-id="x" 가 되어
  #    JS의 dataset.tabId 와 정확히 일치합니다.
  #
  #    _syncUI()의 selector도 [data-tab-id='${tabId}'] 이므로 이와 맞아야 합니다.
  def sidebar_menu_button(label, tab_id:, icon:, url:, badge: nil)
    is_active = (session[:active_tab] == tab_id)

    content_tag(:button,
      type: "button",
      class: "nav-item #{'active' if is_active}",
      data: {
        action:   "click->tabs#openTab",
        role:     "sidebar-menu-item",
        "tab-id": tab_id,
        label:    label,
        url:      url
      }
    ) do
      parts = []
      parts << content_tag(:span, icon, class: "icon")
      parts << " #{label} "
      if badge
        parts << content_tag(:span, badge, class: "badge")
      end
      safe_join(parts)
    end
  end
end
```

---

## 8. 탭 바 파셜

```erb
<%# app/views/shared/_tab_bar.html.erb %>
<%# 주의: 이 파셜은 <turbo-frame id="tab-bar"> 내부에 렌더됨 (update 대상) %>
<div class="tab-bar-inner">
  <% (tabs || []).each do |tab| %>
    <% tab_id = tab["id"] %>
    <% is_active = (tab_id == active) %>

    <button class="tab-item <%= 'active' if is_active %>"
            type="button"
            data-action="click->tabs#activateTab"
            data-tab-id="<%= tab_id %>">
      <span class="tab-dot" style="background:<%= TabRegistry.color_css(tab_id) %>"></span>
      <%= tab["label"] %>

      <%# overview는 핀 고정(닫기 불가), 나머지 탭만 닫기 버튼 표시 %>
      <% if tab_id != "overview" %>
        <span class="tab-close"
              data-action="click->tabs#closeTab:stop"
              data-tab-id="<%= tab_id %>">✕</span>
      <% end %>
    </button>
  <% end %>
</div>
```

---

## 9. Stimulus 컨트롤러 — 완전 구현

### sidebar_controller.js

```javascript
// app/javascript/controllers/sidebar_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["treeChildren"]

  toggleTree(event) {
    const button = event.currentTarget
    const children = button.nextElementSibling

    if (children && children.classList.contains("nav-tree-children")) {
      button.classList.toggle("expanded")
      children.classList.toggle("open")
    }
  }
}
```

### tabs_controller.js — 이슈 #2, #3 완전 해결 + v3.1 개선 반영

```javascript
// app/javascript/controllers/tabs_controller.js
import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"
// ⚠️ Turbo를 명시적으로 import해야 합니다.
//    Rails 8 Importmap 구성에 따라 전역 Turbo가 안 잡히는 경우가 있으며,
//    이 경우 "요청은 200인데 화면이 안 바뀜 + 콘솔에 Turbo undefined" 현상이 발생합니다.

export default class extends Controller {
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 사이드바 메뉴 클릭 → 탭 열기
  // POST /tabs → Turbo Stream(탭바 update + main-content replace)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  openTab(event) {
    event.preventDefault()

    const { tabId, label, url } = event.currentTarget.dataset

    // 서버 응답 성공 후에만 사이드바 + breadcrumb 동기화
    this._turboStreamRequest("POST", "/tabs", {
      tab: { id: tabId, label, url }
    }).then(() => {
      this._syncUI(tabId)
    })
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 탭 클릭 → 활성 탭 전환
  // PATCH /tabs/:tab_id/activate
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  activateTab(event) {
    const tabId = event.currentTarget.dataset.tabId

    // 이미 활성 탭이면 무시
    if (event.currentTarget.classList.contains("active")) return

    this._turboStreamRequest("PATCH", `/tabs/${tabId}/activate`)
      .then(() => {
        this._syncUI(tabId)
      })
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 탭 닫기 (✕ 버튼)
  // DELETE /tabs/:tab_id
  //
  // data-action="click->tabs#closeTab:stop" 에서
  // :stop이 event.stopPropagation() 역할
  //
  // ⚠️ 닫기 후에는 서버가 active_tab을 변경할 수 있으므로,
  //    응답이 탭바를 다시 렌더한 뒤 DOM에서 새 active를 읽어
  //    사이드바 + breadcrumb을 동기화해야 합니다.
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  closeTab(event) {
    const tabId = event.currentTarget.dataset.tabId
    this._turboStreamRequest("DELETE", `/tabs/${tabId}`)
      .then(() => {
        // Turbo Stream이 탭바를 다시 렌더한 후,
        // DOM에서 새로 active된 탭의 id를 읽어옴
        this._syncUIFromActiveTab()
      })
  }

  // ── "Private" methods ──
  // ⚠️ ES private field(#)를 사용하지 않음
  //    사내 WMS 태블릿/전용 단말의 구형 브라우저 호환성을 위해
  //    관례형 prefix(_)로 대체

  _turboStreamRequest(method, url, body = null) {
    const csrfToken = document.querySelector("meta[name='csrf-token']")?.content
    const headers = {
      "X-CSRF-Token": csrfToken,
      "Accept": "text/vnd.turbo-stream.html"
    }

    const options = { method, headers }

    if (body) {
      headers["Content-Type"] = "application/json"
      options.body = JSON.stringify(body)
    }

    // Promise를 반환 → 호출부에서 .then()으로 후속 처리 가능
    return fetch(url, options)
      .then(response => {
        if (!response.ok) throw new Error(`HTTP ${response.status}`)
        return response.text()
      })
      .then(html => {
        Turbo.renderStreamMessage(html)
      })
      .catch(error => {
        console.error("[tabs]", error)
        // 실패 시 Promise chain을 끊어서 .then() 후속 실행 방지
        throw error
      })
  }

  // 사이드바 active 상태 업데이트
  _updateSidebarActive(tabId) {
    document.querySelectorAll("[data-role='sidebar-menu-item']").forEach(btn => {
      btn.classList.toggle("active", btn.dataset.tabId === tabId)
    })
  }

  // breadcrumb 텍스트 업데이트
  _updateBreadcrumb(label) {
    const el = document.getElementById("breadcrumb-current")
    if (el && label) el.textContent = label
  }

  // 사이드바 + breadcrumb을 한 번에 동기화
  // openTab/activateTab: tabId를 직접 알고 있으므로 이걸 씀
  _syncUI(tabId) {
    this._updateSidebarActive(tabId)
    // sidebar 버튼의 data-label에서 breadcrumb 텍스트를 가져옴
    const btn = document.querySelector(`[data-role='sidebar-menu-item'][data-tab-id='${tabId}']`)
    this._updateBreadcrumb(btn?.dataset?.label)
  }

  // 탭 닫기 후: DOM에서 현재 active 탭을 역으로 읽어서 동기화
  // (서버가 active_tab을 변경했을 수 있으므로)
  //
  // ⚠️ queueMicrotask를 사용하는 이유:
  //    Turbo.renderStreamMessage()가 DOM을 갱신하는 시점과
  //    Promise.then() 실행 시점이 거의 동시에 일어날 수 있습니다.
  //    한 tick 뒤에 읽으면 Turbo가 DOM 갱신을 완료한 후 확실히 읽을 수 있습니다.
  //    (특히 저사양 WMS 태블릿 단말에서 간헐 실패 방지)
  _syncUIFromActiveTab() {
    queueMicrotask(() => {
      const activeTab = document.querySelector(".tab-item.active")
      const tabId = activeTab?.dataset?.tabId
      if (tabId) this._syncUI(tabId)
    })
  }
}
```

---

## 10. 업무 컨트롤러 예시 — Turbo Frame 호환

각 업무 화면의 `index.html.erb`는 반드시 `turbo_frame_tag("main-content")`로 감싸야 합니다.
이래야 `<turbo-frame id="main-content" src="/inbound/orders">`가 이 프레임만 추출해 로딩합니다.

```ruby
# app/controllers/inbound/orders_controller.rb
module Inbound
  class OrdersController < ApplicationController
    def index
      @orders = Inbound::Order.recent.page(params[:page])
    end
  end
end
```

```erb
<%# app/views/inbound/orders/index.html.erb %>
<%= turbo_frame_tag "main-content" do %>
  <div class="page-header">
    <h2>📋 입고 오더</h2>
    <div class="page-actions">
      <%= link_to "신규 등록", new_inbound_order_path,
            class: "btn btn-primary",
            data: { turbo_frame: "modal" } %>
      <button class="btn btn-secondary">엑셀 다운로드</button>
    </div>
  </div>

  <div class="data-table-wrapper">
    <table class="data-table">
      <thead>
        <tr>
          <th>오더 번호</th>
          <th>거래처</th>
          <th>예정일</th>
          <th>품목 수</th>
          <th>수량</th>
          <th>상태</th>
          <th>담당자</th>
        </tr>
      </thead>
      <tbody>
        <% @orders.each do |order| %>
          <tr>
            <td class="mono"><%= order.order_number %></td>
            <td><%= order.supplier_name %></td>
            <td><%= order.expected_date&.strftime("%Y-%m-%d") %></td>
            <td class="mono"><%= order.line_items_count %></td>
            <td class="mono"><%= number_with_delimiter(order.total_qty) %></td>
            <td><%= render_status_badge(order.status) %></td>
            <td><%= order.assignee_name %></td>
          </tr>
        <% end %>
      </tbody>
    </table>
  </div>

  <%# 페이지네이션도 Turbo Frame 안에 있으므로 프레임 내에서 동작 %>
  <div class="pagination-wrapper">
    <%= paginate @orders %>
  </div>
<% end %>
```

> **핵심**: `turbo_frame_tag "main-content"` 로 감싸기만 하면 됩니다.
> TabsController가 이 화면의 URL을 몰라도, 브라우저가 `src` 속성으로 자동 로딩합니다.
> 새 화면을 추가할 때 TabsController를 수정할 필요가 없습니다 (TabRegistry에 메뉴 항목만 추가).

---

## 11. 대시보드 (개요) 페이지

```erb
<%# app/views/dashboard/show.html.erb %>
<%= turbo_frame_tag "main-content" do %>
  <div class="stats-grid">
    <div class="stat-card">
      <div class="stat-label">오늘 입고</div>
      <div class="stat-value">1,247</div>
      <div class="stat-change up">↑ 12.5%</div>
    </div>
    <div class="stat-card">
      <div class="stat-value" style="color:var(--accent-green)">892</div>
      <div class="stat-label">오늘 출고</div>
      <div class="stat-change up">↑ 8.3%</div>
    </div>
    <div class="stat-card">
      <div class="stat-value" style="color:var(--accent-amber)">34,521</div>
      <div class="stat-label">현재고 (SKU)</div>
      <div class="stat-change down">↓ 2.1%</div>
    </div>
    <div class="stat-card">
      <div class="stat-value" style="color:var(--accent-cyan)">97.8%</div>
      <div class="stat-label">재고 정확도</div>
      <div class="stat-change up">↑ 0.3%</div>
    </div>
  </div>

  <%# 차트, 테이블 등... %>
<% end %>
```

---

## 12. 헤더 파셜

```erb
<%# app/views/shared/_header.html.erb %>
<header class="main-header">
  <div class="breadcrumb">
    <span>WMS Pro</span>
    <span class="sep">/</span>
    <span class="current" id="breadcrumb-current">
      <%= TabRegistry.find(session[:active_tab] || "overview")&.label || "개요" %>
    </span>
  </div>
  <div class="header-actions">
    <div class="search-box">
      <span class="search-icon">🔍</span>
      <input type="text" placeholder="검색... (⌘K)">
    </div>
    <button class="icon-btn" type="button">🔔</button>
    <button class="icon-btn" type="button">⚙️</button>
  </div>
</header>
```

---

## 동작 흐름 요약

```
[사이드바 "입고 오더" 클릭]
    │
    ▼
<button data-action="click->tabs#openTab"
        data-tab-id="inbound-orders"
        data-label="입고 오더"
        data-url="/inbound/orders">
    │
    ▼
tabs_controller.js → fetch("POST /tabs", { tab: {...} })
    │
    ▼
TabsController#create
  ├─ entry = TabRegistry.find(tab_id)       ← 단일 진실 소스
  ├─ session[:open_tabs] << { id, label, url } (from Registry)
  ├─ session[:active_tab] = "inbound-orders"
  └─ Turbo Stream 응답:
       ├─ turbo_stream.update("tab-bar")         ← 프레임 유지, 내부만 교체
       └─ turbo_stream.replace("main-content")   ← 프레임→프레임 교체 (같은 id, 새 src)
    │
    ▼
브라우저가 <turbo-frame id="main-content" src="/inbound/orders"> 감지
  → id="main-content" 일치 → TurboFrameMissingError 없음
    │
    ▼
GET /inbound/orders → Inbound::OrdersController#index
  └─ turbo_frame_tag("main-content") { ... } 렌더
    │
    ▼
Turbo가 응답에서 id="main-content" 프레임 추출 → 본문 영역에 표시
    │
    ▼
✅ 탭바 갱신 + 본문 로딩 완료 (전체 페이지 리로드 없음)
```

---

## 세션 전략 가이드 (이슈 #5)

| 단계 | 저장소 | 장점 | 단점 |
|------|--------|------|------|
| **MVP/초기** | `session` (쿠키 or 서버) | 설정 없이 바로 동작 | 4KB 제한(쿠키), 멀티디바이스 X |
| **중기** | Redis + `session_store :redis_store` | 서버 스케일아웃 OK, 세션 데이터 제한 없음 | Redis 인프라 필요 |
| **장기/ERP급** | DB (`user_ui_states` 테이블) | 멀티디바이스, 감사로그, 개인화 | 매 요청 DB I/O (캐싱으로 해결) |
| **하이브리드** | localStorage(탭) + 서버(권한/메뉴) | 서버 부하 최소 | 동기화 복잡도 |

**현재 가이드는 세션 기반**이며, Redis 전환은 `config/initializers/session_store.rb` 한 줄 변경으로 가능합니다:

```ruby
# config/initializers/session_store.rb
Rails.application.config.session_store :redis_store,
  servers: [ENV.fetch("REDIS_URL", "redis://localhost:6379/0/session")],
  expire_after: 1.day
```

---

## 요약: 전체 이슈 해결 매핑 (v1 → v3.3 최종)

| # | 이슈 | 해결 |
|---|------|------|
| 1 | `replace` → `<turbo-frame>` 소실 | tab-bar: `update` / main-content: `replace`(프레임→프레임) |
| 2 | `activate` 미구현 | 서버 + JS 양쪽 구현 |
| 3 | `<a>` + `openTab` 중복 요청 | `<button>` 통일 + `data-role` 선택자 |
| 4 | `resolve_partial` God Controller | URL 로드 방식, TabRegistry는 검증+메타용 |
| 5 | 세션 기반 한계 | 단계별 전략 가이드 |
| 6 | `params.expect` 호환성 | `params.require(:tab).permit(...)` |
| A | `url_for` dig 버그 | `INDEX[tab_id]&.url` |
| B | loader frame id 불일치 | `main-content` id 통일 + replace |
| C | label/url 클라이언트 신뢰 | TabRegistry 단일 진실 소스 |
| D | Turbo Stream 외 406 에러 | `format.html { redirect_to }` fallback |
| E | CSS 클래스 의존 JS 선택자 | `data-role="sidebar-menu-item"` |
| F | main-content 프레임 중복 | 레이아웃 outer frame 제거 |
| G | 첫 진입 세션 미초기화 | `ensure_tab_session` → ApplicationController |
| H | overview 닫기 가능 | 핀 고정, 서버에서도 차단 |
| I | destroy 시 nil | `\|\| "overview"` fallback |
| J | JS 실패 시 sidebar 불일치 | 응답 성공 후에만 `_syncUI` |
| K | ES private field 호환성 | `_method` 관례형 prefix |
| L | tabs 컨트롤러 스코프 | `data-controller="tabs"` → app-layout |
| M | 탭 닫기 후 sidebar 미동기화 | `_syncUIFromActiveTab()` DOM 역참조 |
| N | breadcrumb 미갱신 | `_updateBreadcrumb` + `_syncUI` 통합 |
| **O** | **`Turbo` 미import → 화면 갱신 안 됨** | **`import { Turbo } from "@hotwired/turbo-rails"`** |
| **P** | **DOM 역참조 타이밍 (간헐 실패)** | **`queueMicrotask()` 로 한 tick 지연** |
| **Q** | **세션 꼬임 시 overview 소실** | **`ensure_tab_session`에서 overview 존재 매번 검증** |
| **R** | **data-tab_id vs data-tab-id 불일치** | **SidebarHelper에서 `"tab-id":` 문자열 키로 명시** |
