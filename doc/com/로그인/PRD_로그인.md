# PRD: 로그인 기능

## 1. 개요

WMS Pro 애플리케이션에 비밀번호 기반 로그인 기능을 추가합니다.
참조 화면의 레이아웃을 기반으로 하되, 앱의 기존 다크 테마 색상을 적용합니다.

### 참조 화면 vs 구현 범위

| 참조 화면 요소 | 구현 여부 | 비고 |
|---------------|----------|------|
| 로고 + 앱 타이틀 | O | "WMS Pro" |
| 비밀번호 로그인 섹션 제목 | O | |
| 이메일 입력 필드 | O | |
| 비밀번호 입력 필드 | O | |
| 확인 버튼 → 로그인 | O | 핵심 기능 |
| 나를 기억해줘 | X | 불필요 |
| 비밀번호를 잊으셨나요? | X | 불필요 |
| 인증 코드 로그인 | X | 불필요 |
| 계정 등록 | X | 불필요 |
| 역할 선택 버튼 | X | 불필요 |
| 다크/라이트 모드 토글 | X | 불필요 |
| 언어 변경 | X | 불필요 |

---

## 2. 목표

- 미인증 사용자가 앱에 접근하면 로그인 화면으로 리다이렉트한다
- 이메일 + 비밀번호로 인증 후 대시보드(`/`)로 이동한다
- 로그인 화면은 참조 디자인의 중앙 카드 레이아웃을 따르되, 앱의 다크 테마를 적용한다
- 기존 사이드바/탭/헤더 없이 독립된 레이아웃을 사용한다

---

## 3. 범위 외 (Out of Scope)

- 회원가입 (관리자가 Rails 콘솔 또는 시드로 사용자 생성)
- 비밀번호 찾기 / 재설정
- 소셜 로그인 (OAuth)
- 역할 기반 접근 제어 (RBAC)
- Remember me (세션 유지)
- 멀티테넌시

---

## 4. 사용자 시나리오

### 4.1 로그인 성공

```
1. 사용자가 앱(예: /)에 접근한다
2. 인증되지 않았으므로 /session/new (로그인 페이지)로 리다이렉트된다
3. 이메일과 비밀번호를 입력한다
4. "확인" 버튼을 클릭한다
5. 인증 성공 → 원래 접근하려던 페이지(또는 대시보드)로 이동한다
6. 사이드바 하단에 로그인한 사용자 정보가 표시된다
```

### 4.2 로그인 실패

```
1. 사용자가 잘못된 이메일 또는 비밀번호를 입력한다
2. "확인" 버튼을 클릭한다
3. 로그인 폼 위에 에러 메시지가 표시된다: "이메일 또는 비밀번호가 올바르지 않습니다"
4. 입력 필드는 유지된다 (이메일 값 보존)
```

### 4.3 로그아웃

```
1. 사용자가 로그아웃 버튼을 클릭한다 (사이드바 하단)
2. 세션이 삭제되고 로그인 페이지로 이동한다
```

---

## 5. 기술 설계

### 5.1 데이터 모델

#### User 모델

```ruby
# app/models/user.rb
class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  validates :email_address, presence: true,
                            uniqueness: true,
                            format: { with: URI::MailTo::EMAIL_REGEXP }

  normalizes :email_address, with: -> (e) { e.strip.downcase }
end
```

```
# 마이그레이션
create_table :users do |t|
  t.string :email_address, null: false
  t.string :password_digest, null: false
  t.timestamps
end
add_index :users, :email_address, unique: true
```

#### Session 모델

```ruby
# app/models/session.rb
class Session < ApplicationRecord
  belongs_to :user

  before_create :generate_token

  private
    def generate_token
      self.token = SecureRandom.urlsafe_base64(32)
    end
end
```

```
# 마이그레이션
create_table :sessions do |t|
  t.references :user, null: false, foreign_key: true
  t.string :token, null: false
  t.string :user_agent
  t.string :ip_address
  t.timestamps
end
add_index :sessions, :token, unique: true
```

#### Current 클래스

```ruby
# app/models/current.rb
class Current < ActiveSupport::CurrentAttributes
  attribute :session, :user

  def session=(value)
    super(value)
    self.user = value&.user
  end
end
```

### 5.2 라우팅

```ruby
# config/routes.rb
resource :session, only: [:new, :create, :destroy]
```

| HTTP | 경로 | 컨트롤러#액션 | 용도 |
|------|------|-------------|------|
| GET | /session/new | sessions#new | 로그인 폼 |
| POST | /session | sessions#create | 로그인 처리 |
| DELETE | /session | sessions#destroy | 로그아웃 |

### 5.3 인증 흐름

