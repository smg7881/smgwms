# Fizzy Rails 개발 스타일 가이드

이 가이드는 37signals/Basecamp가 만든 협업 프로젝트 관리 도구 Fizzy에서 사용하는 아키텍처와 코딩 패턴을 정리한 문서입니다. 동일한 컨벤션을 따르는 새 Rails 애플리케이션을 만들 때 참고 자료로 활용하세요.

---

## 목차

1. [아키텍처 원칙](#1-아키텍처-원칙)
2. [컨트롤러 패턴](#2-컨트롤러-패턴)
3. [모델 패턴](#3-모델-패턴)
4. [Current Attributes 패턴](#4-current-attributes-패턴)
5. [인증 패턴 (패스워드리스 매직 링크)](#5-인증-패턴-패스워드리스-매직-링크)
6. [멀티테넌시 패턴 (URL 경로 기반)](#6-멀티테넌시-패턴-url-경로-기반)
7. [백그라운드 잡 패턴](#7-백그라운드-잡-패턴)
8. [이벤트 시스템 패턴](#8-이벤트-시스템-패턴)
9. [라우트 구성 패턴](#9-라우트-구성-패턴)
10. [프론트엔드 패턴](#10-프론트엔드-패턴)
11. [테스트 패턴](#11-테스트-패턴)
12. [새 Rails 프로젝트에 적용하기](#12-새-rails-프로젝트에-적용하기)

---

## 1. 아키텍처 원칙

### 핵심 원칙

- **얇은 컨트롤러 + 풍부한 도메인 모델** — 서비스 객체를 사용하지 않는다. 로직은 모델에 존재한다.
- **Concern 기반 모델 컴포지션** — `ActiveSupport::Concern`을 활용해 상속보다 구성(Composition)을 선호한다.
- **RESTful 리소스 설계** — CRUD에 맞지 않는 동작은 커스텀 액션 이름 대신 새 리소스로 추상화한다.

### 커스텀 액션 대신 CRUD 리소스로 추상화

```ruby
# 선호: CRUD가 아닌 동작을 새 리소스로 추상화
resources :cards do
  scope module: :cards do
    resource :closure    # POST /cards/:id/closure  → Cards::ClosuresController#create
    resource :column     # PATCH /cards/:id/column  → Cards::ColumnsController#update
    resource :goldness   # Cards::GoldnessController
    resource :pin        # Cards::PinsController
  end
end

# 지양: 커스텀 액션 이름 직접 사용
resources :cards do
  post :close
  patch :move_to_column
  post :gold
  post :pin
end
```

**이유**: 각 리소스마다 작고 집중된 컨트롤러를 가진다. 액션은 항상 CRUD에 머문다. 라우팅이 예측 가능하게 유지된다.

### 서비스 객체 사용 안 함

순수 ActiveRecord + 모델 메서드를 사용한다. 의도를 명확히 드러내는 모델 API를 선호한다:

```ruby
# 순수 ActiveRecord도 충분하다
@comment = @card.comments.create!(comment_params)

# 의도를 드러내는 모델 API
card = Current.user.draft_new_card_in(@board)
@card.gild
```

폼 객체나 서비스 객체는 진정한 이유가 있을 때 허용되지만, 기본 패턴으로 취급하지 않는다.

---

## 2. 컨트롤러 패턴

### 구조

- 리소스 로딩과 권한 확인은 `before_action`으로 처리
- 파라미터 필터링은 `params.expect()` (Rails 7.1+) 사용
- 다중 포맷 지원은 `respond_to` 블록으로 처리 (HTML, JSON, Turbo Stream)

**참고 파일**: `app/controllers/cards_controller.rb`

```ruby
class CardsController < ApplicationController
  before_action :set_board, only: %i[create]
  before_action :set_card,  only: %i[show edit update destroy]
  before_action :ensure_permission_to_administer_card, only: %i[destroy]

  def create
    respond_to do |format|
      format.html do
        card = Current.user.draft_new_card_in(@board)
        redirect_to card_draft_path(card)
      end

      format.json do
        card = @board.cards.create!(card_params.merge(creator: Current.user, status: "published"))
        head :created, location: card_path(card, format: :json)
      end
    end
  end

  def update
    @card.update!(card_params)

    respond_to do |format|
      format.turbo_stream
      format.json { render :show }
    end
  end

  def destroy
    @card.destroy!

    respond_to do |format|
      format.html { redirect_to @card.board, notice: "카드가 삭제되었습니다" }
      format.json { head :no_content }
    end
  end

  private
    def set_board
      @board = Current.user.boards.find(params[:board_id])
    end

    def set_card
      @card = Current.user.accessible_cards.find_by!(number: params[:id])
    end

    def ensure_permission_to_administer_card
      head :forbidden unless Current.user.can_administer_card?(@card)
    end

    def card_params
      params.expect(card: [:title, :description, :image, :created_at, :last_active_at])
    end
end
```

### 컨트롤러 Concerns

**참고 디렉토리**: `app/controllers/concerns/`

- `authentication.rb` — 세션 인증 + Bearer 토큰
- `authorization.rb` — 역할 기반 접근 제어
- `current_request.rb` — 요청 컨텍스트를 `Current`에 저장

### `scope module:`로 컨트롤러 네임스페이스 적용

리소스에 서브 리소스가 있을 때, URL 구조는 그대로 유지하면서 컨트롤러에 네임스페이스를 적용한다:

```ruby
resources :cards do
  scope module: :cards do
    resource :closure    # → Cards::ClosuresController
    resources :comments  # → Cards::CommentsController
  end
end
```

---

## 3. 모델 패턴

### Concern 기반 컴포지션

모델 동작을 집중된 Concern으로 분리한다. 각 Concern은 하나의 행동(behavior)을 담당한다:

```ruby
class Card < ApplicationRecord
  include Assignable, Closeable, Commentable, Eventable,
          Mentions, Searchable, Taggable, Watchable
end
```

**참고 디렉토리**: `app/models/concerns/`

### Concern 구조

```ruby
module Eventable
  extend ActiveSupport::Concern

  included do
    has_many :events, as: :eventable, dependent: :destroy
  end

  def track_event(action, creator: Current.user, board: self.board, **particulars)
    if should_track_event?
      board.events.create!(
        action: "#{eventable_prefix}_#{action}",
        creator:,
        board:,
        eventable: self,
        particulars:
      )
    end
  end

  private
    def should_track_event?
      true
    end

    def eventable_prefix
      self.class.name.demodulize.underscore
    end
end
```

### 콜백 실행 순서

1. `before_save` — 기본값 설정, 유효성 검사 준비
2. `before_create` — ID 할당 (`assign_number`)
3. `after_save` — 부모 레코드 touch
4. `after_create_commit` — 비동기 작업, 검색 인덱싱, 알림
5. `after_update` — 복잡한 사이드 이펙트

### 메서드 명명 규칙

| 유형 | 예시 |
|------|------|
| 쿼리/조건 메서드 | `drafted?`, `verified?`, `commentable?` |
| 비동기 트리거 | `notify_recipients_later`, `relay_later` |
| 동기 대응 메서드 | `notify_recipients_now`, `relay_now` |
| 토글 메서드 | `toggle_assignment`, `toggle_tag_with` |
| 의도 표현 API | `draft_new_card_in(board)`, `gild` |

### `Current`를 활용한 기본값 설정

```ruby
belongs_to :creator, default: -> { Current.user }
```

### 접근 제한자 스타일

```ruby
class SomeModel < ApplicationRecord
  def some_public_method
    # ...
  end

  private
    def some_private_method
      # ...
    end
end
```

`private` 다음에 빈 줄을 넣지 않는다. 내용은 그 아래에 들여쓴다.

---

## 4. Current Attributes 패턴

**참고 파일**: `app/models/current.rb`

```ruby
class Current < ActiveSupport::CurrentAttributes
  attribute :session, :user, :identity, :account
  attribute :http_method, :request_id, :user_agent, :ip_address, :referrer

  def session=(value)
    super(value)

    if value.present?
      self.identity = session.identity
    end
  end

  def identity=(identity)
    super(identity)

    if identity.present?
      self.user = identity.users.find_by(account: account)
    end
  end

  def with_account(value, &)
    with(account: value, &)
  end

  def without_account(&)
    with(account: nil, &)
  end
end
```

### 사용 패턴

- `Current.user` — 인증된 사용자 (어디서나 접근 가능)
- `Current.account` — 현재 테넌트 (멀티테넌시)
- `Current.identity` — 글로벌 인증 주체 (이메일 기반, 계정 간 공유)
- 모델 기본값: `belongs_to :creator, default: -> { Current.user }`
- 잡: 자동으로 직렬화/복원됨 (백그라운드 잡 패턴 참고)

---

## 5. 인증 패턴 (패스워드리스 매직 링크)

### 아키텍처

| 모델 | 역할 |
|------|------|
| `Identity` | 글로벌 사용자 (이메일 기반), 여러 Account에 소속 가능 |
| `User` | Account 멤버십, 역할 보유 (owner/admin/member/system) |
| `Session` | HTTP-only 서명 쿠키 |
| `MagicLink` | 6자리 코드, 15분 유효, 일회용 |
| `AccessToken` | 읽기/쓰기 권한 범위를 가진 API 토큰 |

### 인증 흐름

```
이메일 입력 → 매직 링크 생성 + 이메일 발송 → 코드 확인 → 세션 생성 → 쿠키 저장
```

### Authentication Concern

**참고 파일**: `app/controllers/concerns/authentication.rb`

```ruby
module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_account
    before_action :require_authentication
    helper_method :authenticated?

    include Authentication::ViaMagicLink, LoginHelper
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
      before_action :resume_session, **options
      allow_unauthorized_access **options
    end
  end

  private
    def authenticated?
      Current.identity.present?
    end

    def require_authentication
      resume_session || authenticate_by_bearer_token || request_authentication
    end

    def resume_session
      if session = find_session_by_cookie
        set_current_session session
      end
    end

    def find_session_by_cookie
      Session.find_signed(cookies.signed[:session_token])
    end

    def authenticate_by_bearer_token
      if request.authorization.to_s.include?("Bearer")
        authenticate_or_request_with_http_token do |token|
          if identity = Identity.find_by_permissable_access_token(token, method: request.method)
            Current.identity = identity
          end
        end
      end
    end

    def set_current_session(session)
      Current.session = session
      cookies.signed.permanent[:session_token] = {
        value: session.signed_id,
        httponly: true,
        same_site: :lax
      }
    end

    def terminate_session
      Current.session.destroy
      cookies.delete(:session_token)
    end
end
```

### 보안 포인트

- HTTP-only 서명 쿠키로 XSS 토큰 탈취 방지
- 매직 링크 코드는 일회용: 확인 즉시 삭제됨
- API 토큰은 읽기/쓰기 권한 범위가 명시적으로 구분됨
- Bearer 토큰 인증은 `Authorization: Bearer` 헤더가 있을 때만 실행됨

---

## 6. 멀티테넌시 패턴 (URL 경로 기반)

### 동작 방식

```
URL: /345622999/boards/123
     ↑ 계정 external_id
```

미들웨어(`AccountSlug::Extractor`)가 `PATH_INFO`에서 계정 ID를 추출해 `SCRIPT_NAME`으로 이동시킨다. Rails는 해당 경로에 마운트된 것처럼 요청을 처리하고, `Current.account`가 자동으로 설정된다.

**참고 파일**: `config/initializers/tenanting/account_slug.rb`

### 모델 데이터 격리

모든 테이블에 `account_id`를 포함한다. 쿼리는 `Current.user`를 통해 자동으로 범위가 제한된다:

```ruby
# 자동으로 현재 계정 범위로 제한됨
@board = Current.user.boards.find(params[:board_id])
@card  = Current.user.accessible_cards.find_by!(number: params[:id])
```

### 백그라운드 잡 컨텍스트

잡이 큐에 추가될 때 `Current.account`가 직렬화되고, 실행 전에 복원된다. 잡에 계정 ID를 수동으로 전달할 필요가 없다.

---

## 7. 백그라운드 잡 패턴

### 얕은 잡(Shallow Job) — 도메인 모델에 위임

잡은 모델 메서드에 위임하는 얇은 래퍼로 유지한다:

```ruby
class NotifyRecipientsJob < ApplicationJob
  queue_as :notifications
  discard_on ActiveJob::DeserializationError

  def perform(notifiable)
    notifiable.notify_recipients  # 모델에 위임
  end
end
```

### Account 컨텍스트 자동 복원

**참고 파일**: `config/initializers/active_job.rb`

```ruby
module FizzyActiveJobExtensions
  extend ActiveSupport::Concern

  prepended do
    attr_reader :account
    self.enqueue_after_transaction_commit = true
  end

  def initialize(...)
    super
    @account = Current.account
  end

  def serialize
    super.merge({ "account" => @account&.to_gid })
  end

  def deserialize(job_data)
    super
    if _account = job_data.fetch("account", nil)
      @account = GlobalID::Locator.locate(_account)
    end
  end

  def perform_now
    if account.present?
      Current.with_account(account) { super }
    else
      super
    end
  end
end

ActiveSupport.on_load(:active_job) do
  prepend FizzyActiveJobExtensions
end
```

**핵심**: `enqueue_after_transaction_commit = true`는 DB 트랜잭션이 커밋된 후에만 잡이 실행되도록 보장한다. 트리거 레코드가 아직 보이지 않는 상태에서 잡이 실행되는 경쟁 조건을 방지한다.

### 명명 규칙

```ruby
# Concern 또는 모델 안에서:

after_create_commit :notify_recipients_later  # 비동기 트리거

def notify_recipients_later
  NotifyRecipientsJob.perform_later(self)
end

def notify_recipients_now        # 동기 대응 메서드
  Notifier.for(self)&.notify
end
```

비동기는 `_later` 접미사, 동기는 `_now` 접미사. 무엇이 지연 실행되는지 명확하게 드러난다.

---

## 8. 이벤트 시스템 패턴

### 이벤트 드리븐 아키텍처

모든 중요한 동작은 `Event` 레코드를 생성한다. 이벤트는 웹훅, 알림, 활동 타임라인을 구동한다.

**참고 파일**: `app/models/concerns/eventable.rb`

```ruby
module Eventable
  extend ActiveSupport::Concern

  included do
    has_many :events, as: :eventable, dependent: :destroy
  end

  def track_event(action, creator: Current.user, board: self.board, **particulars)
    if should_track_event?
      board.events.create!(
        action: "#{eventable_prefix}_#{action}",
        creator:,
        board:,
        eventable: self,
        particulars:
      )
    end
  end

  private
    def should_track_event?
      true
    end

    def eventable_prefix
      self.class.name.demodulize.underscore
    end
end
```

### 폴리모픽 연관

```ruby
class Event < ApplicationRecord
  belongs_to :eventable, polymorphic: true
  # eventable은 Card, Comment 등이 될 수 있다
end
```

### Event → Webhook → Notification 체인

```
Card/Comment에 대한 액션 발생
  → Event 레코드 생성
    → Event::RelayJob 큐에 추가 (트랜잭션 커밋 후)
      → 웹훅 트리거
      → 알림 생성
```

---

## 9. 라우트 구성 패턴

### 컨트롤러 네임스페이스를 위한 `scope module:`

URL 구조를 변경하지 않고 컨트롤러에 네임스페이스를 적용한다:

```ruby
resources :cards do
  scope module: :cards do
    resource :closure    # URL: /cards/:id/closure → Cards::ClosuresController
    resource :column     # URL: /cards/:id/column  → Cards::ColumnsController
    resources :comments  # URL: /cards/:id/comments → Cards::CommentsController
  end
end
```

### URL과 컨트롤러 모두 접두사를 붙이려면 `namespace`

```ruby
namespace :admin do
  mount MissionControl::Jobs::Engine, at: "/jobs"
end

namespace :public do
  resources :boards do
    resources :cards, only: :show
  end
end
```

### CRUD가 아닌 동작은 단수 리소스로 표현

```ruby
resource :session do
  scope module: :sessions do
    resources :transfers
    resource :magic_link
    resource :menu
  end
end

resources :cards do
  scope module: :cards do
    resource :closure
    resource :goldness
    resource :pin
    resource :publish
    resource :watch
  end
end
```

### 폴리모픽 URL 헬퍼를 위한 `resolve`

```ruby
resolve "Comment" do |comment, options|
  options[:anchor] = ActionView::RecordIdentifier.dom_id(comment)
  route_for :card, comment.card, options
end

resolve "Notification" do |notification, options|
  polymorphic_url(notification.notifiable_target, options)
end
```

---

## 10. 프론트엔드 패턴

### CSS 아키텍처 (CSS Layers + OKLCH 색상)

```css
@layer reset, base, components, modules, utilities;

/* OKLCH 색상 시스템 */
:root {
  --color-ink: oklch(20% 0 0);
  --color-canvas: oklch(98% 0 0);
  --color-link: oklch(50% 0.2 250);
}

/* 컴포넌트는 CSS 변수를 오버라이드하는 방식으로 커스터마이징 */
.btn {
  --btn-background: var(--color-link);
  background: var(--btn-background);
}
.btn--positive {
  --btn-background: oklch(55% 0.18 145);
}
```

**참고 파일**: `app/assets/stylesheets/_global.css`

### Stimulus 컨트롤러 패턴

**참고 파일**: `app/javascript/controllers/auto_save_controller.js`

```javascript
import { Controller } from "@hotwired/stimulus"

const AUTOSAVE_INTERVAL = 3000

export default class extends Controller {
  static targets = ["item"]
  static values = { url: String }

  #timer  // # 접두사로 프라이빗 필드 선언

  // 라이프사이클
  connect() { }
  disconnect() { this.submit() }

  // 액션 (public)
  async submit() {
    if (this.#dirty) {
      await this.#save()
    }
  }

  change(event) {
    if (event.target.form === this.element && !this.#dirty) {
      this.#scheduleSave()
    }
  }

  // 프라이빗 구현
  #scheduleSave() {
    this.#timer = setTimeout(() => this.#save(), AUTOSAVE_INTERVAL)
  }

  async #save() {
    this.#resetTimer()
    await submitForm(this.element)
  }

  #resetTimer() {
    clearTimeout(this.#timer)
    this.#timer = null
  }

  get #dirty() {
    return !!this.#timer
  }
}
```

**컨벤션**:
- 프라이빗 필드는 `#` 접두사 사용
- 그룹 순서: 라이프사이클 → 액션 → 프라이빗
- 각 섹션에 주석으로 레이블 표시
- `connect()` / `disconnect()`로 초기화/정리

### Turbo 사용 방침

- **Morphing** 우선 (전체 페이지 리로드 최소화)
- **Turbo Stream** — 폼 제출 후 부분 DOM 업데이트
- **Turbo Frame** — 격리된 섹션에만 제한적으로 사용

---

## 11. 테스트 패턴

### Fixture 기반 테스트

```yaml
# test/fixtures/cards.yml
logo:
  id: <%= ActiveRecord::FixtureSet.identify("logo", :uuid) %>
  board: writebook
  creator: david
  title: 로고가 너무 작습니다
  created_at: <%= 1.week.ago %>
```

### 모델 테스트

```ruby
test "카드 생성 시 번호가 할당된다" do
  assert_difference -> { account.reload.cards_count }, +1 do
    Card.create!(
      title: "테스트",
      board: boards(:writebook),
      creator: users(:david)
    )
  end
end
```

### 컨트롤러 테스트

```ruby
test "새 카드 생성" do
  sign_in_as :david

  assert_difference -> { Card.count }, 1 do
    post board_cards_path(boards(:writebook))
  end

  assert_redirected_to card_path(Card.last)
end
```

### 시스템 테스트

전체 엔드투엔드 플로우는 Capybara + Selenium으로 작성한다. `bin/rails test:system`으로 실행한다.

---

## 12. 새 Rails 프로젝트에 적용하기

### 1단계: 초기 설정

```bash
rails new myapp --database=sqlite3

# Gemfile에 추가
gem "importmap-rails"
gem "propshaft"
gem "stimulus-rails"
gem "turbo-rails"
gem "solid_queue"
gem "solid_cache"
gem "solid_cable"
```

### 2단계: UUID 기본키 설정

```ruby
# config/application.rb
config.generators do |g|
  g.orm :active_record, primary_key_type: :uuid
end
```

SQLite + MySQL 동시 지원을 위해 `config/initializers/uuid_primary_keys.rb`를 복사한다.

### 3단계: Current Attributes 설정

`app/models/current.rb`를 복사한 후 도메인에 맞게 속성을 조정한다:

```ruby
class Current < ActiveSupport::CurrentAttributes
  attribute :session, :user, :account
  attribute :request_id, :user_agent, :ip_address
end
```

### 4단계: Authentication Concern 설정

`app/controllers/concerns/authentication.rb`를 복사한 후 조정한다:
- `Session.find_signed`를 자신의 세션 모델로 교체
- API가 필요 없으면 `authenticate_by_bearer_token` 제거
- `before_action :require_authentication` 구조는 유지

### 5단계: Authorization Concern 설정

`app/controllers/concerns/authorization.rb`를 복사한 후 역할 확인 로직을 조정한다:

```ruby
module Authorization
  extend ActiveSupport::Concern

  private
    def ensure_admin
      head :forbidden unless Current.user.admin?
    end

    def ensure_can_access_account
      unless Current.account.active? && Current.user&.active?
        redirect_to login_path
      end
    end
end
```

### 6단계: 모델 Concerns 생성

다음 횡단 관심사(cross-cutting concerns)를 생성한다:

**`app/models/concerns/eventable.rb`** — 중요한 액션 추적 (Fizzy에서 복사)

**`app/models/concerns/notifiable.rb`**:
```ruby
module Notifiable
  extend ActiveSupport::Concern

  included do
    has_many :notifications, as: :source, dependent: :destroy
    after_create_commit :notify_recipients_later
  end

  def notify_recipients_later
    NotifyRecipientsJob.perform_later(self)
  end

  def notify_recipients_now
    Notifier.for(self)&.notify
  end
end
```

**`app/models/concerns/searchable.rb`** — 검색 인덱싱 (Fizzy에서 복사, `search_record_class` 조정)

### 7단계: 잡 Account 컨텍스트 설정

`config/initializers/active_job.rb`를 복사하고 `FizzyActiveJobExtensions`를 앱 이름에 맞게 변경한다:

```ruby
module MyAppActiveJobExtensions
  # ... 동일한 코드, 앱에 맞게 조정
end

ActiveSupport.on_load(:active_job) do
  prepend MyAppActiveJobExtensions
end
```

### 8단계: 에러 컨텍스트 설정

`config/initializers/error_context.rb`를 복사한다:

```ruby
Rails.error.add_middleware ->(error, context:, **) do
  context.merge \
    user_id: Current.user&.id,
    account_id: Current.account&.id
end
```

### 9단계: 라우트 구성

처음부터 `scope module:`을 활용해 라우트를 구조화한다:

```ruby
Rails.application.routes.draw do
  resources :posts do
    scope module: :posts do
      resource :publication
      resource :closure
      resources :comments
    end
  end

  resource :session do
    scope module: :sessions do
      resource :magic_link
    end
  end
end
```

---

## 핵심 파일 참조표

| 패턴 | Fizzy 파일 |
|------|-----------|
| Current Attributes | `app/models/current.rb` |
| 인증 Concern | `app/controllers/concerns/authentication.rb` |
| 권한 Concern | `app/controllers/concerns/authorization.rb` |
| 멀티테넌시 미들웨어 | `config/initializers/tenanting/account_slug.rb` |
| 잡 Account 직렬화 | `config/initializers/active_job.rb` |
| Eventable Concern | `app/models/concerns/eventable.rb` |
| Notifiable Concern | `app/models/concerns/notifiable.rb` |
| Searchable Concern | `app/models/concerns/searchable.rb` |
| 라우트 구성 | `config/routes.rb` |
| UUID 어댑터 | `config/initializers/uuid_primary_keys.rb` |
| 에러 컨텍스트 | `config/initializers/error_context.rb` |
| Stimulus 패턴 | `app/javascript/controllers/auto_save_controller.js` |
| 컨트롤러 예시 | `app/controllers/cards_controller.rb` |
