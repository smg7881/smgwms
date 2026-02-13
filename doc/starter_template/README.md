# Rails 스타터 템플릿

Fizzy 코드베이스(37signals/Basecamp)에서 추출한 핵심 파일들로, 프로덕션 수준의 패턴을 새 Rails 프로젝트에 빠르게 적용하기 위한 템플릿입니다.

전체 아키텍처 레퍼런스는 Fizzy 루트의 `STYLE_GUIDE.md`를 참고하세요.

---

## 파일 설명

### `app/models/current.rb`

`ActiveSupport::CurrentAttributes`를 사용한 스레드 로컬 요청 컨텍스트입니다.

**조정 방법**: 도메인에 맞게 속성 이름을 변경하세요. `user`와 분리된 `identity`가 필요 없다면 해당 속성을 제거하고 단순화하세요.

**핵심 패턴**: 세터 체이닝 — `session`을 설정하면 자동으로 `identity`가 설정되고, `identity`가 설정되면 자동으로 `user`가 설정됩니다.

---

### `app/controllers/concerns/authentication.rb`

HTTP-only 서명 쿠키를 사용한 세션 기반 인증입니다.

**조정 방법**:
1. `find_session_by_cookie`를 자신의 `Session` 모델 조회로 교체
2. `redirect_to_login_url`을 자신의 로그인 경로로 교체
3. API 토큰이 필요 없으면 `authenticate_by_bearer_token` 제거
4. 멀티테넌시를 사용하지 않으면 `require_account` 제거

**ApplicationController에서 사용**:
```ruby
class ApplicationController < ActionController::Base
  include Authentication
  include Authorization
end
```

**특정 액션에서 인증 건너뛰기**:
```ruby
class SessionsController < ApplicationController
  allow_unauthenticated_access only: [:new, :create]
end
```

---

### `app/controllers/concerns/authorization.rb`

역할 기반 접근 제어(RBAC)입니다.

**조정 방법**:
1. 필요에 따라 역할 확인 헬퍼 추가 (`ensure_owner`, `ensure_member` 등)
2. 자신의 계정/사용자 상태 필드에 맞게 `ensure_can_access_account` 수정
3. 멀티테넌시를 사용하지 않으면 `before_action :ensure_can_access_account` 제거

**컨트롤러에서 사용**:
```ruby
class AdminController < ApplicationController
  before_action :ensure_admin
end
```

---

### `app/models/concerns/eventable.rb`

모델의 중요한 액션을 `Event` 레코드로 추적합니다.

**사전 조건**: 다음 구조의 `Event` 모델이 필요합니다:
- `belongs_to :eventable, polymorphic: true`
- `belongs_to :creator` (사용자 모델)
- `belongs_to :board` (또는 "워크스페이스" 역할을 하는 모델)
- `string :action`
- `jsonb :particulars` (또는 JSON 직렬화를 사용하는 `text`)

**사용 예시**:
```ruby
class Post < ApplicationRecord
  include Eventable

  def publish!
    update!(published_at: Time.current)
    track_event("published")
  end
end
```

---

### `app/models/concerns/notifiable.rb`

레코드 생성 후 알림을 발송합니다.

**사전 조건**:
1. `belongs_to :source, polymorphic: true`를 가진 `Notification` 모델 생성
2. `notifiable.notify_recipients_now`를 호출하는 `NotifyRecipientsJob` 생성
3. `Notifier` 클래스 구현 (또는 `notify_recipients_now` 스텁 교체)

**사용 예시**:
```ruby
class Comment < ApplicationRecord
  include Notifiable
end
```

---

### `config/initializers/active_job_extensions.rb`

잡이 큐에 추가될 때 `Current.account`를 직렬화하고, 실행 전에 복원합니다.

**사전 조건**: `Current`에 `with_account`가 있어야 합니다 (`app/models/current.rb`에 포함).

**조정 방법**: `AppActiveJobExtensions`를 앱 이름에 맞게 변경하세요.

**핵심 이점**: 요청 내부에서 큐에 추가된 잡은 자동으로 올바른 계정 컨텍스트로 실행됩니다. 모든 잡에 `account_id`를 수동으로 전달할 필요가 없습니다.

---

### `config/initializers/error_context.rb`

모든 에러 리포트에 사용자 및 계정 컨텍스트를 추가합니다.

**조정 방법**: `user_id`와 `account_id`를 자신의 `Current` 속성에 맞게 변경하세요.

**호환 도구**: `Rails.error.subscribe`로 통합되는 모든 에러 추적 도구 (Sentry의 `sentry-rails`, Honeybadger, Bugsnag 등).

---

## 빠른 시작

1. 이 파일들을 새 Rails 프로젝트에 복사
2. 필수 모델 생성 (`Session`, `Identity`, `User`, `Account`, `Event`, `Notification`)
3. `ApplicationController`에 Concern 포함:

```ruby
class ApplicationController < ActionController::Base
  include Authentication
  include Authorization
end
```

4. `active_job_extensions.rb`의 `AppActiveJobExtensions`를 앱 이름으로 변경
5. `bin/rails test`로 기존 테스트 통과 여부 확인

---

## 복사 전 결정해야 할 아키텍처 사항

| 결정 사항 | 선택지 |
|----------|--------|
| 인증 방식 | 매직 링크(패스워드리스) vs. 비밀번호 기반 |
| 사용자 모델 | 분리된 `Identity` + `User` (멀티 계정) vs. 단일 `User` |
| 멀티테넌시 | URL 경로 기반 (Fizzy 방식) vs. 서브도메인 vs. 없음 |
| API 토큰 | `AccessToken` 모델 vs. Devise 토큰 인증 vs. 없음 |
| 검색 | 샤딩 전문 검색 (MySQL) vs. pg_search vs. Elasticsearch vs. 없음 |

각 패턴의 상세 내용은 `STYLE_GUIDE.md`를 참고하세요.