```
                     ┌─────────────────┐
                     │ 브라우저 요청     │
                     └────────┬────────┘
                              │
                     ┌────────▼────────┐
                     │ Authentication  │
                     │ Concern         │
                     │ (before_action) │
                     └────────┬────────┘
                              │
                   ┌──────────▼──────────┐
                   │ 서명 쿠키에 세션      │
                   │ 토큰이 있는가?        │
                   └──────────┬──────────┘
                     Yes │          │ No
                  ┌──────▼─────┐  ┌▼───────────────┐
                  │ Session     │  │ 로그인 페이지로  │
                  │ 조회 + 복원  │  │ 리다이렉트      │
                  └──────┬─────┘  └────────────────┘
                         │
                  ┌──────▼─────┐
                  │ Current에   │
                  │ user 설정   │
                  └──────┬─────┘
                         │
                  ┌──────▼─────┐
                  │ 요청 처리   │
                  └────────────┘
```

### 5.4 컨트롤러

#### Authentication Concern

```ruby
# app/controllers/concerns/authentication.rb
module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private
    def authenticated?
      Current.user.present?
    end

    def require_authentication
      resume_session || request_authentication
    end

    def resume_session
      if session_record = find_session_by_cookie
        Current.session = session_record
      end
    end

    def find_session_by_cookie
      if token = cookies.signed[:session_token]
        Session.find_by(token: token)
      end
    end

    def request_authentication
      session[:return_to_after_authenticating] = request.url
      redirect_to new_session_path
    end

    def after_authentication_url
      session.delete(:return_to_after_authenticating) || root_url
    end

    def start_new_session_for(user)
      user.sessions.create!(
        user_agent: request.user_agent,
        ip_address: request.remote_ip
      ).tap do |session_record|
        Current.session = session_record
        cookies.signed.permanent[:session_token] = {
          value: session_record.token,
          httponly: true,
          same_site: :lax
        }
      end
    end

    def terminate_session
      Current.session&.destroy
      cookies.delete(:session_token)
    end
end
```

#### SessionsController

```ruby
# app/controllers/sessions_controller.rb
class SessionsController < ApplicationController
  allow_unauthenticated_access only: [:new, :create]

  layout "session"

  def new
  end

  def create
    if user = User.authenticate_by(email_address: params[:email_address],
                                    password: params[:password])
      start_new_session_for(user)
      redirect_to after_authentication_url
    else
      flash.now[:alert] = "이메일 또는 비밀번호가 올바르지 않습니다"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path
  end
end
```

#### ApplicationController 변경

```ruby
class ApplicationController < ActionController::Base
  include Authentication   # ← 추가

  allow_browser versions: :modern
  stale_when_importmap_changes

  before_action :ensure_tab_session

  # ... 기존 코드 유지
end
```

### 5.5 UI 설계

#### 레이아웃: `layouts/session.html.erb`

사이드바/탭/헤더 없이 로그인 전용 최소 레이아웃을 사용합니다.

```
┌─────────────────────────────────────────────┐
│            (전체 화면, 다크 배경)              │
│                                             │
│         ┌───────────────────────┐           │
│         │  ┌──┐                 │           │
│         │  │W │ WMS Pro         │           │
│         │  └──┘                 │           │
│         │                       │           │
│         │  로그인               │           │
│         │                       │           │
│         │  ┌─────────────────┐  │           │
│         │  │ 이메일           │  │           │
│         │  └─────────────────┘  │           │
│         │                       │           │
│         │  ┌─────────────────┐  │           │
│         │  │ 비밀번호         │  │           │
│         │  └─────────────────┘  │           │
│         │                       │           │
│         │  ┌─────────────────┐  │           │
│         │  │      확인        │  │           │
│         │  └─────────────────┘  │           │
│         │                       │           │
│         └───────────────────────┘           │
│                                             │
└─────────────────────────────────────────────┘
```

#### 색상 매핑

| 요소 | CSS 변수 | 값 |
|------|---------|-----|
| 배경 | --bg-primary | #0f1117 (+ 미묘한 radial gradient) |
| 카드 배경 | --bg-secondary | #161b22 |
| 카드 테두리 | --border | #30363d |
| 입력 필드 배경 | --bg-primary | #0f1117 |
| 입력 필드 테두리 | --border | #30363d |
| 입력 포커스 | --accent | #58a6ff |
| 확인 버튼 | --accent | #58a6ff |
| 제목 텍스트 | --text-primary | #e6edf3 |
| 섹션 제목 | --accent | #58a6ff |
| placeholder | --text-muted | #484f58 |
| 에러 메시지 | --accent-rose | #f85149 |

#### 주요 CSS 클래스

```
.login-container    — 전체 화면 중앙 정렬 (flexbox)
.login-card         — 카드 (max-width: 420px, padding: 40px)
.login-header       — 로고 + 앱 이름 영역
.login-section-title — "비밀번호 로그인" 텍스트
.login-actions      — 확인 버튼 wrapper (전체 너비)
.btn-login          — 확인 버튼 (전체 너비, 더 큰 패딩)
```

기존 클래스 재사용: `.form-group`, `.form-label`, `.form-control`, `.error-messages`, `.logo-icon`

---

## 6. 구현 단계

### Phase 1: 백엔드 기반 (인증 인프라)

| # | 작업 | 파일 |
|---|------|------|
| 1 | bcrypt 젬 활성화 | `Gemfile` |
| 2 | User 모델 + 마이그레이션 | `app/models/user.rb`, `db/migrate/..._create_users.rb` |
| 3 | Session 모델 + 마이그레이션 | `app/models/session.rb`, `db/migrate/..._create_sessions.rb` |
| 4 | Current 클래스 | `app/models/current.rb` |
| 5 | Authentication concern | `app/controllers/concerns/authentication.rb` |
| 6 | ApplicationController에 include | `app/controllers/application_controller.rb` |
| 7 | 라우팅 추가 | `config/routes.rb` |
| 8 | SessionsController | `app/controllers/sessions_controller.rb` |

### Phase 2: 프론트엔드 (로그인 화면)

| # | 작업 | 파일 |
|---|------|------|
| 9 | 로그인 전용 레이아웃 | `app/views/layouts/session.html.erb` |
| 10 | 로그인 뷰 | `app/views/sessions/new.html.erb` |
| 11 | 로그인 CSS | `app/assets/stylesheets/application.css` (하단 추가) |

### Phase 3: 부가 기능

| # | 작업 | 파일 |
|---|------|------|
| 12 | 사이드바 로그아웃 버튼 | `app/views/shared/_sidebar.html.erb` |
| 13 | 사이드바 사용자 정보 동적 표시 | `app/views/shared/_sidebar.html.erb` |
| 14 | 시드 데이터 (기본 사용자) | `db/seeds.rb` |

### Phase 4: 테스트

| # | 작업 | 파일 |
|---|------|------|
| 15 | User 모델 테스트 | `test/models/user_test.rb` |
| 16 | Session 모델 테스트 | `test/models/session_test.rb` |
| 17 | SessionsController 테스트 | `test/controllers/sessions_controller_test.rb` |
| 18 | 인증 통합 테스트 | `test/integration/authentication_test.rb` |

---

## 7. 테스트 계획

### 모델 테스트

```
User
  ✓ 유효한 속성으로 생성 가능
  ✓ email_address 없이 생성 불가
  ✓ password 없이 생성 불가
  ✓ 중복 email_address 생성 불가
  ✓ email_address는 소문자로 정규화
  ✓ email_address 형식 검증

Session
  ✓ user 연결 필수
  ✓ 생성 시 token 자동 생성
```

### 컨트롤러 테스트

```
SessionsController
  GET /session/new
    ✓ 로그인 페이지 렌더링 (200)
    ✓ 이미 로그인된 경우에도 접근 가능

  POST /session
    ✓ 올바른 자격증명 → 리다이렉트 + 쿠키 설정
    ✓ 잘못된 비밀번호 → 422 + 에러 메시지
    ✓ 존재하지 않는 이메일 → 422 + 에러 메시지
    ✓ 로그인 후 원래 URL로 리다이렉트

  DELETE /session
    ✓ 세션 삭제 + 쿠키 제거 + 로그인 페이지로 이동
```

### 통합 테스트

```
인증 흐름
  ✓ 미인증 사용자 → 보호된 페이지 접근 → 로그인으로 리다이렉트
  ✓ 로그인 → 원래 페이지로 복귀
  ✓ 로그아웃 → 보호된 페이지 접근 불가
```

---

## 8. 시드 데이터

```ruby
# db/seeds.rb
User.find_or_create_by!(email_address: "admin@example.com") do |user|
  user.password = "password"
  user.password_confirmation = "password"
end

puts "기본 사용자 생성: admin@example.com / password"
```

---

## 9. 파일 변경 목록 (전체)

### 신규 생성

| 파일 | 설명 |
|------|------|
| `app/models/user.rb` | 사용자 모델 |
| `app/models/session.rb` | 세션 모델 |
| `app/models/current.rb` | 요청 컨텍스트 |
| `app/controllers/concerns/authentication.rb` | 인증 Concern |
| `app/controllers/sessions_controller.rb` | 로그인/로그아웃 컨트롤러 |
| `app/views/layouts/session.html.erb` | 로그인 전용 레이아웃 |
| `app/views/sessions/new.html.erb` | 로그인 폼 뷰 |
| `db/migrate/YYYYMMDD_create_users.rb` | users 테이블 |
| `db/migrate/YYYYMMDD_create_sessions.rb` | sessions 테이블 |
| `test/models/user_test.rb` | User 테스트 |
| `test/models/session_test.rb` | Session 테스트 |
| `test/controllers/sessions_controller_test.rb` | 컨트롤러 테스트 |

### 수정

| 파일 | 변경 내용 |
|------|----------|
| `Gemfile` | bcrypt 주석 해제 |
| `config/routes.rb` | `resource :session` 추가 |
| `app/controllers/application_controller.rb` | `include Authentication` 추가 |
| `app/assets/stylesheets/application.css` | 로그인 CSS 추가 |
| `app/views/shared/_sidebar.html.erb` | 로그아웃 버튼 + 동적 사용자 정보 |
| `db/seeds.rb` | 기본 사용자 추가 |
